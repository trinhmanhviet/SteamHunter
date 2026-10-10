# Mist & Iron — Great Cleaver Demo 0.1.0

Demo riêng cho đòn bổ đại kiếm, dựng theo clip người dùng cung cấp ngày 10/10/2026.
Nhân vật trong demo là sprite 2D, render từ mô hình Hunyuan đã làm sạch. Thân người
và vũ khí là hai lớp riêng; toàn bộ hình nhân vật/kiếm là asset của dự án.

Bản Android, Windows và video chạy trên máy thật:
[Great Cleaver Demo 0.1.0](https://github.com/trinhmanhviet/SteamHunter/releases/tag/gs-demo-v0.1.0).

## Chơi trên Android

Ứng dụng **Mist & Iron GS Demo**, package `org.mistandiron.overheaddemo`.

- Chạm nhanh vùng dưới bên phải để bổ thường.
- Giữ ở vùng đó để nâng kiếm, giữ charge; nhả để bổ xuống.
- Analog xuất hiện đúng vị trí chạm và ẩn khi nhả.
- **Tự diễn** luân phiên đòn thường và charge để xem animation rảnh tay.
- **Phóng to** giúp quan sát tư thế. **Làm lại** xóa bộ đếm và đưa về tư thế đầu.
- Demo có một mục tiêu cố định và một đòn duy nhất, chưa tích hợp bộ combo hay
  di chuyển vào game chính. Mục tiêu nhận hit theo sự kiện tiếp đất của animation;
  đây chưa phải bài kiểm tra collision với quái di chuyển.

## Windows

Chạy `GreatCleaverDemo-0.1.0.exe`. Giữ/nhả Space hoặc chuột ở vùng dưới bên phải.
Esc thoát. APK là bản thử được ký bằng debug keystore của dự án.

## Nhịp chuyển động

Mã nguồn hiện tại đã được đồng bộ với game 0.10.16: nâng .20 s → bổ .10 s →
chịu đà .22 s → hồi .48 s, tổng 1.00 s. Giáp chân và thế đặt chân cũng đã sửa.
APK demo 0.1.0 trên release cũ vẫn dùng nhịp dưới đây.

Nâng kiếm .20 s → bổ .10 s → chịu đà 1.10 s → hồi thế .60 s, tổng 2.00 s.
Charge thêm vòng giữ kiếm .40 s, lặp tới lúc nhả. Nhả sớm được ghi nhận nhưng
nhân vật vẫn hoàn thành đoạn nâng kiếm trước khi bổ. Hit nằm ở frame tiếp đất,
không tính sát thương khi nâng/giữ và không lặp hit lúc đang hồi.

74 frame render, palette chung 28 màu. Chân trước dịch ra chống đỡ, chân sau
nhấc gót; hông/vai xoay và thân cúi sâu lúc chịu đà. Camera, tỉ lệ và mốc đất
giữ nguyên. Khung vũ khí rộng hơn thân để không cắt đầu kiếm.

## Kiểm thử và kết quả

- Godot: 17 kiểm tra controller, 161 kiểm tra UI/tài nguyên đều qua.
- Android thật: 2448×1080 landscape/fullscreen; chạm nhanh 100 sát thương,
  giữ 2.7 s rồi nhả 250, mỗi cú một hit; trong lúc giữ không phát sinh hit.
- Đã sửa lỗi ngưỡng charge do sai số số thực, lệch thời điểm hit một frame và
  Android nhận cả touch lẫn mouse giả khiến nút toggle chạy hai lần.
- Nút tự diễn/phóng to/làm lại được chạm thử trên máy thật sau khi sửa.
- Windows bản đóng gói đã chạy smoke test; Android bản cuối đã cài qua ADB.
- Không có SCRIPT ERROR trong log của hai cú test cuối trên Android.

Ảnh kiểm tra và thông tin xác nhận ở `review/` và `verification.json`.
Animation preview ở `../hunyuan_hunter/overhead_motion/`.

## Tái tạo

Tại gốc repo:

```powershell
& '.tools/blender/blender-4.5.4-windows-x64/blender.exe' -b 'prototypes/hunyuan_hunter/heavy_motion/hunter_heavy_rig.blend' --python 'tools/render_overhead_demo.py' -- 'prototypes/hunyuan_hunter/overhead_motion'
& '.tools/hunyuan-env/Scripts/python.exe' 'tools/pack_overhead_demo.py'
& '.tools/godot/Godot_v4.7.2-stable_win64_console.exe' --headless --path 'prototypes/overhead_demo' --editor --import --quit
& '.tools/godot/Godot_v4.7.2-stable_win64_console.exe' --headless --path 'prototypes/overhead_demo' --script test_cycle.gd
& '.tools/godot/Godot_v4.7.2-stable_win64_console.exe' --headless --path 'prototypes/overhead_demo' --script test_demo.gd
& '.tools/godot/Godot_v4.7.2-stable_win64_console.exe' --headless --path 'prototypes/overhead_demo' --export-debug Android 'build/GreatCleaverDemo-0.1.0.apk'
```

Chi tiết bàn tay/áo giáp và đường cong chuyển động vẫn có thể được chỉnh
thêm sau đánh giá của người dùng. Chất lượng tư thế đã được kiểm tra bằng ảnh,
không suy ra từ việc test logic qua.
