import pytest
from app.services.note_service import NoteService


@pytest.fixture
def note_service(db_session):
    return NoteService(db_session)


@pytest.mark.asyncio
async def test_create_note_with_flat_tags(note_service):
    note = await note_service.create_note("Hello #work #personal")
    assert "Hello #work #personal" in note.content
    tag_paths = [t.full_path for t in note.tags]
    assert "work" in tag_paths
    assert "personal" in tag_paths


@pytest.mark.asyncio
async def test_create_note_with_hierarchical_tags(note_service):
    note = await note_service.create_note("Project update #project/backend/api")
    tag_paths = [t.full_path for t in note.tags]
    assert "project" in tag_paths
    assert "project/backend" in tag_paths
    assert "project/backend/api" in tag_paths


@pytest.mark.asyncio
async def test_create_note_with_mixed_tags(note_service):
    note = await note_service.create_note("This is a demo note. #note #log #memo")
    tag_paths = [t.full_path for t in note.tags]
    assert "note" in tag_paths
    assert "log" in tag_paths
    assert "memo" in tag_paths
    assert len(note.tags) == 3


@pytest.mark.asyncio
async def test_create_note_max_tag_depth(note_service):
    note = await note_service.create_note("Deep tag #a/b/c")
    tag_paths = [t.full_path for t in note.tags]
    assert "a" in tag_paths
    assert "a/b" in tag_paths
    assert "a/b/c" in tag_paths


@pytest.mark.asyncio
async def test_create_note_tag_depth_exceeds_max(note_service):
    note = await note_service.create_note("Too deep #a/b/c/d")
    tag_paths = [t.full_path for t in note.tags]
    assert "a/b/c" in tag_paths
    assert "a/b/c/d" not in tag_paths


@pytest.mark.asyncio
async def test_create_note_without_tags(note_service):
    note = await note_service.create_note("Just text, no tags")
    assert len(note.tags) == 0


@pytest.mark.asyncio
async def test_update_note_content(note_service):
    note = await note_service.create_note("Original #tag1")
    updated = await note_service.update_note(note.id, "Updated #tag2")
    assert updated.content == "Updated #tag2"
    tag_paths = [t.full_path for t in updated.tags]
    assert "tag2" in tag_paths


@pytest.mark.asyncio
async def test_delete_note(note_service):
    note = await note_service.create_note("To delete")
    deleted = await note_service.delete_note(note.id)
    assert deleted.deleted_at is not None
    retrieved = await note_service.get_note(note.id)
    assert retrieved is None


@pytest.mark.asyncio
async def test_list_notes(note_service):
    for i in range(5):
        await note_service.create_note(f"Note {i}")
    notes, total = await note_service.list_notes()
    assert total == 5
    assert len(notes) == 5


@pytest.mark.asyncio
async def test_search_notes(note_service):
    await note_service.create_note("Python programming")
    await note_service.create_note("Java development")
    results, total = await note_service.search_notes("Python")
    assert total == 1
    assert "Python" in results[0].content
