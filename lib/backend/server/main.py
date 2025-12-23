import json
import os
import asyncio
import firebase_admin
import logging
from firebase_admin import credentials, firestore
from fastapi import FastAPI, Query
from datetime import datetime, timedelta, timezone
from models import *
from utils import *
from fastapi.concurrency import run_in_threadpool
from google.cloud.firestore import FieldFilter
from google.cloud.firestore import transactional
WRITE_CONCURRENCY = 10
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

@app.get("/metrics")
def metrics():
    return {
        "queue_size": write_queue.qsize(),
        "queue_capacity": write_queue.maxsize
    }

@app.post("/event/create")
async def createEvent(event: Event):
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
    print(after)
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

@app.post("/user/create")
async def createUser(user: User):
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