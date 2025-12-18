import hashlib
from models import *
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