#!/bin/bash

# CVMA Documentation Organization Script
# Purpose: Organize 143+ markdown files into Training and Technical categories

echo "🏍️ CVMA Documentation Organization - Chapter 20-7"
echo "Organizing 143+ files for CEB training and technical reference..."

# Create organized folder structure
mkdir -p "docs/Training/User-Guides"
mkdir -p "docs/Training/CEB-Officer-Training"
mkdir -p "docs/Training/Member-Guides"
mkdir -p "docs/Technical/Epic-Documentation"
mkdir -p "docs/Technical/Development-Guides"
mkdir -p "docs/Technical/API-Documentation"
mkdir -p "docs/Technical/Deployment-Runbooks"

echo "✅ Created folder structure"

# Training Documentation (Non-technical, User-facing)
echo "📚 Moving Training Documentation..."

# CEB Officer Training Materials
mv *GUIDE*.md docs/Training/User-Guides/ 2>/dev/null || echo "No GUIDE files to move"
mv *USER*.md docs/Training/User-Guides/ 2>/dev/null || echo "No USER files to move"
mv CEB-*.md docs/Training/CEB-Officer-Training/ 2>/dev/null || echo "No CEB files to move"

# Member Training Materials
mv *ACCESSIBILITY*.md docs/Training/Member-Guides/ 2>/dev/null || echo "No ACCESSIBILITY files to move"
mv *TUTORIAL*.md docs/Training/Member-Guides/ 2>/dev/null || echo "No TUTORIAL files to move"
mv *HOW-TO*.md docs/Training/Member-Guides/ 2>/dev/null || echo "No HOW-TO files to move"

# Technical Documentation (Development-focused)
echo "⚙️ Moving Technical Documentation..."

# Epic Documentation
mv EPIC-*.md docs/Technical/Epic-Documentation/ 2>/dev/null || echo "No EPIC files to move"
mv USER-STORY-*.md docs/Technical/Epic-Documentation/ 2>/dev/null || echo "No USER-STORY files to move"

# Development Documentation
mv *DEVELOPMENT*.md docs/Technical/Development-Guides/ 2>/dev/null || echo "No DEVELOPMENT files to move"
mv *AUTOMATION*.md docs/Technical/Development-Guides/ 2>/dev/null || echo "No AUTOMATION files to move"
mv *TECHNICAL*.md docs/Technical/Development-Guides/ 2>/dev/null || echo "No TECHNICAL files to move"

# Deployment Documentation
mv *DEPLOYMENT*.md docs/Technical/Deployment-Runbooks/ 2>/dev/null || echo "No DEPLOYMENT files to move"
mv *RUNBOOK*.md docs/Technical/Deployment-Runbooks/ 2>/dev/null || echo "No RUNBOOK files to move"

# API and Integration Documentation
mv *API*.md docs/Technical/API-Documentation/ 2>/dev/null || echo "No API files to move"
mv *INTEGRATION*.md docs/Technical/API-Documentation/ 2>/dev/null || echo "No INTEGRATION files to move"

echo "✅ Documentation organization complete!"

# Generate index files
echo "📋 Generating index files..."

# Training Index
cat > docs/Training/README.md << 'EOF'
# CVMA Chapter 20-7 Training Documentation

## For CEB Officers and Members

### 📋 CEB Officer Training
- Complete officer dashboard training
- Member management procedures
- Event coordination guides
- Financial oversight training

### 👥 Member Guides
- Accessibility features and support
- Platform navigation tutorials
- Self-service capabilities
- Community engagement tools

### 📖 User Guides
- Step-by-step feature instructions
- Troubleshooting common issues
- Best practices for platform use
- FAQ and support resources

*All training materials are designed for non-technical users*
EOF

# Technical Index
cat > docs/Technical/README.md << 'EOF'
# CVMA Chapter 20-7 Technical Documentation

## For Developers and Technical Staff

### 🚀 Epic Documentation
- Complete Epic implementation details
- User Story technical specifications
- Code reduction achievements
- Quality metrics and testing

### ⚙️ Development Guides
- Architecture patterns and standards
- Claude WX development protocols
- Automation frameworks
- Code quality guidelines

### 🔧 Deployment Runbooks
- Environment setup procedures
- Release management processes
- Rollback and recovery procedures
- Monitoring and maintenance

### 🔗 API Documentation
- Salesforce integration patterns
- External API implementations
- Security and authentication
- Performance optimization

*Technical documentation for development team use*
EOF

echo "✅ Index files generated"

# Count organized files
echo "📊 Organization Summary:"
echo "Training Documents: $(find docs/Training -name "*.md" | wc -l)"
echo "Technical Documents: $(find docs/Technical -name "*.md" | wc -l)"
echo "Remaining in root: $(ls *.md 2>/dev/null | wc -l)"

echo "🏍️ CVMA Documentation Organization Complete!"
echo "Ready for CEB training and technical reference"