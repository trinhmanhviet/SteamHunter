# Chỉnh tư thế Hunter — bản thử

## Mở

Chạy `tools/open_hunter_pose.cmd`. Blender trong dự án sẽ mở nhân vật và bảng
**Pose Hunter** ở thanh bên phải. Không cần cài thêm thư viện hay plugin.

Nếu không thấy bảng: đưa chuột vào vùng nhân vật, nhấn **N**, chọn tab **Item**.
Bảng **Pose Hunter** nằm trên bảng Transform.

## Ba tư thế mẫu

- **Giữ charge**: frame 1; kiếm ra sau, đầu kiếm chạm đất.
- **Bổ xuống**: frame 15; tư thế giữa lúc vung kiếm.
- **Kết thúc**: frame 30; kiếm phía trước gần mặt đất.

Đây là ba tư thế để chỉnh và so sánh. Chưa phải animation hoàn chỉnh để đưa vào
game; các frame giữa chỉ là nội suy giúp quan sát.

## Thao tác

1. Bấm tư thế trong bảng **Pose Hunter**.
2. Chọn điểm điều khiển bằng các nút **Kiếm**, **Hông**, **Thân**, **Chân trước**,
   **Chân sau**. Có thể chọn trực tiếp điểm điều khiển trên nhân vật.
3. **G** rồi kéo chuột để di chuyển; **R** rồi kéo chuột để xoay. Bấm chuột trái
   xác nhận; **Esc** hủy. Hướng ngoài mặt phẳng đi cảnh đã khóa.
4. **Chân**: G để đặt mũi chân; R để nhấc gót quanh mũi chân. Chân giữ vị trí khi
   kéo hông, nên có thể chỉnh độ chùng gối bằng điểm Hông.
5. **Kiếm**: G di chuyển, R đổi góc; hai tay đi theo cán. Không kéo các bàn tay
   riêng vì sẽ làm mất điểm cầm kiếm.
6. **Thân**: R nghiêng thân. **Hông**: G di chuyển hông.
7. **Ctrl+Z** hoàn tác, **Ctrl+S** lưu. Tự ghi keyframe đã bật, nên sửa tư thế tại
   frame hiện tại sẽ được giữ lại khi chuyển sang tư thế khác.

**Khôi phục tư thế** đưa các điểm điều khiển của tư thế mẫu hiện tại về ban đầu.
**Xuất sprite** xuất PNG nền trong suốt 384×384 vào thư mục `exports` cạnh file
Blender. Cơ thể giữ quy mô pixel của game, canvas rộng đủ chứa kiếm.

Nếu kéo kiếm quá xa, tay không với tới; nếu kéo hông quá xa, chân không với tới.
Bảng có thông báo tầm với của hai tay. Các giới hạn hiện chỉ hỗ trợ đi cảnh ngang,
không bảo đảm mọi tư thế tùy ý đều đúng giải phẫu hoặc không xuyên hình.

## Giáp và an toàn dữ liệu

Giáp gối/ống chân là các mảnh cứng tách từ model hiện có, gắn vào cẳng chân. Xương
chân đã sửa hướng gập để tránh giáp quay khỏi camera do xoắn sai như bản trước.
Texture đã đóng gói trong file. Bản thử nằm riêng, chưa thay atlas hoặc APK của
game. Khi thử chỉnh, có thể dùng File → Save As để lưu một bản riêng.
