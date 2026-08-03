# Code Review Checklist

## Requirement and Scope

- [ ] PR อ้างอิง Requirement หรือ Acceptance Criteria ID
- [ ] Scope ตรงกับ PR title/description
- [ ] ไม่มี unrelated refactor ที่เพิ่มความเสี่ยงโดยไม่จำเป็น
- [ ] Known limitations และ follow-up ถูกระบุ

## Architecture

- [ ] UI ไม่เรียก Dio/Hive/Secure Storage โดยตรงโดยไม่มีเหตุผล
- [ ] Domain ไม่ import Flutter UI หรือ data implementation
- [ ] Repository เป็น boundary ของ data policy
- [ ] Provider/controller มี lifecycle ชัดเจน
- [ ] Dependency สามารถ override ใน test ได้

## State and Async

- [ ] Loading/error/data state ครบ
- [ ] ป้องกัน duplicate request
- [ ] ป้องกัน old result ทับ latest result
- [ ] Timer/controller/subscription ถูก dispose
- [ ] `mounted` ถูกตรวจหลัง await เมื่อใช้ BuildContext/setState
- [ ] pagination มี `isLoadingMore` และ `hasMore` guard

## Network

- [ ] Timeout และ typed failure ถูก map
- [ ] 401/refresh ไม่เกิด infinite loop
- [ ] 429 retry มี limit
- [ ] retry ไม่ duplicate non-idempotent request
- [ ] offline/stale data UX ไม่ล้างข้อมูลเดิม
- [ ] request/response log ไม่เผย token หรือ PII

## Authentication and Security

- [ ] Token อยู่ใน secure storage
- [ ] Password/token ไม่อยู่ใน source, Hive หรือ SharedPreferences
- [ ] Concurrent refresh ถูก deduplicate
- [ ] Invalid refresh token clear session
- [ ] Logout clear credential
- [ ] Sensitive fields ถูก redact จาก logger

## Persistence and Cache

- [ ] Schema/serialization backward compatibility ถูกพิจารณา
- [ ] Cache key รวม parameter ที่มีผล เช่น locale/query
- [ ] TTL policy มี test
- [ ] stale cache behavior มี test
- [ ] write failure ไม่ทำให้ usable data หาย

## UI/UX

- [ ] รองรับ EN/TH
- [ ] ไม่มี hard-coded user-facing string ที่ควร localize
- [ ] ratio-based responsive policy ถูกใช้ตามข้อตกลง
- [ ] orientation change ไม่ overflow
- [ ] loading/error/empty/offline state ชัดเจน
- [ ] semantics/tooltip/keyboard behavior ถูกพิจารณา

## Performance

- [ ] ไม่มีงานหนักใน build
- [ ] list/grid ใช้ lazy builder เมื่อเหมาะสม
- [ ] image size/caching เหมาะกับ render size
- [ ] controller/player ถูก dispose
- [ ] provider scope ไม่ทำให้ rebuild กว้างเกินไป

## Testing

- [ ] Unit test ครอบคลุม policy/branch สำคัญ
- [ ] Widget test ครอบคลุม user-visible state
- [ ] Integration test ครอบคลุม critical flow เมื่อเหมาะสม
- [ ] Golden baseline update ถูก review ด้วยสายตา
- [ ] Test deterministic และไม่พึ่ง external API
- [ ] `make check` ผ่าน
- [ ] `make coverage-check` ผ่าน

## Release

- [ ] Version/build impact ถูกระบุ
- [ ] Environment/flavor impact ถูกระบุ
- [ ] Signing/secrets ไม่ถูก commit
- [ ] Migration/rollback ถูกพิจารณา
- [ ] Documentation ถูกอัปเดต
