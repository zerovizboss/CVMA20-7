# YouTube Carousel - CEB User Guide
**CVMA Chapter 20-7 - Combat Veterans Motorcycle Association**

## 🎥 **Quick Start Guide for CEB Officers**

**Your Role**: Public Relations Officer (or designated CEB officer)
**Purpose**: Curate CVMA videos for member engagement
**Time Required**: 5-10 minutes to add a new video

---

## 📋 **What is the YouTube Carousel?**

The YouTube Carousel displays CVMA videos on your Combat Veterans Motorcycle Association Experience Cloud site.

**Key Features**:
- ✅ Featured videos carousel (home page)
- ✅ Category filtering (Events, Testimonials, Rides, etc.)
- ✅ Automatic thumbnail generation from YouTube
- ✅ CEB approval workflow
- ✅ Mobile-responsive video player
- ✅ Military ribbon styling

**Where Members See It**:
- Site home page (featured videos)
- Media Library page (all approved videos)
- Category-specific pages (filtered views)

---

## 🚀 **How to Add a New Video (5 Steps)**

### **Step 1: Upload Video to YouTube**

1. Upload your video to the **CVMA Chapter 20-7** YouTube channel
2. Set video visibility:
   - **Public**: Everyone can see (recommended for promotional videos)
   - **Unlisted**: Only people with the link (good for member-only content)
3. Note the **Video ID** from the URL
   - Example: `https://www.youtube.com/watch?v=dQw4w9WgXcQ`
   - **Video ID** = `dQw4w9WgXcQ` (the part after `v=`)

---

### **Step 2: Create Custom Metadata Record**

1. Navigate to **Setup** → **Custom Metadata Types**
2. Click **Manage Records** next to **CVMA YouTube Video**
3. Click **New**
4. Fill in the form:

**Required Fields**:
- **Label**: Video title (e.g., "CVMA Ride for Veterans 2025")
- **CVMA YouTube Video Name**: Auto-generated (leave as-is)
- **Video ID**: Paste the YouTube video ID (Step 1)
- **Video Title**: Display title for carousel
- **Video Category**: Select category (Events, Testimonials, Rides, Training, etc.)

**Optional Fields**:
- **Video Description**: Brief description (shows on hover)
- **Display Order**: Number for sorting (lower = first, e.g., 1, 2, 3...)
- **Thumbnail URL**: Custom thumbnail (leave blank to auto-generate from YouTube)

**Important Checkboxes**:
- ☑ **Is Active**: Check this box to make video visible
- ☑ **Is Featured**: Check this box to show in home page carousel
- **Approval Status**: Select "Pending Approval" (if CEB review required) OR "Approved" (if self-approving)

5. Click **Save**

---

### **Step 3: CEB Approval (If Required)**

**If your chapter requires CEB approval for videos**:

1. Set **Approval Status** = "Pending Approval"
2. Notify Commander or designated approver via email/Chatter
3. Approver reviews video content:
   - ✅ Appropriate for CVMA brand
   - ✅ No sensitive/confidential information
   - ✅ Quality meets standards
4. Approver updates metadata record:
   - **Approval Status** = "Approved"
   - **Approved By** = Officer name
   - **Approval Date** = Today's date
5. Video now appears on site

**If no approval required**: Set **Approval Status** = "Approved" immediately in Step 2

---

### **Step 4: Test on Site**

1. Navigate to your **Combat Veterans Motorcycle Association** site
2. Go to home page (or Media Library page)
3. Verify video appears:
   - ✅ Correct thumbnail
   - ✅ Correct title and description
   - ✅ Video plays when clicked
   - ✅ Military ribbon styling applied

**Troubleshooting**:
- Video not showing? Check **Is Active** and **Approval Status** = "Approved"
- Wrong thumbnail? Add custom **Thumbnail URL** or wait 24 hours for YouTube auto-gen
- Wrong order? Adjust **Display Order** field (lower numbers first)

