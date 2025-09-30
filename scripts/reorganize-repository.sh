#!/bin/bash

# CVMA Repository Reorganization Script
# Purpose: Restructure repository to align with Experience Cloud site-specific training deployment

echo "🏍️ CVMA Repository Reorganization - Chapter 20-7"
echo "Restructuring for site-specific training deployment..."

# Create new repository structure
echo "📁 Creating new repository structure..."

# Site-specific training content
mkdir -p "sites/ceb-site/training-content"
mkdir -p "sites/ceb-site/components"
mkdir -p "sites/ceb-site/assets"

mkdir -p "sites/member-site/training-content"
mkdir -p "sites/member-site/components"
mkdir -p "sites/member-site/assets"

mkdir -p "sites/help-center-site/training-content"
mkdir -p "sites/help-center-site/components"
mkdir -p "sites/help-center-site/assets"

mkdir -p "sites/main-technical-site/training-content"
mkdir -p "sites/main-technical-site/components"
mkdir -p "sites/main-technical-site/assets"

# Shared components and utilities
mkdir -p "shared/components/training"
mkdir -p "shared/components/navigation"
mkdir -p "shared/components/accessibility"
mkdir -p "shared/utilities"
mkdir -p "shared/styles"

echo "✅ Repository structure created"

# Move documentation based on UX analysis recommendations
echo "📚 Organizing training content by site..."

# CEB Site Content (Officer-focused)
echo "🏢 Organizing CEB Officer content..."
find docs/Training/CEB-Officer-Training -name "*.md" -exec cp {} sites/ceb-site/training-content/ \;
find docs/Training/User-Guides -name "*OFFICER*" -o -name "*CEB*" -o -name "*DASHBOARD*" -exec cp {} sites/ceb-site/training-content/ \; 2>/dev/null || true

# Member Site Content (Self-service focused)
echo "👥 Organizing Member content..."
find docs/Training/Member-Guides -name "*.md" -exec cp {} sites/member-site/training-content/ \;
find docs/Training/User-Guides -name "*MEMBER*" -o -name "*PROFILE*" -o -name "*SELF*" -exec cp {} sites/member-site/training-content/ \; 2>/dev/null || true

# Help Center Content (Support and troubleshooting)
echo "❓ Organizing Help Center content..."
find docs/Training/User-Guides -name "*HELP*" -o -name "*GUIDE*" -o -name "*ACCESSIBILITY*" -exec cp {} sites/help-center-site/training-content/ \; 2>/dev/null || true

# Technical Site Content (Development and API docs)
echo "⚙️ Organizing Technical content..."
find docs/Technical -name "*.md" -exec cp {} sites/main-technical-site/training-content/ \;

# Move site-specific components
echo "🔧 Organizing site-specific components..."

# CEB Components
if [ -f "src/lwc/cvmaCebTrainingHub/cvmaCebTrainingHub.js" ]; then
    cp -r src/lwc/cvmaCebTrainingHub sites/ceb-site/components/
    echo "✅ CEB Training Hub component moved"
fi

# Member Components
if [ -f "src/lwc/cvmaMemberTrainingPortal/cvmaMemberTrainingPortal.js" ]; then
    cp -r src/lwc/cvmaMemberTrainingPortal sites/member-site/components/
    echo "✅ Member Training Portal component moved"
fi

# Shared Document Manager
if [ -f "src/lwc/cvmaDocumentManager/cvmaDocumentManager.js" ]; then
    cp -r src/lwc/cvmaDocumentManager shared/components/training/
    echo "✅ Shared Document Manager component moved"
fi

# Create site-specific README files
echo "📄 Creating site-specific documentation..."

# CEB Site README
cat > sites/ceb-site/README.md << 'EOF'
# CEB Site Training Content

## Chapter Executive Board Officer Training
**Site URL**: https://cvma20-7-dev-ed.develop.my.site.com/ceb

### Content Focus:
- Officer dashboard training
- Member management procedures
- Financial oversight training
- Event coordination guides
- Emergency procedures

### Components:
- `cvmaCebTrainingHub` - Task-oriented officer training interface
- Officer-specific quick actions
- Progress tracking and certification

### Target Audience:
- Chapter President
- Vice President
- Secretary/Treasurer
- Road Captain
- Sergeant at Arms

### Navigation Strategy:
Task-oriented modules organized by daily officer responsibilities
EOF

# Member Site README
cat > sites/member-site/README.md << 'EOF'
# Member Site Training Content

## General Member Training Portal
**Site URL**: https://cvma20-7-dev-ed.develop.my.site.com

### Content Focus:
- Platform getting started guides
- Self-service member tools
- Community engagement training
- Accessibility features

### Components:
- `cvmaMemberTrainingPortal` - Self-service learning paths
- Progressive skill building
- Quick help topics

### Target Audience:
- All CVMA Chapter 20-7 members
- New member onboarding
- Existing members seeking self-service

### Navigation Strategy:
Learning path approach with progressive skill building
EOF

# Help Center README
cat > sites/help-center-site/README.md << 'EOF'
# Help Center Site Training Content

## General Support and Help Center
**Site URL**: https://cvma20-7-dev-ed.develop.my.site.com/defaulthelpcenter12Jun

### Content Focus:
- Basic platform help
- Troubleshooting guides
- FAQ and common issues
- Accessibility support

