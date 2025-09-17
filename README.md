# SkillCertify - Decentralized Professional Certification Platform

A comprehensive smart contract built on Stacks blockchain for issuing, managing, and verifying professional certifications with multi-signature governance support and automated renewal system.

## 🎯 Overview

SkillCertify enables organizations to issue tamper-proof professional certifications while maintaining trust through a multi-signature approval process for high-level certifications. The platform provides a complete ecosystem for certification management, verification, professional profile tracking, and automated renewal processes with continuing education requirements.

## ✨ Features

### Core Functionality
- **Multi-tiered Certification System** - 4 levels: Basic, Intermediate, Advanced, Expert
- **Multi-signature Governance** - Democratic approval for high-level certifications
- **Professional Profiles** - Comprehensive profile management for certificate holders
- **Issuer Management** - Secure registration and authorization system
- **Certificate Verification** - Public verification with expiration tracking
- **Proposal System** - Transparent approval process for advanced certifications

### 🆕 Renewal System
- **Automated Renewal Process** - Streamlined renewal with fee payment in STX tokens
- **Continuing Education (CE) Tracking** - Track and verify CE credits for renewal eligibility
- **Tiered Renewal Requirements** - Different CE and fee requirements by certification level
- **Renewal Window Management** - 30-day renewal window before certification expiry
- **CE Activity Management** - Log and track professional development activities

### Security & Trust
- Tamper-proof certificate storage on blockchain
- Multi-signature requirements for advanced certifications
- Comprehensive input validation and error handling
- Authorization checks for all issuer operations
- Proposal expiration to prevent stale requests
- Secure payment processing for renewal fees

## 🏗️ Architecture

### Certification Levels & Requirements

| Level | Description | Required Signatures | Renewal Fee | CE Credits Required |
|-------|-------------|-------------------|-------------|-------------------|
| Basic (1) | Entry-level certifications | 1 | 1 STX | 10 credits |
| Intermediate (2) | Mid-level certifications | 1 | 2 STX | 15 credits |
| Advanced (3) | High-level certifications | 2 | 3 STX | 20 credits |
| Expert (4) | Master-level certifications | 3 | 5 STX | 30 credits |

### Data Structure

```clarity
;; Enhanced Certification Structure with Renewal Info
{
  holder: principal,
  issuer: principal,
  skill-category: (string-ascii 50),
  certification-name: (string-ascii 100),
  certification-level: uint,
  issue-date: uint,
  expiry-date: uint,
  verified: bool,
  metadata-uri: (string-ascii 200),
  renewal-count: uint,
  last-renewal-date: (optional uint)
}

;; Continuing Education Structure
{
  total-credits: uint,
  last-updated: uint,
  credits-since-renewal: uint
}

;; Renewal Request Structure
{
  cert-id: uint,
  holder: principal,
  renewal-fee-paid: uint,
  ce-credits-earned: uint,
  request-date: uint,
  status: (string-ascii 20),
  metadata-uri: (string-ascii 200)
}
```

## 🚀 Getting Started

### Prerequisites
- Stacks blockchain testnet/mainnet access
- Clarity CLI or compatible development environment
- STX tokens for transaction fees and renewal payments

