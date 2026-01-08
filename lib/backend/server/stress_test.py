import asyncio
import time
import httpx
import random
import math
from datetime import datetime, timezone, timedelta
from models import *
localURL = "http://192.168.97.16:8000"
publicURL = "https://micro-volunteering-hub-backend.onrender.com"
usedURL = publicURL
SEM_LIMIT = 25
sem = asyncio.Semaphore(SEM_LIMIT)
limits = httpx.Limits(
    max_connections=200,
    max_keepalive_connections=100
)

timeout = httpx.Timeout(
    connect=100.0,
    read=300.0,
    write=300.0,
    pool=300.0
)

def randomPointAtDistance(cx, cy, maxDistance):
    distance = random.random() * maxDistance
    theta = random.uniform(0, 2 * math.pi)
    x = cx + distance * math.cos(theta)
    y = cy + distance * math.sin(theta)
    return x,y

center = (37.172065, 28.375394)
maxDistance = 0.5
today = datetime.now(timezone.utc)
async def createEvent(client, i):
    async with sem:
        if i % 100 == 0:
            print(i)
        point = randomPointAtDistance(center[0], center[1], maxDistance)
        user = users[i]
        date = today + timedelta(days=random.randint(0,2), hours=random.randint(0,23), minutes=random.choice([5,10,15,30,45]))
        event = Event(host_name=user.user_name, user_id=user.id, selected_lat=point[0], selected_lon=point[1], user_image_url="",
                    categories=[], title="Test event {}".format(i), description="Test description {}".format(i), people_needed=random.randint(2,100),
                    instant_join= True, duration=random.randint(1,24), starting_date= date)
        response = await client.post("{}/event/create".format(usedURL), json=event.model_dump(mode="json"), timeout=timeout)
        if response.is_error:
            print("EVENT CREATION FAILED:", response.status_code)
            return
        data = response.json()
        events.append({"id": data["event_id"], "capacity": event.people_needed, "joined": 0})

async def createUser(client, i):
    async with sem:
        if i % 100 == 0:
            print(i)
        user = User(id="id#{}".format(i), photo_url="", photo_url_custom="", user_mail="testexample{}@gmail.com".format(i), user_name="User {}".format(i))
        users.append(user)
        response = await client.post("{}/user/create".format(usedURL), json=user.model_dump(mode="json"), timeout=timeout)
        if response.is_error:
            print("CREATING USER FAILED:", response.status_code)

async def joinEvent(client, userIndex):
    async with sem:
        if userIndex % 100 == 0:
            print(userIndex)
        while True:
            event = random.choice(events)
            if event["joined"] < event["capacity"]:
                break
        event["joined"] += 1
        payload = {"user_id": users[userIndex].id}
        response = await client.post("{}/event/{}/join".format(usedURL, event["id"]), json=payload, timeout=timeout)
        if response.is_error:
            print("JOINING FAILED:", response.status_code)
users = [] #Stores user ids
events = [] #Stores event ids
USERCOUNT = 4000
JOINCREATE_RATIO = 5
eventCreationCount = int(USERCOUNT * (JOINCREATE_RATIO / 100))
joinCount = USERCOUNT - eventCreationCount
async def main():
    start = time.time()
    print("Creating users")
    async with httpx.AsyncClient(limits=limits, timeout=60) as client:
        tasks = [createUser(client, i) for i in range(USERCOUNT)]
        await asyncio.gather(*tasks)
    print("Creating events")
    async with httpx.AsyncClient(limits=limits, timeout=60) as client:
        tasks = [createEvent(client, i) for i in range(eventCreationCount)]
        await asyncio.gather(*tasks)
    print("Joining to events")
    async with httpx.AsyncClient(limits=limits, timeout=60) as client:
        tasks = [joinEvent(client, i) for i in range(eventCreationCount, USERCOUNT)]
        await asyncio.gather(*tasks)
    end = time.time()
    print("throughput: {}".format((USERCOUNT*2) / (end-start)))
asyncio.run(main())
