# Direct Messages - Testing Guide

**Environment**: Staging (`iqebtllzptardlgpdnge`)  
**Status**: Backend Deployed, Ready for End-to-End Testing  
**Last Updated**: October 31, 2025

---

## 🎯 Quick Start

Direct Messages are **100% deployed to Staging** and ready to test. The iOS app can now:
- Create conversations
- Send messages
- Receive messages in real-time
- Load message history with pagination
- Display conversation lists

---

## ✅ Pre-Test Checklist

### iOS App Configuration
1. **Build Configuration**: Ensure Xcode is using **Staging** scheme
2. **Supabase URL**: Verify `Resources/Configs/Staging.plist` has correct URL
3. **API Keys**: Verify staging keys are configured
4. **Clean Build**: Run `agctl clean && agctl build` to ensure fresh build

### Backend Verification (Already Deployed)
- ✅ 4 RPC functions deployed
- ✅ Realtime enabled for DM tables
- ✅ RLS policies active
- ✅ Database schema matches Swift models

---

## 🧪 Test Cases

### Test 1: Create New Conversation (Basic)

**Steps**:
1. Launch app on Device A
2. Sign in as User A
3. Navigate to **DM tab** (bottom nav)
4. Tap **"+"** or **"New Message"** button
5. Search for User B
6. Select User B from results
7. Verify conversation appears in list

**Expected Result**:
- ✅ Conversation appears with User B's avatar and name
- ✅ "No messages yet" or empty state shown
- ✅ Conversation ID is generated correctly
- ✅ Both users are listed as participants

**Debug Points**:
- Console should show: `[DM] Creating conversation with user: [USER_B_ID]`
- Check: `create_dm_thread` RPC called successfully
- Check: Conversation inserted into `dms_threads` table

---

### Test 2: Send Message

**Steps**:
1. Continue from Test 1
2. Tap into conversation with User B
3. Type message: "Hello from User A!"
4. Tap **Send**
5. Verify message appears in thread

**Expected Result**:
- ✅ Message appears immediately with timestamp
- ✅ Message shows User A as sender
- ✅ Send button disabled during send
- ✅ Text input cleared after send
- ✅ Conversation updated in thread list

**Debug Points**:
- Console: `[DM] Sending message to thread: [THREAD_ID]`
- Console: `[DM] Message sent: [MESSAGE_ID]`
- Check: `send_dm_message` RPC called
- Check: `dms_messages` table has new row

---

### Test 3: Receive Message in Real-Time (Two Devices Required)

**Setup**: Use 2 devices/simulators with different users

**Steps**:
1. Device A (User A): Open conversation with User B
2. Device B (User B): Open conversation with User A
3. Device A: Send message "Test message 1"
4. Device B: **DO NOT REFRESH** - message should appear automatically
5. Device B: Send reply "Test message 2"
6. Device A: **DO NOT REFRESH** - reply should appear automatically

**Expected Result**:
- ✅ Device B receives message instantly (within 1-2 seconds)
- ✅ Device A receives reply instantly
- ✅ No pull-to-refresh required
- ✅ Messages appear in correct order
- ✅ Timestamps are accurate

**Debug Points**:
- Console: `[Realtime] Subscribed to dms_messages`
- Console: `[Realtime] Received message: [MESSAGE]`
- Check: Realtime subscription status in Supabase Dashboard
- Check: WebSocket connection active

---

### Test 4: Message Pagination

**Steps**:
1. Create conversation with 60+ messages (use loop or manual sending)
2. Open conversation
3. Scroll to **top** of message list
4. Verify older messages load automatically

**Expected Result**:
- ✅ First load shows 50 most recent messages
- ✅ Scrolling to top loads next 50 older messages
- ✅ Smooth loading without jank
- ✅ No duplicate messages
- ✅ Correct chronological order maintained

**Debug Points**:
- Console: `[DM] Loading more messages before: [TIMESTAMP]`
- Console: `[DM] Loaded [COUNT] additional messages`
- Check: `fetch_thread_messages` called with `before_timestamp`

---

### Test 5: Conversation List Updates

**Steps**:
1. Have 3+ conversations with different users
2. Send message in conversation B
3. Verify conversation B moves to top of list
4. Send message in conversation C
5. Verify conversation C moves to top

**Expected Result**:
- ✅ Conversations sorted by `updated_at` (most recent first)
- ✅ Last message preview shows correct text
- ✅ Timestamps update correctly
- ✅ Unread counts update (if implemented)

**Debug Points**:
- Console: `[DM] Fetching conversations for user: [USER_ID]`
- Console: `[DM] Conversation count: [COUNT]`
- Check: `fetch_user_conversations` returns correct order

---

### Test 6: Realtime Conversation Updates (Two Devices)

**Steps**:
1. Device A: Open DM tab (conversation list)
2. Device B: Send message to User A
3. Device A: **DO NOT REFRESH** - conversation should update in list

**Expected Result**:
- ✅ Conversation list updates in real-time
- ✅ New conversation appears at top
- ✅ Last message preview updates
- ✅ Timestamp updates
- ✅ Badge or indicator for new message (if implemented)

**Debug Points**:
- Console: `[Realtime] Subscribed to dms_threads`
- Console: `[Realtime] Thread updated: [THREAD_ID]`

---

### Test 7: Edge Cases

#### Empty States
- [ ] Empty conversation list shows "No conversations yet"
- [ ] Empty conversation shows "Send the first message"
- [ ] Search with no results shows "No users found"

#### Long Messages
- [ ] Send 1000+ character message
- [ ] Verify message displays correctly (wrapped)
- [ ] Verify send succeeds

