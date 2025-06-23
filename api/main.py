from fastapi import FastAPI, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from dotenv import load_dotenv

from database import get_db, create_tables
from models import User, DiaryEntry
from schemas import (
    UserCreate, 
    DiaryEntryCreate, DiaryEntryUpdate, DiaryEntryResponse,
    APIResponse
)

load_dotenv()

app = FastAPI(
    title="No Emo Vibe API",
    description="Save diary entries and get diary entries",
    version="1.0.0"
)

@app.on_event("startup")
def startup_event():
    create_tables()

@app.get("/")
def read_root():
    return {"message": "No Emo Vibe API Server", "status": "running"}

# ----------------------------- User Endpoints -----------------------------
# Register a new device (or confirm an existing one)
def register_device(user_data: UserCreate, db: Session = Depends(get_db)):
    """Register a new device (idempotent)."""
    try:
        # Check whether the device already exists
        existing_user = db.query(User).filter(User.device_id == user_data.device_id).first()
        if existing_user:
            return APIResponse(
                success=True,
                message="Device already exists",
                data={"user_id": existing_user.user_id, "device_id": existing_user.device_id}
            )
        
        # Create a new user (device)
        db_user = User(device_id=user_data.device_id)
        db.add(db_user)
        db.commit()
        db.refresh(db_user)
        
        return APIResponse(
            success=True,
            message="Device registered successfully",
            data={"user_id": db_user.user_id, "device_id": db_user.device_id}
        )
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Registration failed: {str(e)}")

# ---------------------------- Diary Endpoints -----------------------------
# Upload a diary entry
def create_diary_entry(entry_data: DiaryEntryCreate, db: Session = Depends(get_db)):
    """Upload a diary entry."""
    try:
        # Look up user by device ID
        user = db.query(User).filter(User.device_id == entry_data.device_id).first()
        if not user:
            raise HTTPException(status_code=404, detail="Device not registered")
        
        # Check for duplicate diary UUID
        existing_entry = db.query(DiaryEntry).filter(
            DiaryEntry.user_id == user.user_id,
            DiaryEntry.entry_uuid == entry_data.entry_uuid
        ).first()
        
        if existing_entry:
            raise HTTPException(status_code=409, detail="Diary entry already exists")
        
        # Create new diary entry
        db_entry = DiaryEntry(
            user_id=user.user_id,
            entry_uuid=entry_data.entry_uuid,
            entry_date=entry_data.entry_date,
            mood_score=entry_data.mood_score,
            mood_percentage=entry_data.mood_percentage,
            activities=entry_data.activities,
            notes=entry_data.notes
        )
        
        db.add(db_entry)
        db.commit()
        db.refresh(db_entry)
        
        return APIResponse(
            success=True,
            message="Diary entry uploaded successfully",
            data={"entry_id": db_entry.entry_id, "entry_uuid": db_entry.entry_uuid}
        )
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Upload failed: {str(e)}")

# Retrieve diary entries for a device
def get_diary_entries(device_id: str = Query(..., description="Device ID"), db: Session = Depends(get_db)):
    """Get diary entries for the specified device."""
    try:
        # Look up user
        user = db.query(User).filter(User.device_id == device_id).first()
        if not user:
            raise HTTPException(status_code=404, detail="Device not registered")
        
        # Fetch all diary entries for the user, ordered by date DESC
        entries = db.query(DiaryEntry).filter(
            DiaryEntry.user_id == user.user_id
        ).order_by(DiaryEntry.entry_date.desc()).all()
        
        return entries
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve diary entries: {str(e)}")

def update_diary_entry(
    entry_uuid: str, 
    entry_data: DiaryEntryUpdate, 
    device_id: str = Query(..., description="Device ID"),
    db: Session = Depends(get_db)
):
    """Update a diary entry (partial update supported)."""
    try:
        # Look up user
        user = db.query(User).filter(User.device_id == device_id).first()
        if not user:
            raise HTTPException(status_code=404, detail="Device not registered")
        
        # Look up diary entry
        db_entry = db.query(DiaryEntry).filter(
            DiaryEntry.user_id == user.user_id,
            DiaryEntry.entry_uuid == entry_uuid
        ).first()
        
        if not db_entry:
            raise HTTPException(status_code=404, detail="Diary entry not found")
        
        # Apply partial update (only provided fields)
        update_data = entry_data.dict(exclude_unset=True)
        for field, value in update_data.items():
            setattr(db_entry, field, value)
        
        db.commit()
        db.refresh(db_entry)
        
        return APIResponse(
            success=True,
            message="Diary entry updated successfully",
            data={"entry_id": db_entry.entry_id, "entry_uuid": db_entry.entry_uuid}
        )
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Update failed: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000) 