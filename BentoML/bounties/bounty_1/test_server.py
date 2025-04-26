import pytest
import requests
import bentoml
import time

port = 3001

EXAMPLE_INPUT = "Breaking News: In an astonishing turn of events, the small \
town of Willow Creek has been taken by storm as local resident Jerry Thompson's cat, \
Whiskers, performed what witnesses are calling a 'miraculous and gravity-defying leap.' \
Eyewitnesses report that Whiskers, an otherwise unremarkable tabby cat, jumped \
a record-breaking 20 feet into the air to catch a fly. The event, which took \
place in Thompson's backyard, is now being investigated by scientists for potential \
breaches in the laws of physics. Local authorities are considering a town festival \
to celebrate what is being hailed as 'The Leap of the Century."

data = {
    "text": (EXAMPLE_INPUT)
}

def test_local_summary() -> None:
    url = "http://localhost:3001/summarize"
    headers = {
        "accept": "text/plain",
        "Content-Type": "application/json"
    }

    response = requests.post(url, json=data, headers=headers, timeout=120)
    assert response.status_code == 200   

    result = response.text
    assert isinstance(response.text, str)
    assert "Whiskers" in result
    assert len(result) < len(EXAMPLE_INPUT), "The summarized text should be shorter than the input."

@pytest.mark.asyncio(loop_scope="function")
async def test_clients() -> None:
    with bentoml.SyncHTTPClient(f"http://localhost:{port}", timeout=120) as client:
        result = client.summarize(EXAMPLE_INPUT)

    assert isinstance(result, str)
    assert "Whiskers" in result
    assert len(result) < len(EXAMPLE_INPUT), "The summarized text should be shorter than the input."

    async with bentoml.AsyncHTTPClient(f"http://localhost:{port}", timeout=120) as client:
        result = (await client.summarize(EXAMPLE_INPUT))
        
    assert isinstance(result, str)
    assert "Whiskers" in result
    assert len(result) < len(EXAMPLE_INPUT), "The summarized text should be shorter than the input."
