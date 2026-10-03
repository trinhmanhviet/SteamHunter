# Mist & Iron / Sương và Sắt — Thiết kế game hoàn chỉnh

**Trạng thái:** Mục tiêu thiết kế cho bản game hoàn chỉnh. Mục “Đã có” ở cuối mô tả bản đang chạy; các mục còn lại là yêu cầu cần làm, không phải tính năng đã phát hành.

## 1. Lời hứa với người chơi

Một game săn thú 2D đi cảnh ngang cho Android. Người chơi rời trại, lần theo dấu con thú lớn qua địa hình có nhiều tầng, đọc động tác của nó, dùng vũ khí có nhịp riêng để đánh gãy từng bộ phận, lấy vật liệu, quay về rèn đồ và mở vùng đất tiếp theo. Mỗi cuộc săn có ít nhất một biến đổi về thời tiết, đường đi hoặc hành vi thú. Một lượt săn thông thường dài 8–15 phút; trận cuối chương 15–22 phút. Chơi được từ đầu đến hết truyện khi không có mạng.

Game lấy cảm hứng ở *vòng chơi* săn → lấy đồ → rèn → săn tiếp và ở thiên nhiên đổi trạng thái. Nhân vật, thú, cốt truyện, tên, dáng hình, âm thanh, bản đồ và giao diện đều do dự án tự tạo. Góc nhìn, địa hình nền tảng và thao tác điện thoại tạo bản sắc riêng. Tư liệu của Capcom mô tả trọng tâm săn thú lớn, môi trường biến đổi và ngắm đòn chính xác trong Wilds; ở đây các ý tưởng rộng ấy được thiết kế lại thành cơ chế 2D riêng: dấu vết, địa hình nhiều tầng và đánh đúng bộ phận khi thú lộ sơ hở. Nguồn đối chiếu: [Capcom](https://www.capcom.co.jp/ir/english/news/html/e250331.html), [Capcom France](https://www.capcomfrance.fr/mhwi_sop_mai2024/).

## 2. Quyết định sản phẩm

| Mục | Chốt thiết kế |
|---|---|
| Nền tảng | Android 10 trở lên; màn ngang; Godot 4; ngoại tuyến, lưu trên máy |
| Ngôn ngữ | English / Tiếng Việt; mọi chữ trong game có hai bản; tiếng Việt ưu tiên từ thuần thông dụng, không dùng màu sắc Đông Á |
| Cách chơi | Một người; một bạn đồng hành máy điều khiển mở từ chương 2; không cần tài khoản, không bán vật phẩm |
| Góc nhìn | Đi cảnh ngang, camera cuộn, nền tảng có độ cao khác nhau, hang và đường tắt |
| Nội dung mục tiêu | 6 vùng, 18 loài thú lớn riêng, 12 loài thú nhỏ, 8 kiểu vũ khí, 6 bộ đồ mặc, 4 chương truyện, ít nhất 48 cuộc săn viết tay và lượt săn lặp có biến thể |
| Kết thúc | Hạ thú cuối, xem hồi kết, tiếp tục săn ở mức khó cao với trang bị và dấu mốc mới |
| Phân phối | APK cài trực tiếp; bản phát hành có thể đóng gói AAB sau khi hoàn thành kiểm thử và ký phát hành |

Không ép đưa đủ mọi thú vào màn thử nghiệm đầu. Mỗi hệ thống phải hoạt động bằng hình giữ chỗ trước khi làm thêm art. Những ảnh đã tạo được giữ lại để dùng khi hệ thống tương ứng ổn định.

## 3. Bối cảnh và truyện

Vùng biên **Greyreach / Bờ Sương** sống nhờ các lò hơi và bánh nước. Một lớp sương mang bụi kim loại khiến đường di cư của thú đổi hướng, nguồn nước nóng lên và làng bị cắt khỏi nhau. Người chơi là thợ tìm đường của trại **Hearthway / Bến Lửa**, đi cứu tuyến tiếp tế và tìm nguồn sương. Không có “thú ác”: chúng tranh chỗ ở, ăn, bảo vệ con hoặc phản ứng với máy móc của con người. Kết truyện buộc trại tháo nhà máy hút hơi dưới núi; việc săn thú đầu đàn chỉ mở đường đến bộ máy.

| Chương | Vai trò trong truyện | Vùng mở | Bước ngoặt chơi |
|---|---|---|---|
| I — Khói ở đồng | Khôi phục đường than và tìm dấu thú đổi vùng | Smoke Moor, Briarwood | Dấu vết, săn, rèn, bộ phận gãy |
| II — Nước dâng | Giữ tuyến thuyền và kênh nước | Floodworks, Salt Cliffs | Nước đổi mực, dây móc, bạn đồng hành |
| III — Đất nóng | Tìm máy hút hơi cũ dưới lòng đất | Ember Hollow | Nóng, khí độc, lựa đường ngắn có rủi ro |
| IV — Sương mở | Ngăn máy trước khi cả vùng đổi mùa bất thường | Frost Spires | Gió và băng, hai cuộc săn liên tiếp, trận cuối |

Nhân vật ở trại: Mara (thợ rèn, nâng đồ), Edric (người ghi dấu thú, mở sổ tay), Nell (người bào thuốc), Bram (người đưa tin, bảng săn), Pip (bạn đồng hành dùng đèn và dây móc). Mỗi người có chuỗi chuyện ngắn 3–5 đoạn, lời thoại thay đổi theo chương. Truyện được kể qua đoạn nói ngắn, cảnh trong game và dấu tích trên đường; không chặn người chơi bằng đoạn phim dài.

## 4. Vòng chơi và luật cuộc săn

1. Ở trại, xem bảng săn: loài, vùng, thời tiết dự báo, phần thưởng, điều kiện mở; chọn vũ khí, áo, đồ mang.
2. Vào vùng tại một điểm nghỉ. Quan sát dấu chân, lông, vết cào hoặc âm thanh. Thu cây, quặng, đồ thô; săn thú nhỏ nếu cần.
3. Đi qua 3–5 khu nối nhau bằng đường trên/dưới. Dấu vết đưa tới thú lớn; có ít nhất hai lối tiếp cận (nhanh nguy hiểm, dài có đồ nhặt).
4. Thú đổi chỗ 1–2 lần khi mất máu hoặc môi trường đổi. Người chơi có thể nghỉ, nấu nhanh, làm lại đồ dùng tại điểm nghỉ đã mở.
5. Thắng khi hạ hoặc bắt sống nếu cuộc săn cho phép. Thua khi hết ba lần gục hoặc hết thời gian. Chỉ những cuộc săn thử thách mới có giờ giới hạn ngắn.
6. Màn kết quả cho biết thời gian, số lần gục, phần đã gãy, vật liệu nhận, dấu mốc mở. Trở về trại; lưu ngay khi trả thưởng.

**Tuyến săn:** không có quái tự hồi máu khi đổi khu. Nếu người chơi rời trận, thú ăn hoặc ngủ để hồi tối đa 10% máu một lần; hành động này có báo hiệu và có thể cắt ngang. Thú không biến mất vì người chơi rời màn. Tái thử sau thất bại giữ vật liệu đã thu ngoài trận, nhưng không giữ vật liệu của thú lớn chưa hạ; đồ dùng đã tiêu hao vẫn mất. Điểm nghỉ mở trong cuộc săn chỉ dùng cho lượt đó.

**Loại cuộc săn:** 24 truyện chính (4 mỗi vùng), 18 săn phụ viết tay (3 mỗi vùng), 6 thử thách cuối vùng, rồi bảng săn lặp tạo từ thú đã gặp × thời tiết × mục tiêu phụ. Không khóa truyện sau một lần thua; gợi ý xem bộ đồ và điểm yếu trong sổ tay.

## 5. Di chuyển và điều khiển

Hunter chạy, quay đầu, nhảy có độ cao theo thời gian giữ, bám mép, nhảy khỏi tường ở vài chỗ có dấu, lăn tránh, leo thang, trượt xuống dốc, đu dây móc ở điểm neo. Không có leo tự do lên mọi bề mặt. Rơi xuống vực trả người chơi về mép gần nhất và trừ máu nhỏ; không mất lượt săn do một cú hụt chân. Quán tính thấp để điều khiển cảm ứng chính xác.

Điện thoại ngang: ngón trái kéo analog ảo theo độ mạnh của chuyển động. Góc phải có nút **Đánh** lớn, các nút **Mạnh**, **Nhảy**, **Né**, **Dùng** xếp vòng quanh theo bố cục quen thuộc ở game MOBA. Khi đến gần thú lớn, nút **Nhắm** xuất hiện để đổi bộ phận đang nhắm; vòng sáng trên thú chỉ đúng vị trí. Bản đầy đủ sẽ cho giữ **Nhắm** để chọn nhanh nhiều bộ phận khi loài thú có trên hai điểm đánh. Chạm **Dùng** uống thuốc, giữ mở vòng đồ mang. Nút tương tác xuất hiện gần điểm nhặt/điểm nghỉ; không chen thêm nút thường trực. Có đổi bên cụm nút, chỉnh kích cỡ 80–140%, độ trong, tắt rung. Gamepad và bàn phím hỗ trợ cùng chức năng. Vùng chạm tối thiểu 9 mm trên màn tham chiếu; vùng an toàn không đè camera/notch.

Camera ưu tiên nhìn trước theo hướng đi, zoom ra vừa đủ khi thú lớn vào trận, không che hunter bởi HUD. Mọi hành động quan trọng có dấu hiệu bằng hình **và** âm thanh; tùy chọn giảm chớp, rung, lắc màn.

## 6. Chiến đấu

**Các giá trị:** máu, sức bền, độ bén (vũ khí lưỡi), hơi (vũ khí máy), mức choáng, tác động theo phần thân. Đòn nhanh, đòn mạnh và né tiêu sức bền; sức bền hồi khi không ra đòn hoặc chạy nước rút. Không thể hủy mọi đòn: cửa sổ hủy chỉ ở cuối pha vung hoặc sau cú đánh trúng, nên nhịp ra đòn có cam kết. Bị đánh có khoảng bất tử ngắn để tránh chết do nhiều hitbox cùng khung hình. Né có khoảng tránh trúng hữu hạn; không xuyên qua mọi bức tường.

**Đọc thú:** mỗi đòn thú có ba pha rõ: báo trước, gây hại, nghỉ. Dấu báo gồm dáng người, hiệu ứng dưới chân và tiếng riêng. Đòn đầu của loài mới được dạy trong lần gặp truyện; về sau không có chỉ dẫn trên đầu. Không cho thú tấn công ngoài màn hình. Mỗi thú có ít nhất 5 đòn, trong đó một đòn thay đổi theo địa hình/thời tiết, và một trạng thái mệt hoặc nổi giận khác biệt.

**Đánh đúng phần:** đầu, thân, chân/cánh, đuôi hoặc lõi riêng có máu phần thân. Gãy phần tạo thay đổi thật: mất tầm quét, rơi khỏi nền cao, ngừng phun hơi, lộ lõi, hay đi khập khiễng. Không phải mọi phần đều rơi đồ; bảng thưởng mô tả rõ. Điểm bị thương xuất hiện sau nhiều lần đánh trúng cùng phần, tồn tại tới hết trận, khiến đòn ngắm trúng đó gây thêm choáng. Một đòn mạnh chính xác vào điểm bị thương gây ngắt đòn một lần, sau đó điểm đó đóng lại. Cơ chế này phục vụ 2D, dùng vòng chọn phần gần thú, không sao chép biểu tượng hoặc giao diện nguồn cảm hứng.

**Tình trạng:** cháy (mất máu theo nhịp), ướt (đỡ cháy nhưng dễ lạnh), lạnh (hồi sức bền chậm), độc (mất máu nhẹ đến khi uống thuốc), ngợp hơi (hạn chế đòn máy). Mỗi tình trạng có vật chữa, thời gian tối đa và chỉ báo dễ phân biệt; không cộng dồn vô hạn. Địa hình cũng tác động thú.

**Bắt sống:** sau khi thú khập khiễng và sổ tay cho biết bắt được, đặt lồng dây ở nền phẳng, đẩy thú vào khi nó mệt. Thưởng khác hạ thú; một số vật liệu chỉ rơi khi bắt. Trận cuối truyện không bắt được.

## 7. Tám kiểu vũ khí

Mỗi kiểu có đòn nhanh, đòn mạnh, một thế riêng, chi phí sức bền, tầm và đường phát triển 4 bậc. Có thể đổi giữa hai vũ khí đã mang tại điểm nghỉ; không đổi giữa cú vung. Vũ khí được cân theo cơ hội đánh trúng, không theo một con số sát thương duy nhất.

| Kiểu (EN / VI) | Vai trò | Thế riêng |
|---|---|---|
| Cleaver / Dao to | Dễ học, quét gần | Giữ đòn mạnh chém xuống, thêm choáng |
| Pike / Lao dài | Giữ khoảng cách | Chống lao, đâm khi thú xông tới |
| Maul / Búa nặng | Phá phần cứng | Tích lực rồi đập, bước ngắn khi vung |
| Twin Knives / Dao đôi | Nhanh, cần sát thân | Chuỗi đòn tích nhịp, kết thúc rút lui |
| Chain Hook / Móc xích | Đánh tầm trung, kéo | Móc điểm neo hoặc phần thú đang lộ |
| Bell Shield / Khiên chuông | Đỡ đòn, hỗ trợ | Gõ khiên chặn và gây choáng ngắn nếu đúng nhịp |
| Spark Bow / Cung lửa | Tầm xa có giới hạn | Căng dây, chọn góc; mũi tên phải chế ở trại |
| Steam Lance / Lao hơi | Mạnh theo nhịp nạp | Xả hơi đâm xuyên phần cứng, quá nóng phải nguội |

Mỗi loài thú lớn có ít nhất 3 dòng vật liệu cho vũ khí (gốc, cứng, hiếm), nhưng công thức rèn dùng chung một khung dữ liệu để tránh hàng trăm công thức viết tay. Mọi kiểu vũ khí chơi được để kết thúc truyện; không bắt đổi vũ khí để qua một thú.

## 8. Sáu vùng và hệ sinh thái

Mỗi vùng có 3 bộ đường đi được ghép theo cuộc săn, ít nhất một đường tắt mở bằng hành động, 2 thú nhỏ đặc trưng, 3 thú lớn và 2 trạng thái môi trường. Đường đi có bố cục tác giả kiểm soát; chỉ chọn nhánh và điều kiện, không tạo nền tảng ngẫu nhiên vô lý.

| Vùng (EN / VI) | Đặc trưng đường đi | Trạng thái đổi | Thú lớn |
|---|---|---|---|
| Smoke Moor / Bãi Khói | Đập cũ, ống hơi, nền gạch | Sương dày / gió mở sương | Cinderback, Ashbell Ram, Sootwing |
| Briarwood / Rừng Gai | Rễ cao, thân cây gãy, vũng bùn | Khô / mưa rào | Thornhart, Rootjaw, Lantern Moth |
| Floodworks / Kênh Nước | Cống, bánh nước, bè | Nước thấp / nước dâng | Lockmaw, Reed Widow, Mud Drum |
| Salt Cliffs / Vách Muối | Cầu treo, hang gió, mép đá | Gió lặng / gió quật | Cliffhorn, Brineback, Glass Gull |
| Ember Hollow / Hầm Than | Lò ngầm, thang xích, van | Lò nguội / hơi tràn | Furnace Mole, Copper Maw, Kiln Widow |
| Frost Spires / Đỉnh Lạnh | Trụ băng, dây kéo, mái đổ | Quang / bão tuyết | Pale Antler, Rime Wyrm, Grey Bell |

**Thú nhỏ (2 mỗi vùng):** Mire Rat, Bristlehog; Twig Skitter, Bark Hopper; Drain Eel, Reed Runner; Salt Crab, Ledge Kite; Ember Tick, Coal Crawler; Ice Mite, Snow Hopper. Chúng có vai trò kiếm đồ, làm phiền hoặc báo tin thú lớn; không chỉ là vật cản đặt ngẫu nhiên.

**Thời tiết:** đổi theo mốc kịch bản hoặc bộ hẹn giờ có báo trước; dữ liệu lưu seed và thời điểm nên khởi động lại không đổi kết quả săn. Truyện chính không buộc người chơi chờ thời tiết đúng để đi tiếp. Ví dụ mưa làm rễ trơn và dập đốm cháy, gió đẩy đường nhảy và đổi hướng Sootwing. Mỗi vùng có ít nhất một tương tác nơi thú có thể phá đường hoặc tạo lối mới.

## 9. Mười tám thú lớn

Mỗi thú có dáng đọc được ở cỡ điện thoại, cách di chuyển, 5+ đòn, 2 phần gãy có tác động, chỗ ngủ/ăn, dấu vết riêng và vật liệu riêng. Dưới đây là dấu hiệu nhận dạng và biến cố trận; bản hành vi chi tiết sẽ là dữ liệu riêng của từng thú trước khi dựng hình cuối.

| Thú | Dáng và lối đánh chủ đạo | Biến cố khi gãy phần / môi trường |
|---|---|---|
| Cinderback / Lưng Than | Bò sát lưng lò, lao và phun hơi | Gãy van lưng làm luồng hơi ngắn lại |
| Ashbell Ram / Cừu Chuông | Cừu sừng rỗng, húc theo nhịp chuông | Gãy một sừng lệch hướng húc |
| Sootwing / Cánh Muội | Chim cánh phủ tro, bổ từ nền cao | Gãy cánh buộc xuống đất; gió đổi điểm đáp |
| Thornhart / Hươu Gai | Hươu rừng mang rễ gai, phóng gai | Gãy nhánh sừng mất một dải gai |
| Rootjaw / Hàm Rễ | Lợn rừng lớn có hàm rễ, đào dưới sàn | Gãy ngà không phá được một số nền |
| Lantern Moth / Bướm Đèn | Bướm đêm mang bọc sáng, đánh lạc hướng | Vỡ bọc đèn bỏ ảo ảnh, rừng tối hơn |
| Lockmaw / Hàm Cống | Cá sấu phủ chốt sắt, khóa lối nước | Gãy đuôi bơi chậm; nước dâng đổi sân |
| Reed Widow / Nhện Sậy | Nhện chân dài căng tơ giữa cọc | Gãy chân không còn giăng tơ trên cao |
| Mud Drum / Trống Bùn | Cóc bụng rỗng tạo sóng bùn | Vỡ túi bụng mất sóng rộng |
| Cliffhorn / Sừng Vách | Dê núi thân đá, húc trên mép hẹp | Gãy sừng rơi đá ít hơn |
| Brineback / Lưng Muối | Rùa muối trườn qua cầu, phun nước mặn | Bóc mai mở điểm mềm nhưng tăng tốc |
| Glass Gull / Mòng Kính | Chim biển cánh sắc, lượn theo gió | Gãy cánh giảm số lần lượn |
| Furnace Mole / Chuột Lò | Chuột chũi bọc quặng, đào trồi từ sàn | Vỡ mũi khoan mất đòn trồi nhanh |
| Copper Maw / Hàm Đồng | Thằn lằn hàm kim loại, cắn van hơi | Gãy hàm không nuốt được hơi để phun |
| Kiln Widow / Nhện Lò | Nhện trong lò, thả kén nóng | Gãy chân trước bớt kén; hơi tràn đổi lối |
| Pale Antler / Sừng Trắng | Nai trắng chạy trên băng và bậc cao | Gãy gạc tạo ít đường băng hơn |
| Rime Wyrm / Giun Tuyết | Giun dài chui tuyết, cuộn quanh cột | Gãy gai lưng giảm mưa băng |
| Grey Bell / Chuông Xám | Thú cuối có khoang cộng hưởng và bốn chân | Vỡ hai chuông hông mở lõi; đổi sân 3 pha |

Trận Grey Bell có hành vi và hình dáng nguyên gốc; nó là thú bị máy hút hơi làm lạc đường, không là bản sao thú cuối của game tham chiếu. Mỗi thú có lần gặp truyện dạy cơ chế, săn phụ đổi bối cảnh và một lượt khó cao sau truyện.

## 10. Đồ nhặt, rèn và phát triển

Vật liệu có bốn nhóm: cây/thảo mộc, quặng/phế sắt, phần thú nhỏ, phần thú lớn. Phần thú lớn luôn ghi rõ con gì và phần nào; không có đồng tiền thay thế cho mọi thứ. Rèn vũ khí và áo cần vật liệu theo loài + quặng từ vùng tương ứng; nâng bậc 1–4 đòi thú mạnh hơn, không chỉ lặp con đầu. Sổ tay hiện nơi tìm, điều kiện gãy/bắt, những phần đã thấy, và gợi ý điểm yếu mở sau quan sát, tránh lộ hết từ đầu.

Sáu bộ đồ mặc: Field Coat / Áo Đồng, Ember Coat / Áo Than, Thorn Vest / Áo Gai, Reed Suit / Áo Sậy, Salt Mantle / Áo Muối, Frost Wrap / Áo Lạnh. Mỗi bộ có 3 mảnh (mũ, thân, chân), một chỉ số chống đỡ cơ bản, kháng một tình trạng, và một tác dụng bộ khi mặc đủ ba mảnh. Không chia độ hiếm bằng màu để thay cho công dụng. Có thể đổi vẻ ngoài đã mở mà không đổi chỉ số. Ba ảnh áo đã tạo hiện là tư liệu tạm; trước khi hoàn tất trang bị chỉ cần ô màu và tên.

Đồ mang: thuốc uống hồi máu, thuốc giải độc, gói giữ ấm, mồi, lồng dây, mũi tên, bữa ăn, bộ sửa vũ khí. Túi giới hạn theo *loại* và số món, được soạn ở trại; có bổ sung ít món ở điểm nghỉ nếu đã mang vật liệu. Nấu ăn tại trại chọn món theo nguyên liệu và cho một lợi ích ngắn trong một cuộc săn. Thợ rèn cho xem khác biệt chỉ số và vật liệu còn thiếu trước khi trả phí. Bán phần dư đổi tiền công trại, nhưng tiền không thay thế phần thú hiếm.

**Độ khó:** ba mức Trợ lực / Vừa / Gắt có thể đổi tại trại, tác động khoảng báo đòn, số đồ dùng nhận và sát thương trúng; không khóa vật liệu hay truyện. Trợ lực tự mở gợi ý sau ba lần thua cùng thú. Mức khó cao sau truyện thêm mẫu đòn/đổi thời tiết, vật liệu bậc 4 và thành tích riêng, không tăng máu đơn thuần.

## 11. Trại, sổ tay và giao diện

Trại là không gian điều hướng bằng các điểm dễ chạm: Bảng săn, Rèn, Túi, Sổ tay, Nấu, Chỗ nghỉ/Cài đặt. Mỗi màn có nút quay lại ở cùng chỗ. Từ kết quả săn có ba lựa chọn: về trại, săn lại, xem đồ vừa nhặt. Không có màn mua hàng hay đăng nhập. Lần đầu vào game dẫn qua một cuộc săn dạy chạy/nhảy/né/đánh/nhặt, dài dưới 8 phút; có thể xem lại từng chỉ dẫn trong sổ tay.

HUD săn: máu/sức bền góc trái, biểu tượng tình trạng và đồ dùng; tên/máu thú và bộ phận khi giao chiến; dấu đường đi ở rìa màn; nút dừng và cụm điều khiển chạm. Khi không giao chiến, ẩn thanh thú và giảm phần chữ. Tỉ lệ chữ tối thiểu đọc được trên điện thoại 6 inch ở 1080p. Màn thiết lập có âm lượng nhạc/tiếng, cỡ chữ, rung, chớp, nút chạm, ngôn ngữ. Mọi thông báo quan trọng có biểu tượng lẫn chữ, không phân biệt bằng màu đơn độc.

Tên tiếng Việt trong UI phải là cụm ngắn, phổ thông: “Săn”, “Rèn”, “Đồ mang”, “Dấu thú”, “Né”, “Uống”. Tên riêng tiếng Anh được dịch nhất quán trong sổ tay và bảng săn. Toàn bộ chuỗi hiển thị nằm trong kho bản dịch; kiểm thử tự động kiểm tra thiếu khóa.

## 12. Âm thanh và hình ảnh

Đích hình cuối: pixel art nguyên gốc, dáng rõ ở tỉ lệ chơi. Theo ảnh tỉ lệ người chơi cung cấp, trong khung logic cao 540 pixel thợ săn hiện cao khoảng **90 pixel** (17% chiều cao), thú nhỏ **38–50 pixel** (7–9%), thú lớn đầu game **115–135 pixel** (21–25%). Thú cuối có thể lớn hơn nếu sân riêng cho phép; khoảng trống để đọc đòn và nhảy luôn được giữ. Tỉ lệ là kích thước hiển thị, không phụ thuộc độ phân giải file ảnh nguồn. Mỗi vùng có bảng màu và 3 lớp chiều sâu; mỗi thú có silhouette riêng trước khi thêm chi tiết. Hoạt ảnh cuối phải thể hiện rõ báo đòn dù tắt hiệu ứng. Không đưa ảnh tạo ra trực tiếp vào hitbox: va chạm theo dữ liệu gameplay.

Âm thanh: chủ đề trại, sáu lớp nhạc vùng đổi nhịp khi gặp thú, tiếng báo đòn riêng theo loài, tiếng trúng phần cứng/mềm, gãy phần, thời tiết và giao diện. Có thể tắt nhạc để vẫn nghe báo đòn. Tài sản âm thanh do dự án tạo hoặc dùng giấy phép ghi rõ; không lấy âm thanh hay nhạc của game tham chiếu.

**Thứ tự làm:** (1) hình khối giữ chỗ và tín hiệu màu, (2) hệ thống/chuyển trạng thái/hitbox, (3) chơi thử trên điện thoại và sửa nhịp, (4) bản art nháp theo silhouette, (5) art cuối/hoạt ảnh/âm thanh cuối, (6) kiểm tra lại độ đọc được. Những ảnh hiện có không ép thiết kế cơ chế phải chạy theo ảnh.

## 13. Kỹ thuật và dữ liệu

Godot 4, GDScript, mục tiêu 60 FPS trên ASUS_AI2201_C và 30 FPS ổn định trên máy Android mức trung bình. Độ phân giải logic thấp, phóng to nguyên pixel; atlas nén phù hợp Android; chỉ nạp dữ liệu vùng hiện tại. APK sau khi đủ art nhắm dưới 250 MB; bộ nhớ đang dùng dưới 700 MB trên máy tham chiếu. Không xin quyền mạng, vị trí, danh bạ. Hỗ trợ mất ứng dụng đột ngột bằng lưu tự động ở trại, điểm nghỉ và sau kết quả săn; ghi file mới rồi thay file cũ, có bản sao dự phòng và nâng phiên bản save.

**Ranh giới mã:**

| Đơn vị | Trách nhiệm | Giao tiếp |
|---|---|---|
| CampaignCatalog | Vùng, thú, cuộc săn, điều kiện mở, bản dịch khóa | Dữ liệu bất biến; mọi ID được kiểm tra khi nạp |
| HuntDirector | Pha cuộc săn, thời tiết, đường đi, mục tiêu, điểm nghỉ | Nhận dữ liệu cuộc săn; phát sự kiện kết quả |
| HunterController | Di chuyển, sức bền, trạng thái ra đòn, đồ dùng | Nhận hành động đầu vào; phát hit/nhặt/gục |
| BeastBrain | Trạng thái thú, chọn đòn, vùng hoạt động | Nhận môi trường và mục tiêu; phát telegraph/hit |
| BodyParts | Máu phần, vết thương, gãy, vật liệu | Nhận hit đã xác nhận; phát part_broken |
| InventoryForge | Túi, công thức, đổi đồ, thưởng | Giao dịch nguyên tử; không cho số âm |
| SaveStore | Phiên bản dữ liệu, ghi/đọc, sao dự phòng | Không phụ thuộc scene hoặc art |
| GameUI | Màn trại/săn/sổ tay/cài đặt, touch mapping | Chỉ hiển thị và gửi ý định, không tự tính thưởng |

Hiện `main.gd` đang tự dựng hai cuộc săn và giữ nhiều trách nhiệm. Sau bản thiết kế, tách dần bằng lát dọc chạy được, giữ save cũ và hai cuộc săn cũ hoạt động. Catalog phải trỏ tới scene/logic bằng ID; thiếu art dùng texture giữ chỗ có kích thước và tâm cố định. Một dữ liệu mẫu cho mỗi vùng phải chạy được trước khi nhân rộng thú.

**Lưu trữ:** phiên bản save, language, settings, story chapter, hunts cleared, hunt records, inventory by material ID, gear owned/upgrades/equipped, cookbook, bestiary discoveries, companion unlock, accessibility. Mọi ID không còn trong catalog được giữ trong kho “unknown” để bản cập nhật không xóa đồ. Save cũ 0.4.0 được chuyển từ `parts`, `forge_level`, `weapons` sang vật liệu/đồ tương ứng một lần; bản sao lưu tạo trước khi đổi.

## 14. Các chặng triển khai và cổng kiểm tra

| Chặng | Kết quả chơi được | Art |
|---|---|---|
| A — Khung game | Catalog, màn trại, save nâng phiên bản, một tuyến săn dữ liệu hóa, kết quả và thử lại | Giữ chỗ |
| B — Săn sâu | Vết thương/phần gãy, thời tiết, dấu vết, điểm nghỉ, bắt sống, 3 thú đầu | Giữ chỗ |
| C — Phát triển | 8 vũ khí, túi/đồ dùng, 6 bộ đồ, rèn, sổ tay, nấu, bạn đồng hành | Giữ chỗ |
| D — Thế giới | 6 vùng, 18 thú lớn, 12 thú nhỏ, 48 cuộc săn tác giả, truyện 4 chương, kết thúc | Art nháp sau từng cơ chế ổn |
| E — Hoàn thiện | Pixel art/hoạt ảnh/âm thanh cuối, hai ngôn ngữ, hỗ trợ chạm và hiệu năng | Art cuối |
| F — Phát hành | Chơi trọn truyện, sửa lỗi, ký build, thử trên nhiều Android | Không còn hình giữ chỗ |

Mỗi chặng phải có APK cài trên điện thoại, kiểm tra một lượt săn trọn từ trại đến kết quả, chạy lại save của bản trước và log không có lỗi script/crash. B và D thêm kiểm tra rõ từng thú/đường đi. E kiểm tra đọc HUD trên màn nhỏ, tất cả câu thoại ở cả hai ngôn ngữ và tốc độ khung hình. F yêu cầu 3 lượt chơi hết truyện độc lập, không softlock; 30 cuộc săn ngẫu nhiên không crash; bản lưu chịu được tắt ứng dụng lúc đang ghi; không còn ảnh, tên, âm thanh hoặc văn bản mượn từ Monster Hunter.

## 15. Đã có trong bản 0.6.1

Trại, hai cuộc săn Cinderback/Thornhart ở Smoke Moor/Briarwood, ba kiểu vũ khí đầu, quái nhỏ, thuốc uống/cây thuốc, rèn cấp đầu, save cục bộ, hai ngôn ngữ, điều khiển chạm và APK Android đã chạy trên ASUS_AI2201_C. Bản 0.4.1 giảm tỉ lệ thợ săn và thú theo ảnh người chơi cung cấp. Bản 0.4.2 đưa dữ liệu hai cuộc săn vào một catalog và tạo danh sách săn cuộn được từ đó. Bản 0.5.0 thêm save phiên bản 2, file tạm và bản sao dự phòng, cùng dấu mốc và thời gian tốt nhất cho từng cuộc săn; save cũ trên ASUS đã chuyển được, giữ tiếng Việt và số liệu cũ. Bản 0.6.0 thêm analog ảo và cụm nút tròn, hai bộ phận phá được trên mỗi thú lớn, điểm bị thương và nút đổi điểm nhắm. Bản 0.6.1 giữ thú lớn ở khu chạm trán tới khi thợ săn đến gần. Các nội dung đó là lát dọc hiện tại, chưa đạt tiêu chí game hoàn chỉnh ở trên. Ba ảnh áo mới tạo chưa gắn vào game; dùng sau chặng C/E theo thứ tự hình giữ chỗ → cơ chế → art.
