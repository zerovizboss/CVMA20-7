#!/bin/bash

# 🚀 Project Pattern Transfer Automation Script
# Version: 1.0
# Purpose: Transfer CVMA-proven development patterns to new projects
# Usage: ./initialize-project-patterns.sh [platform-type]

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CVMA_REPO_PATH="C:/Users/zerov/IdeaProjects/cvma"
CURRENT_DIR=$(pwd)
PROJECT_NAME=$(basename "$CURRENT_DIR")

# Display banner
echo -e "${BLUE}"
echo "🏍️  CVMA Pattern Transfer Automation"
echo "   Combat Veterans Motorcycle Association"
echo "   Vets Serving Vets through Code Excellence"
echo -e "${NC}"

# Validate input
PLATFORM_TYPE="${1:-salesforce-omnistudio}"

echo -e "${YELLOW}📋 Initializing project: ${PROJECT_NAME}${NC}"
echo -e "${YELLOW}🎯 Platform type: ${PLATFORM_TYPE}${NC}"
echo ""

# Create project directory structure
create_project_structure() {
    echo -e "${BLUE}📁 Creating project directory structure...${NC}"

    mkdir -p .claude/patterns
    mkdir -p docs
    mkdir -p scripts
    mkdir -p src
    mkdir -p tests
    mkdir -p config

    echo -e "${GREEN}✅ Directory structure created${NC}"
}

# Extract CVMA patterns
extract_cvma_patterns() {
    echo -e "${BLUE}📖 Extracting CVMA proven patterns...${NC}"

    # Create patterns directory with extracted patterns
    cat > .claude/patterns/standard-feature-integration.md << 'EOF'
# Standard Feature Integration Pattern

## Core Principle
Leverage platform-native capabilities instead of custom implementations to achieve 70%+ code reduction.

## Implementation Strategy
1. **Identify Native Features**: Research platform-standard capabilities
2. **Map Custom Logic**: Identify areas where native features can replace custom code
3. **Security First**: Implement platform-appropriate security enforcement
4. **Test Comprehensively**: Validate native feature integration
5. **Document Decisions**: Record architectural choices and rationale

## Success Metrics
- Code Reduction: 70%+ target
- Security Compliance: 100% platform-standard enforcement
- Performance: Optimized through native capabilities
- Maintainability: Reduced technical debt through standard features
EOF

    cat > .claude/patterns/security-framework.md << 'EOF'
# Security Framework Pattern

## Platform-Agnostic Security Principles
1. **Authentication**: Platform-native identity management
2. **Authorization**: Role-based access control (RBAC)
3. **Data Protection**: Encryption at rest and in transit
4. **Input Validation**: Comprehensive sanitization and validation
5. **Audit Logging**: Complete activity tracking

## Implementation Guidelines
- Use platform security frameworks (never custom)
- Implement least privilege access
- Validate all user inputs
- Log security-relevant events
- Regular security assessments
EOF

    cat > .claude/patterns/testing-excellence.md << 'EOF'
# Testing Excellence Pattern

## Comprehensive Testing Strategy
1. **Unit Tests**: Individual component validation
2. **Integration Tests**: Component interaction validation
3. **Security Tests**: Access control and data protection validation
4. **Performance Tests**: Load and scalability validation
5. **User Acceptance Tests**: Business requirement validation

## Test Coverage Targets
- Unit Tests: 80%+ code coverage
- Integration Tests: Critical path coverage
- Security Tests: All access points validated
- Performance Tests: Under expected load conditions
EOF

    echo -e "${GREEN}✅ CVMA patterns extracted${NC}"
}

# Generate platform-specific CLAUDE.md
generate_claude_md() {
    echo -e "${BLUE}📝 Generating platform-specific CLAUDE.md...${NC}"

    case $PLATFORM_TYPE in
        "salesforce-omnistudio")
            generate_salesforce_claude_md
            ;;
        "salesforce-experience")
            generate_experience_cloud_claude_md
            ;;
        "python-django")
            generate_django_claude_md
            ;;
        "aws-serverless")
            generate_aws_claude_md
            ;;
        *)
            generate_generic_claude_md
            ;;
    esac

    echo -e "${GREEN}✅ CLAUDE.md generated for ${PLATFORM_TYPE}${NC}"
}

