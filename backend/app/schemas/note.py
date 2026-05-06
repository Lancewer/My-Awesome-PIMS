from pydantic import BaseModel, Field
from datetime import datetime
from uuid import UUID
from typing import Optional


class NoteCreate(BaseModel):
    content: str = Field(..., min_length=1, max_length=10000)


class NoteUpdate(BaseModel):
    content: str = Field(..., min_length=1, max_length=10000)


class NoteResponse(BaseModel):
    id: UUID
    content: str
    tags: list["TagResponse"]
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class NoteListResponse(BaseModel):
    notes: list[NoteResponse]
    total: int
    page: int
    page_size: int


class TagResponse(BaseModel):
    id: UUID
    name: str
    full_path: str
    level: int

    class Config:
        from_attributes = True
