import json
import random
import time
import os
import asyncio
from fastapi.responses import FileResponse
import firebase_admin
import logging
from firebase_admin import credentials, firestore
from fastapi import FastAPI, Query, WebSocket, WebSocketDisconnect
from datetime import datetime, timedelta, timezone
from models import *
from utils import *
from fastapi.concurrency import run_in_threadpool
from google.cloud.firestore import transactional
from fastapi.staticfiles import StaticFiles
from cryptography.fernet import Fernet
MAX_RETRIES = 5
WRITE_CONCURRENCY = 40
GLOBAL_LIMIT = 120
request_sem = asyncio.Semaphore(GLOBAL_LIMIT)
write_queue = asyncio.Queue(maxsize=3000)

#Connect the Firebase database
firebase_json = json.loads(os.environ["FIREBASE_SERVICE_ACCOUNT"])
cred = credentials.Certificate(firebase_json)
firebase_admin.initialize_app(cred)
db = firestore.client()

#Launch the FastAPI
app = FastAPI(title = "QuickHelp")
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

active_connections = {}

app.mount("/static", StaticFiles(directory="static", html=True), name="static")

@app.get("/")
def serveIndex():
    return FileResponse("static/index.html")
@app.on_event("startup")
async def startWorkers():
    for i in range(WRITE_CONCURRENCY):
        asyncio.create_task(writeWorker())

@app.on_event("shutdown")
async def shutdown():
    await write_queue.join()
async def writeWorker():
    while True:
        collection, doc_id, data = await write_queue.get()
        try:
            await run_in_threadpool(db.collection(collection).document(doc_id).set, data)
        except Exception as e:
            logger.error("Write failed: {}".format(e))
        finally:
            write_queue.task_done()

@app.get("/health")
def health():
    return {"ok": True}

@app.get("/metrics")
def metrics():
    return {
        "queue_size": write_queue.qsize(),
        "queue_capacity": write_queue.maxsize
    }

async def connect(event_id, websocket: WebSocket):
    await websocket.accept()
    if event_id not in active_connections:
        active_connections[event_id] = []
    active_connections[event_id].append(websocket)

async def disconnect(event_id, websocket: WebSocket):
    active_connections[event_id].remove(websocket)

async def broadcast(event_id, data):
    for ws in active_connections[event_id]:
        await ws.send_json(data)

@app.websocket("/websocket/chat/{event_id}")
async def chatWebSocket(websocket: WebSocket, event_id: str):
    await connect(event_id, websocket)
    try:
        while True:
            data = await websocket.receive_json()
            now_utc_iso = datetime.now(timezone.utc).isoformat()
            encryptedText = encryptText(data["text"])
            message = {
                "text": encryptedText,
                "sender_id": data["sender_id"],
                "sender_name": data["sender_name"],
                "created_at": firestore.firestore.SERVER_TIMESTAMP,
                "created_at_iso": now_utc_iso
            }
            doc_ref = (
                db.collection("chats").document(event_id)
                .collection("messages").document()
            )
            doc_ref.set(message)
            broadcast_payload = {
                **data,
                "created_at": datetime.now(timezone.utc).isoformat()
            }
            await broadcast(event_id, {
                **data,
                "created_at_iso": now_utc_iso
            })
    except WebSocketDisconnect:
        await disconnect(event_id, websocket)

@app.get("/event/{event_id}/chats")
async def getEventMessages(event_id: str, limit: int = 50):
    messages_ref = db.collection("chats").document(event_id).collection("messages")
    query = messages_ref.order_by("created_at").limit_to_last(limit)
    docs = query.get()
    result = []
    for doc in docs:
        data = doc.to_dict()

        #Decrypted text
        if "text" in data:
            data["text"] = decryptText(data["text"])

        ts = data.get("created_at")
        if ts:
            data["created_at_iso"] = ts.replace(tzinfo=timezone.utc).isoformat()
        result.append(data)
    result.sort(key=lambda x: x.get("created_at_iso"))
    return {"ok": True, "messages": result}

