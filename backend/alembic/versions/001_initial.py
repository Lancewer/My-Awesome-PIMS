"""initial schema

Revision ID: 001
Revises: 
Create Date: 2026-05-06

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '001'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table('notes',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('content', sa.Text(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column('deleted_at', sa.DateTime(timezone=True), nullable=True),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index('ix_notes_created_at', 'notes', ['created_at'])

    op.create_table('tags',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('name', sa.String(length=50), nullable=False),
        sa.Column('full_path', sa.String(length=200), nullable=False),
        sa.Column('parent_id', sa.String(), nullable=True),
        sa.Column('level', sa.SmallInteger(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.PrimaryKeyConstraint('id'),
        sa.ForeignKeyConstraint(['parent_id'], ['tags.id'], ),
        sa.UniqueConstraint('full_path')
    )
    op.create_index('ix_tags_full_path', 'tags', ['full_path'])
    op.create_index('ix_tags_parent_id', 'tags', ['parent_id'])

    op.create_table('note_tags',
        sa.Column('note_id', sa.String(), nullable=False),
        sa.Column('tag_id', sa.String(), nullable=False),
        sa.ForeignKeyConstraint(['note_id'], ['notes.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['tag_id'], ['tags.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('note_id', 'tag_id')
    )


def downgrade() -> None:
    op.drop_table('note_tags')
    op.drop_index('ix_tags_parent_id', table_name='tags')
    op.drop_index('ix_tags_full_path', table_name='tags')
    op.drop_table('tags')
    op.drop_index('ix_notes_created_at', table_name='notes')
    op.drop_table('notes')
