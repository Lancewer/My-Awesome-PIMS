import pytest
from app.services.tag_service import TagService
from app.services.note_service import NoteService


@pytest.fixture
def tag_service(db_session):
    return TagService(db_session)


@pytest.fixture
def note_service(db_session):
    return NoteService(db_session)


@pytest.mark.asyncio
async def test_list_all_tags_with_counts(tag_service, note_service):
    await note_service.create_note("#work")
    await note_service.create_note("#work #personal")
    tags = await tag_service.list_all_tags()
    work_tag = next((t for t in tags if t.full_path == "work"), None)
    assert work_tag is not None
    assert work_tag.note_count == 2