@app.post("/event/create")
async def createEvent(event: Event):
    async with request_sem:
        def createEventTransaction(db, eventID, data):
            doc_ref = db.collection("event_info").document(eventID)
            transaction = db.transaction()

            @transactional
            def txn(transaction):
                snapshot = doc_ref.get(transaction=transaction)
                if snapshot.exists:
                    return False
                transaction.set(doc_ref, data)
                return True
            return txn(transaction)

        if write_queue.full():
            return {"ok": False, "msg": "Server is overloaded, try again shortly."}
        
        #Check if coordinates are valid
        if not ((-90 <= event.selected_lat <= 90) and (-180 <= event.selected_lon <= 180)):
            return {"ok": False, "msg": "Location is not valid."}
        
        try:
            #Duplication handling
            eventID = generateEventID(event)
            serverTime = datetime.now(timezone.utc)
            expire_at =  event.starting_date + timedelta(minutes=event.duration)
            
            data = {
                **event.model_dump(),
                "participant_count": 0,
                "createdAt": serverTime,
                "expireAt": expire_at
            }

            try:
                created = await run_in_threadpool(createEventTransaction, db, eventID, data)
                if not created:
                    return {"ok": False, "msg": "Event already exists."}
                logger.info("Created event {} by user {}".format(eventID,event.user_id))
                return {"ok": True, "event_id": eventID}
            except Exception as e:
                logger.error("Transaction failed: {}".format(e))
        except Exception as e:
            print(e)
            print("Failed to create event")
            return {"ok": False, "msg": "Failed to create event (internal API error)."}

@app.get("/events")
async def getEvents(after: Optional[str] = Query(None, description="Last document ID"), limit: int = 50):
    try:
        query = db.collection("event_info").order_by("createdAt")
        if after:
            last_doc = await run_in_threadpool(lambda: db.collection("event_info").document(after).get())
            query = query.start_after(last_doc)
        docs = await run_in_threadpool(lambda: list(query.limit(limit).stream()))
        events = []
        last_id = None
        for doc in docs:
            data = doc.to_dict()
            data["id"] = doc.id
            events.append(data)
            last_id = doc.id
        return {"ok": True, "events": events, "cursor": last_id}
    except Exception as e:
        print(e)
        return {"ok": False, "msg": str(e)}

@app.post("/event/{eventID}/join")
async def joinEvent(eventID: str, body: JoinRequest):
    async with request_sem:
        def joinEventTransaction():
            transaction = db.transaction()
            @firestore.transactional
            def run(transaction):
                user_doc = db.collection("user_info").document(body.user_id).collection("user_attended_events").document(eventID)
                part_doc = db.collection("participants").document(eventID).collection("users").document(body.user_id)
                event_doc = db.collection("event_info").document(eventID)
                request_doc = db.collection("join_requests").document("{}_{}".format(eventID,body.user_id))

                user_snapshot = part_doc.get(transaction=transaction)

                if user_snapshot.exists:
                    return {"ok": False, "msg": "You already joined this event."}
                
                event_snapshot = event_doc.get(transaction=transaction)
                event_data = event_snapshot.to_dict()
                if event_data["participant_count"] >= event_data["people_needed"]:
                    return {"ok": False, "msg": "Event is full."}
                
                if event_data["instant_join"] == True:
                    transaction.set(user_doc, {
                        "joined_at": firestore.firestore.SERVER_TIMESTAMP
                    })
                    transaction.set(part_doc, {
                        "joined_at": firestore.firestore.SERVER_TIMESTAMP
                    })

                    transaction.update(event_doc, {
                        "participant_count": firestore.firestore.Increment(1)
                    })
                else:
                    request_snapshot = request_doc.get(transaction=transaction)
                    if request_snapshot.exists:
                        return {"ok": False, "msg": "You already sent request to join this event. Wait for join approval from event organizer."}
                    transaction.set(request_doc, {
                        "requester_name": body.user_name,
                        "event_id": eventID,
                        "requester_id": body.user_id,
                        "host_id": event_data["user_id"],
                        "status": "pending",
                        "requested_at": firestore.firestore.SERVER_TIMESTAMP
                    })
                return {"ok": True, "instant_join": event_data["instant_join"]}
            for i in range(MAX_RETRIES):
                try:
                    return run(transaction)
                except Exception as e:
                    print(e)
                    sleep = (2 ** i) * 0.05 + random.random() * 0.05
                    time.sleep(sleep)
            return {"ok": False, "msg": "System is busy, try again shortly."}
        result = await run_in_threadpool(joinEventTransaction)
        return result

@app.post("/event/{eventID}/leave")
async def leaveEvent(eventID: str, user_id: str):
    async with request_sem:
        def leaveEventTransaction():
            transaction = db.transaction()

            @firestore.transactional
            def run(transaction):
                user_doc = db.collection("participants").document(eventID).collection("users").document(user_id)
                event_doc = db.collection("event_info").document(eventID)

                user_snapshot = user_doc.get(transaction=transaction)

                if not user_snapshot.exists:
                    return False
                
                transaction.delete(user_doc)

                transaction.update(event_doc, {
                    "participant_count": firestore.firestore.Increment(-1)
                })

                return True
            return run(transaction)
        removed = await run_in_threadpool(leaveEventTransaction)
        if not removed:
            return {"ok": False, "msg": "You already did not join this event."}
        return {"ok": True}

