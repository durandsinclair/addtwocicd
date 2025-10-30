from fastapi.testclient import TestClient
from src.app.main import app, add_numbers


def test_add_numbers_pure():
    assert add_numbers(2, 3) == 5
    assert add_numbers(-1, 1.5) == 0.5


def test_health():
    client = TestClient(app)
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json()["status"] == "ok"


def test_add_endpoint():
    client = TestClient(app)
    r = client.post("/add", json={"a": 10, "b": 15})
    assert r.status_code == 200
    assert r.json()["result"] == 25