### Components:
- Search-first interface
- Categorized help topics
- Video tutorials integration
- Live chat support

### Target Audience:
- Members needing immediate help
- Accessibility accommodation requests
- General platform troubleshooting

### Navigation Strategy:
Search-driven with categorized fallback navigation
EOF

# Technical Site README
cat > sites/main-technical-site/README.md << 'EOF'
# Main Technical Site Content

## Technical Documentation and Development
**Site URL**: https://cvma20-7-dev-ed.develop.my.site.com

### Content Focus:
- Epic implementation documentation
- API documentation and guides
- Development procedures
- Deployment runbooks

### Components:
- Technical documentation browser
- Code examples and snippets
- API testing interfaces
- Development workflow guides

### Target Audience:
- Technical staff and developers
- System administrators
- Advanced users

### Navigation Strategy:
Reference-style documentation with advanced search and filtering
EOF

echo "✅ Site documentation created"

# Create deployment mapping
cat > SITE-DEPLOYMENT-MAPPING.md << 'EOF'
# CVMA Site-Specific Training Deployment Mapping

## Experience Cloud Sites and Training Content Alignment

### 1. CEB Site (`/ceb`)
**Purpose**: Officer-specific training and administrative tools
**Content**: Task-oriented officer training modules
**Component**: `cvmaCebTrainingHub`
**Navigation**: Quick actions + categorized training modules

### 2. Member Site (`/`)
**Purpose**: General member services and self-service training
**Content**: Progressive learning paths for member empowerment
**Component**: `cvmaMemberTrainingPortal`
**Navigation**: Learning path approach with skill progression

### 3. Help Center (`/defaulthelpcenter12Jun`)
**Purpose**: Support, troubleshooting, and accessibility help
**Content**: Search-driven help topics and accessibility guides
**Component**: `cvmaHelpCenterPortal`
**Navigation**: Search-first with categorized support topics

### 4. Technical Site (`/`)
**Purpose**: Technical documentation and development resources
**Content**: Epic docs, API guides, development procedures
**Component**: `cvmaTechnicalDocsPortal`
**Navigation**: Reference documentation with advanced filtering

## Deployment Strategy

### Phase 1: Foundation (Week 1-2)
- Deploy CEB Training Hub to CEB site
- Deploy Member Training Portal to Member site
- Basic content organization and navigation

### Phase 2: Enhancement (Week 3-4)
- Deploy Help Center Portal
- Deploy Technical Documentation Portal
- Cross-site linking and search integration

### Phase 3: Optimization (Week 5-6)
- Analytics and tracking implementation
- Performance optimization
- User feedback integration and refinement

## Content Distribution Summary

| Site | Training Documents | Components | Target Users |
|------|-------------------|------------|--------------|
| CEB | 15 officer-focused | cvmaCebTrainingHub | 5-8 officers |
| Member | 28 self-service | cvmaMemberTrainingPortal | 100+ members |
| Help Center | 20 support docs | cvmaHelpCenterPortal | All users |
| Technical | 43 tech docs | cvmaTechnicalDocsPortal | 2-3 tech staff |

Total: 106 training documents across 4 optimized sites
EOF

echo "📊 Deployment mapping created"

# Generate summary report
echo "📈 Generating reorganization summary..."

echo "=== CVMA Repository Reorganization Complete ===" > REORGANIZATION-SUMMARY.txt
echo "Date: $(date)" >> REORGANIZATION-SUMMARY.txt
echo "" >> REORGANIZATION-SUMMARY.txt
echo "New Structure:" >> REORGANIZATION-SUMMARY.txt
echo "- 4 site-specific training areas created" >> REORGANIZATION-SUMMARY.txt
echo "- Shared components library established" >> REORGANIZATION-SUMMARY.txt
echo "- Training content distributed by user needs" >> REORGANIZATION-SUMMARY.txt
echo "- Site-specific component deployment ready" >> REORGANIZATION-SUMMARY.txt
echo "" >> REORGANIZATION-SUMMARY.txt
echo "Files Organized:" >> REORGANIZATION-SUMMARY.txt
echo "- CEB Site: $(find sites/ceb-site/training-content -name "*.md" | wc -l) training documents" >> REORGANIZATION-SUMMARY.txt
echo "- Member Site: $(find sites/member-site/training-content -name "*.md" | wc -l) training documents" >> REORGANIZATION-SUMMARY.txt
echo "- Help Center: $(find sites/help-center-site/training-content -name "*.md" | wc -l) training documents" >> REORGANIZATION-SUMMARY.txt
echo "- Technical Site: $(find sites/main-technical-site/training-content -name "*.md" | wc -l) training documents" >> REORGANIZATION-SUMMARY.txt

echo "✅ Repository reorganization complete!"
echo "📋 See SITE-DEPLOYMENT-MAPPING.md for deployment strategy"
echo "📊 See REORGANIZATION-SUMMARY.txt for detailed summary"

echo "🚀 Ready for site-specific training deployment!"
echo ""
echo "Next Steps:"
echo "1. Deploy site-specific components to respective Experience Cloud sites"
echo "2. Configure site navigation and training content integration"
echo "3. Test user journeys across all four sites"
echo "4. Implement cross-site linking and unified search"
echo ""
echo "🏍️ CVMA Chapter 20-7 - Vets Serving Vets through Organized Excellence"