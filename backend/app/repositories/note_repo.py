from typing import Tuple, List, Optional
from sqlalchemy import select, func, or_, text
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from datetime import datetime, timezone

from app.models import Note, Tag, note_tags
from app.core.database import Base


class NoteRepository:
    def __init__(self, session: AsyncSession):
        self.session = session

    async def create(self, content: str) -> Note:
        note = Note(content=content)
        self.session.add(note)
        await self.session.commit()
        await self.session.refresh(note)
        return note

    async def get_by_id(self, note_id: str) -> Optional[Note]:
        stmt = (
            select(Note)
            .where(Note.id == note_id, Note.deleted_at.is_(None))
            .options(selectinload(Note.tags))
        )
        result = await self.session.execute(stmt)
        return result.scalar_one_or_none()

    async def list(self, page: int = 1, page_size: int = 20) -> Tuple[List[Note], int]:
        offset = (page - 1) * page_size
        count_stmt = select(func.count(Note.id)).where(Note.deleted_at.is_(None))
        list_stmt = (
            select(Note)
            .where(Note.deleted_at.is_(None))
            .order_by(Note.created_at.desc())
            .offset(offset)
            .limit(page_size)
            .options(selectinload(Note.tags))
        )
        total_result = await self.session.execute(count_stmt)
        total = total_result.scalar() or 0
        list_result = await self.session.execute(list_stmt)
        notes = list_result.scalars().all()
        return notes, total

    async def update(self, note_id: str, content: str) -> Optional[Note]:
        note = await self.get_by_id(note_id)
        if note is None:
            return None
        note.content = content
        note.updated_at = datetime.now(timezone.utc)
        await self.session.commit()
        await self.session.refresh(note)
        return note

    async def soft_delete(self, note_id: str) -> Optional[Note]:
        note = await self.get_by_id(note_id)
        if note is None:
            return None
        note.deleted_at = datetime.now(timezone.utc)
        await self.session.commit()
        await self.session.refresh(note)
        return note

    async def search(self, query: str, page: int = 1, page_size: int = 20) -> Tuple[List[Note], int]:
        offset = (page - 1) * page_size
        search_filter = Note.content.ilike(f"%{query}%")
        count_stmt = select(func.count(Note.id)).where(
            Note.deleted_at.is_(None), search_filter
        )
        list_stmt = (
            select(Note)
            .where(Note.deleted_at.is_(None), search_filter)
            .order_by(Note.created_at.desc())
            .offset(offset)
            .limit(page_size)
            .options(selectinload(Note.tags))
        )
        total_result = await self.session.execute(count_stmt)
        total = total_result.scalar() or 0
        list_result = await self.session.execute(list_stmt)
        notes = list_result.scalars().all()
        return notes, total

    async def add_tag_to_note(self, note_id: str, tag: Tag) -> Note:
        note = await self.get_by_id(note_id)
        if note is None:
            raise ValueError(f"Note {note_id} not found")
        if tag not in note.tags:
            note.tags.append(tag)
            await self.session.commit()
            await self.session.refresh(note)
        return note
