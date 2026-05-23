-- Tạo bảng characters lưu trữ thông tin nhân vật One Piece
CREATE TABLE IF NOT EXISTS characters (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    alias VARCHAR(255),
    bounty BIGINT NOT NULL DEFAULT 0,
    affiliation VARCHAR(100) NOT NULL,
    role VARCHAR(100),
    devil_fruit VARCHAR(255),
    devil_fruit_type VARCHAR(50) DEFAULT 'Không có',
    hometown VARCHAR(255),
    age INT,
    height INT, -- tính bằng cm
    status VARCHAR(50) DEFAULT 'Còn sống',
    description TEXT,
    image_url TEXT,
    is_custom BOOLEAN DEFAULT FALSE,
    user_id UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Thêm chính sách RLS (Row Level Security) để cho phép đọc công khai và ghi dữ liệu
ALTER TABLE characters ENABLE ROW LEVEL SECURITY;

-- Xóa chính sách cũ nếu tồn tại trước khi tạo mới
DROP POLICY IF EXISTS "Cho phép đọc công khai" ON characters;
DROP POLICY IF EXISTS "Cho phép tạo nhân vật mới" ON characters;
DROP POLICY IF EXISTS "Cho phép xóa nhân vật" ON characters;
DROP POLICY IF EXISTS "Cho phép cập nhật nhân vật" ON characters;

-- Tạo bảng profiles để lưu trữ phân quyền
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role VARCHAR(50) DEFAULT 'user' NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Enable RLS cho profiles
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Cho phép đọc profiles công khai" ON profiles;
CREATE POLICY "Cho phép đọc profiles công khai" ON profiles
    FOR SELECT USING (true);

-- Hàm tự động tạo profile khi user mới đăng ký
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, role)
  VALUES (new.id, 'user');
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger chạy hàm handle_new_user sau khi đăng ký
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Tạo policy cho phép mọi người đọc dữ liệu
CREATE POLICY "Cho phép đọc công khai" ON characters
    FOR SELECT USING (true);

-- Tạo policy cho phép người dùng đã xác thực chèn dữ liệu mới
CREATE POLICY "Cho phép tạo nhân vật mới" ON characters
    FOR INSERT TO authenticated WITH CHECK (true);

