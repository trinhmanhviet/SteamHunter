"""Small dependency-free client for the local ComfyUI HTTP API."""

from __future__ import annotations

import json
import mimetypes
import time
import uuid
from pathlib import Path
from urllib.parse import urlencode
from urllib.request import Request, urlopen


class ComfyClient:
	def __init__(self, base_url: str, timeout_seconds: float = 180.0):
		self.base_url = base_url.rstrip("/")
		self.timeout_seconds = timeout_seconds

	def upload_image(self, path: Path) -> str:
		boundary = f"----character-factory-{uuid.uuid4().hex}"
		mime = mimetypes.guess_type(path.name)[0] or "application/octet-stream"
		body = b"".join((
			f"--{boundary}\r\n".encode(),
			f'Content-Disposition: form-data; name="image"; filename="{path.name}"\r\n'.encode(),
			f"Content-Type: {mime}\r\n\r\n".encode(),
			path.read_bytes(),
			f"\r\n--{boundary}--\r\n".encode(),
		))
		request = Request(f"{self.base_url}/upload/image", data=body, method="POST", headers={"Content-Type": f"multipart/form-data; boundary={boundary}"})
		with urlopen(request, timeout=self.timeout_seconds) as response:
			payload = json.loads(response.read())
		return payload["name"]

	def queue_and_wait(self, graph: dict) -> dict:
		request = Request(
			f"{self.base_url}/prompt",
			data=json.dumps({"prompt": graph, "client_id": "mist-and-iron-character-factory"}).encode(),
			method="POST",
			headers={"Content-Type": "application/json"},
		)
		with urlopen(request, timeout=self.timeout_seconds) as response:
			prompt_id = json.loads(response.read())["prompt_id"]
		deadline = time.monotonic() + self.timeout_seconds
		while time.monotonic() < deadline:
			with urlopen(f"{self.base_url}/history/{prompt_id}", timeout=self.timeout_seconds) as response:
				history = json.loads(response.read())
			entry = history.get(prompt_id)
			if entry and entry.get("status", {}).get("completed"):
				if entry["status"].get("status_str") != "success":
					raise RuntimeError(entry["status"].get("messages", "ComfyUI generation failed"))
				images = entry.get("outputs", {}).get("9", {}).get("images", [])
				if not images:
					raise RuntimeError("ComfyUI produced no saved frame")
				return images[0]
			time.sleep(0.4)
		raise TimeoutError(f"ComfyUI did not complete {prompt_id}")

	def view_url(self, image: dict) -> str:
		return f"{self.base_url}/view?{urlencode({'filename': image['filename'], 'subfolder': image.get('subfolder', ''), 'type': image.get('type', 'output')})}"

	def download_image(self, image: dict, destination: Path) -> Path:
		destination.parent.mkdir(parents=True, exist_ok=True)
		with urlopen(self.view_url(image), timeout=self.timeout_seconds) as response:
			destination.write_bytes(response.read())
		return destination
