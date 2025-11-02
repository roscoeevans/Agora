# 🚀 Direct Messages - Quick Reference

**Status**: ✅ Deployed to Staging | ⏳ Ready to Test  
**Date**: October 31, 2025

---

## 📦 What Was Deployed

### Backend (Staging: `iqebtllzptardlgpdnge`)
- ✅ **4 RPC Functions** (create_dm_thread, fetch_user_conversations, fetch_thread_messages, send_dm_message)
- ✅ **Realtime** (dms_threads, dms_messages, dms_participants)
- ✅ **RLS Policies** (active and verified)

### iOS App
- ✅ **Service Implementation** (`MessagingServiceLive`, `MessagingRealtimeObserver`)
- ✅ **UI Components** (`DirectMessages` feature package)
- ✅ **Dependency Injection** (wired in `AgoraApp.swift`)

---

## 🧪 Quick Test (2 Minutes)

### Prerequisites
- 2 devices/simulators
- 2 different user accounts
- Staging build of iOS app

### Test Steps
1. **Device A**: Open DM tab → Create conversation with User B
2. **Device A**: Send message "Hello!"
3. **Device B**: Open DM tab → Should see conversation instantly
4. **Device B**: Open conversation → Should see "Hello!" instantly
5. **Device B**: Reply "Hi back!"
6. **Device A**: Should see reply instantly (no refresh)

**Expected**: ✅ All messages appear in real-time without refresh

---

## 📚 Documentation

| Document | Purpose | Location |
|----------|---------|----------|
| **DM_DEPLOYMENT_COMPLETE.md** | Full deployment record | Root |
| **DM_TESTING_GUIDE.md** | Comprehensive test cases | Root |
| **DM_DEPLOYMENT_PLAN_COMPLETE.md** | Deployment plan summary | Root |
| **MVP_CHECKLIST.md** | Overall project status | Root |

---

## 🔍 Quick Checks

### Verify Backend Deployment
```sql
-- In Supabase SQL Editor (Staging)
-- Check functions exist
SELECT proname FROM pg_proc 
WHERE proname IN ('create_dm_thread', 'fetch_user_conversations', 'fetch_thread_messages', 'send_dm_message');

-- Check Realtime configured
SELECT tablename FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime' 
AND tablename IN ('dms_threads', 'dms_messages', 'dms_participants');
```

**Expected**: 4 functions + 3 tables in Realtime publication

### Verify iOS Configuration
```bash
# Clean build
agctl clean && agctl build

# Verify Messaging package compiles
agctl build Messaging
agctl build DirectMessages

# Run tests
agctl test Messaging
```

### Test RPC Function Directly
```sql
-- Create test conversation
SELECT * FROM create_dm_thread(
  gen_random_uuid(),           -- thread_id
  '1:1',                       -- kind
  ARRAY['USER_A_ID', 'USER_B_ID']::TEXT[]  -- user_ids
);

-- Fetch conversations
SELECT * FROM fetch_user_conversations('USER_A_ID', 10, 0);
```

---

## 🐛 Common Issues

### Issue: "Function does not exist"
**Fix**: RPC functions not deployed → Re-run migration
```sql
-- Check if functions exist
SELECT proname FROM pg_proc WHERE proname LIKE '%dm%';
```

### Issue: "Real-time not working"
**Fix**: Realtime not configured → Check publication
```sql
SELECT * FROM pg_publication_tables WHERE pubname = 'supabase_realtime';
```

### Issue: "User not a participant"
**Fix**: RLS policy blocking → Check user is in dms_participants
```sql
SELECT * FROM dms_participants WHERE user_id = 'YOUR_USER_ID';
```

### Issue: iOS "No conversations found"
**Fix**: Check console logs for errors
```swift
// Filter Xcode console by: [DM] or [Realtime]
```

---

## 🚀 Next Steps

1. **Now**: Test DM flow on Staging (see `DM_TESTING_GUIDE.md`)
2. **After Tests Pass**: Deploy to Production
3. **Production Deploy**: Apply same migration + Realtime config to `agora-prod`

---

## 📞 Quick Links

- **Staging Dashboard**: https://supabase.com/dashboard/project/iqebtllzptardlgpdnge
- **Production Dashboard**: https://supabase.com/dashboard/project/gnvavfpjjbkabcmsztui
- **iOS Service Code**: `Packages/Kits/Messaging/Sources/Messaging/MessagingServiceLive.swift`
- **iOS UI Code**: `Packages/Features/DirectMessages/Sources/DirectMessages/`
- **Migration File**: `database/migrations/999_dm_rpc_functions.sql`

---

## ✅ Production Deployment (When Ready)

### Prerequisites
- [ ] All Staging tests pass
- [ ] No P0/P1 bugs
- [ ] Performance benchmarks met

### Deploy Commands
```sql
-- 1. Apply migration to Production (agora-prod: gnvavfpjjbkabcmsztui)
-- Use Supabase MCP or SQL Editor
-- Execute: database/migrations/999_dm_rpc_functions.sql

-- 2. Configure Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE dms_threads;
ALTER PUBLICATION supabase_realtime ADD TABLE dms_messages;
ALTER PUBLICATION supabase_realtime ADD TABLE dms_participants;

-- 3. Verify
SELECT proname FROM pg_proc WHERE proname LIKE '%dm%';
SELECT * FROM pg_publication_tables WHERE pubname = 'supabase_realtime';
```

---

## 🎯 Success Criteria

**Must Work**:
- ✅ Create conversation
- ✅ Send message
- ✅ Receive in real-time (< 2s)
- ✅ Load history with pagination
- ✅ Conversation list updates
- ✅ RLS prevents unauthorized access

**Performance**:
- ✅ Send latency: < 500ms
- ✅ Real-time delivery: < 2s
- ✅ Pagination: < 500ms

---

**🎉 DMs are ready! Start testing with `DM_TESTING_GUIDE.md`**


