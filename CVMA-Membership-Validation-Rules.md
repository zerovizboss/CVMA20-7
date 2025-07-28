# CVMA Membership Validation Rules

## Overview

This document describes the validation rules implemented for the Combat Veterans Motorcycle Association (CVMA) Contact object to ensure data integrity for membership management in a headless/guest user architecture.

## Business Requirements

The CVMA organization needed a way to validate membership data without creating individual user accounts for each member. The solution uses two custom fields on the Contact object:

- **Level__c**: Picklist field defining membership level
- **Membership_Id__c**: Text field containing unique membership identifier with flexible length

## Validation Rules Implemented

### 1. CVMA_Membership_Level_Validation

**Purpose**: Ensures the Membership ID prefix matches the selected membership level.

**Logic**: 
- Full Member → Must start with "FM"
- Support Member → Must start with "SUP"  
- Auxiliary Member → Must start with "AUX"

**Formula**:
```javascript
AND(
  NOT(ISBLANK(TEXT(Level__c))),
  NOT(ISBLANK(Membership_Id__c)),
  OR(
    AND(
      TEXT(Level__c) = "Full Member",
      NOT(BEGINS(UPPER(Membership_Id__c), "FM"))
    ),
    AND(
      TEXT(Level__c) = "Support Member",
      NOT(BEGINS(UPPER(Membership_Id__c), "SUP"))
    ),
    AND(
      TEXT(Level__c) = "Auxiliary Member",
      NOT(BEGINS(UPPER(Membership_Id__c), "AUX"))
    )
  )
)
```

**Error Message**: 
```
Membership ID prefix must match level: Full Member=FM, Support Member=SUP, Auxiliary Member=AUX (e.g., FM1, SUP123, AUX12345)
```

### 2. CVMA_Membership_Format_Validation

**Purpose**: Ensures the Membership ID follows the correct format with flexible length based on membership level.

**Logic**: 
- **Full Member**: FM + 1-5 digits (3-8 characters total)
- **Support Member**: SUP + 1-5 digits (4-8 characters total)
- **Auxiliary Member**: AUX + 1-5 digits (4-8 characters total)
- **Maximum**: 8 characters total for all types

**Formula**:
```javascript
AND(
  NOT(ISBLANK(Membership_Id__c)),
  NOT(ISBLANK(TEXT(Level__c))),
  OR(
    LEN(Membership_Id__c) > 8,
    AND(
      TEXT(Level__c) = "Full Member",
      OR(
        LEN(Membership_Id__c) < 3,
        NOT(REGEX(Membership_Id__c, "^[A-Za-z]{2}[0-9]{1,5}$"))
      )
    ),
    AND(
      TEXT(Level__c) = "Support Member",
      OR(
        LEN(Membership_Id__c) < 4,
        NOT(REGEX(Membership_Id__c, "^[A-Za-z]{3}[0-9]{1,5}$"))
      )
    ),
    AND(
      TEXT(Level__c) = "Auxiliary Member",
      OR(
        LEN(Membership_Id__c) < 4,
        NOT(REGEX(Membership_Id__c, "^[A-Za-z]{3}[0-9]{1,5}$"))
      )
    )
  )
)
```

**Error Message**: 
```
Invalid format. Use: FM+1-5 digits (3-8 chars), SUP+1-5 digits (4-8 chars), or AUX+1-5 digits (4-8 chars)
```

## Valid Examples

| Level | Membership ID | Length | Status |
|-------|---------------|--------|--------|
| Full Member | FM1 | 3 chars | ✅ Valid (minimum) |
| Full Member | FM12345 | 7 chars | ✅ Valid (maximum digits) |
| Full Member | fm999 | 5 chars | ✅ Valid (case insensitive) |
| Support Member | SUP1 | 4 chars | ✅ Valid (minimum) |
| Support Member | SUP12345 | 8 chars | ✅ Valid (maximum) |
| Support Member | sup123 | 6 chars | ✅ Valid (case insensitive) |
| Auxiliary Member | AUX1 | 4 chars | ✅ Valid (minimum) |
| Auxiliary Member | AUX12345 | 8 chars | ✅ Valid (maximum) |
| Auxiliary Member | aux0000 | 7 chars | ✅ Valid (case insensitive) |

