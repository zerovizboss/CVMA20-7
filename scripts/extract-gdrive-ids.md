# Quick Guide: Extract Google Drive File IDs

## For Treasurer's Reports Folder
**Folder**: https://drive.google.com/drive/folders/1F9rp_FHFbUEOy7pLw901PNLTZGNpcZpf

1. Open the folder link above
2. For each file, right-click → **Get link** (or **Share**)
3. Copy the sharing link
4. Extract the file ID (the long string between `/d/` and `/view` or `/edit`)

## For Secretary's Meeting Minutes Folder
**Folder**: https://drive.google.com/drive/folders/127kor0VoFUV1y58MdPZV3QxrsG6KMSii

Same process as above.

## File ID Format

**Full Link Example**:
```
https://drive.google.com/file/d/1ABC123xyz456DEF789/view?usp=sharing
```

**File ID to Copy**:
```
1ABC123xyz456DEF789
```

## Paste Format (for Claude to process)

Please paste in this format:

```
TREASURER REPORTS:
- File Name: JANUARY2025 TREASURERS REPORT.pdf
  File ID: [paste ID here]

- File Name: MARCH 2025 TREASURERS REPORT.pdf
  File ID: [paste ID here]

[etc...]

SECRETARY MEETING MINUTES:
- File Name: feb-2025-agenda.pdf
  File ID: [paste ID here]

[etc...]
```

I'll then automatically:
1. Create CVMA_Google_Drive_File__mdt records
2. Deploy to Salesforce
3. Verify they work with the Knowledge Article helper class
