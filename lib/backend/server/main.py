import firebase_admin
from firebase_admin import credentials, firestore
from fastapi import FastAPI, Body

#Connect the Firebase database
cred = credentials.Certificate("service-account-file.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

app = FastAPI(title = "QuickHelp")

@app.post("/event/create")
def createEvent(eventData: dict = Body()):
    db.collection("event_info").add(eventData)
    return {"ok": True}