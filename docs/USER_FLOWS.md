# User Flows

## 1. First Launch

```text
Launch App
  ↓
Initialize localization
  ↓
Load environment
  ↓
Initialize Hive boxes
  ↓
Restore profile preferences
  ↓
Restore auth session from secure storage
  ↓
Open Home
```

Expected behavior:

- App ต้องเปิดได้แม้ไม่มี TMDB token
- ถ้าไม่มี network ให้ใช้ stale cache หรือ mock fallback
- ถ้ามี auth session ที่ valid ให้ restore โดยไม่บังคับ login

## 2. Sign In

```text
Profile
  ↓
Open Login
  ↓
Enter Email + Password
  ↓
Validate
  ├── Invalid → show localized error
  └── Valid
       ↓
Demo Auth API
       ↓
Save secure session
       ↓
Return to Profile
```

## 3. Session Refresh

```text
Authenticated operation
  ↓
Request validSession()
  ↓
Token expired?
  ├── No → continue
  └── Yes
       ↓
Use existing refresh Future or create one
       ↓
Refresh accepted?
  ├── Yes → persist new token → continue
  └── No  → clear session → unauthenticated
```

## 4. Home Feed with Cache

```text
Open Home
  ↓
Read Trending cache
  ↓
Fresh?
  ├── Yes → show cache immediately
  └── No
       ↓
Call TMDB
       ↓
Success?
  ├── Yes → save cache → show network result
  └── No
       ↓
Stale cache exists?
  ├── Yes → show stale cache + notice
  └── No  → show mock data + notice
```

## 5. Search with Debounce

```text
User types query
  ↓
Restart debounce timer
  ↓
No new input within delay
  ↓
Start request with generation N
  ↓
Newer generation exists when result returns?
  ├── Yes → ignore old result
  └── No  → publish result
```

## 6. Search Pagination

```text
Initial Search
  ↓
Load page 1
  ↓
Render results
  ↓
User approaches list end
  ↓
hasMore?
  ├── No → stop
  └── Yes
       ↓
Load page + 1
       ↓
Append items
```

## 7. Add Movie to Watchlist

```text
Movie Detail
  ↓
Add to Watchlist
  ↓
Choose status/rating/date/notes
  ↓
Save
  ↓
WatchlistController
  ↓
Hive
  ↓
Reload state
  ↓
Watchlist/Home preview updates
```

## 8. Change Language

```text
Profile
  ↓
Language
  ↓
Select English / Thai
  ↓
EasyLocalization setLocale
  ↓
Persist languageCode
  ↓
UI rebuilds in selected locale
```

## 9. Offline to Online Recovery

```text
Connectivity Stream emits offline
  ↓
Keep visible data
  ↓
Show offline indication
  ↓
Connectivity emits online
  ↓
Trigger targeted refresh
  ↓
Replace stale data only after successful response
```

## 10. App Background / Foreground

```text
App becomes inactive/paused
  ↓
Pause media/resource
  ↓
App returns resumed
  ↓
Resume safe resource
  ↓
Optionally validate session / refresh stale data
```
