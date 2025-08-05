# SkillCertify - Decentralized Professional Certification Platform

A comprehensive smart contract built on Stacks blockchain for issuing, managing, and verifying professional certifications with multi-signature governance support.

## 🎯 Overview

SkillCertify enables organizations to issue tamper-proof professional certifications while maintaining trust through a multi-signature approval process for high-level certifications. The platform provides a complete ecosystem for certification management, verification, and professional profile tracking.

## ✨ Features

### Core Functionality
- **Multi-tiered Certification System** - 4 levels: Basic, Intermediate, Advanced, Expert
- **Multi-signature Governance** - Democratic approval for high-level certifications
- **Professional Profiles** - Comprehensive profile management for certificate holders
- **Issuer Management** - Secure registration and authorization system
- **Certificate Verification** - Public verification with expiration tracking
- **Proposal System** - Transparent approval process for advanced certifications

### Security & Trust
- Tamper-proof certificate storage on blockchain
- Multi-signature requirements for advanced certifications
- Comprehensive input validation and error handling
- Authorization checks for all issuer operations
- Proposal expiration to prevent stale requests

## 🏗️ Architecture

### Certification Levels & Requirements

| Level | Description | Required Signatures |
|-------|-------------|-------------------|
| Basic (1) | Entry-level certifications | 1 |
| Intermediate (2) | Mid-level certifications | 1 |
| Advanced (3) | High-level certifications | 2 |
| Expert (4) | Master-level certifications | 3 |

### Data Structure

```clarity
;; Certification Structure
{
  holder: principal,
  issuer: principal,
  skill-category: (string-ascii 50),
  certification-name: (string-ascii 100),
  certification-level: uint,
  issue-date: uint,
  expiry-date: uint,
  verified: bool,
  metadata-uri: (string-ascii 200)
}
```

## 🚀 Getting Started

### Prerequisites
- Stacks blockchain testnet/mainnet access
- Clarity CLI or compatible development environment
- STX tokens for transaction fees

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

#### 2. Verify Your Certification
```clarity
(contract-call? .skillcertify verify-certification u1)
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

### Profile & Stats
```clarity
;; Get professional profile
(contract-call? .skillcertify get-professional-profile 'SP1234...HOLDER)

;; Get contract statistics
(contract-call? .skillcertify get-contract-stats)

;; Get issuer information
(contract-call? .skillcertify get-issuer-info 'SP1234...ISSUER)
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

## 🔐 Security Considerations

### Access Control
- Only registered issuers can create certifications
- Multi-signature requirements enforced by certification level
- Authorized signers must be explicitly added by issuer
- Proposals expire after ~1 week to prevent stale requests

### Input Validation
- All string inputs validated for minimum length
- Certification levels restricted to valid range (1-4)
- Validity periods must be positive
- Duplicate signatures prevented

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

## 🧪 Testing

### Unit Tests
```bash
# Run all tests
clarinet test

# Test specific functionality
clarinet test --filter "certification-issuance"
clarinet test --filter "multi-signature"
clarinet test --filter "verification"
```

### Integration Tests
```bash
# Test complete workflows
clarinet test --filter "end-to-end"
```

## 🛠️ Development

### Project Structure
```
skillcertify/
├── contracts/
│   └── skillcertify.clar
├── tests/
│   ├── skillcertify_test.ts
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

*Costs are estimates and may vary based on network conditions*

## 🔮 Future Enhancements

- [ ] Certificate revocation mechanism
- [ ] Batch certification operations
- [ ] Enhanced metadata support with IPFS integration
- [ ] Certificate transfer functionality
- [ ] Integration with external verification APIs
- [ ] Mobile SDK for certificate verification
- [ ] Certificate templates and standardization

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

---

**Built with ❤️ for the decentralized future of professional certifications**