#### Rapid Messaging
- [ ] Send 10 messages in quick succession
- [ ] Verify all messages appear
- [ ] Verify correct order
- [ ] No dropped messages

#### Network Issues
- [ ] Turn off WiFi/cellular
- [ ] Attempt to send message
- [ ] Verify error message
- [ ] Turn network back on
- [ ] Verify message sends when reconnected

#### User Not Found
- [ ] Try creating conversation with invalid user ID
- [ ] Verify error handling

#### Unauthorized Access
- [ ] Try fetching messages from thread user isn't in
- [ ] Verify error: "User is not a participant in this thread"

---

## 🐛 Known Issues & Workarounds

### Issue: Typing Indicators Not Working
**Status**: Deferred for MVP  
**Reason**: Needs Supabase Broadcast channel configuration  
**iOS Structure**: Observer structure ready in `MessagingRealtimeObserver`  
**Workaround**: None needed for MVP

### Issue: Read Receipts Not Tracking
**Status**: Deferred for MVP  
**Reason**: Needs backend `dms_read_receipts` table  
**iOS Structure**: Observer structure ready  
**Workaround**: Unread count currently counts all messages not authored by user

### Issue: Message Attachments Not Supported
**Status**: Deferred for MVP  
**iOS Structure**: `MessagingMediaLive` exists but stubbed  
**Workaround**: Text-only messages for MVP

---

## 🔍 Debugging Tips

### View RPC Function Code
```sql
-- In Supabase SQL Editor
SELECT proname, prosrc FROM pg_proc 
WHERE proname IN ('create_dm_thread', 'fetch_user_conversations', 'fetch_thread_messages', 'send_dm_message');
```

### Check Realtime Publications
```sql
SELECT schemaname, tablename 
FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime' 
AND tablename IN ('dms_threads', 'dms_messages', 'dms_participants');
```

### Query Messages Directly
```sql
-- Check message count
SELECT COUNT(*) FROM dms_messages;

-- View recent messages
SELECT * FROM dms_messages ORDER BY created_at DESC LIMIT 10;

-- Test RPC directly
SELECT * FROM fetch_user_conversations('YOUR_USER_ID', 10, 0);
```

### iOS Logs to Watch
```swift
// Enable verbose logging in MessagingServiceLive.swift
print("[DM] Fetching conversations for user: \(userId)")
print("[DM] Loaded \(conversations.count) conversations")
print("[DM] Sending message to thread: \(threadId)")
print("[DM] Message sent successfully: \(message.id)")

// Realtime logs in MessagingRealtimeObserver.swift
print("[Realtime] Subscribed to dms_messages")
print("[Realtime] Received new message: \(message)")
print("[Realtime] Thread updated: \(thread)")
```

### Supabase Dashboard Monitoring
1. **Realtime**: Dashboard → Realtime → Check active connections
2. **Database**: Dashboard → Database → SQL Editor → Run test queries
3. **Functions**: Dashboard → Database → Functions → View execution logs
4. **Logs**: Dashboard → Logs → Filter by "postgres"

---

## ✅ Test Results Template

**Date**: [YYYY-MM-DD]  
**Tester**: [Your Name]  
**Environment**: Staging  
**iOS Version**: [e.g., 26.0]  
**Device**: [e.g., iPhone 15 Pro Simulator]

### Results

| Test Case | Status | Notes |
|-----------|--------|-------|
| Create Conversation | ✅ PASS / ❌ FAIL | |
| Send Message | ✅ PASS / ❌ FAIL | |
| Receive Real-time | ✅ PASS / ❌ FAIL | |
| Message Pagination | ✅ PASS / ❌ FAIL | |
| Conversation List | ✅ PASS / ❌ FAIL | |
| Realtime List Updates | ✅ PASS / ❌ FAIL | |
| Edge Cases | ✅ PASS / ❌ FAIL | |

### Issues Found
1. [Issue description]
2. [Issue description]

### Performance Notes
- Message send latency: [e.g., ~200ms]
- Real-time delivery latency: [e.g., ~1-2s]
- Pagination load time: [e.g., ~300ms]

---

## 🚀 Production Deployment Checklist

**After Staging Tests Pass**:

1. **Deploy to Production** (Project: `gnvavfpjjbkabcmsztui`)
   ```bash
   # Use Supabase MCP or SQL Editor
   # Apply dm_rpc_functions migration to agora-prod
   ```

2. **Configure Realtime on Production**
   ```sql
   ALTER PUBLICATION supabase_realtime ADD TABLE dms_threads;
   ALTER PUBLICATION supabase_realtime ADD TABLE dms_messages;
   ALTER PUBLICATION supabase_realtime ADD TABLE dms_participants;
   ```

3. **Verify Production**
   - [ ] RPC functions deployed
   - [ ] Realtime configured
   - [ ] RLS policies active
   - [ ] Test DM flow on production build

4. **Monitor Production**
   - [ ] Check error rates
   - [ ] Monitor Realtime connections
   - [ ] Watch database performance

---

## 📞 Support

**Documentation**:
- `DM_DEPLOYMENT_COMPLETE.md` - Full deployment record
- `MVP_CHECKLIST.md` - Overall project status

**Supabase**:
- Dashboard: https://supabase.com/dashboard/project/iqebtllzptardlgpdnge
- Database: Database → SQL Editor
- Realtime: Realtime tab
- Logs: Logs tab

**iOS Code**:
- Service: `Packages/Kits/Messaging/Sources/Messaging/MessagingServiceLive.swift`
- Realtime: `Packages/Kits/Messaging/Sources/Messaging/MessagingRealtimeObserver.swift`
- UI: `Packages/Features/DirectMessages/Sources/DirectMessages/`

**Questions?** Check console logs with filters: `[DM]`, `[Realtime]`


