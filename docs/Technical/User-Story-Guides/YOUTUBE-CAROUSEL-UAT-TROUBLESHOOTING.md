# YouTube Carousel - UAT Troubleshooting Guide

**User Story #33**: YouTube Carousel Component
**Created**: October 6, 2025
**Status**: UAT In Progress

---

## 🔧 **UAT Issues Reported**

### **Issue #1**: Component not visible to guest users ✅ **FIXED**
**Cause**: Apex controller used `with sharing` which restricted guest access
**Fix**: Changed to `without sharing` (deployed)

### **Issue #2**: Videos not playing ⚠️ **IN PROGRESS**
**Likely Causes**:
1. Content Security Policy (CSP) blocking YouTube
2. YouTube IFrame API not loading
3. Video embed restrictions
4. Experience Cloud configuration

---

## 📋 **Troubleshooting Steps**

### **Step 1: Check Browser Console for CSP Errors**

1. Open Experience Cloud site as guest user
2. Open browser Developer Tools (F12)
3. Go to Console tab
4. Look for errors like:
   ```
   Refused to load the script 'https://www.youtube.com/iframe_api' because it violates the following Content Security Policy directive...
   ```
   OR
   ```
   Refused to display 'https://www.youtube.com' in a frame because it violates the following Content Security Policy directive...
   ```

**If you see CSP errors**: Proceed to Step 2 (Add YouTube to Trusted Sites)

---

### **Step 2: Add YouTube to CSP Trusted Sites for Experience Cloud**

Salesforce Experience Cloud requires explicit CSP configuration to load external resources.

#### **Option A: Trusted Sites for Content (Recommended)**

1. Navigate to: **Setup → Trusted URLs for Content Security Policy**
2. Click **New Trusted Site**
3. Enter the following:
   - **API Name**: `YouTube_IFrame_API`
   - **Site URL**: `https://www.youtube.com`
   - **Context**: Select `Communities`
   - **Directives**:
     - ✅ `script-src` (for iframe_api JavaScript)
     - ✅ `frame-src` (for embedding YouTube videos)
     - ✅ `img-src` (for video thumbnails)
     - ✅ `media-src` (for video/audio playback)
4. Click **Save**

5. Add second trusted site for YouTube CDN:
   - **API Name**: `YouTube_CDN`
   - **Site URL**: `https://i.ytimg.com`
   - **Context**: Select `Communities`
   - **Directives**:
     - ✅ `img-src` (for thumbnail images)
6. Click **Save**

#### **Option B: CSP Directives via Experience Workspaces (Alternative)**

1. Navigate to: **All Sites → Your Site (Combat Veterans Motorcycle Association) → Workspaces → Administration**
2. Go to **Security & Privacy**
3. Click **Content Security Policy**
4. Add the following to CSP directives:
   ```
   script-src 'self' https://www.youtube.com;
   frame-src 'self' https://www.youtube.com;
   img-src 'self' https://i.ytimg.com;
   media-src 'self' https://www.youtube.com;
   ```
5. Click **Save**

---

### **Step 3: Configure Guest User Profile Permissions**

Ensure guest users can access the YouTube Carousel component:

1. Navigate to: **Setup → All Sites → Your Site → Workspaces → Administration**
2. Go to **Members → Guest User Profile**
3. Ensure the following:
   - **Apex Class Access**: CVMAYouTubeCarouselController is enabled
   - **Custom Metadata Types**: CVMA_YouTube_Video__mdt has Read access
   - **Lightning Component**: cvmaYouTubeCarousel is visible

**Shortcut Command**:
```bash
# Check guest user profile via CLI
sf org open --target-org cvma
# Navigate to: Setup → Profiles → [Your Site] Profile (Guest)
# Enabled Apex Classes → Add "CVMAYouTubeCarouselController"
```

---

### **Step 4: Verify Video Embed Settings**

Check that your YouTube videos allow embedding:

