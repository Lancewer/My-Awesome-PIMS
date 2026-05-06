from sqlalchemy import Column, String, DateTime, Integer, SmallInteger, ForeignKey, func
from sqlalchemy.orm import relationship
import uuid

from app.core.database import Base


class Tag(Base):
    __tablename__ = "tags"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String(50), nullable=False)
    full_path = Column(String(200), unique=True, nullable=False, index=True)
    parent_id = Column(String, ForeignKey("tags.id"), nullable=True, index=True)
    level = Column(SmallInteger, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    parent = relationship("Tag", remote_side=[id], backref="children", lazy="selectin")
    notes = relationship("Note", secondary="note_tags", back_populates="tags", lazy="selectin")
