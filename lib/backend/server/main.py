import json
import os
import firebase_admin
import logging
from firebase_admin import credentials, firestore
from fastapi import FastAPI, Query
from datetime import datetime, timedelta, timezone
from models import *
from utils import *

#Connect the Firebase database
firebase_json = json.loads(os.environ["FIREBASE_SERVICE_ACCOUNT"])
cred = credentials.Certificate(firebase_json)
firebase_admin.initialize_app(cred)
db = firestore.client()
app = FastAPI(title = "QuickHelp")
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@app.post("/event/create")
def createEvent(event: Event):
    #Check if coordinates are valid
    if not ((-90 <= event.selected_lat <= 90) or (-180 <= event.selected_lon <= 180)):
        return {"ok": False, "msg": "Location is not valid."}
    
    try:
        eventID = generateEventID(event)
        doc_ref = db.collection("event_info").document(eventID)
        if doc_ref.get().exists:
            return {"ok": False, "msg": "Event already has been created and can't be duplicated."}

        #Use server side timestamp to avoid fake device timestamp
        serverTime = datetime.now(timezone.utc)
        expire_at =  event.starting_date + timedelta(hours=event.duration)

        doc_ref = db.collection("event_info").add({
            **event.model_dump(),
            "createdAt": serverTime,
            "expireAt": expire_at
        })
        logger.info("Creating event by user {}".format(event.user_id))

        return {"ok": True, "event_id": doc_ref[1].id}
    except Exception as e:
        print(e)
        print("Failed to create event")
        return {"ok": False, "msg": "Failed to create event (internal API error)."}

@app.get("/events")
def getEvents(since: Optional[int] = Query(None, description="Unix timestamp in ms"), limit: int = 50):
    timestamps = []
    try:
        query = db.collection("event_info").order_by("createdAt")
        
        docs = list(query.limit(limit).stream())
        events = []
        for doc in docs:
            data = doc.to_dict()
            data["id"] = doc.id
            ts = data.get("createdAt")
            if ts:
                timestamps.append(int(ts.timestamp()*1000))
            if since != None:
                if timestamps[-1] > since:
                    events.append(data)
            else:
                events.append(data)
        return {"ok": True, "events": events, "last_ts": max(timestamps)}
    except Exception as e:
        print(e)
        return {"ok": False, "msg": str(e)}

@app.get("/event/delete/all")
def removeEventAll():
    docs = db.collection("event_info").list_documents()
    for doc in docs:
        print("Removing event with id {}".format(doc.id))
        doc.delete()
    print("Removed all events successfully.")
    return {"ok": True}

@app.post("/user/create")
def createUser(user: User):
    try:
        serverTime = datetime.now(timezone.utc)
        db.collection("user_info").document(user.id).set({
            **user.model_dump(),
            "updatedAt": serverTime,
        })
        logger.info("Created user with id {}".format(user.id))

        return {"ok": True, "id": user.id}
    except Exception as e:
        print("Failed to create user: {}".format(e))
        return {"ok": False, "msg": "Failed to create user (internal API error)."}