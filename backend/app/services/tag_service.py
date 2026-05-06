from typing import List
from sqlalchemy import select, func
from app.repositories.tag_repo import TagRepository
from app.schemas.tag import TagResponse
from app.models import Tag, note_tags


class TagService:
    def __init__(self, db_session):
        self.tag_repo = TagRepository(db_session)
        self.session = db_session

    async def list_all_tags(self) -> List[TagResponse]:
        stmt = (
            select(Tag, func.count(note_tags.c.note_id).label("note_count"))
            .outerjoin(note_tags, Tag.id == note_tags.c.tag_id)
            .group_by(Tag.id)
            .order_by(Tag.full_path)
        )
        result = await self.session.execute(stmt)
        rows = result.fetchall()
        return [
            TagResponse(
                id=row.Tag.id,
                name=row.Tag.name,
                full_path=row.Tag.full_path,
                level=row.Tag.level,
                note_count=row.note_count,
            )
            for row in rows
        ]