# Salesforce OmniStudio specific CLAUDE.md
generate_salesforce_claude_md() {
    cat > CLAUDE.md << 'EOF'
# CLAUDE.md - OmniStudio Development Guide

This file provides guidance to Claude Code when working with OmniStudio in this repository.

## Project Overview

This is a Salesforce OmniStudio project implementing AI-enhanced learning management system capabilities. The codebase includes:

- **OmniStudio Components**: FlexCards, OmniScripts, Integration Procedures
- **Lightning Web Components**: Custom LWC for enhanced user experience
- **Apex Controllers**: Business logic with CVMA-proven security patterns
- **Data Models**: Optimized for learning management and analytics
- **Integration Layer**: External service connectivity and API management

## Development Commands

### Salesforce CLI Commands
```bash
# Deploy OmniStudio metadata
sf project deploy start --metadata "OmniUiCard,OmniScript,OmniDataTransform"

# Retrieve OmniStudio components
sf project retrieve start --metadata "OmniUiCard,OmniScript,OmniDataTransform"

# Test Apex components
sf apex run test --code-coverage

# Open scratch org
sf org open
```

## Architecture Notes

### OmniStudio Best Practices
- **FlexCard Design**: Responsive, accessible card layouts
- **OmniScript Logic**: Minimized custom code through platform features
- **Integration Procedures**: Efficient data transformation and API calls
- **DataRaptor Extract/Load**: Optimized data operations

### Standard Feature Integration Applied
- **Platform-Native Components**: Leverage OmniStudio capabilities vs custom development
- **Security Framework**: WITH SECURITY_ENFORCED in all Apex code
- **Performance Optimization**: Efficient DataRaptor and caching strategies
- **Test Coverage**: 80%+ target with comprehensive validation

### Testing Patterns
- All Apex classes follow CVMA testing excellence patterns
- OmniStudio component testing through user scenarios
- Integration testing for external service connectivity
- Performance testing for data-intensive operations

## CVMA Pattern Application

### Security Implementation
- Role-based access control for learning content
- Data protection for student/user information
- Input validation for all user inputs
- Comprehensive audit logging

### Performance Optimization
- Efficient OmniStudio component design
- Optimized DataRaptor operations
- Caching strategies for frequently accessed data
- Governor limit management

### Code Quality Standards
- Use OmniStudio best practices for component design
- Comprehensive error handling
- Clear documentation for business logic
- Regular code reviews and pattern validation

## Memory Notes

- **OmniStudio Excellence**: Leverage platform capabilities for maximum efficiency
- **AI Integration**: Enhance learning experience through intelligent features
- **CVMA Patterns**: Apply proven security and performance patterns
- **User Experience**: Focus on accessibility and responsive design
EOF
}

# Generate additional platform templates (simplified for brevity)
generate_experience_cloud_claude_md() {
    cat > CLAUDE.md << 'EOF'
# CLAUDE.md - Experience Cloud Development Guide

## Project Overview
Salesforce Experience Cloud implementation with CVMA-proven patterns.

## Development Commands
```bash
sf community create --name "Community Name" --template-name "Customer Service"
sf community publish --name "Community Name"
```

## Architecture Notes
- Experience Builder for site construction
- Lightning components for custom functionality
- Profile-based access control
- Mobile-responsive design

## CVMA Pattern Application
- Standard Feature Integration through Experience Builder
- Security through Profiles and Permission Sets
- Performance through Lightning caching
- Testing through user journey validation
EOF
}

generate_django_claude_md() {
    cat > CLAUDE.md << 'EOF'
# CLAUDE.md - Django Development Guide

## Project Overview
Django web application with CVMA-adapted patterns.

## Development Commands
```bash
python manage.py runserver
python manage.py test
python manage.py migrate
python manage.py collectstatic
```

## Architecture Notes
- Django REST Framework for APIs
- PostgreSQL for database
- Redis for caching
- Celery for background tasks

## CVMA Pattern Application
- Django built-in features vs custom code
- Django authentication and permissions
- Django ORM with security best practices
- Comprehensive test coverage with pytest
EOF
}

generate_aws_claude_md() {
    cat > CLAUDE.md << 'EOF'
# CLAUDE.md - AWS Serverless Development Guide

## Project Overview
AWS serverless application with CVMA-adapted patterns.

## Development Commands
```bash
sam build
sam deploy
sam local start-api
aws lambda invoke
```

## Architecture Notes
- Lambda functions for business logic
- API Gateway for REST endpoints
- DynamoDB for data storage
- CloudFormation for infrastructure

## CVMA Pattern Application
- AWS managed services vs custom implementations
- IAM for security and access control
- CloudWatch for monitoring and logging
- AWS native testing and deployment
EOF
}

generate_generic_claude_md() {
    cat > CLAUDE.md << 'EOF'
# CLAUDE.md - Development Guide

## Project Overview
Generic project with CVMA-adapted development patterns.

## Development Commands
Platform-specific commands will be added based on technology stack.

## Architecture Notes
- Standard Feature Integration principles applied
- Security-first development approach
- Comprehensive testing strategy
- Performance optimization through platform features

## CVMA Pattern Application
- Leverage platform-native capabilities
- Implement robust security framework
- Maintain high test coverage
- Document architectural decisions
EOF
}

