#!/bin/bash

# CVMA 20-7 GitHub Project Setup Script
# Run this script after authenticating with GitHub CLI: ./bin/gh.exe auth login

echo "Setting up CVMA 20-7 GitHub Project..."

# Step 1: Authenticate (run this first)
echo "Step 1: Authenticate with GitHub CLI"
echo "Run: ./bin/gh.exe auth login"
echo "Follow the prompts to authenticate with your GitHub account"
echo ""

# Step 2: Create the GitHub Project
echo "Step 2: Creating GitHub Project..."
./bin/gh.exe project create \
  --title "CVMA 20-7 Experience Builder Enhancement" \
  --body "Combat Veterans Motorcycle Association Chapter 20-7 digital platform enhancement project. Mission: Transform the current guest calendar access into a comprehensive veteran services platform that serves the 'Vets Serving Vets' mission." \
  --public

echo "Project created successfully!"

# Step 3: Get project information
echo "Step 3: Getting project details..."
PROJECT_URL=$(./bin/gh.exe project list --owner zerovizboss --format json | jq -r '.projects[] | select(.title=="CVMA 20-7 Experience Builder Enhancement") | .url')
echo "Project URL: $PROJECT_URL"

# Step 4: Create Epic Issues
echo "Step 4: Creating Epic issues..."

# Epic 1: Enhanced Member Management
./bin/gh.exe issue create \
  --title "[EPIC] Enhanced Member Management" \
  --body "## Epic Description
Streamline membership processes and improve member engagement

## Business Value
- Reduce manual membership processing time
- Improve member satisfaction through self-service
- Enable better member tracking and communication

## User Stories
- [ ] As a CVMA member, I want to update my profile information online
- [ ] As a CVMA chapter officer, I want to view member status and renewal dates  
- [ ] As a prospective member, I want to submit a membership application online

## Acceptance Criteria
- [ ] All user stories completed and tested
- [ ] Member self-service functionality working
- [ ] Officer dashboard operational
- [ ] Application workflow functional

## Estimated Story Points: 21
## Priority: High" \
  --label "epic,enhancement,high-priority"

# Epic 2: Event Management & Calendar Enhancement
./bin/gh.exe issue create \
  --title "[EPIC] Event Management & Calendar Enhancement" \
  --body "## Epic Description
Improve event participation and member engagement through enhanced calendar and RSVP functionality

## Business Value
- Increase event attendance through better communication
- Streamline event management processes
- Provide guest access to appropriate events

## User Stories
- [ ] As a CVMA member, I want to RSVP for events and see attendees
- [ ] As an event organizer, I want to create and manage chapter events
- [ ] As a guest user, I want to view public events and request attendance

## Acceptance Criteria
- [ ] All user stories completed and tested
- [ ] RSVP system functional
- [ ] Event management tools working
- [ ] Guest access properly configured

## Estimated Story Points: 18
## Priority: High" \
  --label "epic,enhancement,high-priority"

# Epic 3: Resource Library & Documentation
./bin/gh.exe issue create \
  --title "[EPIC] Resource Library & Documentation" \
  --body "## Epic Description
Centralize information and improve member access to chapter resources and documentation

## Business Value
- Improve information accessibility for members
- Reduce administrative overhead for document sharing
- Enable better knowledge management

## User Stories
- [ ] As a CVMA member, I want to access chapter documents and bylaws
- [ ] As a chapter secretary, I want to upload and organize official documents

## Acceptance Criteria
- [ ] All user stories completed and tested
- [ ] Document library functional
- [ ] Search and organization features working
- [ ] Access controls properly implemented

## Estimated Story Points: 13
## Priority: Medium" \
  --label "epic,enhancement,medium-priority"

# Epic 4: Communication Hub
./bin/gh.exe issue create \
  --title "[EPIC] Communication Hub" \
  --body "## Epic Description
Enhance member communication and community building through forums and announcement systems

## Business Value
- Improve member engagement and community building
- Streamline communication processes
- Enable better information dissemination

## User Stories
- [ ] As a CVMA member, I want to participate in chapter discussions
- [ ] As a chapter leader, I want to send announcements to all members

## Acceptance Criteria
- [ ] All user stories completed and tested
- [ ] Forum functionality operational
- [ ] Announcement system working
- [ ] Moderation tools functional

## Estimated Story Points: 16
## Priority: Medium" \
  --label "epic,enhancement,medium-priority"

# Epic 5: Veteran Support Services
./bin/gh.exe issue create \
  --title "[EPIC] Veteran Support Services" \
  --body "## Epic Description
Fulfill the 'Vets Serving Vets' mission through digital veteran support resources and coordination tools

## Business Value
- Support the core CVMA mission of veteran assistance
- Improve coordination of support activities
- Provide better resource access for veterans in need

## User Stories
- [ ] As a veteran in need, I want to find local veteran resources
- [ ] As a CVMA volunteer, I want to coordinate veteran assistance activities

## Acceptance Criteria
- [ ] All user stories completed and tested
- [ ] Resource directory functional
- [ ] Volunteer coordination system working
- [ ] Request tracking operational

## Estimated Story Points: 15
## Priority: High" \
  --label "epic,enhancement,high-priority"

# Epic 6: Mobile Experience Optimization
./bin/gh.exe issue create \
  --title "[EPIC] Mobile Experience Optimization" \
  --body "## Epic Description
Improve accessibility and usability for mobile users across all platform features

## Business Value
- Improve user experience for mobile users
- Increase platform accessibility
- Support modern usage patterns

## User Stories
- [ ] As a mobile user, I want the site to work seamlessly on my phone

## Acceptance Criteria
- [ ] All user stories completed and tested
- [ ] Responsive design implemented
- [ ] Mobile performance optimized
- [ ] Touch-friendly interface operational

## Estimated Story Points: 10
## Priority: Medium" \
  --label "epic,enhancement,medium-priority"

echo "All Epic issues created successfully!"

# Step 5: Add issues to project (requires project ID)
echo "Step 5: Adding issues to project..."
echo "You'll need to manually add the created issues to your project board"
echo "Visit your project at: $PROJECT_URL"
echo "Use the 'Add item' feature to add the Epic issues we just created"

echo ""
echo "GitHub Project Setup Complete!"
echo "Next steps:"
echo "1. Visit your project: $PROJECT_URL"
echo "2. Configure custom fields (Epic, Priority, Story Points, Sprint, etc.)"
echo "3. Set up project views (Epic Overview, Sprint Planning, etc.)"
echo "4. Add the Epic issues to your project board"
echo "5. Create individual user story issues for each epic"
echo "6. Set up milestones and begin sprint planning"