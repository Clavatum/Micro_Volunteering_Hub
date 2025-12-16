import firebase_admin
import logging
from firebase_admin import credentials, firestore
from fastapi import FastAPI
from datetime import datetime, timedelta, timezone
from models import *
from utils import *

#Connect the Firebase database
cred = credentials.Certificate("service-account-file.json")
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