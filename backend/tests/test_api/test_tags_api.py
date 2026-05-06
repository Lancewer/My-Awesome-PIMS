import pytest


@pytest.mark.asyncio
async def test_list_tags(client):
    await client.post("/api/v1/notes", json={"content": "#work"})
    await client.post("/api/v1/notes", json={"content": "#work #personal"})
    response = await client.get("/api/v1/tags")
    assert response.status_code == 200
    tags = response.json()
    work_tag = next((t for t in tags if t["full_path"] == "work"), None)
    assert work_tag is not None
    assert work_tag["note_count"] == 2


@pytest.mark.asyncio
async def test_list_tags_empty(client):
    response = await client.get("/api/v1/tags")
    assert response.status_code == 200
    assert response.json() == []
