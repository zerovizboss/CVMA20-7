# Epic #3 CEB Presentation - Viewing Guide

**Created**: October 25, 2025
**Presentation File**: `EPIC-3-CEB-PRESENTATION.html`
**Format**: Reveal.js Interactive HTML Presentation

---

## 🎯 Quick Start

### **Option 1: View in Browser (Recommended)**
1. Open `EPIC-3-CEB-PRESENTATION.html` in any modern browser:
   - **Windows**: Right-click → Open with → Chrome/Edge/Firefox
   - **Direct path**: `C:\Users\zerov\IdeaProjects\cvma\docs\Technical\Epic-Documentation\EPIC-3-CEB-PRESENTATION.html`
2. Press `F11` for full-screen mode (exit with `F11` or `Esc`)
3. Use arrow keys or click arrows to navigate

### **Option 2: Present from VS Code**
1. Install "Live Server" extension in VS Code
2. Right-click `EPIC-3-CEB-PRESENTATION.html` → "Open with Live Server"
3. Presentation opens in browser with auto-reload

---

## ⌨️ Keyboard Controls

| Key | Action |
|-----|--------|
| `→` or `Space` | Next slide |
| `←` or `Shift+Space` | Previous slide |
| `Home` | First slide |
| `End` | Last slide |
| `F11` or `F` | Toggle full-screen |
| `Esc` or `O` | Overview mode (see all slides) |
| `S` | Speaker notes (if presenter) |
| `B` or `.` | Pause/blackout screen |
| `?` | Show keyboard help |

---

## 📊 Presentation Structure (21 Slides)

### **Part 1: Context & Current State** (Slides 1-4)
1. **Title Slide** - Epic #3 introduction
2. **Executive Summary** - What we've built, what we need to decide
3. **Current State** - 107 files deployed status
4. **Three-Tier Access Model** - Guest → Member → CEB (Mermaid diagram)

### **Part 2: Architecture & Workflows** (Slides 5-7)
5. **CEB Role Hierarchy** - Organizational structure (Mermaid diagram)
6. **Secretary Workflow** - Meeting minutes creation → publication
7. **Treasurer Workflow** - Financial reports creation → publication

### **Part 3: The Decision Options** (Slides 8-12)
8. **The Decision** - Overview of 3 options
9. **Option 1 Details** - Member Documents Hub (centralized)
10. **Option 2 Details** - Role-Specific Pages (distributed)
11. **Option 3 Details** - Hybrid Approach ⭐ RECOMMENDED
12. **Option 3 Architecture** - Hybrid workflow diagram (Mermaid)

### **Part 4: Analysis & Planning** (Slides 13-17)
13. **Comparison Matrix** - 8 criteria across 3 options
14. **Implementation Timeline** - Phase 2A/2B/2C breakdown (Option 3)
15. **Technical Implementation** - What's built vs. what's needed
16. **Google Drive Folder Structure** - Current deployment status
17. **Success Metrics** - User adoption, performance, content growth

### **Part 5: Decision & Next Steps** (Slides 18-21)
18. **Decision Request** - CEB Commander selection template
19. **Questions & Discussion** - Key questions for CEB to consider
20. **Next Steps** - Timeline from decision to production
21. **Thank You** - Contact info and closing

---

## 🎨 Visual Features

### **Mermaid Diagrams** (Interactive Flowcharts)
The presentation includes 3 professional Mermaid diagrams:
- **Slide 4**: Three-Tier Access Model (authentication flow)
- **Slide 5**: CEB Role Hierarchy (organizational structure)
- **Slide 12**: Option 3 Hybrid Architecture (publication workflow)

**Note**: Diagrams auto-render when slides are displayed. If a diagram doesn't load, refresh the browser.

