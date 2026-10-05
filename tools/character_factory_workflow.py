"""ComfyUI API graphs for reference-locked Qwen Image 2.1 character frames."""

from __future__ import annotations


NEGATIVE_PROMPT = (
	"different character, redesigned outfit, different weapon, duplicate weapon, duplicate limbs, "
	"front view, back view, cropped body, scene background, text, watermark, blurry, photorealistic"
)


def locked_prompt(pose_instruction: str) -> str:
	return (
		"Create the exact same original pixel-art hunter shown in the supplied master references. "
		"The final reference image is only the requested body pose. "
		"Preserve exactly identity, anatomy, short blond hair, brick-red coat, pale-blue steel armor, "
		"cream scarf, navy outline, long rectangular silver great cleaver, brass guard, dark handle, "
		"and the bright master palette. Strict side view facing right. Whole character centered on a plain "
		"transparent-ready backdrop. Do not redesign the character. Do not add or remove equipment. "
		f"Pose instruction: {pose_instruction}"
	)


def build_frame_workflow(reference_names: list[str], pose_instruction: str, seed: int, filename_prefix: str) -> dict:
	"""Create a valid ComfyUI graph with up to ten image references."""
	if not 1 <= len(reference_names) <= 10:
		raise ValueError("reference_names must contain 1 to 10 files")
	encoder_inputs = {
		"clip": ["2", 0],
		"vae": ["3", 0],
		"prompt": locked_prompt(pose_instruction),
		"negative_prompt": NEGATIVE_PROMPT,
		"resolution": 1024,
		"images": {},
	}
	graph = {
		"1": {"class_type": "UNETLoader", "inputs": {"unet_name": "qwen_image_2.1_int8_convrot.safetensors", "weight_dtype": "default"}},
		"2": {"class_type": "CLIPLoader", "inputs": {"clip_name": "qwen3vl_8b_int8_convrot.safetensors", "type": "qwen_image", "device": "default"}},
		"3": {"class_type": "VAELoader", "inputs": {"vae_name": "qwen_image_2.1_vae_bf16.safetensors"}},
		"5": {"class_type": "TextEncodeQwenImage21", "inputs": encoder_inputs},
		"7": {"class_type": "KSampler", "inputs": {"seed": seed, "steps": 25, "cfg": 1.0, "sampler_name": "euler", "scheduler": "simple", "denoise": 1.0, "model": ["1", 0], "positive": ["5", 0], "negative": ["5", 1], "latent_image": ["5", 2]}},
		"8": {"class_type": "VAEDecode", "inputs": {"samples": ["7", 0], "vae": ["3", 0]}},
		"9": {"class_type": "SaveImage", "inputs": {"filename_prefix": filename_prefix, "images": ["20", 0]}},
		"19": {"class_type": "ImageRGBA2RGB", "inputs": {"image": ["8", 0]}},
		"20": {"class_type": "RMBG", "inputs": {"model": "RMBG-2.0", "sensitivity": 1.0, "process_res": 1024, "mask_blur": 0, "mask_offset": 0, "invert_output": False, "refine_foreground": False, "background": "Alpha", "background_color": "#222222", "image": ["19", 0]}},
	}
	for index, name in enumerate(reference_names, start=1):
		node_id = str(9 + index)
		graph[node_id] = {"class_type": "LoadImage", "inputs": {"image": name}}
		encoder_inputs["images"][f"image_{index}"] = [node_id, 0]
	return graph


def generate_frame(client, reference_paths, pose_instruction: str, seed: int, filename_prefix: str) -> dict:
	"""Upload the locked references and return ComfyUI's completed output descriptor."""
	reference_names = [client.upload_image(path) for path in reference_paths]
	graph = build_frame_workflow(reference_names, pose_instruction, seed, filename_prefix)
	return client.queue_and_wait(graph)
