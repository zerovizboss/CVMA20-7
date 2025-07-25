# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Salesforce project for the Combat Veterans Motorcycle Association (CVMA). The codebase includes:

- **Salesforce Communities**: Multiple community sites including CEB, Combat Veterans Motorcycle Association, and Default Help Center
- **Apex Classes**: Custom business logic including authentication controllers, iterables, and test classes
- **Lightning Components**: Custom Aura components for site functionality
- **Third-party Packages**: Includes NPSP (Nonprofit Success Pack), Google Drive connector, map plotting tools, and Trailhead integration
- **Custom Objects**: Various custom objects with DNBI__, Extentia_SIM__, npsp__, and trailheadapp__ namespaces

## Development Commands

### Salesforce CLI Commands
The project uses Salesforce CLI (`sf` command) for development:

```bash
# Deploy metadata to org
sf project deploy start

# Retrieve metadata from org  
sf project retrieve start

# Run Apex tests
sf apex run test

# Execute anonymous Apex
sf apex run

# Open default org
sf org open

# Check CLI status and configuration
sf doctor

# View org information
sf org display
```

### Testing
- Apex test classes follow the pattern `*Test.cls` (e.g., `MyIterableTest.cls`)
- Run tests using: `sf apex run test`
- Test classes use `@IsTest` annotation and standard Apex testing patterns

## Architecture Notes

### Package Structure
- **src/**: Main source directory containing all Salesforce metadata
- **classes/**: Apex classes and test classes (.cls files with .cls-meta.xml metadata)
- **aura/**: Lightning Aura components
- **objects/**: Custom and standard object configurations
- **layouts/**: Page layouts for various objects
- **communities/**: Experience Cloud site configurations
- **flows/**: Process automation flows

### Key Namespaces
- **DNBI__**: Dun & Bradstreet integration package
- **Extentia_SIM__**: Map plotting functionality 
- **npsp__**: Nonprofit Success Pack for donor management
- **trailheadapp__**: Trailhead integration for learning management
- **V2_Gdrive__**: Google Drive connector
- **lightngcarousel__**: Lightning carousel components

### Testing Patterns
- All test classes are in `src/classes/` with `Test` suffix
- Use `@IsTest` annotation for test classes and methods
- Standard System.debug() for debugging in tests
- Follow Salesforce testing best practices with test data creation

### Communities Setup
The org has multiple Experience Cloud communities configured:
- Internal Zone (internal users)
- CEB community 
- Combat Veterans Motorcycle Association main community
- Default Help Center for support

Each community has its own branding, navigation menus, and moderation rules configured.