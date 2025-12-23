from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, Field
from models import *
class Event(BaseModel):
    host_name: str
    user_id: str
    selected_lat: float
    selected_lon: float
    user_image_url: Optional[str] = None
    categories: List[str]
    title: str
    description: str
    people_needed: int = Field(..., gt=0)
    duration: int = Field(..., gt=0)
    starting_date: datetime

class User(BaseModel):
    id: str
    photo_url: str
    photo_url_custom: str
    user_mail: str
    user_name: str