### Deployment

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd skillcertify
   ```

2. **Deploy the contract**
   ```bash
   clarinet deploy --testnet
   ```

3. **Verify deployment**
   ```bash
   clarinet call-read-only skillcertify get-contract-stats
   ```

## 📖 Usage Guide

### For Certification Issuers

#### 1. Register as Issuer
```clarity
(contract-call? .skillcertify register-issuer "Your Organization Name")
```

#### 2. Add Authorized Signers (for multi-sig)
```clarity
(contract-call? .skillcertify add-authorized-signer 'SP1234...SIGNER)
```

#### 3. Issue Certification
```clarity
(contract-call? .skillcertify issue-certification
  'SP1234...HOLDER
  "Software Development"
  "Full Stack Developer Certification"
  u2  ;; Intermediate level
  u52560  ;; Valid for ~1 year
  "https://metadata.example.com/cert123"
)
```

### For Certificate Holders

#### 1. Update Professional Profile
```clarity
(contract-call? .skillcertify update-profile "Your Professional Name")
```

#### 2. Add Continuing Education Activity
```clarity
(contract-call? .skillcertify add-ce-activity
  "Advanced React Workshop"
  u5  ;; 5 CE credits
  "https://verification.example.com/activity123"
)
```

#### 3. Update CE Credits for Specific Certification
```clarity
(contract-call? .skillcertify update-ce-credits-for-cert u1 u10)
```

#### 4. Check Renewal Eligibility
```clarity
(contract-call? .skillcertify check-renewal-eligibility u1)
```

#### 5. Request Certification Renewal
```clarity
(contract-call? .skillcertify request-certification-renewal 
  u1  ;; Certificate ID
  "https://renewal-metadata.example.com/renewal123"
)
```

### For Advanced Certifications (Multi-sig Required)

#### 1. Create Proposal (Automatic when issuing Advanced/Expert)
When issuing Advanced (level 3) or Expert (level 4) certifications, a proposal is automatically created.

#### 2. Sign Proposal
```clarity
(contract-call? .skillcertify sign-certification-proposal u1)
```

#### 3. Automatic Execution
Once required signatures are collected, the certification is automatically issued.

## 📊 Read-Only Functions

### Verification Functions
```clarity
;; Verify certificate validity
(contract-call? .skillcertify verify-certification u1)

;; Get certificate details
(contract-call? .skillcertify get-certification u1)

;; Check if holder has specific certification
(contract-call? .skillcertify has-certification 'SP1234...HOLDER u1)
```

### Renewal & CE Functions
```clarity
;; Check renewal eligibility
(contract-call? .skillcertify check-renewal-eligibility u1)

;; Get renewal request details
(contract-call? .skillcertify get-renewal-request u1)

;; Get CE credits for certification
(contract-call? .skillcertify get-ce-credits 'SP1234...HOLDER u1)

;; Get CE activity details
(contract-call? .skillcertify get-ce-activity 'SP1234...HOLDER u1)

;; Get renewal fee for certification level
(contract-call? .skillcertify get-renewal-fee-for-level u2)

;; Get required CE credits for certification level
(contract-call? .skillcertify get-required-ce-for-level u2)
```

### Profile & Stats
```clarity
;; Get professional profile
(contract-call? .skillcertify get-professional-profile 'SP1234...HOLDER)

;; Get contract statistics
(contract-call? .skillcertify get-contract-stats)

;; Get issuer information
(contract-call? .skillcertify get-issuer-info 'SP1234...ISSUER)

;; Get contract treasury balance
(contract-call? .skillcertify get-contract-treasury)
```

### Multi-signature Queries
```clarity
;; Get proposal details
(contract-call? .skillcertify get-certification-proposal u1)

;; Check if user signed proposal
(contract-call? .skillcertify has-signed-proposal u1 'SP1234...SIGNER)

;; Check if user is authorized signer
(contract-call? .skillcertify is-authorized-signer 'SP1234...ISSUER 'SP1234...SIGNER)
```

## 🔄 Renewal Process Flow

### 1. Pre-Renewal Phase
- Certificate holders accumulate CE credits through professional development activities
- System tracks CE credits per certification
- Renewal window opens 30 days before expiry

### 2. Renewal Eligibility Check
- Verify certificate is within renewal window
- Confirm sufficient CE credits accumulated
- Calculate required renewal fee

### 3. Renewal Execution
- Submit renewal request with metadata
- Pay renewal fee in STX tokens
- System validates CE requirements
- Automatic approval and certificate extension

### 4. Post-Renewal
- Certificate expiry date extended
- Renewal count incremented
- CE credits counter reset for next renewal cycle

## 🔐 Security Considerations

### Access Control
- Only registered issuers can create certifications
- Multi-signature requirements enforced by certification level
- Authorized signers must be explicitly added by issuer
- Proposals expire after ~1 week to prevent stale requests
- Only certificate holders can renew their own certificates

### Input Validation
- All string inputs validated for minimum length
- Certification levels restricted to valid range (1-4)
- Validity periods must be positive
- Duplicate signatures prevented
- CE credits capped per activity and update
- Renewal fees validated against certification levels

### Financial Security
- STX payments securely transferred to contract treasury
- Renewal fees stored and tracked in contract
- Payment validation before renewal processing

### Error Handling
| Error Code | Description |
|------------|-------------|
| u401 | Unauthorized access |
| u404 | Resource not found |
| u409 | Resource already exists |
| u400 | Invalid input parameters |
| u410 | Certificate expired |
| u411 | Insufficient signatures |
| u412 | Already signed |
| u413 | Proposal expired |
| u414 | Insufficient payment |
| u415 | Renewal not eligible |
| u416 | Insufficient CE credits |
| u417 | Renewal too early |

## 🧪 Testing

### Unit Tests
```bash
# Run all tests
clarinet test

# Test specific functionality
clarinet test --filter "certification-issuance"
clarinet test --filter "multi-signature"
clarinet test --filter "verification"
clarinet test --filter "renewal-system"
clarinet test --filter "continuing-education"
```

### Integration Tests
```bash
# Test complete workflows
clarinet test --filter "end-to-end"
clarinet test --filter "renewal-workflow"
```

## 🛠️ Development

### Project Structure
```
skillcertify/
├── contracts/
│   └── skillcertify.clar
├── tests/
│   ├── skillcertify_test.ts
│   ├── renewal_test.ts
│   └── integration_test.ts
├── README.md
└── Clarinet.toml
```

### Contributing
1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📈 Gas Costs

| Operation | Estimated Cost (STX) |
|-----------|---------------------|
| Register Issuer | ~0.01 |
| Issue Basic Cert | ~0.02 |
| Create Proposal | ~0.03 |
| Sign Proposal | ~0.01 |
| Update Profile | ~0.01 |
| Add CE Activity | ~0.015 |
| Update CE Credits | ~0.01 |
| Request Renewal | ~0.02 + Renewal Fee |
| Basic Renewal | ~0.02 + 1 STX |
| Expert Renewal | ~0.02 + 5 STX |

*Costs are estimates and may vary based on network conditions*

## 🔮 Future Enhancements

- [ ] Certificate revocation mechanism
- [ ] Batch certification operations
- [ ] Enhanced metadata support with IPFS integration
- [ ] Certificate transfer functionality
- [ ] Integration with external verification APIs
- [ ] Mobile SDK for certificate verification
- [ ] Certificate templates and standardization
- [x] **Certification Renewal System** ✅
- [ ] Automated renewal reminders
- [ ] Bulk CE credit import from external systems
- [ ] Advanced analytics and reporting dashboard

## 📊 Renewal System Benefits

### For Certificate Holders
- **Streamlined Process**: Simple renewal with automatic approval when requirements are met
- **Clear Requirements**: Transparent CE credit and fee requirements by certification level
- **Flexible CE Tracking**: Multiple ways to earn and track continuing education credits
- **Cost Transparency**: Fixed renewal fees per certification level

### For Issuers
- **Automated Compliance**: System ensures renewal requirements are met
- **Revenue Generation**: Renewal fees contribute to platform sustainability
- **Quality Assurance**: CE requirements maintain certification value
- **Reduced Administration**: Automated processing reduces manual oversight

### For the Ecosystem
- **Professional Development**: Incentivizes ongoing learning and skill development
- **Platform Sustainability**: Renewal fees support platform maintenance and development
- **Trust Maintenance**: Regular renewals with CE requirements maintain certification credibility
- **Market Transparency**: Clear renewal metrics and requirements build confidence

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Support

- **Documentation**: Check this README and inline code comments
- **Issues**: Report bugs and request features via GitHub Issues
- **Community**: Join our Discord/Telegram for discussions
- **Email**: contact@skillcertify.example.com

## 🙏 Acknowledgments

- Stacks blockchain team for the Clarity smart contract language
- Contributors and community members
- Organizations testing the platform
- Professional development community for renewal system feedback

---

**Built with ❤️ for the decentralized future of professional certifications with sustainable renewal processes**