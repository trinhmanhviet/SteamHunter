"""ComfyUI API graphs for the isolated Hunyuan3D-2 Shape and Paint experiment."""


def shape_graph(seed=834625):
    return {
        "1": {"class_type": "LoadImage", "inputs": {"image": "hunter_imagegen_cutout.png"}},
        "2": {"class_type": "InvertMask", "inputs": {"mask": ["1", 1]}},
        "3": {"class_type": "Hy3DModelLoader", "inputs": {
            "model": "hunyuan3d-dit-v2-0-fp16.safetensors", "attention_mode": "sdpa", "cublas_ops": False,
        }},
        "4": {"class_type": "Hy3DGenerateMesh", "inputs": {
            "pipeline": ["3", 0], "image": ["1", 0], "mask": ["2", 0],
            "guidance_scale": 5.5, "steps": 30, "seed": seed,
            "scheduler": "FlowMatchEulerDiscreteScheduler", "force_offload": True,
        }},
        "5": {"class_type": "Hy3DVAEDecode", "inputs": {
            "vae": ["3", 1], "latents": ["4", 0], "box_v": 1.01,
            "octree_resolution": 384, "num_chunks": 8000, "mc_level": 0.0,
            "mc_algo": "mc", "enable_flash_vdm": True, "force_offload": True,
        }},
        "6": {"class_type": "Hy3DExportMesh", "inputs": {
            "trimesh": ["5", 0], "filename_prefix": "hunyuan/shape_raw", "file_format": "glb", "save_file": True,
        }},
        "7": {"class_type": "Hy3DPostprocessMesh", "inputs": {
            "trimesh": ["5", 0], "remove_floaters": False, "remove_degenerate_faces": True,
            "reduce_faces": True, "max_facenum": 45000, "smooth_normals": False,
        }},
        "8": {"class_type": "Hy3DExportMesh", "inputs": {
            "trimesh": ["7", 0], "filename_prefix": "hunyuan/shape_prepared", "file_format": "glb", "save_file": True,
        }},
    }


def paint_graph(mesh_path: str, seed=834625):
    return {
        "1": {"class_type": "LoadImage", "inputs": {"image": "hunter_imagegen_cutout.png"}},
        "2": {"class_type": "Hy3DLoadMesh", "inputs": {"glb_path": mesh_path}},
        "3": {"class_type": "Hy3DMeshUVWrap", "inputs": {"trimesh": ["2", 0]}},
        "4": {"class_type": "Hy3DCameraConfig", "inputs": {
            "camera_azimuths": "0,90,180,270,0,180", "camera_elevations": "0,0,0,0,90,-90",
            "view_weights": "1,0.1,0.5,0.1,0.05,0.05", "camera_distance": 1.45, "ortho_scale": 1.2,
        }},
        "5": {"class_type": "Hy3DRenderMultiView", "inputs": {
            "trimesh": ["3", 0], "render_size": 512, "texture_size": 2048,
            "camera_config": ["4", 0], "normal_space": "world",
        }},
        "6": {"class_type": "DownloadAndLoadHy3DPaintModel", "inputs": {"model": "hunyuan3d-paint-v2-0"}},
        "7": {"class_type": "Hy3DSampleMultiView", "inputs": {
            "pipeline": ["6", 0], "ref_image": ["1", 0], "normal_maps": ["5", 0],
            "position_maps": ["5", 1], "view_size": 512, "steps": 30, "seed": seed,
            "camera_config": ["4", 0], "denoise_strength": 1.0,
        }},
        "8": {"class_type": "Hy3DBakeFromMultiview", "inputs": {
            "images": ["7", 0], "renderer": ["5", 2], "camera_config": ["4", 0],
        }},
        "9": {"class_type": "Hy3DMeshVerticeInpaintTexture", "inputs": {
            "texture": ["8", 0], "mask": ["8", 1], "renderer": ["8", 2],
        }},
        "10": {"class_type": "CV2InpaintTexture", "inputs": {
            "texture": ["9", 0], "mask": ["9", 1], "inpaint_radius": 3, "inpaint_method": "ns",
        }},
        "11": {"class_type": "Hy3DApplyTexture", "inputs": {"texture": ["10", 0], "renderer": ["9", 2]}},
        "12": {"class_type": "Hy3DExportMesh", "inputs": {
            "trimesh": ["11", 0], "filename_prefix": "hunyuan/hunter_textured", "file_format": "glb", "save_file": True,
        }},
        "13": {"class_type": "SaveImage", "inputs": {"images": ["10", 0], "filename_prefix": "hunyuan/texture_atlas"}},
        "14": {"class_type": "SaveImage", "inputs": {"images": ["7", 0], "filename_prefix": "hunyuan/painted_views"}},
        "15": {"class_type": "SaveImage", "inputs": {"images": ["5", 0], "filename_prefix": "hunyuan/normal_views"}},
    }
