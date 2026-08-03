# Acceptance Criteria

Acceptance Criteria ใช้รหัสอ้างอิงเพื่อเชื่อม Product Requirement, implementation, test และ defect report

## Authentication

### AC-AUTH-001 Login Success

Given ผู้ใช้กรอก email ที่มี `@` และ password อย่างน้อย 6 ตัวอักษร
When ผู้ใช้กด Sign in
Then ระบบสร้าง authenticated session
And บันทึก access token, refresh token และ expiry ลง secure storage
And ไม่บันทึก token ลง Hive, SharedPreferences หรือ log

### AC-AUTH-002 Invalid Credentials

Given email หรือ password ไม่ผ่าน validation ของ demo auth
When ผู้ใช้กด Sign in
Then หน้า Login ยังคงแสดงอยู่
And แสดง localized error
And ไม่มี session ถูกบันทึก

### AC-AUTH-003 Session Restoration

Given มี session ที่ยังไม่หมดอายุใน secure storage
When application เริ่มทำงานและ AuthController build
Then authenticated state ถูก restore โดยไม่เรียก refresh endpoint

### AC-AUTH-004 Concurrent Refresh

Given token หมดอายุ
And มี request อย่างน้อย 2 รายการเรียก `validSession()` พร้อมกัน
When repository refresh session
Then remote refresh ถูกเรียกเพียงครั้งเดียว
And callers ทั้งหมดได้รับ session ใหม่เดียวกัน

### AC-AUTH-005 Invalid Refresh Token

Given refresh token ถูกปฏิเสธ
When application restore session
Then local token ถูกลบ
And auth state กลับเป็น unauthenticated

## Cache and Network

### AC-CACHE-001 Fresh Cache

Given Trending cache ยังอยู่ใน TTL
When Home ขอ Trending feed โดยไม่ได้ force refresh
Then repository คืน fresh cache
And ไม่เรียก TMDB

### AC-CACHE-002 Expired Cache Refresh

Given cache หมดอายุ
When Home ขอ Trending feed
Then repository เรียก TMDB
And บันทึก response ใหม่พร้อม timestamp
And source metadata เป็น network

### AC-CACHE-003 Stale Cache Fallback

Given มี stale cache
And TMDB request ล้มเหลว
When repository โหลด Trending feed
Then repository คืน stale cache
And failure metadata ไม่เป็น null
And UI แสดง stale/offline notice โดยไม่ล้าง movie list

### AC-CACHE-004 Mock Fallback

Given ไม่มี cache
And TMDB request ล้มเหลว
When repository โหลด Trending feed
Thenคืน deterministic mock movies
And source metadata เป็น mock

## Search

### AC-SEARCH-001 Latest Result Wins

Given ผู้ใช้ส่ง search request หลายครั้งติดกัน
When request เก่าเสร็จหลัง request ใหม่
Then result เก่าไม่สามารถทับ result ใหม่

### AC-SEARCH-002 Pagination Metadata

Given TMDB search response มี `page` และ `total_pages`
When data source map response
Then `PagedMovies.page` และ `totalPages` ตรงกับ response
And `hasMore` เป็นจริงเมื่อ page < totalPages

### AC-SEARCH-003 Append Page

Given มี page เดิมและ page ถัดไป
When `append(next)` ถูกเรียก
Then items เดิมอยู่ก่อน items ใหม่
And page/totalPages ใช้ค่าจาก page ถัดไป

## Watchlist

### AC-WATCHLIST-001 Persist Item

Given ผู้ใช้อยู่หน้า Movie Detail
When เพิ่มหนังลง Watchlist และกด Save
Then item ถูกเขียนลง Hive
And Watchlist provider อัปเดต
And item ยังคงอยู่หลัง restart

### AC-WATCHLIST-002 Watched Statistics

Givenมี watched items ที่มี runtime และ rating
Whenเปิดหน้า Watchlist
Then total movies, total hours และ average rating คำนวณจาก watched items เท่านั้น

## Profile and Localization

### AC-PROFILE-001 Edit Profile

Givenผู้ใช้อยู่หน้า Profile
Whenแก้ display name, email และ favorite genre แล้ว Save
Thenค่าถูก normalize และ persist ลง Hive

### AC-LOCALE-001 Runtime Language

Given application ใช้ English
Whenผู้ใช้เลือก Thai
Thenข้อความที่ localized เปลี่ยนเป็น Thai โดยไม่ restart
Andค่า languageCode ถูก persist

## Responsive

### AC-RESPONSIVE-001 Ratio Classification

Givenหน้าจอสองขนาดมี width/height ratio เท่ากัน
When layout policy ประเมิน screen size
Thenทั้งสองหน้าจอได้ ratio class และจำนวน column เดียวกัน

### AC-RESPONSIVE-002 Orientation Change

Givenผู้ใช้หมุนอุปกรณ์จาก portrait เป็น landscape
When MediaQuery size เปลี่ยน
Then grid และ padding ถูกคำนวณใหม่จาก ratio ปัจจุบัน
Andไม่มี overflow

## Lifecycle and Diagnostics

### AC-LIFECYCLE-001 Pause Resource

Givenหน้าที่มี media/resource ใช้งานอยู่
When application เข้า inactive/paused
Then lifecycle callback สำหรับ pause ถูกเรียก

### AC-LIFECYCLE-002 Resume

When application กลับ resumed
Then callback resume ถูกเรียกหนึ่งครั้งต่อ lifecycle transition

### AC-LOG-001 Redaction

Given logger context มี token, password หรือ email
When logger เขียน context
Thenค่าที่ sensitive ถูกแทนด้วย `<redacted>`

## CI and Release

### AC-CI-001 Pull Request Validation

Whenเปิด Pull Request ไป main
Then CI ต้องตรวจ format, static analysis, host tests และ coverage threshold

### AC-CI-002 Coverage Gate

Given line coverage ต่ำกว่า `COVERAGE_MIN`
Whenรัน `make coverage-check`
Then command ต้องจบด้วย non-zero exit code
