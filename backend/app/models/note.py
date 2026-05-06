from sqlalchemy import Column, String, DateTime, Text, func
from sqlalchemy.orm import relationship
import uuid

from app.core.database import Base


class Note(Base):
    __tablename__ = "notes"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    content = Column(Text, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    deleted_at = Column(DateTime(timezone=True), nullable=True)

    tags = relationship("Tag", secondary="note_tags", back_populates="notes", lazy="selectin")
