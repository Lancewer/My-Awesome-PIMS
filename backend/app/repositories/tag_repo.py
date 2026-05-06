from typing import List, Optional
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Tag


class TagRepository:
    def __init__(self, session: AsyncSession):
        self.session = session

    async def create(
        self, name: str, full_path: str, level: int, parent_id: Optional[UUID] = None
    ) -> Tag:
        tag = Tag(name=name, full_path=full_path, level=level, parent_id=parent_id)
        self.session.add(tag)
        await self.session.commit()
        await self.session.refresh(tag)
        return tag

    async def get_by_full_path(self, full_path: str) -> Optional[Tag]:
        stmt = select(Tag).where(Tag.full_path == full_path)
        result = await self.session.execute(stmt)
        return result.scalar_one_or_none()

    async def get_by_id(self, tag_id: UUID) -> Optional[Tag]:
        stmt = select(Tag).where(Tag.id == tag_id)
        result = await self.session.execute(stmt)
        return result.scalar_one_or_none()

    async def list_all(self) -> List[Tag]:
        stmt = select(Tag).order_by(Tag.full_path)
        result = await self.session.execute(stmt)
        return list(result.scalars().all())

    async def get_or_create(
        self, name: str, full_path: str, level: int, parent_id: Optional[UUID] = None
    ) -> Tag:
        tag = await self.get_by_full_path(full_path)
        if tag is not None:
            return tag
        return await self.create(name, full_path, level, parent_id)
