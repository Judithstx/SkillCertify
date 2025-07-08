**PR Title:** Add SkillCertify smart contract for professional certification management

**PR Description:**

## Summary
This PR introduces SkillCertify, a comprehensive smart contract system for managing professional certifications in the consulting industry. The contract enables organizations to issue verifiable digital certificates that are stored immutably on the Stacks blockchain, providing a transparent and tamper-proof certification system.

## Features Added
- **Issuer Registration System**: Organizations can register as certified issuers with validation
- **Certification Issuance**: Complete certification creation with metadata support and expiration dates
- **Professional Profile Management**: User profiles tracking certification history and achievements
- **Verification System**: Real-time certification validation with expiration checking
- **Statistics Tracking**: Contract-wide metrics for total certifications and professionals
- **Data Integrity**: Comprehensive input validation and error handling

## Technical Implementation
- **Data Structure**: Three primary maps for certifications, issuers, and professional profiles
- **Access Control**: Role-based permissions ensuring only registered issuers can create certifications
- **Expiration Management**: Block-height based expiration system with automatic validation
- **Cross-referencing**: Efficient lookup system linking holders to their certifications
- **State Management**: Proper incremental ID generation and global statistics tracking
- **Error Handling**: Comprehensive error codes for all edge cases

## Testing
- All functions pass clarinet check without errors or warnings
- Input validation tested for edge cases and invalid data
- Access control mechanisms verified for unauthorized access attempts
- Expiration logic tested with various validity periods
- Data integrity confirmed across all map operations

## Future Enhancements
This initial implementation provides the foundation for a robust certification platform with clear paths for expansion and additional features as outlined in the roadmap.

## Breaking Changes
None - this is a new contract implementation.

## Dependencies
- Stacks blockchain
- Clarity smart contract language
- Clarinet development environment