## Invalid Examples

| Level | Membership ID | Error | Reason |
|-------|---------------|-------|--------|
| Full Member | SUP1234 | Level Validation | Wrong prefix for Full Member |
| Support Member | AUX6789 | Level Validation | Wrong prefix for Support Member |
| Auxiliary Member | FM11111 | Level Validation | Wrong prefix for Auxiliary Member |
| Full Member | FM | 2 chars | Format Validation | Too short (minimum 3 chars) |
| Support Member | SUP | 3 chars | Format Validation | Too short (minimum 4 chars) |
| Any Member | FM123456 | 8+ chars | Format Validation | Too long (maximum 8 chars) |
| Full Member | FM123A | - | Format Validation | Letter in number portion |
| Support Member | SUP12A34 | - | Format Validation | Letter in number portion |

## Flexible Length Benefits

The new flexible format provides several advantages:

1. **Scalability**: Accommodates organizations of different sizes
2. **Future Growth**: Can handle membership expansion without format changes
3. **Legacy Support**: Can accommodate existing shorter membership IDs
4. **User Friendly**: Shorter IDs are easier to remember and communicate
5. **Consistent Maximum**: 8-character limit ensures field compatibility

## Headless Architecture Benefits

These validation rules support CVMA's headless architecture by:

1. **Data Integrity**: Ensures consistent membership data without requiring user accounts
2. **Guest User Support**: Validates data entered by unauthenticated users
3. **Automated Validation**: Prevents invalid combinations at the database level
4. **Scalability**: Supports large membership without individual user management overhead
5. **Flexible Format**: Accommodates different membership ID lengths and types

## Technical Implementation

### Field Configuration
- **Level__c**: Required picklist field with restricted values
- **Membership_Id__c**: Required text field (10 characters max, unique, external ID)

### Validation Triggers
- Both rules trigger on INSERT and UPDATE operations
- Case-insensitive prefix matching using UPPER() function
- REGEX pattern matching for format validation with flexible length
- Level-specific minimum and maximum length requirements

### Test Coverage
Comprehensive test class `CVMAMembershipValidationTest` provides:
- 100% test coverage for both validation rules (6/6 tests passing)
- Flexible length testing (3-8 character combinations)
- Edge case testing (minimum/maximum lengths, mixed case)
- Positive and negative test scenarios
- Update operation validation
- Boundary condition testing

## Deployment Notes

1. Validation rules are embedded in the Contact.object metadata file
2. Deploy using Salesforce CLI: `sf project deploy start --source-dir src/objects/Contact.object`
3. Test class must be deployed separately: `sf project deploy start --source-dir src/classes/CVMAMembershipValidationTest.cls`
4. Error messages are optimized to fit within 255-character Salesforce limit

## Future Enhancements

Potential improvements for future releases:

1. **Custom Metadata Types**: Store prefix mappings in custom metadata for easier maintenance
2. **Flow Integration**: Create flows for guided membership ID generation with length options
3. **Duplicate Detection**: Add duplicate rule for Membership_Id__c field
4. **Audit Trail**: Track membership level changes with field history tracking
5. **Bulk Data Loader**: Create utility for bulk membership data import with validation
6. **Auto-Generation**: Create flows to auto-generate membership IDs based on level and sequence

## Support and Maintenance

For questions or modifications to these validation rules, contact the CVMA Salesforce development team. All changes should be tested in a sandbox environment before production deployment.

### Change Log

- **v1.2** (December 2024): Updated to flexible length format - FM(3-8 chars), SUP(4-8 chars), AUX(4-8 chars)
- **v1.1** (December 2024): Updated prefixes - Support Member: SM→SUP, Auxiliary Member: AM→AUX
- **v1.0** (December 2024): Initial implementation with FM, SM, AM prefixes

---

**Last Updated**: December 2024  
**Version**: 1.2  
**Author**: CVMA Development Team