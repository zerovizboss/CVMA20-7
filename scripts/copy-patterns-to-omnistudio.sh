#!/bin/bash

# 🚀 OmniStudio Pattern Transfer Script
# Purpose: Copy CVMA patterns to OmniStudio repository with one command
# Usage: ./copy-patterns-to-omnistudio.sh

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
CVMA_REPO="C:/Users/zerov/IdeaProjects/cvma"
OMNISTUDIO_REPO="C:/Users/zerov/IdeaProjects/OmniStudio"

echo -e "${BLUE}"
echo "🏍️  CVMA → OmniStudio Pattern Transfer"
echo "   Copying proven development patterns"
echo "   Vets Serving Vets through Code Excellence"
echo -e "${NC}"

# Validate directories exist
if [ ! -d "$CVMA_REPO" ]; then
    echo -e "${RED}❌ CVMA repository not found: $CVMA_REPO${NC}"
    exit 1
fi

if [ ! -d "$OMNISTUDIO_REPO" ]; then
    echo -e "${YELLOW}📁 Creating OmniStudio directory: $OMNISTUDIO_REPO${NC}"
    mkdir -p "$OMNISTUDIO_REPO"
fi

echo -e "${BLUE}📋 Copying automation scripts to OmniStudio...${NC}"

# Create scripts directory in OmniStudio
mkdir -p "$OMNISTUDIO_REPO/scripts"

# Copy the pattern transfer script
cp "$CVMA_REPO/scripts/initialize-project-patterns.sh" "$OMNISTUDIO_REPO/scripts/"

# Create OmniStudio-specific quick setup script
cat > "$OMNISTUDIO_REPO/setup-omnistudio.sh" << 'EOF'
#!/bin/bash

# 🚀 OmniStudio Quick Setup Script
# Usage: ./setup-omnistudio.sh

echo "🏍️ Setting up OmniStudio with CVMA patterns..."

# Run the pattern transfer automation
./scripts/initialize-project-patterns.sh salesforce-omnistudio

echo ""
echo "✅ OmniStudio setup complete!"
echo "📖 Review CLAUDE.md for development guidance"
echo "🚀 Ready for AI-enhanced learning management development!"
EOF

chmod +x "$OMNISTUDIO_REPO/setup-omnistudio.sh"
chmod +x "$OMNISTUDIO_REPO/scripts/initialize-project-patterns.sh"

echo -e "${GREEN}✅ Pattern transfer scripts copied successfully!${NC}"
echo ""
echo -e "${YELLOW}📋 Next steps:${NC}"
echo "1. Navigate to OmniStudio repository:"
echo "   cd $OMNISTUDIO_REPO"
echo ""
echo "2. Run the automated setup:"
echo "   ./setup-omnistudio.sh"
echo ""
echo "3. Begin development with proven CVMA patterns!"
echo ""
echo -e "${BLUE}🎯 OmniStudio ready for AI-enhanced learning management development!${NC}"