@app.get("/{userID}/requests")
async def getEventRequests(userID: str, after: Optional[str] = Query(None), limit: int = 50):
    try:
        query = db.collection("join_requests").where("host_id", "==", userID).where("status", "==", "pending").order_by("__name__")
        if after:
            last_doc = await run_in_threadpool(lambda: db.collection("join_requests").document(after).get())
            query = query.start_after(last_doc)
        docs = await run_in_threadpool(lambda: list(query.limit(limit).stream()))
        requests = []
        last_id = None
        for doc in docs:
            data = doc.to_dict()
            requests.append(data)
            last_id = doc.id
        return {"ok": True, "requests": requests, "cursor": last_id}
    except Exception as e:
        print(e)
        return {"ok": False, "msg": str(e)}

@app.post("/event/{eventID}/requests")
async def eventRequests(eventID: str, body: EventRequest):
    async with request_sem:
        def eventRequestsTransaction():
            transaction = db.transaction()

            @firestore.transactional
            def run(transaction):
                request_doc = db.collection("join_requests").document("{}_{}".format(eventID,body.user_id))
                user_doc = db.collection("user_info").document(body.user_id).collection("user_attended_events").document(eventID)
                part_doc = db.collection("participants").document(eventID).collection("users").document(body.user_id)
                event_doc = db.collection("event_info").document(eventID)
                if(body.status == "reject"):
                    transaction.update(request_doc, {
                        "status": "rejected",
                    })
                elif(body.status == "approve"):
                    event_snapshot = event_doc.get(transaction=transaction)
                    event_data = event_snapshot.to_dict()

                    #User cannot join if event capacity is full
                    if event_data["participant_count"] >= event_data["people_needed"]:
                        return {"ok": False, "msg": "Event is full, cannot approve join request."}
                    
                    transaction.update(request_doc, {
                        "status": "approved",
                    })

                    transaction.set(user_doc, {
                        "joined_at": firestore.firestore.SERVER_TIMESTAMP
                    })
                    transaction.set(part_doc, {
                        "joined_at": firestore.firestore.SERVER_TIMESTAMP
                    })

                    transaction.update(event_doc, {
                        "participant_count": firestore.firestore.Increment(1)
                    })
                return {"ok": True}
            for i in range(MAX_RETRIES):
                try:
                    return run(transaction)
                except Exception as e:
                    sleep = (2 ** i) * 0.05 + random.random() * 0.05
                    time.sleep(sleep)
            return {"ok": False, "msg": "System is busy, try again shortly."}
        result = await run_in_threadpool(eventRequestsTransaction)
        return result

@app.get("/event/delete/all")
def removeEventAll(secret: str = Query(...)):
    if secret != os.environ.get("ADMIN_SECRET"):
        return {"ok": False, "msg":"Forbidden"}
    docs = db.collection("event_info").list_documents()
    for doc in docs:
        print("Removing event with id {}".format(doc.id))
        doc.delete()
    print("Removed all events successfully.")
    return {"ok": True}

@app.get("/user")
async def getUser(id: str = Query(...)):
    try:
        doc_ref = db.collection("user_info").document(id)
        doc = await run_in_threadpool(doc_ref.get)
        if not doc.exists:
            return {"ok": True, "user": None}
        user_data = doc.to_dict()
        user_data["id"] = doc.id

        doc_ref = db.collection("user_info").document(id).collection("user_attended_events")
        docs = await run_in_threadpool(doc_ref.get)
        attended_events = [doc.id for doc in docs]
        return {"ok": True, "user": user_data, "user_attended_events": attended_events}
    except Exception as e:
        print(e)
        return {"ok": False, "msg": str(e)}

@app.post("/user/create")
async def createUser(user: User):
    async with request_sem:
        try:
            serverTime = datetime.now(timezone.utc)
            def setUser():
                return db.collection("user_info").document(user.id).set({
                    **user.model_dump(),
                    "updatedAt": serverTime
                })
            write_result = await run_in_threadpool(setUser)
            logger.info("Created user with id {}".format(user.id))

            return {"ok": True, "id": user.id}
        except Exception as e:
            print("Failed to create user: {}".format(e))
            return {"ok": False, "msg": "Failed to create user (internal API error)."}