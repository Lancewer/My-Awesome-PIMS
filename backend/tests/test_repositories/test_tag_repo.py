import pytest
from sqlalchemy.ext.asyncio import AsyncSession
from app.repositories.tag_repo import TagRepository


@pytest.fixture
def tag_repo(db_session):
    return TagRepository(db_session)


@pytest.mark.asyncio
async def test_create_flat_tag(tag_repo):
    tag = await tag_repo.create(name="work", full_path="work", level=1)
    assert tag.name == "work"
    assert tag.full_path == "work"
    assert tag.level == 1
    assert tag.parent_id is None


@pytest.mark.asyncio
async def test_create_hierarchical_tag(tag_repo):
    parent = await tag_repo.create(name="project", full_path="project", level=1)
    child = await tag_repo.create(name="backend", full_path="project/backend", level=2, parent_id=parent.id)
    assert child.parent_id == parent.id
    assert child.level == 2


@pytest.mark.asyncio
async def test_get_tag_by_full_path(tag_repo):
    await tag_repo.create(name="note", full_path="note", level=1)
    tag = await tag_repo.get_by_full_path("note")
    assert tag is not None
    assert tag.full_path == "note"


@pytest.mark.asyncio
async def test_get_tag_by_full_path_returns_none(tag_repo):
    tag = await tag_repo.get_by_full_path("nonexistent")
    assert tag is None


@pytest.mark.asyncio
async def test_list_all_tags(tag_repo):
    await tag_repo.create(name="a", full_path="a", level=1)
    await tag_repo.create(name="b", full_path="b", level=1)
    tags = await tag_repo.list_all()
    assert len(tags) >= 2


@pytest.mark.asyncio
async def test_get_or_create_flat_tag(tag_repo):
    tag1 = await tag_repo.get_or_create("test", "test", 1)
    tag2 = await tag_repo.get_or_create("test", "test", 1)
    assert tag1.id == tag2.id


@pytest.mark.asyncio
async def test_get_or_create_hierarchical_tag(tag_repo):
    parent = await tag_repo.get_or_create("project", "project", 1)
    child = await tag_repo.get_or_create("api", "project/api", 2, parent_id=parent.id)
    same_child = await tag_repo.get_or_create("api", "project/api", 2, parent_id=parent.id)
    assert child.id == same_child.id
