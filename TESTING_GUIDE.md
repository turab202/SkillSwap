# SkillSwap Web - Testing Guide

## Overview
You now have a fully functional web version of SkillSwap with 10 core features. This guide walks you through testing each one.

## Prerequisites
1. Make sure you have a local `.env` file with real Firebase credentials (not `.env.example`)
2. Start the dev server: `npm run dev` from the `web` directory
3. The app runs on `http://localhost:3000`

---

## Feature Testing Checklist

### 1. **Authentication** ✓
**Test with:**
- Email/password signup
- Email/password signin
- Google Sign-In
- Persistent session (close browser, reopen app - should stay logged in)

**Expected:**
- New user profile created in Firestore `users` collection
- Profile marked as `profileComplete: false` initially
- Browser session persists via localStorage

**Navigate to:** http://localhost:3000

---

### 2. **Profile Editor** ✓
**Test with:**
- Click "My profile" button in the dashboard sidebar
- Edit fields:
  - Name (required)
  - Location
  - Skills offered (comma-separated)
  - Skills wanted (comma-separated)
  - Experience level (Novice/Expert/Master)
  - Availability
  - Bio

**Expected:**
- Form saves to Firestore `users/{uid}` collection
- `profileComplete` is set to `true` after saving
- User immediately becomes discoverable

**Navigate to:** Dashboard → My Profile button

---

### 3. **Dashboard (Home)** ✓
**Test with:**
- Login as a user with complete profile
- View welcome message with first name
- See community impact stats:
  - People Helped
  - Skills Shared
  - Projects Joined
  - Mentorship Sessions
  - Volunteer Activities
- See quick action cards:
  - Start Discovering People
  - Manage Your Profile
  - View Skill Swaps
  - Browse Posts
  - Community Feed

**Expected:**
- All stats display (may be 0 for new users)
- Navigation links work smoothly

**Navigate to:** Dashboard (default on login)

---

### 4. **Discover People** ✓
**Test with:**
- Click "Discover" in sidebar
- Search by name or skill
- Filter by skill type dropdown
- View people cards showing:
  - Name, location, experience level
  - Bio
  - Skills offered
- Click "View profile" to see full profile
- Click "Start Skill Swap" to propose exchange

**Expected:**
- Only users with `profileComplete: true` appear
- Search/filter updates in real-time
- Profile dialog shows endorsements and reviews
- Profile dialog has "Give Endorsement" button

**Navigate to:** Sidebar → Discover

---

### 5. **Skill Swap Requests** ✓
**Test with (need 2+ test accounts):**
- From Discover, click "View profile" on someone
- Click "Start Skill Swap" button
- In the modal:
  - Select a skill they offer (dropdown)
  - Type a skill you offer
  - Optional: Add a message
  - Click "Send Request"

**Expected:**
- Request creates a `collaborations` document in Firestore
- Status is `pending`
- Requester and target get notifications
- Recipient can accept/decline from Collaborations page

**Navigate to:** Discover → Profile → "Start Skill Swap"

---

### 6. **Collaborations** ✓
**Test with (need 2+ test accounts):**
- Click "Collaborations" in sidebar
- View all skill swaps where user is requester or target
- Filter by status tabs:
  - Pending (amber)
  - Accepted (green)
  - In Progress (blue)
  - Completed (indigo)
  - Cancelled (red)
- For **pending** (as target):
  - Click "Accept" or "Decline"
- For **accepted**:
  - Click "Start" to move to in-progress
- For **in-progress**:
  - Click "Complete" to finish

**Expected:**
- Tab badges show count per status
- Actions update Firestore in real-time
- Collaborations feed reflects status changes

**Navigate to:** Sidebar → Collaborations

---

### 7. **Community Posts** ✓
**Test with:**
- Click "Posts" in sidebar
- View all community posts with types:
  - Skill Offers (teaching skills)
  - Service Offers (offering services)
  - Help Requests (asking for help)
  - Projects (group collaboration)
  - Volunteer Work (volunteer opportunities)
  - Mentorship (mentoring/learning)
- Search by title/skill
- Filter by type dropdown
- View post details:
  - Author, photo, date
  - Title, description
  - Location (if provided)
  - Participant count
  - "Join Post" button

**Expected:**
- Only posts from Firestore `posts` collection display
- Search/filter updates in real-time
- Joining a post increments participant count
- User avatar falls back to initials if no photo

**Navigate to:** Sidebar → Posts

---