---

### **Step 5: Monitor & Update**

**Monthly Tasks**:
- [ ] Review **View Count** (if analytics enabled)
- [ ] Rotate featured videos (uncheck **Is Featured** on old, check on new)
- [ ] Archive outdated videos (uncheck **Is Active**)
- [ ] Add new event videos from recent rides/activities

---

## 🎯 **Video Categories Explained**

### **Events**
- Chapter events (picnics, fundraisers, memorial services)
- Multi-chapter gatherings
- CVMA state/regional/national events

### **Testimonials**
- Veteran testimonials
- Member success stories
- "Why I joined CVMA" stories

### **Rides**
- Ride videos (chapter rides, poker runs, awareness rides)
- Route highlights
- Ride safety demonstrations

### **Training**
- CEB training materials
- Member orientation videos
- How-to guides (patch care, uniform standards, etc.)

### **Promotional**
- CVMA mission videos
- Recruitment materials
- Community outreach highlights

### **Chapter History**
- Historical footage
- Founding member stories
- Milestone celebrations

---

## 📋 **CEB Approval Guidelines**

### **Approve Videos That**:
- ✅ Align with CVMA mission ("Vets Serving Vets")
- ✅ Showcase positive chapter activities
- ✅ Maintain professional quality (clear audio/video)
- ✅ Respect member privacy (no sensitive information)
- ✅ Follow CVMA branding standards

### **Reject or Request Edits For**:
- ❌ Poor audio/video quality
- ❌ Inappropriate language or content
- ❌ Sensitive member information visible (addresses, phone numbers)
- ❌ Violations of CVMA bylaws or conduct standards
- ❌ Copyright violations (unauthorized music, images)

### **CEB Discussion Required**:
- Videos involving controversial topics
- Videos featuring minors (need parental consent)
- Videos with financial solicitation
- Videos mentioning legal matters or investigations

---

## 🔧 **Common Tasks**

### **Rotate Featured Videos (Monthly)**

**Why**: Keep home page fresh with recent content

**How**:
1. Navigate to **Setup** → **Custom Metadata Types** → **CVMA YouTube Video** → **Manage Records**
2. Find current featured video
3. Edit → Uncheck **Is Featured** → Save
4. Find new video to feature
5. Edit → Check **Is Featured** → Save

**Tip**: Feature seasonal content (rides in summer, memorial services in May, fundraisers during holidays)

---

### **Archive Old Videos**

**Why**: Keep catalog current and relevant

**How**:
1. Navigate to metadata records
2. Find video to archive
3. Edit → Uncheck **Is Active** → Save
4. Video no longer visible on site (but record preserved for history)

**When to Archive**:
- Event videos >2 years old
- Outdated training materials
- Videos with outdated information
- Low-quality early videos replaced by better versions

---

### **Change Video Order in Carousel**

**Why**: Highlight most important videos first

**How**:
1. Edit metadata records
2. Set **Display Order**:
   - 1 = First video shown
   - 2 = Second video
   - 3 = Third video, etc.
3. Save

**Tip**: Use gaps (1, 5, 10, 15) so you can insert videos later without renumbering everything

---

### **Update Video Thumbnail**

**Why**: Auto-generated thumbnails sometimes not ideal

**How**:
1. Create custom thumbnail image (1280x720 pixels recommended)
2. Upload to YouTube → Edit Video → Custom Thumbnail
3. Copy thumbnail URL
4. Edit metadata record → **Thumbnail URL** → Paste URL → Save

**Alternative**: Use YouTube's auto-generated thumbnails (YouTube picks 3 options)

---

## 📊 **Analytics & Reporting**

### **View Count Tracking**

**Current Status**: Basic view count field available
**Future Enhancement**: Full analytics dashboard (views, watch time, engagement)

**How to Update View Count** (optional):
1. Check YouTube Analytics for video
2. Edit metadata record
3. Update **View Count** field
4. Save

