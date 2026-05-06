import pytest
import pytest_asyncio
from sqlalchemy.ext.asyncio import AsyncSession
from app.repositories.note_repo import NoteRepository
from app.models import Note
import time


@pytest.fixture
def note_repo(db_session):
    return NoteRepository(db_session)


@pytest.mark.asyncio
async def test_create_note(note_repo, db_session):
    note = await note_repo.create(content="Test note content")
    assert note.content == "Test note content"
    assert note.id is not None
    assert note.created_at is not None


@pytest.mark.asyncio
async def test_get_note_by_id(note_repo):
    note = await note_repo.create(content="Get by ID test")
    retrieved = await note_repo.get_by_id(note.id)
    assert retrieved is not None
    assert retrieved.id == note.id
    assert retrieved.content == "Get by ID test"


@pytest.mark.asyncio
async def test_get_note_by_id_returns_none_for_deleted(note_repo):
    note = await note_repo.create(content="Deleted note")
    await note_repo.soft_delete(note.id)
    retrieved = await note_repo.get_by_id(note.id)
    assert retrieved is None


@pytest.mark.asyncio
async def test_list_notes_paginated(note_repo):
    for i in range(15):
        await note_repo.create(content=f"Note {i}")
    notes, total = await note_repo.list(page=1, page_size=10)
    assert len(notes) == 10
    assert total == 15
    assert notes[0].created_at >= notes[-1].created_at


@pytest.mark.asyncio
async def test_list_notes_second_page(note_repo):
    for i in range(15):
        await note_repo.create(content=f"Note {i}")
    notes, total = await note_repo.list(page=2, page_size=10)
    assert len(notes) == 5


@pytest.mark.asyncio
async def test_update_note(note_repo):
    note = await note_repo.create(content="Original")
    time.sleep(0.1)
    updated = await note_repo.update(note.id, content="Updated content")
    assert updated.content == "Updated content"


@pytest.mark.asyncio
async def test_soft_delete_note(note_repo):
    note = await note_repo.create(content="To delete")
    deleted = await note_repo.soft_delete(note.id)
    assert deleted.deleted_at is not None
    retrieved = await note_repo.get_by_id(note.id)
    assert retrieved is None


@pytest.mark.asyncio
async def test_search_notes(note_repo):
    await note_repo.create(content="Python programming is fun")
    await note_repo.create(content="Java is also good")
    await note_repo.create(content="Rust is fast")
    results, total = await note_repo.search("Python")
    assert total >= 1
    assert any("Python" in r.content for r in results)