1. Go to **YouTube Studio** (https://studio.youtube.com)
2. Select your video
3. Click **Details** → **Show More**
4. Scroll to **Advanced Settings**
5. Ensure **"Allow embedding"** is checked
6. Verify **Privacy** is set to:
   - ✅ **Public** (visible to all)
   - ✅ **Unlisted** (visible to anyone with link)
   - ❌ **Private** (will NOT work in carousel)

**Test Video IDs Currently Deployed**:
- `cUTpSYPspTI` - CVMA Welcome Video (user-provided)
- `9No-FiEInLA` - Sample video (placeholder)
- `tgbNymZ7vqY` - Sample video (placeholder)

---

### **Step 5: Test YouTube IFrame API Loading**

Check if the YouTube IFrame API is loading correctly:

1. Open Browser Console (F12) on Experience Cloud site
2. Type: `console.log(typeof YT)`
3. Expected results:
   - ✅ **"object"** = YouTube API loaded successfully
   - ❌ **"undefined"** = YouTube API blocked by CSP or not loading

**If undefined**:
- Verify CSP Trusted Sites are configured (Step 2)
- Check Network tab for failed requests to `www.youtube.com/iframe_api`
- Ensure `script-src` directive includes `https://www.youtube.com`

---

### **Step 6: Experience Cloud Site Security Settings**

1. Navigate to: **All Sites → Combat Veterans Motorcycle Association → Workspaces → Administration**
2. Go to **Security & Privacy**
3. Verify:
   - **Force HTTPS**: Enabled
   - **HSTS (HTTP Strict Transport Security)**: Enabled (recommended)
   - **Content Security Policy**: Configured with YouTube URLs (Step 2)

---

## 🧪 **Manual Testing Checklist**

### **Guest User Access**
- [ ] Component visible on Home page (guest user)
- [ ] Component loads without errors (guest user)
- [ ] Videos display thumbnails (guest user)
- [ ] Video player initializes (guest user)

### **Video Playback**
- [ ] Click Play button - video starts
- [ ] Navigation buttons work (Previous/Next)
- [ ] Thumbnail navigation works
- [ ] Video plays to completion
- [ ] Auto-advance to next video works

### **Responsive Design**
- [ ] Desktop view (1920x1080)
- [ ] Tablet view (768x1024)
- [ ] Mobile view (375x667)
- [ ] Navy ribbon styling displays correctly

### **Cross-Browser Testing**
- [ ] Chrome/Edge (Chromium)
- [ ] Firefox
- [ ] Safari (macOS/iOS)

---

## 🚨 **Common Error Messages & Fixes**

### **Error**: "Refused to load the script 'https://www.youtube.com/iframe_api'"
**Fix**: Add `https://www.youtube.com` to Trusted Sites with `script-src` directive (Step 2)

### **Error**: "Refused to display 'https://www.youtube.com' in a frame"
**Fix**: Add `https://www.youtube.com` to Trusted Sites with `frame-src` directive (Step 2)

### **Error**: "Unable to load videos" (in component UI)
**Fix**: Check Apex controller guest user access (Step 3)

### **Error**: Video player shows black screen
**Fix**:
1. Verify video ID is correct
2. Check video embed settings on YouTube (Step 4)
3. Ensure video is Public or Unlisted (not Private)

### **Error**: Thumbnails not loading
**Fix**: Add `https://i.ytimg.com` to Trusted Sites with `img-src` directive (Step 2)

---

## 🔍 **Debugging Commands**

### **Check Custom Metadata Records**
```bash
sf data query --query "SELECT Video_ID__c, Video_Title__c, Is_Active__c, Is_Featured__c FROM CVMA_YouTube_Video__mdt WHERE Is_Active__c = true" --target-org cvma
```

### **Test Apex Controller from Anonymous Apex**
```apex
// Run in Developer Console → Debug → Open Execute Anonymous Window
List<CVMAYouTubeCarouselController.VideoMetadata> videos = CVMAYouTubeCarouselController.getFeaturedVideos();
System.debug('Video Count: ' + videos.size());
for (CVMAYouTubeCarouselController.VideoMetadata video : videos) {
    System.debug('Video: ' + video.title + ' (' + video.videoId + ')');
}
```

### **Check Guest User Profile Permissions**
```bash
# Open org and navigate to guest profile
sf org open --target-org cvma
# Setup → Profiles → [Site Name] Profile (Guest) → Enabled Apex Classes
```

---

## 📞 **Escalation Path**

If issues persist after completing all troubleshooting steps:

1. **Capture Browser Console Errors**:
   - Screenshot all console errors
   - Export Network tab HAR file (right-click → Save as HAR)

2. **Check Salesforce Debug Logs**:
   - Setup → Debug Logs
   - Enable logging for guest user
   - Reproduce issue
   - Check logs for Apex errors

3. **Verify Component Deployment**:
   ```bash
   sf project deploy report --job-id <DEPLOY_ID> --target-org cvma
   ```

4. **Contact Development Team**:
   - Provide browser console screenshots
   - Share guest user profile name
   - Include YouTube video IDs being tested
   - Describe exact steps to reproduce

---

## ✅ **Success Criteria**

YouTube Carousel is working correctly when:

1. ✅ Guest users can see component on Experience Cloud site
2. ✅ Video thumbnails load correctly
3. ✅ Clicking Play button starts video playback
4. ✅ Navigation buttons (Previous/Next) work smoothly
5. ✅ Navy ribbon styling displays on navigation buttons
6. ✅ Videos auto-advance after completion
7. ✅ Category filtering works (if not featured-only mode)
8. ✅ Mobile responsive design works across devices

---

**Implementation Guide**: See `USER-STORY-33-YOUTUBE-CAROUSEL-IMPLEMENTATION.md`
**Deployment Status**: DEPLOYED (October 6, 2025)
**CSP Configuration**: REQUIRED (see Step 2 above)

🎖️ Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
