from fastapi import FastAPI, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional

from app.core.database import get_db
from app.schemas.note import NoteCreate, NoteUpdate, NoteResponse, NoteListResponse
from app.schemas.tag import TagResponse
from app.services.note_service import NoteService
from app.services.tag_service import TagService

app = FastAPI(title="MyNote API", version="0.1.0")


@app.post("/api/v1/notes", response_model=NoteResponse, status_code=201)
async def create_note(note: NoteCreate, db: AsyncSession = Depends(get_db)):
    service = NoteService(db)
    return await service.create_note(note.content)


@app.get("/api/v1/notes", response_model=NoteListResponse)
async def list_notes(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
):
    service = NoteService(db)
    notes, total = await service.list_notes(page, page_size)
    return NoteListResponse(notes=notes, total=total, page=page, page_size=page_size)


@app.get("/api/v1/notes/{note_id}", response_model=NoteResponse)
async def get_note(note_id: str, db: AsyncSession = Depends(get_db)):
    service = NoteService(db)
    note = await service.get_note(note_id)
    if note is None:
        raise HTTPException(status_code=404, detail="Note not found")
    return note


@app.put("/api/v1/notes/{note_id}", response_model=NoteResponse)
async def update_note(note_id: str, note: NoteUpdate, db: AsyncSession = Depends(get_db)):
    service = NoteService(db)
    updated = await service.update_note(note_id, note.content)
    if updated is None:
        raise HTTPException(status_code=404, detail="Note not found")
    return updated


@app.delete("/api/v1/notes/{note_id}", response_model=NoteResponse)
async def delete_note(note_id: str, db: AsyncSession = Depends(get_db)):
    service = NoteService(db)
    deleted = await service.delete_note(note_id)
    if deleted is None:
        raise HTTPException(status_code=404, detail="Note not found")
    return deleted


@app.get("/api/v1/tags", response_model=list[TagResponse])
async def list_tags(db: AsyncSession = Depends(get_db)):
    service = TagService(db)
    return await service.list_all_tags()


@app.get("/api/v1/search", response_model=NoteListResponse)
async def search_notes(
    q: str = Query(..., min_length=1),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
):
    service = NoteService(db)
    notes, total = await service.search_notes(q, page, page_size)
    return NoteListResponse(notes=notes, total=total, page=page, page_size=page_size)
