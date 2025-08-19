# CVMA Pull Request

## 📋 Description
Brief description of the changes made.

## 🚀 Type of Change
- [ ] 🐛 Bug fix (non-breaking change which fixes an issue)
- [ ] ✨ New feature (non-breaking change which adds functionality)
- [ ] 💥 Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] 📚 Documentation update
- [ ] 🧹 Code refactoring (no functional changes)
- [ ] 🧪 Test additions or modifications
- [ ] 🔧 Build/CI configuration changes

## 🎯 Epic & User Story
- **Epic:**
- **User Story:**
- **GitHub Issue:** Closes #

## ✅ Pre-Submission Checklist

### Code Quality & Standards
- [ ] Code follows CVMA Salesforce development standards
- [ ] All PMD violations addressed (Critical/High priority)
- [ ] Code is properly formatted and follows naming conventions
- [ ] No hardcoded IDs, URLs, or sensitive information
- [ ] Comments and documentation added where necessary

### Security & Best Practices
- [ ] All SOQL queries use `WITH SECURITY_ENFORCED`
- [ ] CRUD/FLS permissions validated using `CVMAErrorHandler.validateCRUDPermissions()`
- [ ] User input sanitized using `CVMAErrorHandler.sanitizeInput()`
- [ ] Guest user access restrictions implemented where applicable
- [ ] Error handling uses `CVMAErrorHandler` framework
- [ ] No XSS vulnerabilities in user-facing outputs

### Testing
- [ ] New test classes created with comprehensive coverage
- [ ] Existing test classes updated where necessary
- [ ] Test data created using `CVMATestDataFactory` patterns
- [ ] Code coverage meets minimum 75% requirement
- [ ] All tests pass locally
- [ ] Edge cases and error scenarios covered

### Salesforce Deployment
- [ ] Metadata properly structured and formatted
- [ ] Dependencies and references are correct
- [ ] No conflicts with existing org configuration
- [ ] Component versions updated appropriately (API 64.0+)

### Documentation
- [ ] MEMORY.md updated with implementation details
- [ ] CLAUDE.md updated if development patterns changed
- [ ] README.md updated if public-facing changes
- [ ] Inline code comments for complex logic

## 🧪 Test Results
- **Local Test Coverage:** __%
- **PMD Violations:** (Critical: __, High: __, Medium: __, Low: __)
- **Apex Test Results:** __ passed / __ total

## 📸 Screenshots (if applicable)
<!-- Add screenshots for UI changes -->

## 🔄 Related Changes
- List any dependent PRs
- Related issues or user stories
- Breaking changes that affect other components

## 📝 Additional Notes
<!-- Any additional information, context, or considerations -->

## 🧑‍💻 Reviewer Instructions
1. **Automated Checks:** Ensure all GitHub Actions pass
2. **PMD Analysis:** Review and approve resolution of critical/high violations
3. **Security Review:** Verify security patterns and data access controls
4. **Test Review:** Confirm comprehensive test coverage and edge cases
5. **Functionality Review:** Test in Salesforce org if UI/logic changes
6. **Documentation Review:** Ensure adequate documentation and comments

## 🚢 Deployment Notes
<!-- Special considerations for deployment -->

---
**Combat Veterans Motorcycle Association - Chapter 20-7**
*Vets Serving Vets* 🏍️
