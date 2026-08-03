# Product Requirements — Popcorn Movie Tracker

## Product Goal

Popcorn ช่วยผู้ใช้ค้นหาภาพยนตร์ ดูข้อมูลประกอบการตัดสินใจ บันทึกรายการที่สนใจ เก็บประวัติการรับชม และใช้งานต่อได้เมื่อเครือข่ายไม่เสถียร

## Primary Users

- ผู้ใช้ที่ต้องการค้นหาหนังใหม่
- ผู้ใช้ที่ต้องการบันทึก Watchlist
- ผู้ใช้ที่ต้องการเก็บสถานะ Watched/Favorite และ Personal Rating
- Reviewer ที่ต้องการประเมิน Flutter architecture, network, persistence และ testing

## Functional Requirements

### FR-MOVIE-001 Movie Discovery

ระบบต้องแสดง Trending, Popular, Top Rated, Upcoming และ Now Playing จาก TMDB หรือ fallback ที่ระบุแหล่งข้อมูลได้

### FR-MOVIE-002 Movie Detail

ระบบต้องแสดง title, overview, rating, release year, runtime, genres, cast, trailer และ similar movies เมื่อข้อมูลมีอยู่

### FR-SEARCH-001 Search

ผู้ใช้ต้องค้นหาภาพยนตร์ด้วยข้อความได้ ระบบต้องป้องกันผลลัพธ์ request เก่าทับ request ใหม่ และรองรับ pagination contract

### FR-WATCHLIST-001 Local Watchlist

ผู้ใช้ต้องเพิ่มหนังเป็น Want to Watch, Watched หรือ Favorite พร้อม rating, note และ watched date ได้ ข้อมูลต้องคงอยู่หลัง restart

### FR-PROFILE-001 Profile

ผู้ใช้ต้องแก้ display name, email และ favorite genre ได้

### FR-LOCALE-001 Localization

ผู้ใช้ต้องเปลี่ยน English/Thai ระหว่าง runtime และค่าภาษาต้อง persist

### FR-AUTH-001 Demo Authentication

ระบบต้องสาธิต login/logout, session restoration, secure token persistence และ synchronized refresh โดยไม่อ้างว่าเป็น backend security system จริง

### FR-CACHE-001 Cache

Trending feed ต้องใช้ fresh cache ภายใน TTL, refresh เมื่อหมดอายุ, fallback stale cache เมื่อ network fail และ fallback mock เมื่อไม่มี cache

### FR-NETWORK-001 Recovery

ระบบต้องจัดการ timeout, offline, 429, unauthorized, server และ parsing failures โดยไม่ล้างข้อมูลที่ยังใช้งานได้โดยไม่จำเป็น

### FR-RESPONSIVE-001 Ratio Layout

Home, Search และ Watchlist ต้องตัดสินใจ layout จาก `width / height` ตาม policy ที่กำหนด ไม่ใช้ absolute width breakpoint เป็นเงื่อนไขหลัก

## Non-Functional Requirements

### NFR-ARCH-001 Maintainability

UI ต้องไม่เรียก Dio/Hive/Secure Storage โดยตรงเมื่อสามารถผ่าน provider/repository/data source ได้

### NFR-SEC-001 Credential Storage

Access/refresh token ต้องไม่เก็บใน SharedPreferences, source code, log หรือ crash context

### NFR-TEST-001 Automated Tests

Critical policy ต้องมี unit/widget/integration test และ CI ต้อง enforce format, analysis, tests และ coverage threshold

### NFR-PERF-001 Performance

List/Grid ต้องใช้ lazy builder เมื่อข้อมูลอาจเติบโต, หลีกเลี่ยงงานหนักใน build และบันทึกขั้นตอน profiling ไว้ในเอกสาร

### NFR-OBS-001 Observability

ระบบต้องมี structured logging, redaction และ crash reporter abstraction

## Out of Scope

- Production identity provider
- Payment
- Social features
- Real push notification delivery
- Cloud watchlist sync
- App Store/Play Store credentials