**Automated Tracking**: Future feature (auto-sync with YouTube API)

---

### **Most Popular Videos Report**

**Create Report**:
1. Navigate to **Reports** → **New Report**
2. Report Type: **Custom Metadata** → **CVMA YouTube Video**
3. Filters: **Is Active** = TRUE
4. Sort By: **View Count** (descending)
5. Save Report: "Most Popular CVMA Videos"

**Use**: Identify what content resonates with members, plan future videos

---

## 🚨 **Troubleshooting**

### **Problem**: Video shows "Video unavailable" error
**Cause**: YouTube video set to Private or Deleted
**Solution**: Change YouTube video to Public or Unlisted, or update Video ID in metadata

---

### **Problem**: Thumbnail not loading
**Cause**: YouTube hasn't generated thumbnail yet, or custom URL broken
**Solution**: Wait 24 hours for YouTube auto-gen, or upload custom thumbnail and update URL

---

### **Problem**: Video not appearing in carousel
**Checklist**:
- [ ] **Is Active** = Checked?
- [ ] **Is Featured** = Checked? (for home page carousel)
- [ ] **Approval Status** = "Approved"?
- [ ] Video ID correct?
- [ ] Clear browser cache and refresh page

---

### **Problem**: Videos out of order
**Cause**: **Display Order** field not set correctly
**Solution**: Edit metadata records, set **Display Order** (1, 2, 3, etc.), save

---

### **Problem**: Can't find metadata records in Setup
**Solution**:
1. Go to **Setup** → Search "Custom Metadata Types"
2. Click **Custom Metadata Types**
3. Find **CVMA YouTube Video**
4. Click **Manage Records**

---

## 📞 **Support & Training**

**Technical Questions**: detonator@cvma20-7.org
**CEB Questions**: Chapter Commander or designated video coordinator
**YouTube Channel Access**: Request from Public Relations Officer

**Training Sessions**:
- Monthly CEB meeting: Video management overview
- Quarterly: Video creation best practices
- As needed: One-on-one training for new PR officers

---

## 💡 **Best Practices**

### **Video Content Tips**:
- ✅ Keep videos 2-5 minutes (optimal engagement)
- ✅ Add closed captions (accessibility + SEO)
- ✅ Use descriptive titles ("CVMA 20-7 Ride for Veterans 2025" not "Ride Video")
- ✅ Include call-to-action ("Join us at next month's ride!")
- ✅ Film horizontally (landscape mode) not vertically

### **Video Quality Tips**:
- ✅ Stable camera (use tripod or stabilization)
- ✅ Good lighting (outdoor daylight or indoor lighting)
- ✅ Clear audio (external mic recommended for speeches)
- ✅ Minimal background noise
- ✅ Edit out dead time (long pauses, setup/teardown)

### **CVMA Branding Tips**:
- ✅ Start with CVMA logo or chapter patch graphic
- ✅ Include chapter name in video description
- ✅ Use CVMA colors (red, gold, black)
- ✅ End with chapter contact info or website
- ✅ Add CVMA watermark (optional)

---

## 🎖️ **Quick Reference Card**

**Add New Video**:
1. Upload to YouTube → Get Video ID
2. Setup → Custom Metadata Types → CVMA YouTube Video → New
3. Fill form (Video ID, Title, Category)
4. Check Is Active + Is Featured + Set Approval Status
5. Save → Test on site

**Archive Old Video**:
1. Setup → Custom Metadata Types → CVMA YouTube Video → Manage Records
2. Find video → Edit
3. Uncheck Is Active → Save

**Rotate Featured Video**:
1. Uncheck Is Featured on current video
2. Check Is Featured on new video
3. Save both

---

🎖️ **Generated with [Claude Code](https://claude.com/claude-code)**
**Date**: October 6, 2025
**For**: CEB Officers & Public Relations Team
**GitHub Issue**: #79 (YouTube Carousel Implementation)