### 8. **Messaging** ✓
**Test with (need 2+ test accounts):**
- Click "Messaging" in sidebar
- View all chats (conversations with collaborators)
- Left sidebar shows:
  - Chat list with names
  - Last message preview
  - Unread badge if any
- Click a chat to open it
- Type message and click "Send"
- Messages appear in real-time thread

**Expected:**
- Messages stored in Firestore `messages` collection
- Organized by `chatId` (collaboration or match ID)
- Messages auto-scroll to latest
- Unread count updates per user
- Message sender bubbles on right, receiver on left

**Navigate to:** Sidebar → Messaging

---

### 9. **Notifications** ✓
**Test with (trigger actions on other account):**
- Click "Notifications" in sidebar (bell icon or nav)
- View notifications sorted by recency
- Each notification shows:
  - Icon (colored by type)
  - Title and body text
  - Time stamp
  - Unread indicator dot
- Filter by status:
  - Unread (with badge count)
  - All
- Click notification to navigate to related section
- Click X to delete notification
- Clicking notification marks as read

**Expected:**
- Notifications trigger when:
  - Skill swap request received
  - Collaboration status changes
  - New post from followed category
  - Message received
  - Endorsement given
- Color-coded by type
- Real-time updates from Firestore `notifications` collection

**Navigate to:** Sidebar → Notifications (or bell icon)

---

### 10. **User Profiles** ✓
**Test with (view your own or others):**
- From Discover → Click "View profile" on any person
- Profile shows:
  - Header with avatar, name, location, experience
  - Community impact stats
  - Endorsement badges (if any)
  - Bio section
  - Skills offered/wanted (color-coded)
  - Reviews section with average star rating
- Buttons:
  - "Start Skill Swap" (propose exchange)
  - "Give Endorsement" (for other users only)
- Click "Give Endorsement":
  - Select badge type from 7 options
  - Click "Send Endorsement"
  - Modal closes, endorsement appears in badges section

**Expected:**
- Profile data loads from Firestore `users/{uid}`
- Endorsements load from `endorsements` collection
- Reviews load from `reviews` collection
- Own profile shows edit/settings buttons instead
- Endorsement counts update in real-time

**Navigate to:** Discover → View profile on any card

---

## Testing Flow Example (End-to-End)

### Scenario: Two users making a skill swap

**Account A (You):**
1. Sign up with email, create profile
2. Go to Discover, find Account B
3. Click "View profile"
4. Click "Start Skill Swap"
5. Select a skill they offer
6. Type a skill you're offering
7. Add optional message
8. Submit

**Account B (Other person):**
1. Sign up with email, create profile
2. Go to Notifications → See skill swap request
3. Go to Collaborations
4. Click "Accept" on pending request
5. Click "Start" to begin exchange

**Account A:**
1. Go to Collaborations
2. See status changed to "In Progress"
3. After exchanging skills, click "Complete"

**Account B:**
1. Go to Collaborations
2. See status is "Completed"
3. Leave a review (next feature)
4. Give an endorsement

---

## Common Testing Issues

### Issue: "Profile not found" on Discover
**Solution:** Make sure the user you're viewing has `profileComplete: true` in Firestore

### Issue: Collaborations not appearing
**Solution:** Check that both users have complete profiles. Requests are only sent to discoverable users.

### Issue: Messages not syncing
**Solution:** Make sure you've started a collaboration with the person first. Messages only appear in active collaborations.

### Issue: Endorsements not showing
**Solution:** Endorsement badges only show for the **recipient**, not the giver. Check on the person's profile you endorsed.

---

## Database Structure to Verify (Firestore)

Navigate to Firebase Console → SkillSwap Project → Firestore Database

**Should see these collections:**
- `users/` → User profiles with skills, bio, stats
- `collaborations/` → Skill swap requests and exchanges
- `posts/` → Community posts
- `messages/` → Conversation messages
- `notifications/` → User notifications
- `endorsements/` → Endorsement badges given
- `reviews/` → User reviews and ratings (for next feature)

Each document should have the structure matching the TypeScript models in `web/src/lib/models.ts`

---

## Performance Benchmarks

**Expected load times:**
- Dashboard load: < 2s
- Discover page (30 people): < 2s
- Search/filter response: < 500ms
- Send message: < 1s
- Collaborations updates: Real-time (< 100ms)

---

## Next Steps for Testing

1. ✅ Test features 1-10 in the list above
2. 📝 Note any bugs or missing functionality
3. 🚀 Ready to implement the next feature (User Reviews)

Would you like guidance on any specific feature, or shall we move forward with the next feature implementation?