# Create session initialization script
create_session_scripts() {
    echo -e "${BLUE}⚙️  Creating session automation scripts...${NC}"

    cat > scripts/claude-session-init.sh << 'EOF'
#!/bin/bash
# Claude Code session initialization script

echo "🏍️ CVMA Development Environment"
echo "   Project: $(basename $(pwd))"
echo "   Vets Serving Vets through Code Excellence"
echo ""

# Display current git status
if [ -d ".git" ]; then
    echo "📊 Git Status:"
    git status --porcelain | head -5
    echo ""
fi

# Display project overview
if [ -f "CLAUDE.md" ]; then
    echo "📖 Development Guide: CLAUDE.md available"
else
    echo "⚠️  No CLAUDE.md found - run pattern initialization"
fi

echo ""
echo "✅ Development environment ready!"
echo ""
EOF

    chmod +x scripts/claude-session-init.sh

    # Platform-specific deployment script
    case $PLATFORM_TYPE in
        "salesforce-"*)
            cat > scripts/deploy.sh << 'EOF'
#!/bin/bash
# Salesforce deployment script

echo "🚀 Deploying to Salesforce..."
sf project deploy start --wait 10
echo "✅ Deployment complete!"
EOF
            ;;
        *)
            cat > scripts/deploy.sh << 'EOF'
#!/bin/bash
# Generic deployment script

echo "🚀 Platform-specific deployment commands will be added here"
EOF
            ;;
    esac

    chmod +x scripts/deploy.sh

    echo -e "${GREEN}✅ Session scripts created${NC}"
}

# Create Claude Code configuration
create_claude_config() {
    echo -e "${BLUE}⚙️  Creating Claude Code configuration...${NC}"

    cat > .claude/settings.local.json << EOF
{
  "workingDirectory": "$(pwd)",
  "projectName": "${PROJECT_NAME}",
  "platform": "${PLATFORM_TYPE}",
  "patterns": {
    "standardFeatureIntegration": true,
    "securityFirst": true,
    "testingExcellence": true,
    "documentationRequired": true
  },
  "codeReductionTarget": 70,
  "testCoverageTarget": 80
}
EOF

    echo -e "${GREEN}✅ Claude Code configuration created${NC}"
}

# Create project documentation
create_project_docs() {
    echo -e "${BLUE}📚 Creating project documentation...${NC}"

    cat > README.md << EOF
# ${PROJECT_NAME}

$(echo $PLATFORM_TYPE | tr '-' ' ' | awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr($i,1,1)),$i)}1') project with CVMA-proven development patterns.

## Quick Start

\`\`\`bash
# Initialize development session
./scripts/claude-session-init.sh

# Run tests
./scripts/test.sh

# Deploy application
./scripts/deploy.sh
\`\`\`

## Development

This project implements CVMA-proven patterns:
- Standard Feature Integration (70%+ code reduction target)
- Security-first development approach
- Comprehensive testing strategy
- Performance optimization through platform features

## Documentation

- [Development Guide](CLAUDE.md) - Claude Code development instructions
- [Architecture](docs/ARCHITECTURE.md) - System architecture overview
- [Patterns](docs/PATTERNS.md) - Applied development patterns

## Getting Help

Refer to CLAUDE.md for platform-specific development guidance and commands.
EOF

    cat > docs/ARCHITECTURE.md << EOF
# ${PROJECT_NAME} Architecture

## Overview
$(echo $PLATFORM_TYPE | tr '-' ' ') implementation with CVMA-adapted patterns.

## Principles
- Standard Feature Integration
- Security-first design
- Performance optimization
- Comprehensive testing

## Components
[Components will be documented as development progresses]

## Patterns Applied
- Security Framework
- Testing Excellence
- Performance Optimization
- Documentation Standards
EOF

    echo -e "${GREEN}✅ Project documentation created${NC}"
}

# Main execution
main() {
    echo -e "${YELLOW}🚀 Starting pattern transfer automation...${NC}"
    echo ""

    create_project_structure
    extract_cvma_patterns
    generate_claude_md
    create_session_scripts
    create_claude_config
    create_project_docs

    echo ""
    echo -e "${GREEN}🎉 Pattern transfer complete!${NC}"
    echo ""
    echo -e "${BLUE}📋 Next steps:${NC}"
    echo "1. Review generated CLAUDE.md for project-specific guidance"
    echo "2. Run ./scripts/claude-session-init.sh to initialize development"
    echo "3. Begin development with proven CVMA patterns"
    echo ""
    echo -e "${YELLOW}🏍️ Vets Serving Vets through Code Excellence!${NC}"
}

# Execute main function
main "$@"