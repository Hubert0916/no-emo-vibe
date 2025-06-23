from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

# user related
class UserCreate(BaseModel):
    device_id: str

class UserResponse(BaseModel):
    user_id: int
    device_id: str
    created_at: datetime
    
    class Config:
        from_attributes = True

# diary related
class DiaryEntryCreate(BaseModel):
    entry_uuid: str
    entry_date: datetime
    mood_score: int
    mood_percentage: int
    activities: Optional[List[str]] = []
    notes: Optional[str] = ""
    device_id: str 

class DiaryEntryUpdate(BaseModel):
    entry_date: Optional[datetime] = None
    mood_score: Optional[int] = None
    mood_percentage: Optional[int] = None
    activities: Optional[List[str]] = None
    notes: Optional[str] = None

class DiaryEntryResponse(BaseModel):
    entry_id: int
    entry_uuid: str
    entry_date: datetime
    mood_score: int
    mood_percentage: int
    activities: Optional[List[str]]
    notes: Optional[str]
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

# API response format
class APIResponse(BaseModel):
    success: bool
    message: str
    data: Optional[dict] = None 