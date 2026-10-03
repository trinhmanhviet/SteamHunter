extends RefCounted

const TEXT := {
	"en": {
		"title": "Mist & Iron", "subtitle": "A hunt beneath the smoke",
		"start": "HUNT", "forge": "FORGE", "lang": "TIẾNG VIỆT", "quit": "QUIT",
		"camp": "THE CAMP", "choose_hunt": "CHOOSE A HUNT", "hunt_name": "CINDERBACK", "moor_region": "SMOKE MOOR", "hunt_tip": "Follow tracks through the smoke.",
		"thornhart_name": "THORNHART", "briarwood_region": "BRIARWOOD", "briarwood_tip": "Follow broken branches into the woods.", "boar_name": "BRISTLEHOG", "antler_break": "ANTLERS BROKEN!",
		"hunt_goal": "Track down the Cinderback", "boss_name": "CINDERBACK", "small_name": "MIRE RAT",
		"health": "HEALTH", "stamina": "STAMINA", "parts": "IRON PARTS", "level": "FORGE",
		"gear_button": "GEAR", "gear_title": "THE GEAR FORGE", "blade_name": "GREAT CLEAVER", "counter_name": "WARDEN SABRE", "twins_name": "TWIN FANGS", "pike_name": "BASTION PIKE", "maul_name": "FOUNDRY MAUL",
		"blade_desc": "Read the beast, then commit.", "counter_desc": "Build Focus and turn blows aside.", "twins_desc": "Build Tempo through fast pressure.", "pike_desc": "Hold ground behind a stout guard.", "maul_desc": "Short reach, crushing blows.",
		"equipped": "EQUIPPED", "equip": "EQUIP", "craft_weapon": "FORGE · {cost} PARTS", "need_parts": "NEED {cost} PARTS",
		"forge_ready": "Heat the forge - {cost} parts", "forge_short": "Need {cost} parts",
		"forge_done": "Your blade bites deeper!", "back": "BACK", "resume": "RESUME", "retry": "TRY AGAIN",
		"return": "BACK TO CAMP", "victory": "HUNT COMPLETE", "defeat": "THE HUNT ENDS",
		"victory_body": "You brought back {parts} iron parts.", "defeat_body": "Rest by the fire and set out again.",
		"controls": "A/D MOVE  •  SPACE JUMP  •  J STRIKE  •  HOLD L HEAVY  •  K DODGE",
		"break": "VENT BROKEN!", "part_broken": "PART BROKEN!", "wound_open": "WOUND OPEN", "target": "TARGET", "target_cycle": "AIM", "part_vent": "BACK VENT", "part_tail": "TAIL", "part_antler": "ANTLERS", "part_hoof": "HOOF",
		"dodge": "DODGE", "jump": "JUMP", "attack": "HIT", "heavy": "HEAVY",
		"pause": "PAUSED", "collected": "+1 IRON PART", "press": "PRESS TO HUNT", "potion": "HERB DRAUGHT", "drink": "DRINK", "herb": "+1 HERB DRAUGHT", "healed": "WOUNDS MENDED",
		"forge_max": "Forge at full heat", "new_hunt": "Cinderback grows fiercer with each hunt",
		"hunt_count": "HUNTS WON: {count}", "sound": "SOUND"
	},
	"vi": {
		"title": "Sương và Sắt", "subtitle": "Đi săn dưới làn khói",
		"start": "ĐI SĂN", "forge": "RÈN DAO", "lang": "ENGLISH", "quit": "RA NGOÀI",
		"camp": "BÊN LỀU", "choose_hunt": "CHỌN CHỖ SĂN", "hunt_name": "LƯNG THAN", "moor_region": "BÃI KHÓI", "hunt_tip": "Lần theo dấu chân qua bãi lầy.",
		"thornhart_name": "HƯƠU GAI", "briarwood_region": "RỪNG GAI", "briarwood_tip": "Theo cành cây gãy vào rừng sâu.", "boar_name": "LỢN GAI", "antler_break": "SỪNG GÃY!",
		"hunt_goal": "Tìm và hạ Lưng Than", "boss_name": "LƯNG THAN", "small_name": "CHUỘT LẦY",
		"health": "MÁU", "stamina": "SỨC", "parts": "MẢNH SẮT", "level": "LÒ",
		"gear_button": "ĐỒ", "gear_title": "LÒ RÈN ĐỒ", "blade_name": "DAO BẢN LỚN", "counter_name": "DAO GẠT ĐÒN", "twins_name": "DAO ĐÔI", "pike_name": "GIÁO CHẮN", "maul_name": "BÚA LÒ",
		"blade_desc": "Đọc đòn quái rồi chém dứt khoát.", "counter_desc": "Gom Nhịp và gạt đòn đúng lúc.", "twins_desc": "Gom Đà bằng chuỗi chém nhanh.", "pike_desc": "Giữ chỗ bằng khiên và mũi giáo.", "maul_desc": "Đánh gần, đòn nặng.",
		"equipped": "ĐANG CẦM", "equip": "CẦM MÓN NÀY", "craft_weapon": "RÈN · {cost} MẢNH", "need_parts": "CẦN {cost} MẢNH",
		"forge_ready": "Rèn thêm - tốn {cost} mảnh", "forge_short": "Cần {cost} mảnh để rèn",
		"forge_done": "Dao của bạn bén hơn!", "back": "QUAY LẠI", "resume": "CHƠI TIẾP", "retry": "SĂN LẠI",
		"return": "VỀ LỀU", "victory": "SĂN XONG", "defeat": "BẠN NGÃ RỒI",
		"victory_body": "Bạn mang về {parts} mảnh sắt.", "defeat_body": "Nghỉ bên bếp lửa rồi đi săn lại.",
		"controls": "A/D ĐI  •  SPACE NHẢY  •  J CHÉM  •  GIỮ L CHÉM MẠNH  •  K LĂN",
		"break": "VỠ LƯNG!", "part_broken": "ĐIỂM NHẮM HỎNG!", "wound_open": "RÁCH MỞ", "target": "ĐIỂM NHẮM", "target_cycle": "NHẮM", "part_vent": "LỖ HƠI", "part_tail": "ĐUÔI", "part_antler": "CẶP SỪNG", "part_hoof": "MÓNG",
		"dodge": "LĂN", "jump": "NHẢY", "attack": "CHÉM", "heavy": "CHÉM MẠNH",
		"pause": "DỪNG", "collected": "+1 MẢNH SẮT", "press": "BẤM ĐỂ ĐI SĂN", "potion": "NƯỚC LÁ", "drink": "UỐNG", "herb": "+1 NƯỚC LÁ", "healed": "ĐỠ ĐAU RỒI",
		"forge_max": "Đã rèn hết mức", "new_hunt": "Lưng Than sẽ dữ hơn sau mỗi lần săn",
		"hunt_count": "ĐÃ SĂN THẮNG: {count}", "sound": "TIẾNG"
	}
}

static func get_text(language: String, key: String) -> String:
	var english: Dictionary = TEXT["en"]
	var bucket: Dictionary = TEXT.get(language, english)
	return str(bucket.get(key, english.get(key, key)))
