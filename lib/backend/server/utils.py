import hashlib
import os
from models import *
from cryptography.fernet import Fernet

ENCRYPTION_KEY = os.getenv("FIREBASE_ENCRYPTION_KEY")
cipher_suite = Fernet(ENCRYPTION_KEY.encode())

def encryptText(rawText: str) -> str:
    if not rawText:
        return rawText
    return cipher_suite.encrypt(rawText.encode()).decode()

def decryptText(encryptedText: str) -> str:
    if not encryptedText:
        return encryptedText
    try:
        return cipher_suite.decrypt(encryptedText.encode()).decode()
    except Exception:
        #Return if text is already decrypted or key is wrong
        return encryptedText

def generateEventID(event: Event) -> str:
    #Normalize data for consistent hash creating
    start = event.starting_date.strftime("%Y-%m-%dT%H:%M:%S")
    lat = round(event.selected_lat, 6)
    lon = round(event.selected_lon, 6)
    raw = "{}|{}|{}|{}".format(event.user_id, start, lat, lon)
    return hashlib.sha256(raw.encode()).hexdigest()

def generateUserID(user: User):
    raw = "{}|{}|{}".format(user.user_id,user.user_mail,user.user_name)
    return hashlib.sha256(raw.encode()).hexdigest()