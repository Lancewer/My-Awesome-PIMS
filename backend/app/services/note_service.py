import re
from typing import List, Optional, Tuple
from uuid import UUID

from app.repositories.note_repo import NoteRepository
from app.repositories.tag_repo import TagRepository
from app.models import Note, Tag


MAX_TAG_DEPTH = 3


class NoteService:
    def __init__(self, db_session):
        self.note_repo = NoteRepository(db_session)
        self.tag_repo = TagRepository(db_session)

    def extract_tags(self, content: str) -> List[Tuple[str, str, int]]:
        tag_pattern = re.compile(r'#([a-zA-Z0-9_/]+)')
        matches = tag_pattern.findall(content)
        tags = []
        for match in matches:
            parts = match.split('/')
            if len(parts) > MAX_TAG_DEPTH:
                parts = parts[:MAX_TAG_DEPTH]
            for i in range(len(parts)):
                sub_path = '/'.join(parts[:i+1])
                level = i + 1
                if level > MAX_TAG_DEPTH:
                    break
                tags.append((parts[i], sub_path, level))
        seen = set()
        unique_tags = []
        for name, path, level in tags:
            if path not in seen:
                seen.add(path)
                unique_tags.append((name, path, level))
        return unique_tags

    async def create_note(self, content: str) -> Note:
        note = await self.note_repo.create(content)
        tag_specs = self.extract_tags(content)
        parent_map = {}
        for name, full_path, level in tag_specs:
            parent_id = parent_map.get('/'.join(full_path.split('/')[:-1])) if level > 1 else None
            tag = await self.tag_repo.get_or_create(name, full_path, level, parent_id)
            if full_path in parent_map:
                pass
            parent_map[full_path] = tag.id
            await self.note_repo.add_tag_to_note(note.id, tag)
        result = await self.note_repo.get_by_id(note.id)
        return result

    async def get_note(self, note_id: UUID) -> Optional[Note]:
        return await self.note_repo.get_by_id(note_id)

    async def list_notes(self, page: int = 1, page_size: int = 20) -> Tuple[List[Note], int]:
        return await self.note_repo.list(page, page_size)

    async def update_note(self, note_id: UUID, content: str) -> Optional[Note]:
        note = await self.note_repo.update(note_id, content)
        if note is None:
            return None
        note.tags.clear()
        await self.note_repo.session.commit()
        tag_specs = self.extract_tags(content)
        parent_map = {}
        for name, full_path, level in tag_specs:
            parent_id = parent_map.get('/'.join(full_path.split('/')[:-1])) if level > 1 else None
            tag = await self.tag_repo.get_or_create(name, full_path, level, parent_id)
            parent_map[full_path] = tag.id
            await self.note_repo.add_tag_to_note(note_id, tag)
        return await self.note_repo.get_by_id(note_id)

    async def delete_note(self, note_id: UUID) -> Optional[Note]:
        return await self.note_repo.soft_delete(note_id)

    async def search_notes(self, query: str, page: int = 1, page_size: int = 20) -> Tuple[List[Note], int]:
        return await self.note_repo.search(query, page, page_size)
