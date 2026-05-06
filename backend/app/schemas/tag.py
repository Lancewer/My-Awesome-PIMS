from pydantic import BaseModel
from datetime import datetime
from uuid import UUID


class TagResponse(BaseModel):
    id: UUID
    name: str
    full_path: str
    level: int
    note_count: int = 0

    class Config:
        from_attributes = True


class TagWithNotes(BaseModel):
    tag: TagResponse
    notes: list["NoteResponse"]

    class Config:
        from_attributes = True
