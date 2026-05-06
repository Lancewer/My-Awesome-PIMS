import pytest


@pytest.mark.asyncio
async def test_create_note(client):
    response = await client.post("/api/v1/notes", json={"content": "Hello #test"})
    assert response.status_code == 201
    data = response.json()
    assert "Hello #test" in data["content"]
    assert any(t["full_path"] == "test" for t in data["tags"])


@pytest.mark.asyncio
async def test_create_note_invalid_content(client):
    response = await client.post("/api/v1/notes", json={"content": ""})
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_list_notes(client):
    for i in range(3):
        await client.post("/api/v1/notes", json={"content": f"Note {i}"})
    response = await client.get("/api/v1/notes")
    assert response.status_code == 200
    data = response.json()
    assert data["total"] == 3
    assert len(data["notes"]) == 3


@pytest.mark.asyncio
async def test_get_note_by_id(client):
    create_response = await client.post("/api/v1/notes", json={"content": "Single note"})
    note_id = create_response.json()["id"]
    response = await client.get(f"/api/v1/notes/{note_id}")
    assert response.status_code == 200
    assert response.json()["content"] == "Single note"


@pytest.mark.asyncio
async def test_update_note(client):
    create_response = await client.post("/api/v1/notes", json={"content": "Original"})
    note_id = create_response.json()["id"]
    response = await client.put(f"/api/v1/notes/{note_id}", json={"content": "Updated #new"})
    assert response.status_code == 200
    assert response.json()["content"] == "Updated #new"


@pytest.mark.asyncio
async def test_delete_note(client):
    create_response = await client.post("/api/v1/notes", json={"content": "Delete me"})
    note_id = create_response.json()["id"]
    response = await client.delete(f"/api/v1/notes/{note_id}")
    assert response.status_code == 200
    get_response = await client.get(f"/api/v1/notes/{note_id}")
    assert get_response.status_code == 404


@pytest.mark.asyncio
async def test_search_notes(client):
    await client.post("/api/v1/notes", json={"content": "Python programming"})
    await client.post("/api/v1/notes", json={"content": "Java development"})
    response = await client.get("/api/v1/search?q=Python")
    assert response.status_code == 200
    data = response.json()
    assert data["total"] == 1
    assert "Python" in data["notes"][0]["content"]