### **Color Coding**
- **Gold/Yellow** (#FFD700): Recommended options, highlights
- **Green** (#00FF00): Checkmarks, success indicators
- **Orange** (#FFA500): Warnings, considerations
- **Cyan/Teal** (#4ecdc4): Secondary emphasis

### **Theme**
- Dark theme (black background) for professional presentation
- High contrast for readability in meeting rooms
- Responsive design (works on laptops, projectors, tablets)

---

## 📤 Export to PDF

### **Method 1: Browser Print (Easiest)**
1. Open presentation in Chrome or Edge
2. Add `?print-pdf` to URL:
   ```
   file:///C:/Users/zerov/IdeaProjects/cvma/docs/Technical/Epic-Documentation/EPIC-3-CEB-PRESENTATION.html?print-pdf
   ```
3. Press `Ctrl+P` (Print)
4. Select "Save as PDF"
5. Settings:
   - Layout: Portrait
   - Margins: None
   - Background graphics: Enabled
6. Click "Save"

**Note**: Mermaid diagrams may not render perfectly in PDF. Consider taking screenshots if needed.

### **Method 2: Reveal.js DeckTape (Advanced)**
If you need high-quality PDF export with perfect diagram rendering:

```bash
# Install DeckTape (one-time setup)
npm install -g decktape

# Export to PDF
decktape reveal EPIC-3-CEB-PRESENTATION.html EPIC-3-CEB-PRESENTATION.pdf
```

---

## 📧 Share with CEB Members

### **Option A: Email HTML File**
1. Attach `EPIC-3-CEB-PRESENTATION.html` to email
2. Recipients open in browser (works offline, no internet required)
3. All diagrams and styling are embedded (no external dependencies except CDN)

**Email Template**:
```
Subject: Epic #3 Decision Request - Knowledge Article Publication Strategy

Attached is an interactive presentation for our upcoming CEB meeting regarding
Epic #3 (Knowledge Article Foundation).

To view:
1. Download the attached HTML file
2. Open in Chrome, Edge, or Firefox
3. Use arrow keys to navigate through 21 slides
4. Press F11 for full-screen mode

Key Decision Needed: Where should CEB members publish documents for Member access?
- Option 1: Single "Member Documents" hub
- Option 2: Role-specific publication pages
- Option 3: Hybrid approach (RECOMMENDED)

Please review before our meeting on [DATE].
```

### **Option B: Share via Google Drive/OneDrive**
1. Upload `EPIC-3-CEB-PRESENTATION.html` to shared folder
2. Share link with CEB members
3. Members download and open locally

### **Option C: Host on Internal Server**
If CVMA has internal web hosting, copy HTML file to server and share URL.

---

## 🔧 Troubleshooting

### **Diagrams Not Rendering**
- **Cause**: Internet connection required for Mermaid CDN
- **Fix**: Ensure internet connection, or download Mermaid library locally

### **Slides Not Advancing**
- **Cause**: JavaScript disabled or browser incompatibility
- **Fix**: Use Chrome/Edge/Firefox with JavaScript enabled

### **Text Too Small**
- **Cause**: High-resolution display or projector settings
- **Fix**: Zoom in with `Ctrl +` or adjust browser zoom level

### **Full-Screen Not Working**
- **Cause**: Browser security settings
- **Fix**: Use `F` key instead of `F11`, or manually resize browser window

---

## 🎤 Presenter Tips

### **Speaker Notes**
Press `S` to open speaker view with notes (currently no speaker notes added, but can be added if needed).

### **Presentation Flow**
**Suggested timing** (30-minute meeting):
- Slides 1-4: Context (5 min)
- Slides 5-7: Workflows (5 min)
- Slides 8-12: Options (10 min) ← **Main focus**
- Slides 13-17: Analysis (5 min)
- Slides 18-21: Decision & Q&A (5 min)

### **Key Talking Points**
1. **Slide 2 (Executive Summary)**: Emphasize we've already built the foundation (107 files)
2. **Slide 6-7 (Workflows)**: Explain the "Where should published docs appear?" question
3. **Slide 11 (Option 3)**: Highlight why Hybrid is recommended (flexibility)
4. **Slide 13 (Comparison Matrix)**: Show Option 3 scores highest in 5/8 criteria
5. **Slide 18 (Decision Request)**: Get explicit CEB vote/decision

### **Anticipate Questions**
- **"How much does each option cost?"** → No licensing costs, only dev time
- **"Can we change later?"** → Yes, but rework required. Option 3 easiest to adapt.
- **"What if CEB doesn't agree?"** → Can start with Option 1, add Option 3 features later
- **"How long until members can use it?"** → 2-3 weeks from decision to production

---

## 📝 Post-Presentation Actions

### **After CEB Decides**
1. Update `EPIC-3-CEB-DECISION-REQUEST.md` with decision:
   ```markdown
   **Decision Maker**: Chapter Commander
   **Decision Status**: ✅ APPROVED
   **Decision Date**: [DATE]
   **Decided Option**: Option 3 (Hybrid Approach)
   **Notes**: CEB unanimously approved hybrid approach...
   ```

2. Notify development team:
   - Update STORM_CLAUDE_CORE.md with decision
   - Add Phase 2 tasks to TodoWrite
   - Begin implementation (8-12 hours estimated)

3. Schedule follow-up:
   - CEB testing session (1-2 weeks after deployment)
   - Member announcement/training
   - Feedback collection

---

## 🔗 Related Documentation

**Architecture Details**:
- `EPIC-3-CEB-ROLE-BASED-ARCHITECTURE.md` - Full technical architecture
- `EPIC-3-CEB-DECISION-REQUEST.md` - Detailed decision framework

**Implementation Guides**:
- `EPIC-3-MCP-KNOWLEDGE-INTEGRATION-DEV-GUIDE.md` - Developer documentation
- `GOOGLE-DRIVE-FOLDER-SETUP-GUIDE.md` - Google Drive setup guide

**Status Reports**:
- `EPIC-3-EXISTING-GDRIVE-STATUS.md` - Current deployment (101 files)
- `EPIC-3-POC-SUCCESS-VALIDATION.md` - Proof-of-concept validation

---

## 💡 Customization (Optional)

### **Add Your Own Branding**
Edit `EPIC-3-CEB-PRESENTATION.html` and modify:
```html
<!-- Change theme (line 9) -->
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/reveal.js@5.0.4/dist/theme/black.css">
<!-- Available themes: black, white, league, beige, sky, night, serif, simple, solarized -->

<!-- Add CVMA logo (add to slide 1) -->
<img src="path/to/cvma-logo.png" style="max-width: 200px;">
```

### **Add Speaker Notes**
Add notes to any slide:
```html
<section data-markdown>
    <textarea data-template>
    ## Slide Content Here

    Note:
    These are speaker notes. Press 'S' to view them.
    </textarea>
</section>
```

### **Embed Videos**
Add video to any slide:
```html
<section>
    <h2>Demo Video</h2>
    <video controls width="800">
        <source src="path/to/demo.mp4" type="video/mp4">
    </video>
</section>
```

---

## ✅ Pre-Meeting Checklist

**Before presenting to CEB**:
- [ ] Test presentation on actual projector/screen (if in-person)
- [ ] Ensure laptop is fully charged (or connected to power)
- [ ] Download/print backup PDF (in case of technical issues)
- [ ] Have decision template ready for CEB vote
- [ ] Prepare answers to anticipated questions
- [ ] Test internet connection (for Mermaid diagrams)
- [ ] Set browser to full-screen mode before meeting starts
- [ ] Disable notifications/popups on laptop

---

## 📞 Support

**Technical Issues During Presentation**:
- Fallback: Open `EPIC-3-CEB-DECISION-REQUEST.md` in VS Code as backup
- Mermaid diagrams also documented in architecture files
- Can walk through decision without slides if needed

**Questions About Content**:
- Reference architecture documents in `docs/Technical/Epic-Documentation/`
- All technical specs are in `EPIC-3-MCP-KNOWLEDGE-INTEGRATION-DEV-GUIDE.md`

---

**Good luck with the CEB presentation! 🏍️**

**Vets Serving Vets**
Combat Veterans Motorcycle Association - Chapter 20-7