-- Tạo policy cho phép người dùng xóa nhân vật (của họ hoặc admin xóa bất kỳ)
CREATE POLICY "Cho phép xóa nhân vật" ON characters
    FOR DELETE TO authenticated 
    USING (
      auth.uid() = user_id OR 
      EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Tạo policy cho phép người dùng cập nhật nhân vật (của họ hoặc admin cập nhật bất kỳ)
CREATE POLICY "Cho phép cập nhật nhân vật" ON characters
    FOR UPDATE TO authenticated 
    USING (
      auth.uid() = user_id OR 
      EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    ) 
    WITH CHECK (
      auth.uid() = user_id OR 
      EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- Setup Storage for avatars
INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true) ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Avatar images are publicly accessible." ON storage.objects;
DROP POLICY IF EXISTS "Anyone can upload an avatar." ON storage.objects;
DROP POLICY IF EXISTS "Anyone can update their own avatar." ON storage.objects;
DROP POLICY IF EXISTS "Anyone can delete their own avatar." ON storage.objects;

CREATE POLICY "Avatar images are publicly accessible." ON storage.objects FOR SELECT USING ( bucket_id = 'avatars' );
CREATE POLICY "Anyone can upload an avatar." ON storage.objects FOR INSERT TO authenticated WITH CHECK ( bucket_id = 'avatars' );
CREATE POLICY "Anyone can update their own avatar." ON storage.objects FOR UPDATE TO authenticated USING ( auth.uid() = owner ) WITH CHECK ( bucket_id = 'avatars' );
CREATE POLICY "Anyone can delete their own avatar." ON storage.objects FOR DELETE TO authenticated USING ( auth.uid() = owner );

-- Xóa dữ liệu cũ nếu có
TRUNCATE TABLE characters;

-- Thêm dữ liệu mẫu cực kỳ chi tiết cho các nhân vật huyền thoại One Piece
INSERT INTO characters (name, alias, bounty, affiliation, role, devil_fruit, devil_fruit_type, hometown, age, height, status, description, image_url) VALUES
(
    'Monkey D. Luffy',
    'Mũ Rơm',
    3000000000,
    'Băng Mũ Rơm',
    'Thuyền trưởng (Tứ Hoàng)',
    'Hito Hito no Mi, Model: Nika',
    'Zoan Thần Thoại',
    'Làng Foosha, Biển Đông',
    19,
    174,
    'Còn sống',
    'Nhân vật chính của One Piece, người sáng lập và thuyền trưởng của Băng Hải tặc Mũ Rơm. Luffy sở hữu sức mạnh của Thần Mặt Trời Nika (Gear 5), mang lại sự tự do tối đa và khả năng biến mọi thứ xung quanh thành cao su. Ước mơ của cậu là tìm thấy kho báu One Piece và trở thành Vua Hải Tặc.',
    'https://static.wikia.nocookie.net/onepiece/images/6/6d/Monkey_D._Luffy_Anime_Post_Timeskip_Infobox.png'
),
(
    'Roronoa Zoro',
    'Thợ Săn Hải Tặc',
    1111000000,
    'Băng Mũ Rơm',
    'Kiếm sĩ (Phó thuyền trưởng)',
    'Không có',
    'Không có',
    'Làng Shimotsuki, Biển Đông',
    21,
    181,
    'Còn sống',
    'Kiếm sĩ phái Tam Kiếm cực kỳ mạnh mẽ, là thành viên đầu tiên gia nhập băng Mũ Rơm. Zoro nổi tiếng với tinh thần chiến đấu bất khuất, lòng trung thành tuyệt đối với Luffy và thói quen lạc đường nghiêm trọng. Ước mơ của anh là đánh bại Mihawk để trở thành Kiếm sĩ mạnh nhất thế giới.',
    'https://static.wikia.nocookie.net/onepiece/images/5/52/Roronoa_Zoro_Anime_Post_Timeskip_Infobox.png'
),
(
    'Vinsmoke Sanji',
    'Hắc Cước',
    1032000000,
    'Băng Mũ Rơm',
    'Đầu bếp',
    'Không có',
    'Không có',
    'Vương quốc Germa, Biển Bắc',
    21,
    180,
    'Còn sống',
    'Đầu bếp tài ba của Băng Mũ Rơm và là một trong ba chiến binh mạnh nhất nhóm (Bộ Ba Quái Vật). Sanji chiến đấu chỉ bằng chân để bảo vệ đôi tay đầu bếp của mình và có phong cách lịch lãm, cực kỳ ga-lăng với phụ nữ. Ước mơ của anh là tìm thấy vùng biển huyền thoại All Blue.',
    'https://static.wikia.nocookie.net/onepiece/images/b/b6/Sanji_Anime_Post_Timeskip_Infobox.png'
),
(
    'Shanks',
    'Tóc Đỏ',
    4048900000,
    'Băng Tóc Đỏ',
    'Thuyền trưởng (Tứ Hoàng)',
    'Không có',
    'Không có',
    'Biển Tây',
    39,
    199,
    'Còn sống',
    'Thuyền trưởng Băng Hải tặc Tóc Đỏ và là một trong các Tứ Hoàng thống trị Tân Thế Giới. Shanks là người đã truyền cảm hứng cho Luffy đi theo con đường hải tặc và trao cho cậu chiếc Mũ Rơm huyền thoại. Ông sở hữu Haki Bá Vương mạnh mẽ nhất thế giới dù chỉ còn một cánh tay.',
    'https://static.wikia.nocookie.net/onepiece/images/6/66/Shanks_Anime_Infobox.png'
),
(
    'Gol D. Roger',
    'Vua Hải Tặc',
    5564800000,
    'Băng Roger',
    'Thuyền trưởng (Đã giải tán)',
    'Không có',
    'Không có',
    'Loguetown, Biển Đông',
    47,
    274,
    'Đã mất',
    'Hải tặc huyền thoại duy nhất chinh phục được toàn bộ Grand Line và đạt được danh hiệu Vua Hải Tặc. Trước khi bị hành quyết, lời tuyên bố của Roger về kho báu vĩ đại "One Piece" đã mở ra Kỷ Nguyên Hải Tặc vĩ đại, truyền cảm hứng cho hàng vạn người ra khơi tìm kiếm.',
    'https://static.wikia.nocookie.net/onepiece/images/2/24/Gol_D._Roger_Anime_Infobox.png'
),
(
    'Edward Newgate',
    'Râu Trắng',
    5046000000,
    'Băng Râu Trắng',
    'Thuyền trưởng (Đã giải tán)',
    'Gura Gura no Mi',
    'Paramecia',
    'Đảo Sphinx, Tân Thế Giới',
    72,
    666,
    'Đã mất',
    'Được biết đến là "Người đàn ông mạnh nhất thế giới" and là đối thủ truyền kiếp ngang tài ngang sức duy nhất của Vua Hải Tặc Gol D. Roger. Râu Trắng sở hữu trái ác quỷ chấn động có thể phá hủy thế giới. Ông coi toàn bộ thủy thủ đoàn của mình như những đứa con yêu quý.',
    'https://static.wikia.nocookie.net/onepiece/images/b/b7/Edward_Newgate_Anime_Infobox.png'
),
(
    'Marshall D. Teach',
    'Râu Đen',
    3996000000,
    'Băng Râu Đen',
    'Thuyền trưởng (Tứ Hoàng)',
    'Yami Yami & Gura Gura',
    'Logia & Paramecia',
    'Không rõ',
    40,
    344,
    'Còn sống',
    'Kẻ xảo quyệt và tham vọng bậc nhất Grand Line. Râu Đen là người duy nhất trong lịch sử sở hữu sức mạnh của hai Trái Ác Quỷ cùng một lúc: bóng tối hấp thụ mọi thứ và chấn động hủy diệt. Hắn đang săn lùng những Trái Ác Quỷ mạnh nhất thế giới cho đồng bọn.',
    'https://static.wikia.nocookie.net/onepiece/images/f/ff/Marshall_D._Teach_Anime_Post_Timeskip_Infobox.png'
),
(
    'Dracule Mihawk',
    'Mắt Diều Hâu',
    3590000000,
    'Cross Guild',
    'Thành viên sáng lập',
    'Không có',
    'Không có',
    'Không rõ',
    43,
    198,
    'Còn sống',
    'Đệ Nhất Kiếm Sĩ Thế Giới, sở hữu thanh hắc kiếm Kokuto Yoru cực mạnh. Mihawk từng là một Thất Vũ Hải khét tiếng trước khi hệ thống này bị bãi bỏ. Hiện tại, ông đã liên minh với Crocodile và Buggy để thành lập tổ chức săn lùng Hải quân mang tên Cross Guild.',
    'https://static.wikia.nocookie.net/onepiece/images/b/bf/Dracule_Mihawk_Anime_Infobox.png'
),
(
    'Monkey D. Garp',
    'Anh Hùng Hải Quân',
    3000000000,
    'Hải Quân',
    'Phó Đô Đốc',
    'Không có',
    'Không có',
    'Làng Foosha, Biển Đông',
    78,
    287,
    'Còn sống',
    'Anh hùng huyền thoại của Hải quân, cha của thủ lĩnh Quân Cách mạng Dragon và là ông nội của Luffy. Garp nổi tiếng với nắm đấm yêu thương mạnh mẽ phá hủy cả núi đá mà không cần trái ác quỷ. Ông đã cùng Roger đánh bại băng hải tặc khét tiếng Rocks tại Thung lũng Chúa Trời.',
    'https://static.wikia.nocookie.net/onepiece/images/e/e1/Monkey_D._Garp_Anime_Infobox.png'
),
(
    'Monkey D. Dragon',
    'Nhà Cách Mạng',
    0,
    'Quân Cách Mạng',
    'Tổng tư lệnh',
    'Trái Thời Tiết (Dự kiến)',
    'Chưa xác định',
    'Làng Foosha, Biển Đông',
    55,
    256,
    'Còn sống',
    'Người đàn ông bị truy nã gắt gao nhất thế giới, Tổng tư lệnh Quân Cách Mạng chống lại Chính phủ Thế giới. Dragon là cha của Luffy và là con trai of Garp. Ông sở hữu một lý tưởng vĩ đại giải phóng các quốc gia khỏi ách thống trị tàn bạo của Thiên Long Nhân.',
    'https://static.wikia.nocookie.net/onepiece/images/f/f5/Monkey_D._Dragon_Anime_Infobox.png'
),
(
    'Kaidou',
    'Sinh Vật Mạnh Nhất Thế Giới',
    4611100000,
    'Băng Bách Thú',
    'Thuyền trưởng (Cựu Tứ Hoàng)',
    'Uo Uo no Mi, Model: Seiryu',
    'Zoan Thần Thoại',
    'Vương quốc Vodka',
    59,
    710,
    'Không rõ',
    'Thuyền trưởng Băng Hải tặc Bách Thú và là thực thể được coi là ''Sinh vật mạnh nhất thế giới''. Kaido sở hữu sức mạnh biến thành một con Rồng Thanh Long khổng lồ với lớp vảy bất hoại và hơi thở lửa hủy diệt. Ông từng là thành viên của Băng Hải tặc Rocks huyền thoại.',
    'https://static.wikia.nocookie.net/onepiece/images/2/2d/Kaidou_Anime_Infobox.png'
),
(
    'Charlotte Linlin',
    'Big Mom',
    4388000000,
    'Băng Big Mom',
    'Thuyền trưởng (Cựu Tứ Hoàng)',
    'Soru Soru no Mi',
    'Paramecia',
    'Totto Land',
    68,
    880,
    'Không rõ',
    'Nữ Hoàng của Vương quốc Totto Land và thuyền trưởng Băng Hải tặc Big Mom. Linlin sở hữu năng lực thao túng linh hồn, cho phép bà rút ngắn tuổi thọ của người khác và thổi hồn vào các vật vô tri để tạo ra thuộc hạ ''Homies''. Bà khao khát tạo ra một thế giới hòa bình cho mọi chủng tộc.',
    'https://static.wikia.nocookie.net/onepiece/images/d/d8/Charlotte_Linlin_Anime_Infobox.png'
),
(
    'Buggy',
    'Hề Gió Buốt',
    3189000000,
    'Cross Guild',
    'Thủ lĩnh (Tứ Hoàng)',
    'Bara Bara no Mi',
    'Paramecia',
    'Grand Line',
    39,
    192,
    'Còn sống',
    'Cựu thành viên học việc trên tàu của Vua Hải Tặc Roger và hiện là một trong các Tứ Hoàng thống trị Tân Thế Giới nhờ một loạt sự hiểu lầm vĩ đại. Buggy là thủ lĩnh trên danh nghĩa của tổ chức Cross Guild, liên minh cùng Crocodile và Mihawk. Anh sở hữu khả năng phân tách cơ thể thành nhiều phần.',
    'https://static.wikia.nocookie.net/onepiece/images/f/f7/Buggy_Anime_Post_Timeskip_Infobox.png'
),
(
    'Trafalgar D. Water Law',
    'Bác Sĩ Tử Thần',
    3000000000,
    'Băng Trái Tim',
    'Thuyền trưởng (Thế hệ tồi tệ nhất)',
    'Ope Ope no Mi',
    'Paramecia',
    'Flevance, Biển Bắc',
    26,
    191,
    'Còn sống',
    'Thuyền trưởng kiêm bác sĩ của Băng Hải tặc Trái Tim. Law sở hữu Trái Ác Quỷ tối thượng Ope Ope no Mi, cho phép anh tạo ra một không gian bán kính gọi là ''ROOM'' để phẫu thuật và biến đổi mọi thứ bên trong theo ý muốn. Anh đã liên minh với Luffy để lật đổ Kaido.',
    'https://static.wikia.nocookie.net/onepiece/images/4/4d/Trafalgar_D._Water_Law_Anime_Post_Timeskip_Infobox.png'
),
(
    'Eustass Kid',
    'Captain Kid',
    3000000000,
    'Băng Kid',
    'Thuyền trưởng (Thế hệ tồi tệ nhất)',
    'Jiki Jiki no Mi',
    'Paramecia',
    'Biển Nam',
    23,
    205,
    'Còn sống',
    'Thuyền trưởng kiêm chiến binh ngông cuồng của Băng Hải tặc Kid. Anh sở hữu năng lực từ tính mạnh mẽ, có thể thu hút, đẩy lùi và thao túng kim loại xung quanh để tạo thành những cánh tay cơ khí khổng lồ hoặc vũ khí hủy diệt. Kid nổi tiếng với tính cách tàn bạo và liều lĩnh.',
    'https://static.wikia.nocookie.net/onepiece/images/4/47/Eustass_Kid_Anime_Post_Timeskip_Infobox.png'
),
(
    'Crocodile',
    'Cựu Sa Hoàng',
    1965000000,
    'Cross Guild',
    'Thành viên sáng lập',
    'Suna Suna no Mi',
    'Logia',
    'Không rõ',
    46,
    253,
    'Còn sống',
    'Cựu Thất Vũ Hải kiêm thủ lĩnh tổ chức Baroque Works khét tiếng một thời. Crocodile sở hữu Trái Ác Quỷ Cát hệ Logia, cho phép ông biến cơ thể thành cát, tạo bão cát và hút cạn độ ẩm của đối phương. Ông hiện là bộ óc chiến lược đằng sau sự thành lập của tổ chức Cross Guild.',
    'https://static.wikia.nocookie.net/onepiece/images/f/fd/Crocodile_Anime_Infobox.png'
),
(
    'Boa Hancock',
    'Nữ Hoàng Hải Tặc',
    1659000000,
    'Băng Kuja',
    'Thuyền trưởng (Cựu Thất Vũ Hải)',
    'Mero Mero no Mi',
    'Paramecia',
    'Amazon Lily',
    31,
    191,
    'Còn sống',
    'Nữ vương của hòn đảo Amazon Lily xinh đẹp và thuyền trưởng Băng Hải tặc Kuja dũng mãnh. Boa Hancock được coi là người phụ nữ đẹp nhất thế giới, sở hữu Trái Ác Quỷ có khả năng hóa đá bất kỳ ai có ý nghĩ đen tối với cô. Hancock dành tình yêu đơn phương say đắm cho Luffy.',
    'https://static.wikia.nocookie.net/onepiece/images/f/f0/Boa_Hancock_Anime_Infobox.png'
),
(
    'King',
    'King Hỏa Hoạn',
    1390000000,
    'Băng Bách Thú',
    'Tổng tư lệnh',
    'Ryu Ryu no Mi, Model: Pteranodon',
    'Zoan Cổ Đại',
    'Tân Thế Giới',
    47,
    613,
    'Còn sống',
    'Thành viên mạnh nhất trong hàng ngũ đầu lĩnh của Kaido và là người sống sót duy nhất của chủng tộc Lunarian huyền thoại có khả năng tạo ra lửa từ cơ thể. King có thể biến hình thành một con thằn lằn bay Pteranodon khổng lồ với tốc độ kinh hoàng và sức tàn phá cực lớn.',
    'https://static.wikia.nocookie.net/onepiece/images/8/8f/King_Anime_Infobox.png'
),
(
    'Marco',
    'Marco Phượng Hoàng',
    1374000000,
    'Băng Râu Trắng',
    'Đội trưởng đội 1 (Cựu phó băng)',
    'Tori Tori no Mi, Model: Phoenix',
    'Zoan Thần Thoại',
    'Đảo Sphinx',
    45,
    203,
    'Còn sống',
    'Cựu đội trưởng Đội 1 kiêm cánh tay phải đắc lực của Tứ Hoàng Râu Trắng. Marco sở hữu Trái Ác Quỷ Phượng Hoàng hệ Zoan Thần Thoại quý hiếm, cho phép anh tái tạo bất kỳ vết thương nào nhờ ngọn lửa xanh bất tử. Anh là một người điềm tĩnh, trung thành và giàu lòng nhân ái.',
    'https://static.wikia.nocookie.net/onepiece/images/2/2c/Marco_Anime_Post_Timeskip_Infobox.png'
),
(
    'Queen',
    'Queen Bệnh Dịch',
    1320000000,
    'Băng Bách Thú',
    'Tổng tư lệnh',
    'Ryu Ryu no Mi, Model: Brachiosaurus',
    'Zoan Cổ Đại',
    'Tân Thế Giới',
    56,
    612,
    'Còn sống',
    'Nhà khoa học điên rồ kiêm phó tổng tư lệnh Băng Bách Thú. Queen sở hữu khả năng biến hình thành khủng long cổ dài Brachiosaurus với kích thước khổng lồ. Ông nổi tiếng với sở thích nhảy múa tưng bừng và việc chế tạo ra các loại vũ khí sinh học cực kỳ nguy hiểm như đạn virus.',
    'https://static.wikia.nocookie.net/onepiece/images/5/52/Queen_Anime_Infobox.png'
),
(
    'Jinbe',
    'Kỵ Sĩ Biển Cả',
    1100000000,
    'Băng Mũ Rơm',
    'Lái tàu',
    'Không có',
    'Không có',
    'Đảo Người Cá',
    46,
    301,
    'Còn sống',
    'Người cá thuộc chủng tộc Cá Mập Voi kiêm bậc thầy môn võ Karate Người Cá. Jinbe là cựu Thất Vũ Hải có uy tín và lòng chính trực cao cả bậc nhất Tân Thế Giới. Sau khi rời khỏi Băng Mặt Trời và liên minh Big Mom, ông đã gia nhập Băng Mũ Rơm với tư cách người lái tàu tài ba.',
    'https://static.wikia.nocookie.net/onepiece/images/8/81/Jinbe_Anime_Infobox.png'
),
(
    'Charlotte Katakuri',
    'Tư Lệnh Ngọt',
    1057000000,
    'Băng Big Mom',
    'Tư lệnh ngọt',
    'Mochi Mochi no Mi',
    'Paramecia',
    'Totto Land',
    48,
    509,
    'Còn sống',
    'Con trai thứ hai của Big Mom kiêm Tư lệnh Ngọt mạnh nhất vương quốc. Katakuri sở hữu Trái Ác Quỷ Mochi đặc biệt giúp anh biến đổi cơ thể linh hoạt như hệ Logia. Anh nổi tiếng với khả năng sử dụng Haki Quan Sát ở cấp độ tối thượng, cho phép nhìn thấy trước một tương lai ngắn.',
    'https://static.wikia.nocookie.net/onepiece/images/2/2e/Charlotte_Katakuri_Anime_Infobox.png'
),
(
    'Jack',
    'Jack Hạn Hán',
    1000000000,
    'Băng Bách Thú',
    'Tổng tư lệnh',
    'Zou Zou no Mi, Model: Mammoth',
    'Zoan Cổ Đại',
    'Tân Thế Giới',
    28,
    830,
    'Còn sống',
    'Một trong ba đầu lĩnh ''Thảm Họa'' của Kaido. Jack sở hữu sức mạnh của loài voi cổ đại Mammoth khổng lồ, mang lại thể lực và độ dẻo dai vô song. Hắn nổi tiếng with tính cách hung bạo, hiếu chiến, đi đến bất cứ hòn đảo nào cũng tàn phá hủy diệt như một trận hạn hán kéo qua.',
    'https://static.wikia.nocookie.net/onepiece/images/3/3f/Jack_Anime_Infobox.png'
),
(
    'Nico Robin',
    'Đứa Con Của Ác Quỷ',
    930000000,
    'Băng Mũ Rơm',
    'Khảo cổ học',
    'Hana Hana no Mi',
    'Paramecia',
    'Ohara, Biển Tây',
    30,
    188,
    'Còn sống',
    'Nhà khảo cổ học duy nhất trên thế giới còn sống sót có khả năng đọc được các ký tự cổ đại Poneglyph - chìa khóa dẫn tới kho báu One Piece. Robin sở hữu Trái Ác Quỷ giúp cô mọc ra các bộ phận cơ thể ở bất kỳ bề mặt nào. Cô coi Băng Mũ Rơm là gia đình thực sự của mình.',
    'https://static.wikia.nocookie.net/onepiece/images/b/bc/Nico_Robin_Anime_Post_Timeskip_Infobox.png'
),
(
    'Sabo',
    'Tổng Tham Mưu Trưởng',
    602000000,
    'Quân Cách Mạng',
    'Tổng tham mưu trưởng',
    'Mera Mera no Mi',
    'Logia',
    'Vương quốc Goa, Biển Đông',
    22,
    187,
    'Còn sống',
    'Anh em kết nghĩa của Luffy và Ace, hiện giữ chức vụ Tổng tham mưu trưởng Quân Cách Mạng (nhân vật quyền lực thứ hai sau Dragon). Sabo kế thừa ngọn lửa ý chí và sức mạnh Trái Ác Quỷ Mera Mera no Mi của Ace để tiếp tục cuộc chiến giải phóng thế giới khỏi ách thống trị.',
    'https://static.wikia.nocookie.net/onepiece/images/c/c2/Sabo_Anime_Infobox.png'
),
(
    'Usopp',
    'God Usopp',
    500000000,
    'Băng Mũ Rơm',
    'Xạ thủ',
    'Không có',
    'Không có',
    'Làng Syrup, Biển Đông',
    19,
    176,
    'Còn sống',
    'Xạ thủ tài ba kiêm người pha trò vĩ đại của Băng Mũ Rơm. Usopp nổi tiếng với tài bắn tỉa bách phát bách trúng bằng vũ khí tự chế Kabuto và trí tưởng tượng phong phú. Dù có tính cách nhút nhát, anh luôn dũng cảm đứng lên chiến đấu bảo vệ đồng đội trong những thời khắc sinh tử.',
    'https://static.wikia.nocookie.net/onepiece/images/3/35/Usopp_Anime_Post_Timeskip_Infobox.png'
),
(
    'Donquixote Doflamingo',
    'Thiên Dạ Xoa',
    340000000,
    'Băng Donquixote',
    'Thuyền trưởng (Cựu Thất Vũ Hải)',
    'Ito Ito no Mi',
    'Paramecia',
    'Mariejois',
    41,
    305,
    'Bị giam giữ',
    'Cựu Thiên Long Nhân kiêm nhà vua tàn bạo của vương quốc Dressrosa và là ông trùm thế giới ngầm Joker khét tiếng Tân Thế Giới. Doflamingo sở hữu Trái Ác Quỷ Ito Ito no Mi giúp điều khiển tơ chỉ sắt bén để thao túng cơ thể người khác và cắt đôi các tòa nhà lớn.',
    'https://static.wikia.nocookie.net/onepiece/images/7/7e/Donquixote_Doflamingo_Anime_Infobox.png'
),
(
    'Nami',
    'Miêu Tặc',
    366000000,
    'Băng Mũ Rơm',
    'Hoa tiêu',
    'Không có',
    'Không có',
    'Làng Cocoyasi, Biển Đông',
    20,
    170,
    'Còn sống',
    'Hoa tiêu xuất chúng sở hữu tài năng thiên bẩm về khí tượng và khả năng vẽ bản đồ thế giới cực kỳ chuẩn xác. Nami chiến đấu bằng cây gậy thời tiết Clima-Tact và có thể điều khiển mây sét sấm chớp một cách điêu luyện. Ước mơ của cô là vẽ bản đồ của toàn thế giới.',
    'https://static.wikia.nocookie.net/onepiece/images/6/68/Nami_Anime_Post_Timeskip_Infobox.png'
),
(
    'Portgas D. Ace',
    'Hỏa Quyền Ace',
    550000000,
    'Băng Râu Trắng',
    'Đội trưởng đội 2 (Đã mất)',
    'Mera Mera no Mi',
    'Logia',
    'Làng Foosha, Biển Đông',
    20,
    185,
    'Đã mất',
    'Con trai ruột của Vua Hải Tặc Gol D. Roger và là anh trai kết nghĩa của Luffy. Ace sở hữu ngọn lửa thiêu rụi vạn vật hệ Logia và giữ chức Đội trưởng Đội 2 Băng Râu Trắng. Sự ra đi đầy kiêu hãnh của Ace tại Marineford đã khắc sâu dấu ấn vĩnh cửu trong lòng người hâm mộ.',
    'https://static.wikia.nocookie.net/onepiece/images/4/4f/Portgas_D._Ace_Anime_Infobox.png'
),
(
    'Tony Tony Chopper',
    'Kẻ Yêu Kẹo Bông Gòn',
    1000,
    'Băng Mũ Rơm',
    'Bác sĩ',
    'Hito Hito no Mi',
    'Zoan',
    'Đảo Drum, Biển Tây',
    17,
    90,
    'Còn sống',
    'Chú tuần lộc mũi xanh đáng yêu kiêm bác sĩ tài năng của Băng Mũ Rơm. Nhờ ăn Trái Ác Quỷ người Hito Hito no Mi, Chopper có thể biến đổi thành nhiều dạng chiến đấu khác nhau. Dù sở hữu sức mạnh quái vật (Monster Point), Hải quân chỉ xem Chopper là thú cưng với mức truy nã hài hước.',
    'https://static.wikia.nocookie.net/onepiece/images/a/af/Tony_Tony_Chopper_Anime_Post_Timeskip_Infobox.png'
),
(
    'Franky',
    'Người Sắt Franky',
    394000000,
    'Băng Mũ Rơm',
    'Thợ đóng tàu',
    'Không có',
    'Không có',
    'Water 7',
    36,
    240,
    'Còn sống',
    'Thợ đóng tàu nửa người nửa máy (Cyborg) cực kỳ lập dị và mạnh mẽ của Băng Mũ Rơm. Franky là người đã thiết kế và chế tạo ra tàu Thousand Sunny huyền thoại từ gỗ cây kho báu Adam. Anh chiến đấu bằng cơ thể chứa đầy vũ khí công nghệ cao và uống cola làm nhiên liệu hoạt động.',
    'https://static.wikia.nocookie.net/onepiece/images/8/8c/Franky_Anime_Post_Timeskip_Infobox.png'
),
(
    'Brook',
    'Soul King',
    383000000,
    'Băng Mũ Rơm',
    'Nhạc công',
    'Yomi Yomi no Mi',
    'Paramecia',
    'Biển Tây',
    90,
    277,
    'Còn sống',
    'Nhạc sĩ kiêm kiếm sĩ kỳ cựu of Băng Mũ Rơm. Nhờ sức mạnh của Trái Ác Quỷ Yomi Yomi no Mi, linh hồn của Brook đã quay trở lại cơ thể sau khi chết, biến anh thành một bộ xương sống bất tử biết ca hát. Anh chiến đấu bằng thanh kiếm giấu trong gậy và sức mạnh thao túng băng giá từ cõi âm.',
    'https://static.wikia.nocookie.net/onepiece/images/4/41/Brook_Anime_Post_Timeskip_Infobox.png'
),
(
    'Koby',
    'Người Hùng Hải Quân Tương Lai',
    500000000,
    'Hải Quân',
    'Đại tá (Thành viên SWORD)',
    'Không có',
    'Không có',
    'Biển Đông',
    18,
    167,
    'Còn sống',
    'Một đại tá trẻ tuổi đầy triển vọng của Hải Quân và là thành viên cốt cán của lực lượng đặc nhiệm mật SWORD. Từng là một cậu bé tạp vụ nhút nhát trên tàu Alvida, Koby đã nỗ lực rèn luyện dưới sự dẫn dắt của Garp để trở thành một chiến binh mạnh mẽ sở hữu Haki Quan Sát vượt trội. Anh được Cross Guild định giá truy nã 5 sao tương đương 500 triệu Belly.',
    'https://static.wikia.nocookie.net/onepiece/images/b/b8/Koby_Anime_Post_Timeskip_Infobox.png'
),
(
    'Bepo',
    'Thú Cưng Băng Trái Tim',
    500,
    'Băng Trái Tim',
    'Lái tàu',
    'Không có',
    'Không có',
    'Zou',
    22,
    240,
    'Còn sống',
    'Chú gấu trắng thuộc tộc Mink kiêm lái tàu của Băng Hải tặc Trái Tim dưới trướng Trafalgar Law. Bepo là một võ sĩ Kung Fu cựu trào với cơ thể dẻo dai và lòng trung thành tuyệt đối với Law. Khi sử dụng thuốc biến đổi dạng Sulong của Chopper, Bepo đạt được sức mạnh quái thú khổng lồ có thể áp đảo các đối thủ cực mạnh.',
    'https://static.wikia.nocookie.net/onepiece/images/5/5f/Bepo_Anime_Infobox.png'
),
(
    'Killer',
    'Chiến Binh Sát Thủ',
    370000000,
    'Băng Kid',
    'Kiếm sĩ (Phó thuyền trưởng)',
    'SMILE (Thất bại)',
    'Zoan Nhân Tạo',
    'Biển Nam',
    27,
    205,
    'Còn sống',
    'Cánh tay phải đắc lực và là phó thuyền trưởng trung thành của Eustass Kid. Killer luôn đeo chiếc mặt nạ sắt che kín khuôn mặt và chiến đấu bằng cặp vũ khí xoay tròn độc đáo Punishers. Anh nổi tiếng với phong cách chiến đấu tàn nhẫn, lạnh lùng nhưng luôn quan tâm sâu sắc tới đồng đội.',
    'https://static.wikia.nocookie.net/onepiece/images/7/70/Killer_Anime_Post_Timeskip_Infobox.png'
),
(
    'Bartholomew Kuma',
    'Bạo Chúa',
    296000000,
    'Quân Cách Mạng',
    'Cựu Thất Vũ Hải',
    'Nikyu Nikyu no Mi',
    'Paramecia',
    'Vương quốc Sorbet, Biển Nam',
    47,
    689,
    'Còn sống',
    'Cựu Thất Vũ Hải kiêm cán bộ cốt cán sáng lập Quân Cách Mạng. Kuma sở hữu Trái Ác Quỷ đệm thịt Nikyu Nikyu no Mi cho phép ông đẩy bay mọi thứ với tốc độ ánh sáng, nén không khí thành bom sấm sét và thậm chí đẩy cả đau đớn, mệt mỏi ra khỏi cơ thể người khác. Ông đã hy sinh lý trí của mình để trở thành vũ khí sinh học PX-0 bảo vệ Luffy.',
    'https://static.wikia.nocookie.net/onepiece/images/8/8d/Bartholomew_Kuma_Anime_Infobox.png'
),
(
    'Gecko Moria',
    'Chúa Tể Bóng Tối',
    320000000,
    'Cướp biển Thriller Bark',
    'Thuyền trưởng (Cựu Thất Vũ Hải)',
    'Kage Kage no Mi',
    'Paramecia',
    'Biển Tây',
    50,
    692,
    'Còn sống',
    'Thuyền trưởng của con tàu khổng lồ Thriller Bark kiêm cựu Thất Vũ Hải. Moria sở hữu Trái Ác Quỷ thao túng bóng Kage Kage no Mi, cho phép ông cắt bóng của người khác để tạo ra những chiến binh thây ma (Zombies) bất hoại phục tùng mệnh lệnh và hấp thụ bóng để gia tăng sức mạnh của bản thân lên cực hạn.',
    'https://static.wikia.nocookie.net/onepiece/images/b/be/Gecko_Moria_Anime_Infobox.png'
),
(
    'Jewelry Bonney',
    'Kẻ Ăn Tạp',
    320000000,
    'Băng Bonney',
    'Thuyền trưởng (Thế hệ tồi tệ nhất)',
    'Toshi Toshi no Mi',
    'Paramecia',
    'Vương quốc Sorbet, Biển Nam',
    12,
    174,
    'Còn sống',
    'Nữ thuyền trưởng duy nhất trong thế hệ hải tặc tồi tệ nhất và là con gái của Bartholomew Kuma. Bonney sở hữu năng lực điều khiển tuổi tác của bản thân và người khác theo ý muốn. Với tuyệt chiêu ''Tương lai méo mó'', cô có thể biến đổi cơ thể thành những tương lai giả định mạnh mẽ như biến thành dạng người khổng lồ giống Thần Mặt Trời Nika.',
    'https://static.wikia.nocookie.net/onepiece/images/6/62/Jewelry_Bonney_Anime_Post_Timeskip_Infobox.png'
),
(
    'Charlotte Smoothie',
    'Tư Lệnh Ngọt Smoothie',
    932000000,
    'Băng Big Mom',
    'Tư lệnh ngọt (Con gái thứ 14)',
    'Shibo Shibo no Mi',
    'Paramecia',
    'Totto Land',
    35,
    464,
    'Còn sống',
    'Một trong ba Tư lệnh Ngọt mạnh nhất dưới trướng Tứ Hoàng Big Mom. Smoothie sở hữu chiều cao khổng lồ của bộ tộc chân dài và Trái Ác Quỷ vắt nước Shibo Shibo no Mi, cho phép cô vắt cạn nước và chất độc từ bất kỳ sinh vật nào giống như vắt nước trái cây, đồng thời hấp thụ nước để cơ thể phình to khổng lồ.',
    'https://static.wikia.nocookie.net/onepiece/images/c/c5/Charlotte_Smoothie_Anime_Infobox.png'
),
(
    'Charlotte Cracker',
    'Cracker Ngàn Tay',
    860000000,
    'Băng Big Mom',
    'Tư lệnh ngọt (Con trai thứ 10)',
    'Bisu Bisu no Mi',
    'Paramecia',
    'Totto Land',
    45,
    307,
    'Còn sống',
    'Tư lệnh Ngọt dũng mãnh và là con trai thứ mười của Big Mom. Cracker sở hữu Trái Ác Quỷ Bánh Bích Quy Bisu Bisu no Mi giúp anh tạo ra vô số chiến binh giáp sắt bằng bánh quy vô cùng cứng cáp và tinh xảo để chiến đấu thay mình. Anh nổi tiếng là một chiến binh kiêu ngạo, có kiếm thuật cực đỉnh.',
    'https://static.wikia.nocookie.net/onepiece/images/6/64/Charlotte_Cracker_Anime_Infobox.png'
),
(
    'Basil Hawkins',
    'Phù Thủy',
    320000000,
    'Băng Hawkins',
    'Thuyền trưởng',
    'Wara Wara no Mi',
    'Paramecia',
    'Biển Bắc',
    31,
    210,
    'Còn sống',
    'Thuyền trưởng Băng Hải tặc Hawkins kiêm một trong các Siêu Tân Tinh của Thế hệ Tồi tệ nhất. Anh sở hữu năng lực bói bài tarot dự báo tương lai và Trái Ác Quỷ bùn rơm Wara Wara no Mi, cho phép anh chuyển hướng mọi sát thương phải gánh chịu sang các hình nhân rơm thế mạng giấu trong người.',
    'https://static.wikia.nocookie.net/onepiece/images/f/f8/Basil_Hawkins_Anime_Post_Timeskip_Infobox.png'
),
(
    'Scratchmen Apoo',
    'Tiếng Gầm Biển Cả',
    350000000,
    'Băng On-Air',
    'Thuyền trưởng',
    'Tatake Tatake no Mi',
    'Paramecia',
    'Grand Line',
    31,
    256,
    'Còn sống',
    'Thuyền trưởng Băng Hải tặc On-Air thuộc bộ tộc Tay Dài. Apoo sở hữu năng lực biến đổi các bộ phận cơ thể thành nhạc cụ và sử dụng âm thanh làm vũ khí chém cắt, gây nổ cực kỳ khó chịu. Anh là một kẻ cơ hội, xảo quyệt, sẵn sàng phản bội đồng minh để theo phe mạnh hơn.',
    'https://static.wikia.nocookie.net/onepiece/images/d/d0/Scratchmen_Apoo_Anime_Post_Timeskip_Infobox.png'
),
(
    'Capone Bege',
    'Gang Bege',
    350000000,
    'Băng Firetank',
    'Thuyền trưởng',
    'Shiro Shiro no Mi',
    'Paramecia',
    'Biển Tây',
    42,
    166,
    'Còn sống',
    'Thuyền trưởng Băng Hải tặc Firetank, một trùm mafia khét tiếng thế giới ngầm. Nhờ Trái Ác Quỷ Shiro Shiro no Mi, cơ thể của Bege biến thành một pháo đài sống khổng lồ chứa hàng trăm lính canh, ngựa chiến và pháo hạng nặng thu nhỏ bên trong sẵn sàng nổ súng tàn phá.',
    'https://static.wikia.nocookie.net/onepiece/images/9/99/Capone_Bege_Anime_Post_Timeskip_Infobox.png'
),
(
    'X Drake',
    'Nanh Đỏ',
    222000000,
    'Hải Quân',
    'Thuyền trưởng (Đội trưởng SWORD)',
    'Ryu Ryu no Mi, Model: Allosaurus',
    'Zoan Cổ Đại',
    'Biển Bắc',
    33,
    233,
    'Còn sống',
    'Cựu thiếu tướng Hải quân, sau đó trở thành thuyền trưởng Băng Hải tặc Drake để hoạt động gián điệp nằm vùng sâu trong hàng ngũ Kaido dưới tư cách Đội trưởng lực lượng SWORD. Drake sở hữu năng lực biến hình thành một con khủng long ăn thịt Allosaurus dũng mãnh.',
    'https://static.wikia.nocookie.net/onepiece/images/0/04/X_Drake_Anime_Post_Timeskip_Infobox.png'
),
(
    'Urouge',
    'Phá Giới Tăng',
    108000000,
    'Băng Chư Tăng Đọa Lạc',
    'Thuyền trưởng',
    'Chưa đặt tên (Hấp thụ sát thương)',
    'Paramecia',
    'Đảo Trên Trời',
    47,
    388,
    'Còn sống',
    'Thuyền trưởng Băng Hải tặc Chư Tăng Đọa Lạc đến từ Đảo Trên Trời. Urouge là một tu sĩ lực lưỡng, sở hữu năng lực Trái Ác Quỷ độc đáo giúp chuyển hóa toàn bộ sát thương vật lý phải gánh chịu thành sức mạnh cơ bắp khổng lồ để phản công nghiền nát đối thủ.',
    'https://static.wikia.nocookie.net/onepiece/images/f/fb/Urouge_Anime_Infobox.png'
),
(
    'Fisher Tiger',
    'Người Hùng Người Cá',
    230000000,
    'Băng Mặt Trời',
    'Thuyền trưởng sáng lập (Đã mất)',
    'Không có',
    'Không có',
    'Đảo Người Cá',
    48,
    520,
    'Đã mất',
    'Anh hùng huyền thoại của chủng tộc Người Cá, người đã dũng cảm leo lên thánh địa Mariejois tay không để giải phóng hàng ngàn nô lệ của Thiên Long Nhân. Ông đã sáng lập ra Băng Hải tặc Mặt Trời để bảo vệ các nô lệ trốn chạy và thúc đẩy lý tưởng bình đẳng chủng tộc.',
    'https://static.wikia.nocookie.net/onepiece/images/c/c5/Fisher_Tiger_Anime_Infobox.png'
),
(
    'Arlong',
    'Răng Cưa',
    20000000,
    'Băng Arlong',
    'Thuyền trưởng (Bị bắt)',
    'Không có',
    'Không có',
    'Đảo Người Cá',
    41,
    263,
    'Bị giam giữ',
    'Cựu thành viên Băng Mặt Trời kiêm kẻ thống trị tàn bạo của Arlong Park tại Biển Đông. Arlong là một người cá thuộc loài Cá Mập Cưa cực kỳ kiêu ngạo, coi con người là chủng tộc hạ đẳng và đã bóc lột, hành hạ quê hương của Nami suốt nhiều năm trước khi bị Luffy đánh bại.',
    'https://static.wikia.nocookie.net/onepiece/images/0/01/Arlong_Anime_Infobox.png'
),
(
    'Cavendish',
    'Bạch Mã',
    330000000,
    'Băng Khúc Hoa Hồng',
    'Thuyền trưởng (Đại hạm đội Mũ Rơm)',
    'Không có',
    'Không có',
    'Vương quốc Bourbon',
    26,
    240,
    'Còn sống',
    'Thuyền trưởng tuấn tú kiêm kiếm sĩ tài hoa bậc nhất của Băng Hải tặc Khúc Hoa Hồng. Cavendish mang trong mình một nhân cách thứ hai tàn bạo mang tên Hakuba có tốc độ di chuyển siêu việt chém giết vạn vật khi anh ngủ thiếp đi. Anh hiện là thủ lĩnh Đội 1 Đại Hạm Đội Mũ Rơm.',
    'https://static.wikia.nocookie.net/onepiece/images/a/a1/Cavendish_Anime_Infobox.png'
),
(
    'Bartolomeo',
    'Kẻ Ăn Thịt Người',
    200000000,
    'Băng Barto Club',
    'Thuyền trưởng (Đại hạm đội Mũ Rơm)',
    'Bari Bari no Mi',
    'Paramecia',
    'Loguetown, Biển Đông',
    24,
    220,
    'Còn sống',
    'Thuyền trưởng Băng Barto Club kiêm người hâm mộ cuồng nhiệt số một thế giới của Băng Mũ Rơm. Bartolomeo sở hữu Trái Ác Quỷ rào chắn Bari Bari no Mi, cho phép anh tạo ra những bức tường rào vô hình bất hoại có thể cản phá mọi đòn tấn công vật lý mạnh mẽ nhất.',
    'https://static.wikia.nocookie.net/onepiece/images/e/eb/Bartolomeo_Anime_Infobox.png'
),
(
    'Caesar Clown',
    'Nhà Khoa Học Khí Gas',
    300000000,
    'Mads',
    'Nhà nghiên cứu khoa học điên',
    'Gasu Gasu no Mi',
    'Logia',
    'Không rõ',
    40,
    309,
    'Còn sống',
    'Một nhà khoa học điên rồ, tàn nhẫn và là cựu cộng sự của Vegapunk tại tổ chức MADS. Caesar sở hữu Trái Ác Quỷ Khí Gas hệ Logia, cho phép hắn biến cơ thể thành khí độc, kiểm soát lượng oxy xung quanh và chế tạo ra chất độc hủy diệt hàng loạt Smile cung cấp cho thế giới ngầm.',
    'https://static.wikia.nocookie.net/onepiece/images/a/a6/Caesar_Clown_Anime_Infobox.png'
),
(
    'Don Chinjao',
    'Chân Sử Don Chinjao',
    542000000,
    'Gia tộc Chinjao',
    'Cựu thủ lĩnh bát bảo thủy quân',
    'Không có',
    'Không có',
    'Vương quốc Hoa',
    78,
    520,
    'Còn sống',
    'Cựu thủ lĩnh huyền thoại của Bát Bảo Thủy Quân và là một bậc thầy môn võ Bát Trùng Quyền. Chinjao sở hữu chiếc đầu nhọn bọc thép có sức công phá kinh hoàng có thể tách đôi cả lục địa băng giá, trước khi bị Garp đấm bẹt đầu trong quá khứ.',
    'https://static.wikia.nocookie.net/onepiece/images/b/b0/Chinjao_Anime_Infobox.png'
),
(
    'Caribou',
    'Tóc Ướt',
    210000000,
    'Băng Caribou',
    'Thuyền trưởng',
    'Numa Numa no Mi',
    'Logia',
    'Biển Bắc',
    32,
    228,
    'Còn sống',
    'Tên cướp biển hung bạo, xảo quyệt sở hữu năng lực Trái Ác Quỷ Vũng Lầy Numa Numa no Mi hệ Logia. Caribou có thể biến cơ thể thành đầm lầy để nuốt chửng, cất giấu vô số vũ khí khổng lồ hoặc con tin bên trong người. Hắn nổi tiếng với tính cách hèn hạ và thói quen rình mò bí mật.',
    'https://static.wikia.nocookie.net/onepiece/images/7/76/Caribou_Anime_Infobox.png'
),
(
    'Bellamy',
    'Kẻ Nhảy Cót',
    195000000,
    'Băng Bellamy',
    'Thuyền trưởng (Đã giải nghệ)',
    'Bane Bane no Mi',
    'Paramecia',
    'Biển Bắc',
    27,
    240,
    'Còn sống',
    'Cựu thuyền trưởng Băng Bellamy từng tôn sùng Doflamingo hết mực. Bellamy sở hữu năng lực lò xo Bane Bane no Mi cho phép biến chân thành lò xo để bật nhảy với tốc độ cực lớn. Sau thất bại tại Dressrosa, anh đã quyết định giải nghệ hải tặc và chuyển sang học nghề dệt cờ.',
    'https://static.wikia.nocookie.net/onepiece/images/2/27/Bellamy_Anime_Post_Timeskip_Infobox.png'
),
(
    'Charlotte Perospero',
    'Kẻ Thao Túng Kẹo',
    700000000,
    'Băng Big Mom',
    'Con trai cả (Bộ óc chiến lược)',
    'Pero Pero no Mi',
    'Paramecia',
    'Totto Land',
    50,
    333,
    'Còn sống',
    'Con trai cả của Big Mom kiêm bộ óc chiến lược nguy hiểm của vương quốc Totto Land. Perospero sở hữu Trái Ác Quỷ Pero Pero no Mi cho phép tạo ra và thao túng kẹo ngọt cứng như thép để giam giữ đối thủ hoặc tạo ra các công trình khổng lồ theo ý muốn.',
    'https://static.wikia.nocookie.net/onepiece/images/7/7e/Charlotte_Perospero_Anime_Infobox.png'
),
(
    'Nico Olvia',
    'Nhà Khảo Cổ Ohara',
    79000000,
    'Ohara',
    'Nhà khảo cổ học (Đã mất)',
    'Không có',
    'Không có',
    'Ohara, Biển Tây',
    33,
    186,
    'Đã mất',
    'Nhà khảo cổ học dũng cảm của hòn đảo Ohara huyền thoại và là mẹ ruột của Nico Robin. Olvia đã hy sinh thân mình trong cuộc tàn sát Buster Call để bảo vệ kho tàng tri thức lịch sử Poneglyph và ý chí tự do tìm kiếm sự thật về Thế Kỷ Trống.',
    'https://static.wikia.nocookie.net/onepiece/images/f/fc/Nico_Olvia_Anime_Infobox.png'
),
(
    'Curly Dadan',
    'Sơn Tặc Dadan',
    7800000,
    'Gia đình Dadan',
    'Thủ lĩnh sơn tặc (Mẹ nuôi)',
    'Không có',
    'Không có',
    'Vương quốc Goa, Biển Đông',
    55,
    221,
    'Còn sống',
    'Thủ lĩnh của băng sơn tặc Dadan dũng mãnh sống tại núi Colubo. Dù mang vẻ ngoài thô lỗ, cộc cằn, Dadan thực chất là một người phụ nữ vô cùng nhân hậu, giàu tình thương, đã nhận lời Garp để chăm sóc, nuôi dạy Luffy, Ace và Sabo khôn lớn thành người.',
    'https://static.wikia.nocookie.net/onepiece/images/b/b4/Curly_Dadan_Anime_Infobox.png'
),
(
    'Alvida',
    'Chùy Sắt Alvida',
    5000000,
    'Băng Buggy',
    'Đồng thủ lĩnh',
    'Sube Sube no Mi',
    'Paramecia',
    'Biển Đông',
    27,
    198,
    'Còn sống',
    'Đối thủ đầu tiên of Luffy tại Biển Đông. Alvida sau khi ăn Trái Ác Quỷ trơn mượt Sube Sube no Mi đã lột xác thành một mỹ nhân xinh đẹp có khả năng làm mọi đòn tấn công vật lý trượt đi không thể chạm vào người. Chi hiện là đồng thủ lĩnh liên minh cùng Buggy.',
    'https://static.wikia.nocookie.net/onepiece/images/c/cd/Alvida_Anime_Infobox.png'
),
(
    'Don Krieg',
    'Đại Đô Đốc Don Krieg',
    17000000,
    'Băng Don Krieg',
    'Đại đô đốc hải tặc',
    'Không có',
    'Không có',
    'Biển Đông',
    44,
    243,
    'Còn sống',
    'Đại đô đốc khét tiếng thống trị hạm đội hải tặc 50 tàu dũng mãnh nhất Biển Đông một thời. Krieg chiến đấu bằng một bộ giáp sắt bọc vàng trang bị vô số vũ khí tối tân, giáo nổ hạng nặng và đạn hơi độc độc hại trước khi bị Luffy đánh bại hoàn toàn tại nhà hàng Baratie.',
    'https://static.wikia.nocookie.net/onepiece/images/b/bb/Krieg_Anime_Infobox.png'
),
(
    'Kuro',
    'Kuro Trăm Kế',
    16000000,
    'Băng Mèo Đen',
    'Thuyền trưởng',
    'Không có',
    'Không có',
    'Biển Đông',
    37,
    207,
    'Còn sống',
    'Thuyền trưởng thông minh kiệt xuất của Băng Mèo Đen với biệt danh ''Kuro Trăm Kế''. Kuro sở hữu tốc độ di chuyển cực nhanh tương đương Lục Thức của Hải quân và chiến đấu bằng cặp găng tay móng vuốt mèo mèo sắt bén khổng lồ dài 2 mét.',
    'https://static.wikia.nocookie.net/onepiece/images/7/7e/Kuro_Anime_Infobox.png'
),
(
    'Pedro',
    'Pedro Của Ngọn Lửa',
    382000000,
    'Zou (Tộc Mink)',
    'Chiến binh tộc Mink (Đã mất)',
    'Không có',
    'Không có',
    'Zou',
    32,
    233,
    'Đã mất',
    'Chiến binh dũng cảm thuộc tộc Mink kiêm cựu thuyền trưởng Băng Hải tặc Nox. Pedro đã dũng cảm hy sinh thân mình kích hoạt bom tự sát tại đảo bánh ngọt để giải cứu nhóm Mũ Rơm thoát khỏi vòng vây của Big Mom, thắp sáng con đường mở ra kỷ nguyên mới.',
    'https://static.wikia.nocookie.net/onepiece/images/c/c8/Pedro_Anime_Infobox.png'
);

-- THÊM NHÂN VẬT BỔ SUNG (Hải Quân, Wano, CP0...)
INSERT INTO characters (name, alias, bounty, affiliation, role, devil_fruit, devil_fruit_type, hometown, age, height, status, description, image_url) VALUES
('Aramaki', 'Ryokugyu (Bò Lục)', 3000000000, 'Hải Quân', 'Đô đốc', 'Mori Mori no Mi', 'Logia', 'Tân Thế Giới', 0, 0, 'Còn sống', 'Đô đốc mới sở hữu cơ thể của rừng xanh. Có thể tạo ra và kiểm soát mọi loài thực vật để hút cạn dinh dưỡng của kẻ thù, biến sa mạc thành ốc đảo trong chớp mắt.', 'https://static.wikia.nocookie.net/onepiece/images/0/05/Aramaki_Anime_Infobox.png'),
('Borsalino', 'Kizaru (Khỉ Vàng)', 3000000000, 'Hải Quân', 'Đô đốc', 'Pika Pika no Mi', 'Logia', 'Tân Thế Giới', 58, 302, 'Còn sống', 'Đô đốc Hải quân đại diện cho ''Công lý Mơ hồ''. Kizaru có thể di chuyển, tấn công bằng vận tốc ánh sáng và bắn ra những tia laser hủy diệt diện rộng một cách vô cùng nhàn nhã.', 'https://static.wikia.nocookie.net/onepiece/images/1/14/Borsalino_Anime_Infobox.png'),
('Carrot', 'Thỏ Sulong', 0, 'Zou (Tộc Mink)', 'Vua của Mokomo Dukedom', 'Không có', 'Không có', 'Tân Thế Giới', 15, 161, 'Còn sống', 'Chiến binh thỏ dũng cảm tộc Mink từng đồng hành giải cứu Sanji. Dưới ánh trăng tròn, cô biến thành dạng Sulong tuyệt đẹp với tốc độ siêu việt, hiện đã được kế vị làm người dẫn dắt vương quốc Zou.', 'https://static.wikia.nocookie.net/onepiece/images/e/e2/Carrot_Anime_Infobox.png'),
('Enel', 'Chúa Trời Enel', 0, 'Vương quốc Birca', 'Kẻ Cai Trị (God)', 'Goro Goro no Mi', 'Logia', 'Tân Thế Giới', 39, 266, 'Còn sống', 'Kẻ tự xưng là Thần sở hữu năng lực sét tối thượng. Mặc dù bị Luffy khắc chế và đánh bại ở đảo trên trời, sức mạnh thực sự của hắn được Oda ước tính có thể đạt mức truy nã trên 500 triệu Belly nếu xuống biển xanh.', 'https://static.wikia.nocookie.net/onepiece/images/a/ad/Enel_Anime_Infobox.png'),
('Helmeppo', 'Cậu Ấm Hải Quân', 0, 'Hải Quân (SWORD)', 'Thiếu Tá', 'Không có', 'Không có', 'Tân Thế Giới', 22, 201, 'Còn sống', 'Từ một công tử hống hách con quan, sau quá trình huấn luyện địa ngục cùng Garp, anh đã trở thành chiến binh dũng cảm chiến đấu bằng cặp đao Kukri độc đáo.', 'https://static.wikia.nocookie.net/onepiece/images/a/a3/Helmeppo_Anime_Post_Timeskip_Infobox.png'),
('Issho', 'Fujitora (Hổ Tím)', 3000000000, 'Hải Quân', 'Đô đốc', 'Zushi Zushi no Mi', 'Paramecia', 'Tân Thế Giới', 54, 270, 'Còn sống', 'Đô đốc mù được tuyển mộ thông qua Quân dịch Thế giới. Sở hữu khả năng kiểm soát trọng lực kinh hồn, có thể gọi cả thiên thạch từ không gian xuống để tấn công.', 'https://static.wikia.nocookie.net/onepiece/images/e/e8/Issho_Anime_Infobox.png'),
('Kin''emon', 'Hỏa狐 (Cáo Lửa)', 0, 'Gia tộc Kozuki', 'Thủ lĩnh Cửu Hồng Bao', 'Fuku Fuku no Mi', 'Paramecia', 'Tân Thế Giới', 36, 295, 'Còn sống', 'Bầy tôi trung thành số một của Oden. Có khả năng chém lửa độc đáo và năng lực tạo trang phục ngụy trang kỳ lạ giúp cả nhóm thoát hiểm trong nhiều tình huống ngặt nghèo.', 'https://static.wikia.nocookie.net/onepiece/images/e/ec/Kin%27emon_Anime_Infobox.png'),
('Kozuki Momonosuke', 'Shogun Wano Quốc', 0, 'Gia tộc Kozuki', 'Tướng Quân Wano', 'Uo Uo no Mi bản sao nhân tạo', 'Zoan Thần Thoại', 'Tân Thế Giới', 28, 250, 'Còn sống', 'Con trai trưởng của Oden. Sau khi nhờ Shinobu dùng năng lực làm lão hóa 20 năm, Momo đã trở thành một dũng sĩ khổng lồ có thể biến thành Rồng hồng lớn tương đương Kaido để gánh vác vận mệnh Wano.', 'https://static.wikia.nocookie.net/onepiece/images/8/8b/Kouzuki_Momonosuke_Anime_Infobox.png'),
('Kozuki Oden', 'Lãnh Chúa Kuri', 3500000000, 'Gia tộc Kozuki (Cựu Băng Râu Trắng, Băng Roger)', 'Lãnh chúa Kuri (Đã mất)', 'Không có', 'Không có', 'Tân Thế Giới', 39, 382, 'Đã mất', 'Huyền thoại vĩ đại nhất lịch sử Wano Quốc, người từng phiêu lưu cùng cả Râu Trắng và Roger. Oden là kiếm sĩ duy nhất để lại vết sẹo vĩnh viễn trên người Kaido bằng thanh kiếm Enma trứ danh.', 'https://static.wikia.nocookie.net/onepiece/images/7/7a/Kouzuki_Oden_Anime_Infobox.png'),
('Kuzan', 'Aokiji (Chim Trĩ Xanh)', 0, 'Băng Râu Đen (Cựu Hải Quân)', 'Đội trưởng Đội 10', 'Hie Hie no Mi', 'Logia', 'Tân Thế Giới', 49, 298, 'Còn sống', 'Cựu Đô đốc Hải quân theo đuổi ''Công lý Thư thả''. Sau trận chiến sinh tử thua Akainu tại Punk Hazard, ông đã rời hải quân và hiện đang liên minh gây sốc với băng hải tặc Râu Đen.', 'https://static.wikia.nocookie.net/onepiece/images/d/d6/Kuzan_Anime_Post_Timeskip_Infobox.png'),
('Nefertari Vivi', 'Miss Wednesday', 0, 'Vương quốc Alabasta (Cựu Baroque Works)', 'Công Chúa / Cựu thành viên Mũ Rơm', 'Không có', 'Không có', 'Tân Thế Giới', 18, 169, 'Còn sống', 'Vương nữ của vương quốc Alabasta và là người đồng đội trân quý của Băng Mũ Rơm. Cô mang trong mình dòng máu D. bí ẩn hiện đang là mục tiêu quan trọng nhất bị Imu truy lùng gắt gao.', 'https://static.wikia.nocookie.net/onepiece/images/0/09/Nefertari_Vivi_Anime_Post_Timeskip_Infobox.png'),
('Perona', 'Công Chúa Bóng Ma', 0, 'Cướp biển Thriller Bark', 'Chỉ huy', 'Horo Horo no Mi', 'Paramecia', 'Tân Thế Giới', 25, 160, 'Còn sống', 'Năng lực tạo ra những bóng ma làm suy sụp ý chí người khác khiến cô trở thành một đối thủ cực kỳ khó chịu. Từng sống chung đảo với Zoro và Mihawk suốt 2 năm.', 'https://static.wikia.nocookie.net/onepiece/images/4/4a/Perona_Anime_Post_Timeskip_Infobox.png'),
('Rob Lucci', 'Vũ Khí Sát Thủ', 0, 'CP0', 'Đặc vụ tối mật', 'Neko Neko no Mi, Model: Leopard', 'Zoan', 'Tân Thế Giới', 30, 212, 'Còn sống', 'Kẻ mạnh nhất trong lịch sử tổ chức CP9 trước đây, nay đã thăng cấp lên CP0 bảo vệ Thiên Long Nhân. Thông thạo cả 6 kỹ thức Rokushiki và đã thức tỉnh sức mạnh Báo Đốm mạnh mẽ.', 'https://static.wikia.nocookie.net/onepiece/images/d/d7/Rob_Lucci_Anime_Post_Timeskip_Infobox.png'),
('Sakazuki', 'Akainu (Chó Đỏ)', 5000000000, 'Hải Quân', 'Thủy sư Đô đốc', 'Magu Magu no Mi', 'Logia', 'Tân Thế Giới', 55, 306, 'Còn sống', 'Người đứng đầu cao nhất của lực lượng Hải quân thế giới với triết lý ''Công lý Tuyệt đối''. Akainu sở hữu sức tấn công nóng chảy hủy diệt nhất thế giới và là kẻ trực tiếp kết liễu Ace tại Marineford.', 'https://static.wikia.nocookie.net/onepiece/images/d/d7/Sakazuki_Anime_Post_Timeskip_Infobox.png'),
('Sengoku', 'Đức Phật Sengoku', 0, 'Hải Quân', 'Thanh tra (Cựu Thủy sư)', 'Hito Hito no Mi, Model: Daibutsu', 'Zoan Thần Thoại', 'Tân Thế Giới', 79, 278, 'Còn sống', 'Nhà chiến lược tài ba lỗi lạc từng lãnh đạo hải quân đi qua thời đại cũ. Ông có thể biến hình thành tượng Phật vàng khổng lồ phát ra những đòn tấn công sóng xung kích cực mạnh.', 'https://static.wikia.nocookie.net/onepiece/images/2/24/Sengoku_Anime_Post_Timeskip_Infobox.png'),
('Silvers Rayleigh', 'Vua Bóng Tối', 2243000000, 'Băng Roger', 'Cựu phó thuyền trưởng', 'Không có', 'Không có', 'Tân Thế Giới', 78, 188, 'Còn sống', 'Phó thuyền trưởng huyền thoại của Băng Hải tặc Roger, cánh tay phải của Vua Hải Tặc. Rayleigh là bậc thầy sử dụng Haki thượng thừa và là người đã truyền dạy tất cả kiến thức Haki cho Luffy trong 2 năm luyện tập.', 'https://static.wikia.nocookie.net/onepiece/images/b/b1/Silvers_Rayleigh_Anime_Infobox.png'),
('Smoker', 'Thợ Săn Trắng', 0, 'Hải Quân', 'Phó Đô Đốc', 'Moku Moku no Mi', 'Logia', 'Tân Thế Giới', 36, 209, 'Còn sống', 'Sĩ quan hải quân bướng bỉnh luôn đuổi theo dấu vết của Luffy từ tận Loguetown. Anh đại diện cho lối suy nghĩ công lý riêng biệt, không hoàn toàn phục tùng mệnh lệnh mù quáng từ cấp trên.', 'https://static.wikia.nocookie.net/onepiece/images/c/c4/Smoker_Anime_Post_Timeskip_Infobox.png'),
('Tashigi', 'Kiếm Sĩ Mắt Cận', 0, 'Hải Quân', 'Đại Tá', 'Không có', 'Không có', 'Tân Thế Giới', 23, 170, 'Còn sống', 'Đồng đội sát cánh trung thành của Smoker với ngoại hình giống hệt người bạn quá cố Kuina của Zoro. Ước mơ lớn nhất của cô là thu thập toàn bộ các thanh danh kiếm lọt vào tay hải tặc.', 'https://static.wikia.nocookie.net/onepiece/images/1/1e/Tashigi_Anime_Post_Timeskip_Infobox.png'),
('Vegapunk', 'Bộ Óc Lớn Nhất Thế Giới', 0, 'Chính Phủ Thế Giới', 'Nhà Khoa Học Thiên Tài', 'Nomi Nomi no Mi', 'Paramecia', 'Tân Thế Giới', 65, 180, 'Đã mất', 'Người sở hữu bộ óc có tri thức vượt trước thời đại tới 500 năm. Sáng tạo ra PX, Seraphim và phát hiện cội nguồn của Trái Ác Quỷ trước khi công khai bí mật chấn động thế giới về Thế Kỷ Trống.', 'https://static.wikia.nocookie.net/onepiece/images/b/b9/Vegapunk_Anime_Infobox.png'),
('Yamato', 'Oden Tự Xưng', 0, 'Gia tộc Kozuki', 'Chiến binh bảo hộ', 'Inu Inu no Mi, Model: Okuchi no Makami', 'Zoan Thần Thoại', 'Tân Thế Giới', 28, 263, 'Còn sống', 'Con gái ruột của Tứ Hoàng Kaido nhưng lại tự nhận mình là Kozuki Oden. Sở hữu sức mạnh thể chất kinh hoàng của tộc Quỷ và năng lực biến hình thành sói thần hộ mệnh của Wano quốc.', 'https://static.wikia.nocookie.net/onepiece/images/b/bd/Yamato_Anime_Infobox.png');

-- THÊM NHÂN VẬT PHỤC VỤ MỞ RỘNG LỚN (Băng Râu Đen, Tobi Roppo, Quân Cách Mạng...)
INSERT INTO characters (name, alias, bounty, affiliation, role, devil_fruit, devil_fruit_type, hometown, age, height, status, description, image_url) VALUES
('Van Augur', 'Siêu Xạ Thủ', 0, 'Băng Râu Đen', 'Đội trưởng đội 3 (Xạ thủ)', 'Wapu Wapu no Mi', 'Paramecia', 'Tân Thế Giới', 27, 340, 'Còn sống', 'Xạ thủ thiện xạ bách phát bách trúng có thể bắn hạ chim từ khoảng cách không tưởng ngoài đường chân trời. Năng lực Dịch Chuyển Tức Thời khiến hắn trở thành kẻ săn mồi bất khả chiến bại.', 'https://static.wikia.nocookie.net/onepiece/images/9/95/Van_Augur_Anime_Post_Timeskip_Infobox.png'),
('Emporio Ivankov', 'Vua Okama', 0, 'Quân Cách Mạng', 'Chỉ huy quân đội G', 'Horu Horu no Mi', 'Paramecia', 'Tân Thế Giới', 53, 449, 'Còn sống', 'Nữ vương vương quốc Kamabakka và là một trong những chỉ huy trụ cột thân cận nhất của Dragon. Năng lực thay đổi hormone có thể thay đổi giới tính, chữa trị vết thương hiểm nghèo và tăng cường sinh lực phi thường.', 'https://static.wikia.nocookie.net/onepiece/images/d/de/Emporio_Ivankov_Anime_Infobox.png'),
('Sanjuan Wolf', 'Chiến Hạm Khổng Lồ', 0, 'Băng Râu Đen', 'Đội trưởng đội 7', 'Deka Deka no Mi', 'Paramecia', 'Tân Thế Giới', 99, 18000, 'Còn sống', 'Sinh vật có kích thước khổng lồ nhất thế giới, to lớn gấp nhiều lần một người khổng lồ bình thường, lớn đến mức có thể đứng giữa đại dương mà nước chỉ ngập tới bụng.', 'https://static.wikia.nocookie.net/onepiece/images/6/62/Sanjuan_Wolf_Anime_Post_Timeskip_Infobox.png'),
('Lindbergh', 'Nhà Sáng Chế', 316000000, 'Quân Cách Mạng', 'Chỉ huy quân đội Nam', 'Không có', 'Không có', 'Tân Thế Giới', 0, 149, 'Còn sống', 'Một người tộc Mink chồn sở hữu tài năng sáng chế thiên tài, chuyên chế tạo các loại vũ khí tối tân và ba lô bay phản lực phục vụ chiến đấu cho quân cách mạng.', 'https://static.wikia.nocookie.net/onepiece/images/e/e1/Lindbergh_Anime_Infobox.png'),
('Douglas Bullet', 'Kế Thừa Quỷ Dữ', 0, 'Cựu Băng Roger', 'Hải tặc đơn độc', 'Gasha Gasha no Mi', 'Paramecia', 'Tân Thế Giới', 45, 491, 'Còn sống', 'Một con quái vật chiến tranh đích thực, cựu thành viên băng Roger với sức mạnh cơ bắp và Haki kinh hoàng có thể một mình đối đầu toàn bộ thế hệ Tồi Tệ nhất.', 'https://static.wikia.nocookie.net/onepiece/images/5/54/Douglas_Bullet_Anime_Infobox.png'),
('Morley', 'Kẻ Đào Hầm', 293000000, 'Quân Cách Mạng', 'Chỉ huy quân đội Tây', 'Oshi Oshi no Mi', 'Paramecia', 'Tân Thế Giới', 160, 1253, 'Còn sống', 'Một người khổng lồ Okama sở hữu năng lực đẩy đẩy mọi vật chất bao gồm cả lòng đất, chính là người bí ẩn đã đào ra tầng 5.5 huyền thoại tại ngục Impel Down.', 'https://static.wikia.nocookie.net/onepiece/images/4/48/Morley_Anime_Infobox.png'),
('Uta', 'Diva Của Thế Giới', 0, 'Elegia', 'Ca sĩ / Con gái Shanks', 'Uta Uta no Mi', 'Paramecia', 'Tân Thế Giới', 21, 169, 'Còn sống', 'Một ca sĩ huyền thoại nổi tiếng toàn cầu sở hữu giọng hát mê hoặc có thể đưa ý thức người nghe vào thế giới mộng ảo vĩnh cửu của mình. Cô là người bạn thơ ấu thân nhất của Luffy.', 'https://static.wikia.nocookie.net/onepiece/images/0/06/Uta_Anime_Infobox.png'),
('Denjiro', 'Kyoshiro', 0, 'Gia tộc Kozuki', 'Cửu Hồng Bao', 'Không có', 'Không có', 'Tân Thế Giới', 47, 306, 'Còn sống', 'Bầy tôi của Oden, người đã nén hận thù thay đổi diện mạo để trở thành trùm Yakuza dưới trướng Orochi suốt 20 năm, âm thầm chờ đợi thời cơ lật đổ bạo chúa giải cứu Wano.', 'https://static.wikia.nocookie.net/onepiece/images/7/7e/Denjiro_Anime_Infobox.png'),
('Inuarashi', 'Công Tước Bình Minh', 0, 'Zou (Tộc Mink)', 'Vua Ban Ngày', 'Không có', 'Không có', 'Tân Thế Giới', 40, 322, 'Còn sống', 'Vị vua cai trị Zou ban ngày, một kiếm sĩ chó tộc Mink sở hữu kiếm pháp lịch lãm nhưng vô cùng uy lực, đối thủ cân tài cân sức không bao giờ ngủ của Nekomamushi.', 'https://static.wikia.nocookie.net/onepiece/images/9/9f/Inuarashi_Anime_Infobox.png'),
('Magellan', 'Tổng Giám Ngục Độc Dược', 0, 'Impel Down', 'Phó tổng ngục (Cựu tổng)', 'Doku Doku no Mi', 'Paramecia', 'Tân Thế Giới', 45, 491, 'Còn sống', 'Pháo đài sống bảo vệ nhà ngục bất khả xâm phạm Impel Down. Toàn thân hắn bao phủ bởi kịch độc có thể tan chảy cả đá và giết chết bất cứ ai chỉ với một cái chạm nhẹ.', 'https://static.wikia.nocookie.net/onepiece/images/9/9e/Magellan_Anime_Post_Timeskip_Infobox.png'),
('Bentham', 'Mr. 2 Bon Clay', 32000000, 'Cựu Baroque Works', 'Tân Nữ Vương Okama', 'Mane Mane no Mi', 'Paramecia', 'Tân Thế Giới', 32, 212, 'Còn sống', 'Người bạn tâm giao trượng nghĩa nhất của Luffy. Đã 2 lần hy sinh tự do của mình để cứu cả nhóm Mũ Rơm. Có năng lực chạm vào mặt để sao chép biến hình thành bất cứ ai.', 'https://static.wikia.nocookie.net/onepiece/images/0/0e/Bentham_Anime_Infobox.png'),
('Stussy', 'Nữ Hoàng Phố Đèn Đỏ', 0, 'CP0 / Cựu MADS', 'Đặc vụ tối mật (Nhân bản)', 'Không rõ', 'Zoan', 'Tân Thế Giới', 0, 178, 'Còn sống', 'Một đặc vụ chìm của CP0, nhân bản thành công đầu tiên của cựu thành viên băng ROCKS là Buckingham Stussy. Sở hữu ngoại hình trẻ trung quyến rũ và khả năng hút máu gây mê đối thủ.', 'https://static.wikia.nocookie.net/onepiece/images/e/ee/Stussy_Anime_Infobox.png'),
('Zeff', 'Zeff Chân Đỏ', 0, 'Nhà Hàng Baratie', 'Bếp trưởng / Chủ nhà hàng', 'Không có', 'Không có', 'Tân Thế Giới', 67, 189, 'Còn sống', 'Cựu cướp biển huyền thoại đã truyền thụ tuyệt kỹ cước pháp cho Sanji. Ông đã từ bỏ chân phải của mình và cả sự nghiệp hải tặc để cứu mạng và cùng Sanji xây dựng nhà hàng trên biển Baratie.', 'https://static.wikia.nocookie.net/onepiece/images/d/d9/Zeff_Anime_Infobox.png'),
('Page One', 'Kỵ Sĩ Gai', 290000000, 'Băng Bách Thú', 'Tobi Roppo', 'Ryu Ryu no Mi, Model: Spinosaurus', 'Zoan Cổ Đại', 'Tân Thế Giới', 20, 171, 'Còn sống', 'Em trai của Ulti, sở hữu năng lực Khủng long gai gai lưng gai dạ. Khi biến hình hoàn toàn, cậu là cỗ máy cắn xé khổng lồ mang sức mạnh hủy diệt thuần túy của loài săn mồi cổ đại.', 'https://static.wikia.nocookie.net/onepiece/images/4/46/Page_One_Anime_Infobox.png'),
('Vasco Shot', 'Kẻ Nát Rượu', 0, 'Băng Râu Đen', 'Đội trưởng đội 8', 'Gabu Gabu no Mi', 'Paramecia', 'Tân Thế Giới', 38, 573, 'Còn sống', 'Một gã nghiện rượu nặng nề tàn bạo đến từ tầng 6 Impel Down. Hắn có thể uống lượng cồn khổng lồ và dùng năng lực phun ra những biển lửa rượu rực cháy thiêu đốt đối thủ.', 'https://static.wikia.nocookie.net/onepiece/images/6/66/Vasco_Shot_Anime_Post_Timeskip_Infobox.png'),
('Shiryu', 'Shiryu Cơn Mưa', 0, 'Băng Râu Đen', 'Đội trưởng đội 2', 'Suke Suke no Mi', 'Paramecia', 'Tân Thế Giới', 44, 340, 'Còn sống', 'Cựu tổng ngục Impel Down khét tiếng tàn bạo, kẻ thích tàn sát tù nhân mua vui. Sau khi gia nhập Râu Đen, hắn sở hữu thanh quỷ kiếm Raiu và năng lực tàng hình tuyệt đối.', 'https://static.wikia.nocookie.net/onepiece/images/4/4a/Shiryu_Anime_Infobox.png'),
('Raizo', 'Ninja Raizo Sương Mù', 0, 'Gia tộc Kozuki', 'Cửu Hồng Bao (Ninja)', 'Maki Maki no Mi', 'Paramecia', 'Tân Thế Giới', 35, 311, 'Còn sống', 'Một ninja chân chính xứ Wano sở hữu năng lực cuộn giấy Maki Maki, có thể hấp thụ đòn tấn công của đối thủ (kể cả ngọn lửa của Kaido) vào cuộn giấy và phóng ngược lại trả đòn.', 'https://static.wikia.nocookie.net/onepiece/images/2/23/Raizo_Anime_Infobox.png'),
('Charlotte Oven', 'Bộ Trưởng Nung Nóng', 300000000, 'Băng Big Mom', 'Con trai thứ 4', 'Netsu Netsu no Mi', 'Paramecia', 'Tân Thế Giới', 48, 492, 'Còn sống', 'Kẻ sở hữu cơ thể tỏa nhiệt cực đại có thể đun sôi cả đại dương mênh mông trong tích tắc chỉ bằng cách nhúng tay xuống nước, là một trong những chiến binh cận chiến tàn bạo nhất của Totto Land.', 'https://static.wikia.nocookie.net/onepiece/images/f/f0/Charlotte_Oven_Anime_Infobox.png'),
('Inazuma', 'Gió Cắt', 0, 'Quân Cách Mạng', 'Trợ tá quân đội G', 'Choki Choki no Mi', 'Paramecia', 'Tân Thế Giới', 29, 228, 'Còn sống', 'Đồng đội thân cận của Ivankov với năng lực biến tay thành kéo khổng lồ để cắt mọi vật thể như thể chúng là giấy, kể cả đá và kim loại kiên cố.', 'https://static.wikia.nocookie.net/onepiece/images/d/d8/Inazuma_Anime_Infobox.png'),
('Laffitte', 'Cảnh Sát Trưởng Quỷ', 0, 'Băng Râu Đen', 'Đội trưởng đội 5 (Hoa tiêu)', 'Không xác định', 'Paramecia', 'Tân Thế Giới', 41, 340, 'Còn sống', 'Kẻ sở hữu kỹ năng thâm nhập và thôi miên siêu hạng, có thể mọc cánh thiên nga trắng để bay lượn. Từng một mình thâm nhập căn cứ Mariejois mà không bị ai phát hiện.', 'https://static.wikia.nocookie.net/onepiece/images/0/00/Laffitte_Anime_Infobox.png'),
('Nekomamushi', 'Chúa Tể Bóng Đêm', 0, 'Zou (Tộc Mink)', 'Vua Hồi Chuông', 'Không có', 'Không có', 'Tân Thế Giới', 40, 318, 'Còn sống', 'Vị vua khổng lồ cai trị Zou về đêm. Một con mèo tộc Mink thiện chiến với sức mạnh quái vật và phong cách chiến đấu đầy hoang dã, từng phiêu lưu trên tàu của cả Râu Trắng và Roger.', 'https://static.wikia.nocookie.net/onepiece/images/a/a2/Nekomamushi_Anime_Infobox.png'),
('Sasaki', 'Thiết Giáp', 472000000, 'Băng Bách Thú', 'Tobi Roppo', 'Ryu Ryu no Mi, Model: Triceratops', 'Zoan Cổ Đại', 'Tân Thế Giới', 34, 318, 'Còn sống', 'Chỉ huy sư đoàn Thiết Giáp bọc thép của Kaido. Có thể biến hình thành Tam Giác Long cổ đại và kỳ lạ thay, hắn có thể xoay cái bờm quanh cổ như cánh quạt trực thăng để bay lượn.', 'https://static.wikia.nocookie.net/onepiece/images/d/d7/Sasaki_Anime_Infobox.png'),
('Ashura Doji', 'Shutenmaru', 0, 'Gia tộc Kozuki', 'Cửu Hồng Bao', 'Không có', 'Không có', 'Tân Thế Giới', 56, 544, 'Còn sống', 'Kẻ mạnh nhất trong số các Cửu Hồng Bao, kiếm sĩ cướp núi vĩ đại vùng Kuri. Sức mạnh cơ bắp kinh hồn của ông từng có thể một kiếm chém trúng và đả thương trực diện Jack Hạn Hán.', 'https://static.wikia.nocookie.net/onepiece/images/4/44/Ashura_Doji_Anime_Infobox.png'),
('Ulti', 'Mỹ Nhân Thiết Đầu', 400000000, 'Băng Bách Thú', 'Tobi Roppo', 'Ryu Ryu no Mi, Model: Pachycephalosaurus', 'Zoan Cổ Đại', 'Tân Thế Giới', 22, 173, 'Còn sống', 'Thành viên Tobi Roppo sở hữu tính cách hung hăng và cực kỳ yêu chiều em trai Page One. Cô có thể biến thành Khủng long đầu dày với những cú húc đầu kinh thiên động địa có thể làm nứt sọ đối thủ.', 'https://static.wikia.nocookie.net/onepiece/images/d/dc/Ulti_Anime_Infobox.png'),
('Charlotte Daifuku', 'Bộ Trưởng Hạt Đậu', 300000000, 'Băng Big Mom', 'Con trai thứ 3', 'Hoya Hoya no Mi', 'Paramecia', 'Tân Thế Giới', 48, 489, 'Còn sống', 'Bằng cách xoa bụng mình như đèn thần, hắn triệu hồi ra một Thần Đèn khổng lồ cầm đao to lớn mang sức mạnh tàn phá khủng khiếp để chiến đấu thay cho bản thân.', 'https://static.wikia.nocookie.net/onepiece/images/c/cd/Charlotte_Daifuku_Anime_Infobox.png'),
('Karasu', 'Quạ Đen', 400000000, 'Quân Cách Mạng', 'Chỉ huy quân đội Bắc', 'Susu Susu no Mi', 'Logia', 'Tân Thế Giới', 0, 265, 'Còn sống', 'Chỉ huy bí ẩn điều khiển quân đội phía Bắc của cách mạng. Có năng lực biến cơ thể thành bồ hóng và điều khiển bầy quạ sát thủ tấn công kẻ địch.', 'https://static.wikia.nocookie.net/onepiece/images/9/9a/Karasu_Anime_Infobox.png'),
('Avalo Pizarro', 'Ác Vương', 0, 'Băng Râu Đen', 'Đội trưởng đội 4', 'Shima Shima no Mi', 'Paramecia', 'Tân Thế Giới', 42, 505, 'Còn sống', 'Cựu quốc vương bạo chúa độc ác bị lật đổ. Nhờ Trái Ác Quỷ Đồng Hóa Đảo, hắn có thể hợp nhất ý thức với cả một hòn đảo khổng lồ, biến mọi tòa nhà và vách đá thành cơ thể mình.', 'https://static.wikia.nocookie.net/onepiece/images/e/ef/Avalo_Pizarro_Anime_Post_Timeskip_Infobox.png'),
('Galdino', 'Mr. 3', 24000000, 'Cross Guild', 'Sĩ quan cao cấp', 'Doru Doru no Mi', 'Paramecia', 'Tân Thế Giới', 37, 179, 'Còn sống', 'Bộ óc mưu mẹo xảo quyệt có năng lực điều khiển sáp nến cứng như thép. Sáp của hắn chính là chìa khóa vàng đã giải thoát cùm khóa tay cho Ace tại đỉnh đài hành hình Marineford.', 'https://static.wikia.nocookie.net/onepiece/images/1/13/Galdino_Anime_Infobox.png'),
('Black Maria', 'Nhện Quỷ', 480000000, 'Băng Bách Thú', 'Tobi Roppo', 'Kumo Kumo no Mi, Model: Rosamygale Grauvogeli', 'Zoan Cổ Đại', 'Tân Thế Giới', 29, 820, 'Còn sống', 'Một người khổng lồ xinh đẹp quản lý kỹ viện Onigashima. Cô có thể biến thành Nhện cổ đại phun ra tơ cực độc, lửa cháy và sở hữu ảo thuật đánh lừa ký ức đối thủ cực kỳ xảo quyệt.', 'https://static.wikia.nocookie.net/onepiece/images/e/e2/Black_Maria_Anime_Infobox.png'),
('Gin', 'Quỷ Nhân Gin', 12000000, 'Băng Don Krieg', 'Đại chiến binh chỉ huy', 'Không có', 'Không có', 'Tân Thế Giới', 27, 186, 'Còn sống', 'Cánh tay phải trung thành đến cực đoan của Don Krieg. Dù sở hữu biệt danh Quỷ nhân tàn độc, anh lại là một người trọng tình nghĩa, đã khóc khi nhận được dĩa cơm ân tình cứu đói của Sanji.', 'https://static.wikia.nocookie.net/onepiece/images/4/49/Gin_Anime_Infobox.png'),
('Catarina Devon', 'Thợ Săn Trăng Lưỡi Liềm', 0, 'Băng Râu Đen', 'Đội trưởng đội 6', 'Inu Inu no Mi, Model: Kyubi no Kitsune', 'Zoan Thần Thoại', 'Tân Thế Giới', 36, 361, 'Còn sống', 'Nữ hải tặc nguy hiểm và xấu xí nhất lịch sử ngục Cấp 6. Cô sở hữu năng lực Cửu Vĩ Hồ cho phép biến hình sao chép hoàn hảo ngoại hình và trang phục của bất cứ ai.', 'https://static.wikia.nocookie.net/onepiece/images/4/4a/Catarina_Devon_Anime_Post_Timeskip_Infobox.png'),
('Charlotte Brulee', 'Mụ Phù Thủy Gương', 0, 'Băng Big Mom', 'Con gái thứ 8', 'Mira Mira no Mi', 'Paramecia', 'Tân Thế Giới', 43, 350, 'Còn sống', 'Sở hữu năng lực Trái Ác Quỷ Gương vô cùng phiền toái, kết nối mọi tấm gương trên đảo vào một chiều không gian mê cung song song, cho phép dịch chuyển quân đội thần tốc.', 'https://static.wikia.nocookie.net/onepiece/images/d/d9/Charlotte_Br%C3%BBl%C3%A9e_Anime_Infobox.png'),
('Doc Q', 'Thần Chết', 0, 'Băng Râu Đen', 'Đội trưởng đội 9 (Bác sĩ)', 'Shiku Shiku no Mi', 'Paramecia', 'Tân Thế Giới', 28, 342, 'Còn sống', 'Tên bác sĩ bệnh hoạn luôn cưỡi trên con ngựa Stronger ốm yếu. Hắn sở hữu năng lực tạo ra và gieo rắc mọi loại dịch bệnh quái đản cho bất cứ mục tiêu nào hắn muốn.', 'https://static.wikia.nocookie.net/onepiece/images/c/c4/Doc_Q_Anime_Infobox.png'),
('Belo Betty', 'Nữ Kỳ Thủ Tự Do', 457000000, 'Quân Cách Mạng', 'Chỉ huy quân đội Đông', 'Kobu Kobu no Mi', 'Paramecia', 'Tân Thế Giới', 34, 196, 'Còn sống', 'Năng lực Trái Ác Quỷ Cổ Vũ cho phép cô vẫy cờ để thức tỉnh sức mạnh tiềm ẩn, ý chí chiến đấu và thể chất của toàn bộ thường dân hoặc quân lính trong vùng rộng lớn.', 'https://static.wikia.nocookie.net/onepiece/images/d/dd/Belo_Betty_Anime_Infobox.png'),
('Kawamatsu', 'Kappa Kawamatsu', 0, 'Gia tộc Kozuki', 'Cửu Hồng Bao (Yokozuna)', 'Không có', 'Không có', 'Tân Thế Giới', 41, 271, 'Còn sống', 'Một võ sĩ Sumo vĩ đại thuộc tộc Người Cá Blowfish. Ông chính là người đã cống hiến cả tuổi xuân chăm sóc, bảo vệ Công chúa Hiyori thoát khỏi sự truy quét của quân Kaido.', 'https://static.wikia.nocookie.net/onepiece/images/5/5e/Kawamatsu_Anime_Infobox.png'),
('Koala', 'Trợ giảng Karate Người Cá', 0, 'Quân Cách Mạng', 'Sĩ quan tình báo', 'Không có', 'Không có', 'Tân Thế Giới', 23, 160, 'Còn sống', 'Cựu nô lệ được Fisher Tiger giải cứu, nay là cao thủ Karate Người cá duy nhất thuộc tộc người. Cô làm việc ăn ý cùng Sabo và Hack trong tổng bộ Quân Cách mạng.', 'https://static.wikia.nocookie.net/onepiece/images/3/3d/Koala_Anime_Infobox.png'),
('Who''s-Who', 'Nanh Vuốt', 546000000, 'Băng Bách Thú', 'Tobi Roppo', 'Neko Neko no Mi, Model: Saber-toothed Tiger', 'Zoan Cổ Đại', 'Tân Thế Giới', 38, 336, 'Còn sống', 'Cựu thành viên CP9 thiên tài bị bỏ tù vì làm mất Trái Gomu Gomu. Sở hữu kỹ năng Lục thức thượng thừa kết hợp với sức mạnh hổ răng kiếm cổ đại cực kỳ nhanh nhẹn và sắc bén.', 'https://static.wikia.nocookie.net/onepiece/images/9/94/Who''s-Who_Anime_Infobox.png'),
('Jesus Burgess', 'Nhà Vô Địch', 0, 'Băng Râu Đen', 'Đội trưởng đội 1 (Lái tàu)', 'Riki Riki no Mi', 'Paramecia', 'Tân Thế Giới', 29, 355, 'Còn sống', 'Đội trưởng tiên phong của Râu Đen, cuồng chiến binh đô vật hạng nặng. Sau khi ăn trái Sức Mạnh Riki Riki, gã có thể nhấc bổng cả một ngọn núi đá khổng lồ ném đi như ném hòn sỏi.', 'https://static.wikia.nocookie.net/onepiece/images/4/43/Jesus_Burgess_Anime_Post_Timeskip_Infobox.png'),
('Kikunojo', 'O-Kiku / Tuyết Dư Trà', 0, 'Gia tộc Kozuki', 'Cửu Hồng Bao', 'Không có', 'Không có', 'Tân Thế Giới', 22, 287, 'Còn sống', 'Một nam kiếm sĩ có dung mạo kiều diễm hơn bất cứ mỹ nhân nào, chiến đấu bằng kiếm thuật lạnh lùng và đẹp mắt như những bông tuyết mùa đông rơi trong thầm lặng.', 'https://static.wikia.nocookie.net/onepiece/images/1/12/Kikunojo_Anime_Infobox.png'),
('Kaku', 'Hươu Cao Cổ', 0, 'CP0', 'Đặc vụ tối mật', 'Ushi Ushi no Mi, Model: Giraffe', 'Zoan', 'Tân Thế Giới', 25, 193, 'Còn sống', 'Kiếm sĩ tài năng sử dụng Tứ Kiếm Thuật kết hợp Rankyaku cực kỳ điêu luyện. Anh đã thăng cấp lên CP0 cùng Lucci và đã hoàn toàn thức tỉnh năng lực hươu cao cổ của mình.', 'https://static.wikia.nocookie.net/onepiece/images/0/09/Kaku_Anime_Post_Timeskip_Infobox.png');

-- THÊM NHÂN VẬT BỔ SUNG (Băng Tóc Đỏ, Râu Trắng, Donquixote)
INSERT INTO characters (name, alias, bounty, affiliation, role, devil_fruit, devil_fruit_type, hometown, age, height, status, description, image_url) VALUES
('Benn Beckman', 'Cánh Tay Phải Của Shanks', 0, 'Băng Tóc Đỏ', 'Phó thuyền trưởng', 'Không có', 'Không có', 'Tân Thế Giới', 50, 206, 'Còn sống', 'Người có chỉ số IQ cao nhất ở Biển Đông, phó thuyền trưởng đáng sợ với phong thái điềm tĩnh. Một tay súng Haki bậc thầy từng khiến Đô đốc Kizaru phải đứng hình tại Marineford.', 'https://static.wikia.nocookie.net/onepiece/images/1/12/Benn_Beckman_Anime_Infobox.png'),
('Gladius', 'Pháo Nổ', 31000000, 'Băng Donquixote', 'Sĩ quan quân Bích', 'Pamu Pamu no Mi', 'Paramecia', 'Tân Thế Giới', 33, 260, 'Còn sống', 'Kẻ trung thành cuồng tín luôn mang mặt nạ và cặp kính bảo hộ. Hắn có thể làm phồng to và nổ tung bất cứ vật thể vô cơ nào, kể cả chính các bộ phận cơ thể mình thành những mảnh đạn sắc bén.', 'https://static.wikia.nocookie.net/onepiece/images/3/3d/Gladius_Anime_Infobox.png'),
('Senor Pink', 'Quý Ông Đích Thực', 58000000, 'Băng Donquixote', 'Sĩ quan quân Rô', 'Sui Sui no Mi', 'Paramecia', 'Tân Thế Giới', 46, 244, 'Còn sống', 'Đằng sau vẻ ngoài quái đản trong bộ đồ em bé là một quá khứ bi thương và tinh thần trượng nghĩa của một quý ông đích thực khiến cả Franky cũng phải tôn trọng.', 'https://static.wikia.nocookie.net/onepiece/images/4/48/Senor_Pink_Anime_Infobox.png'),
('Jozu', 'Kim Cương Jozu', 0, 'Băng Râu Trắng', 'Đội trưởng đội 3', 'Kira Kira no Mi', 'Paramecia', 'Tân Thế Giới', 42, 503, 'Còn sống', 'Sở hữu sức phòng ngự vật lý mạnh bậc nhất thế giới nhờ năng lực hóa kim cương toàn thân, từng chặn đứng hoàn toàn cú chém mạnh nhất thế giới của Dracule Mihawk.', 'https://static.wikia.nocookie.net/onepiece/images/6/61/Jozu_Anime_Infobox.png'),
('Pica', 'Quái Vật Giọng Thanh', 99000000, 'Băng Donquixote', 'Chỉ huy tối cao quân Bích', 'Ishi Ishi no Mi', 'Paramecia', 'Tân Thế Giới', 40, 470, 'Còn sống', 'Dù sở hữu chất giọng mỏng lét hài hước, gã là cơn ác mộng với năng lực hòa nhập và điều khiển đá, có thể hóa thành một tượng đá khổng lồ to lớn bao trùm toàn bộ kinh đô Dressrosa.', 'https://static.wikia.nocookie.net/onepiece/images/a/a4/Pica_Anime_Infobox.png'),
('Lao G', 'Võ Sư Già', 61000000, 'Băng Donquixote', 'Sĩ quan quân Rô', 'Không có', 'Không có', 'Tân Thế Giới', 70, 157, 'Còn sống', 'Võ sư già nua lụ khụ sở hữu tuyệt kỹ Địa Ông Quyền, cho phép ông tích trữ toàn bộ thể lực sung mãn thời trai trẻ để bùng nổ sức mạnh kinh hồn trong trận chiến.', 'https://static.wikia.nocookie.net/onepiece/images/5/52/Lao_G_Anime_Infobox.png'),
('Vista', 'Hoa Kiếm Vista', 0, 'Băng Râu Trắng', 'Đội trưởng đội 5', 'Không có', 'Không có', 'Tân Thế Giới', 47, 328, 'Còn sống', 'Kiếm sĩ song kiếm lừng danh sử dụng những cánh hoa hồng trứ danh trong từng đường kiếm, một trong số ít người đủ bản lĩnh giao chiêu cân tài ngang ngửa với đệ nhất kiếm sĩ Mihawk.', 'https://static.wikia.nocookie.net/onepiece/images/7/78/Vista_Anime_Infobox.png'),
('Izo', 'Tay Súng Kimono', 510000000, 'Băng Râu Trắng', 'Đội trưởng đội 16', 'Không có', 'Không có', 'Tân Thế Giới', 45, 192, 'Còn sống', 'Cựu Cửu Hồng Bao của Wano quốc, người đã rời quê hương phiêu lưu cùng Râu Trắng. Chiến đấu bằng phong cách bắn súng điêu luyện trong trang phục Geisha độc đáo.', 'https://static.wikia.nocookie.net/onepiece/images/8/81/Izou_Anime_Post_Timeskip_Infobox.png'),
('Lucky Roux', 'Sát Thủ Cười', 0, 'Băng Tóc Đỏ', 'Lực sĩ chiến đấu', 'Không có', 'Không có', 'Tân Thế Giới', 35, 241, 'Còn sống', 'Tay súng vui nhộn luôn cầm đùi thịt trên tay. Ẩn sau vẻ ngoài to béo là tốc độ di chuyển đáng kinh ngạc có thể áp sát và nổ súng trước khi kẻ thù kịp phản ứng.', 'https://static.wikia.nocookie.net/onepiece/images/0/03/Lucky_Roux_Anime_Pre_Timeskip_Infobox.png'),
('Monet', 'Yêu Nữ Tuyết', 0, 'Băng Donquixote', 'Trợ lý / Gián điệp', 'Yuki Yuki no Mi', 'Logia', 'Tân Thế Giới', 30, 227, 'Còn sống', 'Em gái của Sugar, một mỹ nhân sở hữu đôi cánh chim và năng lực Tuyết hệ Logia tuyệt đẹp nhưng lạnh lùng và chết chóc.', 'https://static.wikia.nocookie.net/onepiece/images/9/98/Monet_Anime_Infobox.png'),
('Haruta', 'Kiếm Sĩ Trẻ', 0, 'Băng Râu Trắng', 'Đội trưởng đội 12', 'Không có', 'Không có', 'Tân Thế Giới', 0, 160, 'Còn sống', 'Một kiếm sĩ nhanh nhẹn với phong cách chiến đấu linh hoạt, mặc dù có ngoại hình khá nhỏ bé nhưng luôn chiến đấu vô cùng quả cảm ở tuyến đầu.', 'https://static.wikia.nocookie.net/onepiece/images/4/4f/Haruta_Anime_Infobox.png'),
('Yasopp', 'Tay Súng Chaser', 0, 'Băng Tóc Đỏ', 'Xạ thủ bắn tỉa', 'Không có', 'Không có', 'Tân Thế Giới', 47, 183, 'Còn sống', 'Cha đẻ của Usopp, một trong những xạ thủ giỏi nhất thế giới với Haki Quan sát thượng thừa có thể nhìn trước tương lai và bắn trúng cả râu của một con kiến từ khoảng cách 100 mét.', 'https://static.wikia.nocookie.net/onepiece/images/1/15/Yasopp_Anime_Infobox.png'),
('Diamante', 'Người Hùng Đấu Trường', 99000000, 'Băng Donquixote', 'Chỉ huy tối cao quân Rô', 'Hira Hira no Mi', 'Paramecia', 'Tân Thế Giới', 45, 525, 'Còn sống', 'Nhà vô địch tàn độc của đấu trường Corrida. Năng lực Biến Đổi Cờ cho phép hắn biến mọi vật thể rắn như thanh kiếm hay áo choàng trở nên mỏng và dẻo như một tấm vải.', 'https://static.wikia.nocookie.net/onepiece/images/7/72/Diamante_Anime_Infobox.png'),
('Vergo', 'Quỷ Trúc Vergo', 0, 'Băng Donquixote', 'Chỉ huy cấp cao (Nằm vùng Hải quân)', 'Không có', 'Không có', 'Tân Thế Giới', 41, 247, 'Còn sống', 'Gián điệp nguy hiểm nhất nằm sâu trong G-5 hải quân. Bậc thầy sử dụng Haki Vũ trang toàn thân, có thể biến cây sáo trúc thành một vũ khí hủy diệt cứng hơn cả thép.', 'https://static.wikia.nocookie.net/onepiece/images/c/cf/Vergo_Anime_Infobox.png'),
('Trebol', 'Cố Vấn Tối Cao Trebol', 99000000, 'Băng Donquixote', 'Chỉ huy tối cao quân Nhép', 'Beta Beta no Mi', 'Paramecia', 'Tân Thế Giới', 49, 349, 'Còn sống', 'Gã cố vấn xảo trá với năng lực tạo ra chất nhầy siêu dính và cực kỳ dễ cháy, chính là kẻ đã đưa Trái ác quỷ và khẩu súng cho Doflamingo thuở nhỏ.', 'https://static.wikia.nocookie.net/onepiece/images/f/f5/Trebol_Anime_Infobox.png'),
('Dellinger', 'Cá Chọi', 15000000, 'Băng Donquixote', 'Sĩ quan quân Rô', 'Không có', 'Không có', 'Tân Thế Giới', 16, 145, 'Còn sống', 'Con lai mang dòng máu Tộc Cá Chọi hung tợn. Dù mang vẻ ngoài thời trang nhí nhảnh, cậu sở hữu tốc độ và những cú đá đâm lủng người đầy tàn bạo.', 'https://static.wikia.nocookie.net/onepiece/images/8/8b/Dellinger_Anime_Infobox.png'),
('Corazon', 'Rosinante', 0, 'Hải Quân', 'Trung tá (Nằm vùng Băng Donquixote)', 'Nagi Nagi no Mi', 'Paramecia', 'Tân Thế Giới', 26, 293, 'Còn sống', 'Em trai ruột của Doflamingo và là người cha tinh thần vĩ đại của Trafalgar Law. Ông đã hy sinh mạng sống để đánh cắp Trái Ope Ope cứu mạng Law và tặng cho cậu nụ cười cuối cùng đầy ấm áp.', 'https://static.wikia.nocookie.net/onepiece/images/7/71/Donquixote_Rosinante_Anime_Infobox.png'),
('Sugar', 'Hobby Hobby', 0, 'Băng Donquixote', 'Chủ lực quan trọng nhất', 'Hobi Hobi no Mi', 'Paramecia', 'Tân Thế Giới', 22, 110, 'Còn sống', 'Sở hữu ngoại hình vĩnh viễn của một đứa trẻ nhưng nắm giữ năng lực kinh hoàng nhất: Chỉ cần chạm vào ai, người đó sẽ biến thành đồ chơi và ký ức về họ biến mất vĩnh viễn khỏi tâm trí thế giới.', 'https://static.wikia.nocookie.net/onepiece/images/e/e9/Sugar_Anime_Infobox.png');

-- THÊM THÀNH VIÊN BĂNG BIG MOM BỔ SUNG
INSERT INTO characters (name, alias, bounty, affiliation, role, devil_fruit, devil_fruit_type, hometown, age, height, status, description, image_url) VALUES
('Baron Tamago', 'Nam Tước Trứng', 429000000, 'Băng Big Mom', 'Chiến binh Kỵ sĩ cấp cao', 'Tama Tama no Mi', 'Không phân loại', 'Tân Thế Giới', 46, 301, 'Còn sống', 'Một chiến binh tộc Chân dài lịch lãm sở hữu năng lực Trái Ác Quỷ vô cùng quái đản, giúp anh ta tiến hóa liên tục thành Gà sau mỗi lần cơ thể bị đập vỡ.', 'https://static.wikia.nocookie.net/onepiece/images/4/49/Tamago_Anime_Infobox.png'),
('Streusen', 'Tổng Bếp Trưởng', 0, 'Băng Big Mom', 'Đồng sáng lập / Tổng bếp trưởng', 'Kuku Kuku no Mi', 'Paramecia', 'Tân Thế Giới', 92, 140, 'Còn sống', 'Người đầu tiên khám phá ra tài năng của Big Mom từ thuở nhỏ. Có thể biến bất cứ vật thể vô cơ nào thành đồ ăn ngon chỉ bằng một lát cắt kiếm.', 'https://static.wikia.nocookie.net/onepiece/images/3/34/Streusen_Anime_Infobox.png'),
('Charlotte Snack', 'Cựu Tư Lệnh Ngọt', 600000000, 'Băng Big Mom', 'Bộ trưởng khoai tây', 'Không rõ', 'Không rõ', 'Tân Thế Giới', 30, 300, 'Còn sống', 'Cựu Tư lệnh ngọt thứ 4 trước khi bị Urouge đánh bại. Sở hữu ngoại hình to lớn và sức chiến đấu mạnh mẽ với thanh kiếm khổng lồ đeo sau lưng.', 'https://static.wikia.nocookie.net/onepiece/images/1/18/Charlotte_Snack_Anime_Infobox.png'),
('Charlotte Chiffon', 'Vợ của Bege', 0, 'Băng Bege (Fire Tank)', 'Cựu Công chúa Big Mom', 'Không có', 'Không có', 'Tân Thế Giới', 26, 210, 'Còn sống', 'Chị song sinh của Lola, người vợ trung thủy hết lòng của Capone Bege. Cô có trái tim dũng cảm, dám chống lại sự bạo ngược của người mẹ Big Mom để bảo vệ gia đình nhỏ của mình.', 'https://static.wikia.nocookie.net/onepiece/images/6/6d/Charlotte_Chiffon_Anime_Infobox.png'),
('Charlotte Flampe', 'Chủ Tịch Hội Fan', 0, 'Băng Big Mom', 'Bộ trưởng mật ong', 'Không rõ', 'Không rõ', 'Tân Thế Giới', 15, 150, 'Còn sống', 'Cô em gái phiền phức luôn thần tượng mù quáng anh trai Katakuri. Có tài thổi phi tiêu tẩm thuốc tê cực kỳ chuẩn xác từ khoảng cách xa.', 'https://static.wikia.nocookie.net/onepiece/images/9/91/Charlotte_Flampe_Anime_Infobox.png'),
('Charlotte Amande', 'Quỷ Phu Nhân', 0, 'Băng Big Mom', 'Bộ trưởng hạt dẻ', 'Không có', 'Không có', 'Tân Thế Giới', 30, 240, 'Còn sống', 'Nữ kiếm sĩ tàn bạo của tộc Cổ dài, sở hữu thanh quỷ kiếm Meito Shirauo. Cô thích kết liễu kẻ thù một cách từ tốn nhất để họ cảm nhận nỗi đau thấu xương.', 'https://static.wikia.nocookie.net/onepiece/images/b/b9/Charlotte_Amande_Anime_Infobox.png'),
('Pekoms', 'Pekoms Sư Tử', 330000000, 'Băng Big Mom', 'Chiến binh chiến đấu', 'Kame Kame no Mi', 'Zoan', 'Tân Thế Giới', 27, 232, 'Còn sống', 'Một chiến binh tộc Mink sư tử có đôi mắt dễ thương nhưng kỹ năng chiến đấu vô cùng dũng mãnh kết hợp cùng năng lực Rùa mai cứng như thép.', 'https://static.wikia.nocookie.net/onepiece/images/1/15/Pekoms_Anime_Infobox.png'),
('Charlotte Mont-d''Or', 'Bộ Trưởng Sách', 120000000, 'Băng Big Mom', 'Bộ trưởng phô mai', 'Buku Buku no Mi', 'Paramecia', 'Tân Thế Giới', 30, 260, 'Còn sống', 'Bộ óc chiến lược thông thái điều khiển mạng lưới liên lạc của đảo Bánh Ngọt. Có thể thao túng không gian bên trong những cuốn sách, nhốt con người vào thế giới ảo mộng vĩnh hằng.', 'https://static.wikia.nocookie.net/onepiece/images/d/d4/Charlotte_Mont-d''Or_Anime_Infobox.png'),
('Bobbin', 'Kẻ Thu Hồi Phí', 105500000, 'Băng Big Mom', 'Đặc vụ thu hồi nợ', 'Không rõ', 'Không rõ', 'Tân Thế Giới', 20, 156, 'Còn sống', 'Chiến binh chuyên đi tàn phá những hòn đảo không nộp đủ kẹo cống nạp cho Big Mom. Có khả năng lắc đầu liên tục tạo ra âm thanh thôi miên gây ngủ kỳ quái.', 'https://static.wikia.nocookie.net/onepiece/images/1/1c/Bobbin_Anime_Infobox.png'),
('Charlotte Opera', 'Bộ Trưởng Kem', 0, 'Băng Big Mom', 'Bộ trưởng Kem tươi', 'Kuri Kuri no Mi', 'Paramecia', 'Tân Thế Giới', 46, 400, 'Còn sống', 'Con trai thứ 5 của Big Mom sở hữu ngoại hình như một cây kem tan chảy khổng lồ. Có thể tạo ra kem tươi tạo nhiệt cực độ để thiêu cháy làn da đối thủ.', 'https://static.wikia.nocookie.net/onepiece/images/5/56/Charlotte_Opera_Anime_Infobox.png'),
('Charlotte Pudding', 'Con gái mắt thứ ba', 0, 'Băng Big Mom', 'Bộ trưởng Chocolate', 'Memo Memo no Mi', 'Paramecia', 'Tân Thế Giới', 16, 166, 'Còn sống', 'Vị hôn thê hụt của Sanji với năng lực chỉnh sửa ký ức. Cô sở hữu con mắt thứ ba bí ẩn của tộc Ba Mắt có khả năng nghe được tiếng nói của vạn vật.', 'https://static.wikia.nocookie.net/onepiece/images/6/60/Charlotte_Pudding_Anime_Infobox.png'),
('Charlotte Galette', 'Bộ Trưởng Bơ', 0, 'Băng Big Mom', 'Bộ trưởng bơ', 'Bata Bata no Mi', 'Paramecia', 'Tân Thế Giới', 31, 170, 'Còn sống', 'Một trong những nữ nhi quyến rũ nhất gia tộc với năng lực tạo ra và điều khiển bơ lỏng nóng chảy để trói chặt và khống chế cử động của kẻ thù.', 'https://static.wikia.nocookie.net/onepiece/images/7/71/Charlotte_Galette_Anime_Infobox.png');

-- THÊM THÀNH VIÊN TỔ CHỨC BAROQUE WORKS CỐT CÁN
INSERT INTO characters (name, alias, bounty, affiliation, role, devil_fruit, devil_fruit_type, hometown, age, height, status, description, image_url) VALUES
('Marianne', 'Miss Goldenweek', 0, 'Baroque Works', 'Cộng sự của Mr. 3', 'Không có', 'Họa sĩ điều khiển cảm xúc', 'Đại Hải Trình', 18, 145, 'Còn sống', 'Họa sĩ nhí kỳ lạ không ăn trái ác quỷ nhưng sở hữu Màu Sắc Phép Thuật có thể hoàn toàn điều khiển ý chí và cảm xúc của người bị vẽ lên người.', 'https://static.wikia.nocookie.net/onepiece/images/b/b4/Marianne_Anime_Infobox.png'),
('Mr. 9', 'Hoàng tử vương miện', 0, 'Baroque Works', 'Đặc vụ biên giới (Cộng sự Vivi)', 'Không có', 'Không có', 'Đại Hải Trình', 31, 185, 'Còn sống', 'Hoàng tử rởm kiêm cộng sự trung thành của Miss Wednesday (Vivi), nổi bật với chiếc vương miện và đôi gậy nhào lộn acrobatics.', 'https://static.wikia.nocookie.net/onepiece/images/e/e4/Mr._9_Anime_Pre_Timeskip_Infobox.png'),
('Gem', 'Mr. 5', 0, 'Baroque Works', 'Đặc vụ biên giới cấp cao', 'Bomu Bomu no Mi', 'Paramecia', 'Đại Hải Trình', 26, 185, 'Còn sống', 'Toàn thân hắn bao gồm cả hơi thở, chất thải đều có thể gây nổ. Thường sử dụng nước bọt tẩm thuốc súng kết hợp bắn súng để tiêu diệt mục tiêu tầm xa.', 'https://static.wikia.nocookie.net/onepiece/images/1/14/Gem_Anime_Infobox.png'),
('Drophy', 'Miss Merry Christmas', 0, 'Baroque Works', 'Cộng sự của Mr. 4', 'Mogu Mogu no Mi', 'Zoan', 'Đại Hải Trình', 51, 156, 'Còn sống', 'Mụ già lùn tịt nói năng tía lia siêu tốc, có thể biến thành chuột chũi để đào những đường hầm bí mật phục vụ những đòn tấn công bất ngờ cùng Mr. 4.', 'https://static.wikia.nocookie.net/onepiece/images/f/f4/Drophy_Anime_Infobox.png'),
('Zala', 'Miss Doublefinger', 0, 'Baroque Works', 'Cộng sự của Mr. 1', 'Toge Toge no Mi', 'Paramecia', 'Đại Hải Trình', 28, 187, 'Còn sống', 'Nữ sát thủ lạnh lùng quyến rũ với bước đi uyển chuyển, có năng lực mọc gai nhọn siêu cứng ở bất cứ đâu trên cơ thể để đâm xuyên kẻ địch.', 'https://static.wikia.nocookie.net/onepiece/images/6/60/Zala_Anime_Infobox.png'),
('Miss Monday', 'Nữ lực sĩ', 0, 'Baroque Works', 'Đặc vụ biên giới', 'Không có', 'Không có', 'Đại Hải Trình', 32, 200, 'Còn sống', 'Nữ đô vật có thể hình cơ bắp đồ sộ vạm vỡ vượt trội hơn đa số đàn ông, chiến đấu bằng sức mạnh vật lý cơ bắp thuần túy với những quả đấm thép.', 'https://static.wikia.nocookie.net/onepiece/images/d/dd/Miss_Monday_Anime_Pre_Timeskip_Infobox.png'),
('Mikita', 'Miss Valentine', 0, 'Baroque Works', 'Cộng sự của Mr. 5', 'Kilo Kilo no Mi', 'Paramecia', 'Đại Hải Trình', 24, 177, 'Còn sống', 'Nữ đặc vụ sở hữu nụ cười chanh chua và năng lực thay đổi trọng lượng cơ thể linh hoạt từ 1kg siêu nhẹ để bay lơ lửng đến 10 tấn khổng lồ để đè bẹp kẻ thù.', 'https://static.wikia.nocookie.net/onepiece/images/b/bc/Mikita_Anime_Infobox.png'),
('Daz Bonez', 'Mr. 1', 0, 'Cross Guild (Cựu Baroque Works)', 'Sĩ quan cao cấp', 'Supa Supa no Mi', 'Paramecia', 'Đại Hải Trình', 31, 212, 'Còn sống', 'Sát thủ đáng sợ nhất Biển Tây, sở hữu năng lực biến mọi bộ phận cơ thể thành lưỡi đao thép cứng cáp. Hiện đã tái xuất giang hồ cùng Crocodile gia nhập Cross Guild.', 'https://static.wikia.nocookie.net/onepiece/images/e/e9/Daz_Bonez_Anime_Infobox.png'),
('Babe', 'Mr. 4', 0, 'Baroque Works', 'Đặc vụ Officer Agent', 'Không có', 'Không có', 'Đại Hải Trình', 30, 218, 'Còn sống', 'Gã to xác phản xạ chậm chạp nhưng sở hữu lực vung chày 4 tấn kinh khủng. Kết hợp cùng khẩu súng chó Lassoo để tạo ra những đòn phối hợp bóng nổ chết người.', 'https://static.wikia.nocookie.net/onepiece/images/d/da/Babe_Anime_Infobox.png');

-- THÊM THÀNH VIÊN HUYỀN THOẠI BĂNG ROCKS
INSERT INTO characters (name, alias, bounty, affiliation, role, devil_fruit, devil_fruit_type, hometown, age, height, status, description, image_url) VALUES
('Rocks D. Xebec', 'Kẻ Hủy Diệt Thế Giới', 0, 'Băng Rocks', 'Thuyền trưởng', 'Không rõ', 'Không rõ', 'Không rõ', 0, 0, 'Đã mất', 'Thuyền trưởng huyền thoại đáng sợ nhất mọi thời đại, tham vọng trở thành ''Vua của thế giới''. Rocks sở hữu thủy thủ đoàn quái vật gồm 3 Tứ hoàng tương lai trước khi bị liên minh Roger và Garp tiêu diệt tại God Valley.', 'https://static.wikia.nocookie.net/onepiece/images/f/fb/Rocks_D._Xebec_Manga_Infobox.png'),
('Captain John', 'Thuyền trưởng John', 0, 'Băng Rocks', 'Thành viên cốt cán', 'Không rõ', 'Không rõ', 'Không rõ', 0, 0, 'Đã mất', 'Một hải tặc khét tiếng ham mê kho báu tột độ từng thuộc Băng Rocks. Sau khi chết, xác của ông đã bị biến thành một Tướng quân Zombie (General Zombie) của Gecko Moria tại Thriller Bark.', 'https://static.wikia.nocookie.net/onepiece/images/b/b1/John_Anime_Infobox.png'),
('Miss Buckingham Stussy', 'Mẹ của Weevil', 0, 'Băng Rocks (Cựu MADS)', 'Thành viên cốt cán', 'Không rõ', 'Không rõ', 'Không rõ', 76, 160, 'Đã mất', 'Người phụ nữ tự xưng là tình nhân của Râu Trắng, cựu thành viên băng Rocks và tổ chức khoa học MADS. Mẫu nhân bản (Clone) thành công đầu tiên của bà hiện là điệp viên Stussy của CP0.', 'https://static.wikia.nocookie.net/onepiece/images/c/c6/Buckingham_Stussy_Anime_Infobox.png'),
('Shiki', 'Sư Tử Vàng', 0, 'Hải Tặc Sư Tử Vàng (Cựu Băng Rocks)', 'Thuyền trưởng', 'Fuwa Fuwa no Mi', 'Paramecia', 'Không rõ', 0, 0, 'Đã mất', 'Cựu thành viên Băng Rocks và là đối thủ truyền kiếp ngang tầm với Gol D. Roger. Sở hữu năng lực điều khiển trọng lực khiến mọi vật thể khổng lồ bay lơ lửng trên bầu trời, người đầu tiên vượt ngục thành công khỏi Impel Down.', 'https://static.wikia.nocookie.net/onepiece/images/3/32/Shiki_Anime_Infobox.png');

-- THÊM THÀNH VIÊN HUYỀN THOẠI BĂNG ROGER
INSERT INTO characters (name, alias, bounty, affiliation, role, devil_fruit, devil_fruit_type, hometown, age, height, status, description, image_url) VALUES
('Crocus', 'Bác Sĩ Ngọn Hải Đăng', 0, 'Băng Roger', 'Bác sĩ của băng', 'Không có', 'Không có', 'Không rõ', 73, 203, 'Còn sống', 'Bác sĩ huyền thoại đã giúp Roger cầm cự qua bạo bệnh để chinh phục Grand Line. Hiện đang chăm sóc chú cá voi Laboon tại Mỏm Núi Song Sinh.', 'https://static.wikia.nocookie.net/onepiece/images/3/34/Crocus_Anime_Infobox.png'),
('Douglas Bullet', 'Kẻ Thừa Kế Của Quỷ', 0, 'Cựu Băng Roger', 'Thành viên cốt cán', 'Gasha Gasha no Mi', 'Paramecia', 'Không rõ', 45, 300, 'Còn sống', 'Quái vật chiến tranh sở hữu sức mạnh vật lý thuần túy khủng khiếp ngang ngửa Rayleigh thời trẻ. Sau khi bị bắt vào Impel Down, hắn đã thoát ra và ôm mộng tiêu diệt tất cả thế hệ mới.', 'https://static.wikia.nocookie.net/onepiece/images/5/54/Douglas_Bullet_Anime_Infobox.png'),
('Scopper Gaban', 'Cánh Tay Trái Của Vua Hải Tặc', 0, 'Băng Roger', 'Thành viên cốt cán / Cựu thuyền trưởng dưới trướng', 'Không có', 'Không có', 'Không rõ', 0, 0, 'Còn sống', 'Đại cao thủ mạnh thứ 3 trong băng Roger, chỉ sau Thuyền trưởng và Thuyền phó. Sử dụng cặp rìu chiến mạnh mẽ, một trong những người hiếm hoi đặt chân đến Laugh Tale.', 'https://static.wikia.nocookie.net/onepiece/images/0/07/Scopper_Gaban_26_Years_Ago.png');

-- THÊM THÀNH VIÊN BĂNG HẢI TẶC MẶT TRỜI
INSERT INTO characters (name, alias, bounty, affiliation, role, devil_fruit, devil_fruit_type, hometown, age, height, status, description, image_url) VALUES
('Hatchan', 'Hachi', 0, 'Băng Arlong (Cựu Băng Mặt Trời)', 'Kiếm sĩ', 'Không có', 'Không có', 'Đảo Người Cá', 38, 220, 'Còn sống', 'Người cá bạch tuộc đa sầu đa cảm sử dụng phái Lục Kiếm. Sau này đã cải tà quy chính, mở quán bán Takoyaki ngon nổi tiếng và trở thành bạn thân hữu của băng Mũ Rơm.', 'https://static.wikia.nocookie.net/onepiece/images/3/3d/Hatchan_Anime_Infobox.png'),
('Aladine', 'Thuyền Phó Băng Mặt Trời', 0, 'Băng Mặt Trời (Tộc Người Cá)', 'Thuyền phó / Bác sĩ', 'Không có', 'Không có', 'Đảo Người Cá', 46, 627, 'Còn sống', 'Thuyền phó trung thành và là bác sĩ y khoa của băng Mặt Trời. Anh đã kết hôn với Charlotte Praline và là lãnh đạo hiện tại gánh vác băng sau khi Jinbe gia nhập băng Mũ Rơm.', 'https://static.wikia.nocookie.net/onepiece/images/0/07/Aladine_Anime_Infobox.png'),
('Chew', 'Cán bộ Chew', 0, 'Băng Arlong (Cựu Băng Mặt Trời)', 'Xạ thủ bắn tỉa', 'Không có', 'Không có', 'Đảo Người Cá', 0, 0, 'Còn sống', 'Cán bộ bắn tỉa của băng Arlong có khả năng bắn những viên nước có uy lực như đạn súng máy.', 'https://static.wikia.nocookie.net/onepiece/images/0/05/Chew_Anime_Infobox.png'),
('Kuroobi', 'Cán bộ Kuroobi', 0, 'Băng Arlong (Cựu Băng Mặt Trời)', 'Cao thủ Karate Người Cá', 'Không có', 'Không có', 'Đảo Người Cá', 0, 0, 'Còn sống', 'Cán bộ cấp cao và là chuyên gia bậc thầy Karate Người Cá cấp độ cao, đối thủ cận chiến hạng nặng của Sanji tại Arlong Park.', 'https://static.wikia.nocookie.net/onepiece/images/1/17/Kuroobi_Anime_Infobox.png');

-- THÊM NHÂN VẬT THUỘC TỘC NGƯỜI CÁ VÀ TIÊN CÁ
INSERT INTO characters (name, alias, bounty, affiliation, role, devil_fruit, devil_fruit_type, hometown, age, height, status, description, image_url) VALUES
('Shirahoshi', 'Công Chúa Tóc Tiên', 0, 'Vương quốc Ryugu (Tộc Người Cá)', 'Công chúa / Vũ khí Cổ đại Poseidon', 'Không có', 'Không có', 'Đảo Người Cá', 16, 1187, 'Còn sống', 'Công chúa tiên cá khổng lồ mang trong mình sức mạnh truyền thuyết có khả năng trò chuyện và ra lệnh cho các Vua Biển khổng lồ.', 'https://static.wikia.nocookie.net/onepiece/images/c/c1/Shirahoshi_Anime_Infobox.png'),
('Neptune', 'Thần Biển Cả', 0, 'Vương quốc Ryugu (Tộc Người Cá)', 'Quốc vương', 'Không có', 'Không có', 'Đảo Người Cá', 70, 1220, 'Còn sống', 'Vua của Đảo Người Cá, chiến binh Merman cá vây chân sở hữu thể lực mạnh mẽ, luôn khao khát hòa bình giữa thế giới mặt đất và biển cả.', 'https://static.wikia.nocookie.net/onepiece/images/4/40/Neptune_Anime_Infobox.png'),
('Camie', 'Người Cá Hôn Nhân', 0, 'Đảo Người Cá (Tộc Người Cá)', 'Thiết kế thời trang học việc', 'Không có', 'Không có', 'Đảo Người Cá', 18, 160, 'Còn sống', 'Cô gái người cá gourami hôn cực kỳ ngây thơ, luôn mơ ước trở thành nhà thiết kế thời trang tài năng.', 'https://static.wikia.nocookie.net/onepiece/images/a/af/Camie_Anime_Post_Timeskip_Infobox.png'),
('Madam Shyarly', 'Nhà Tiên Tri Madam Shyarly', 0, 'Đảo Người Cá (Tộc Người Cá)', 'Chủ quán Mermaid Cafe', 'Không có', 'Không có', 'Đảo Người Cá', 29, 520, 'Còn sống', 'Người cá mập mako và là em gái cùng cha khác mẹ của Arlong. Sở hữu khả năng tiên tri chính xác tuyệt đối tương lai.', 'https://static.wikia.nocookie.net/onepiece/images/6/61/Shyarly_Anime_Infobox.png'),
('Hody Jones', 'Kẻ Kế Thừa Căm Thù', 0, 'Băng Người Cá Mới (Tộc Người Cá)', 'Thuyền trưởng', 'Không có', 'Không có', 'Đảo Người Cá', 30, 331, 'Còn sống', 'Thuyền trưởng cuồng tín kế thừa ý chí cực đoan nhất của Arlong, lạm dụng thuốc năng lượng E.S để cố gắng lật đổ vương quốc Ryugu.', 'https://static.wikia.nocookie.net/onepiece/images/f/f3/Hody_Jones_Anime_Infobox.png'),
('Tom', 'Thợ Đóng Tàu Huyền Thoại', 0, 'Công ty Tom Workers (Tộc Người Cá)', 'Chủ tịch công ty', 'Không có', 'Không có', 'Đảo Người Cá', 67, 296, 'Đã mất', 'Người cá bò khổng lồ, người đã đóng nên con tàu Oro Jackson của Vua Hải Tặc Roger và sáng chế thành công đoàn tàu trên biển Puffing Tom. Sư phụ tôn kính của Franky.', 'https://static.wikia.nocookie.net/onepiece/images/a/a9/Tom_Anime_Infobox.png');
