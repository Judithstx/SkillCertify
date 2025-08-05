;; SkillCertify - Decentralized Professional Certification Platform
;; A smart contract for issuing and verifying professional certifications with multi-signature support

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u401))
(define-constant ERR_NOT_FOUND (err u404))
(define-constant ERR_ALREADY_EXISTS (err u409))
(define-constant ERR_INVALID_INPUT (err u400))
(define-constant ERR_EXPIRED (err u410))
(define-constant ERR_INSUFFICIENT_SIGNATURES (err u411))
(define-constant ERR_ALREADY_SIGNED (err u412))
(define-constant ERR_PROPOSAL_EXPIRED (err u413))

;; Certification levels
(define-constant LEVEL_BASIC u1)
(define-constant LEVEL_INTERMEDIATE u2)
(define-constant LEVEL_ADVANCED u3)
(define-constant LEVEL_EXPERT u4)

;; Multi-sig requirements by level
(define-constant BASIC_REQUIRED_SIGNATURES u1)
(define-constant INTERMEDIATE_REQUIRED_SIGNATURES u1)
(define-constant ADVANCED_REQUIRED_SIGNATURES u2)
(define-constant EXPERT_REQUIRED_SIGNATURES u3)

;; Data Variables
(define-data-var next-cert-id uint u1)
(define-data-var next-proposal-id uint u1)
(define-data-var total-certified-professionals uint u0)

;; Data Maps
(define-map certifications
  { cert-id: uint }
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
)

(define-map certified-issuers
  { issuer: principal }
  {
    organization-name: (string-ascii 100),
    is-active: bool,
    certification-count: uint,
    registration-date: uint
  }
)

(define-map professional-profiles
  { holder: principal }
  {
    name: (string-ascii 100),
    total-certifications: uint,
    active-certifications: uint,
    profile-created: uint
  }
)

(define-map holder-certifications
  { holder: principal, cert-id: uint }
  { exists: bool }
)

;; Multi-signature maps
(define-map authorized-signers
  { issuer: principal, signer: principal }
  { 
    is-authorized: bool,
    authorization-date: uint
  }
)

(define-map certification-proposals
  { proposal-id: uint }
  {
    issuer: principal,
    holder: principal,
    skill-category: (string-ascii 50),
    certification-name: (string-ascii 100),
    certification-level: uint,
    validity-period: uint,
    metadata-uri: (string-ascii 200),
    required-signatures: uint,
    current-signatures: uint,
    proposal-expiry: uint,
    is-executed: bool,
    created-date: uint
  }
)

(define-map proposal-signatures
  { proposal-id: uint, signer: principal }
  { 
    has-signed: bool,
    signature-date: uint
  }
)

;; Public Functions

;; Register as a certified issuer
(define-public (register-issuer (organization-name (string-ascii 100)))
  (let ((issuer tx-sender))
    (asserts! (> (len organization-name) u0) ERR_INVALID_INPUT)
    (asserts! (is-none (map-get? certified-issuers { issuer: issuer })) ERR_ALREADY_EXISTS)
    
    (map-set certified-issuers
      { issuer: issuer }
      {
        organization-name: organization-name,
        is-active: true,
        certification-count: u0,
        registration-date: stacks-block-height
      }
    )
    (ok true)
  )
)

;; Add authorized signer to an organization
(define-public (add-authorized-signer (signer principal))
  (let ((issuer tx-sender))
    (asserts! (not (is-eq issuer signer)) ERR_INVALID_INPUT)
    
    ;; Check if issuer is registered and active
    (match (map-get? certified-issuers { issuer: issuer })
      issuer-data
      (begin
        (asserts! (get is-active issuer-data) ERR_UNAUTHORIZED)
        (asserts! (is-none (map-get? authorized-signers { issuer: issuer, signer: signer })) ERR_ALREADY_EXISTS)
        
        (map-set authorized-signers
          { issuer: issuer, signer: signer }
          {
            is-authorized: true,
            authorization-date: stacks-block-height
          }
        )
        (ok true)
      )
      ERR_UNAUTHORIZED
    )
  )
)

;; Remove authorized signer
(define-public (remove-authorized-signer (signer principal))
  (let ((issuer tx-sender))
    (asserts! (not (is-eq issuer signer)) ERR_INVALID_INPUT)
    
    ;; Check if issuer is registered and active
    (match (map-get? certified-issuers { issuer: issuer })
      issuer-data
      (begin
        (asserts! (get is-active issuer-data) ERR_UNAUTHORIZED)
        
        (map-set authorized-signers
          { issuer: issuer, signer: signer }
          {
            is-authorized: false,
            authorization-date: stacks-block-height
          }
        )
        (ok true)
      )
      ERR_UNAUTHORIZED
    )
  )
)

;; Get required signatures for certification level
(define-private (get-required-signatures (level uint))
  (if (is-eq level LEVEL_BASIC)
    BASIC_REQUIRED_SIGNATURES
    (if (is-eq level LEVEL_INTERMEDIATE)
      INTERMEDIATE_REQUIRED_SIGNATURES
      (if (is-eq level LEVEL_ADVANCED)
        ADVANCED_REQUIRED_SIGNATURES
        (if (is-eq level LEVEL_EXPERT)
          EXPERT_REQUIRED_SIGNATURES
          u1
        )
      )
    )
  )
)

;; Issue a certification (for basic/intermediate) or create proposal (for advanced/expert)
(define-public (issue-certification 
  (holder principal)
  (skill-category (string-ascii 50))
  (certification-name (string-ascii 100))
  (certification-level uint)
  (validity-period uint)
  (metadata-uri (string-ascii 200)))
  
  (let (
    (issuer tx-sender)
  )
    ;; Validate inputs
    (asserts! (> (len skill-category) u0) ERR_INVALID_INPUT)
    (asserts! (> (len certification-name) u0) ERR_INVALID_INPUT)
    (asserts! (> validity-period u0) ERR_INVALID_INPUT)
    (asserts! (> (len metadata-uri) u0) ERR_INVALID_INPUT)
    (asserts! (not (is-eq holder issuer)) ERR_INVALID_INPUT)
    (asserts! (and (>= certification-level LEVEL_BASIC) (<= certification-level LEVEL_EXPERT)) ERR_INVALID_INPUT)
    
    (let ((required-sigs (get-required-signatures certification-level)))
    
    ;; Check if issuer is registered and active
    (match (map-get? certified-issuers { issuer: issuer })
      issuer-data 
      (begin
        (asserts! (get is-active issuer-data) ERR_UNAUTHORIZED)
        
        ;; If basic or intermediate, issue directly
        (if (<= required-sigs u1)
          (issue-certification-direct holder skill-category certification-name certification-level validity-period metadata-uri issuer)
          ;; Otherwise create proposal
          (create-certification-proposal holder skill-category certification-name certification-level validity-period metadata-uri issuer required-sigs)
        )
      )
      ERR_UNAUTHORIZED
    )
    )
  )
)

;; Direct certification issuance (private function)
(define-private (issue-certification-direct 
  (holder principal)
  (skill-category (string-ascii 50))
  (certification-name (string-ascii 100))
  (certification-level uint)
  (validity-period uint)
  (metadata-uri (string-ascii 200))
  (issuer principal))
  
  (let (
    (cert-id (var-get next-cert-id))
    (current-height stacks-block-height)
    (expiry-date (+ current-height validity-period))
  )
    ;; Create certification
    (map-set certifications
      { cert-id: cert-id }
      {
        holder: holder,
        issuer: issuer,
        skill-category: skill-category,
        certification-name: certification-name,
        certification-level: certification-level,
        issue-date: current-height,
        expiry-date: expiry-date,
        verified: true,
        metadata-uri: metadata-uri
      }
    )
    
    ;; Link certification to holder
    (map-set holder-certifications
      { holder: holder, cert-id: cert-id }
      { exists: true }
    )
    
    ;; Update issuer stats
    (match (map-get? certified-issuers { issuer: issuer })
      issuer-data
      (map-set certified-issuers
        { issuer: issuer }
        (merge issuer-data { certification-count: (+ (get certification-count issuer-data) u1) })
      )
      false ;; This should not happen as we checked earlier
    )
    
    ;; Update or create professional profile
    (match (map-get? professional-profiles { holder: holder })
      profile-data
      (map-set professional-profiles
        { holder: holder }
        (merge profile-data { 
          total-certifications: (+ (get total-certifications profile-data) u1),
          active-certifications: (+ (get active-certifications profile-data) u1)
        })
      )
      (map-set professional-profiles
        { holder: holder }
        {
          name: "",
          total-certifications: u1,
          active-certifications: u1,
          profile-created: stacks-block-height
        }
      )
    )
    
    ;; Update global stats
    (var-set next-cert-id (+ cert-id u1))
    (var-set total-certified-professionals (+ (var-get total-certified-professionals) u1))
    
    (ok cert-id)
  )
)

;; Create certification proposal (private function)
(define-private (create-certification-proposal
  (holder principal)
  (skill-category (string-ascii 50))
  (certification-name (string-ascii 100))
  (certification-level uint)
  (validity-period uint)
  (metadata-uri (string-ascii 200))
  (issuer principal)
  (required-sigs uint))
  
  (let (
    (proposal-id (var-get next-proposal-id))
    (current-height stacks-block-height)
    (proposal-expiry (+ current-height u1008)) ;; Proposal expires in ~1 week (assuming 10min blocks)
  )
    ;; Create proposal
    (map-set certification-proposals
      { proposal-id: proposal-id }
      {
        issuer: issuer,
        holder: holder,
        skill-category: skill-category,
        certification-name: certification-name,
        certification-level: certification-level,
        validity-period: validity-period,
        metadata-uri: metadata-uri,
        required-signatures: required-sigs,
        current-signatures: u0,
        proposal-expiry: proposal-expiry,
        is-executed: false,
        created-date: current-height
      }
    )
    
    (var-set next-proposal-id (+ proposal-id u1))
    (ok proposal-id)
  )
)

;; Sign a certification proposal
(define-public (sign-certification-proposal (proposal-id uint))
  (let (
    (signer tx-sender)
    (current-height stacks-block-height)
  )
    ;; Validate proposal-id input
    (asserts! (> proposal-id u0) ERR_INVALID_INPUT)
    (asserts! (< proposal-id (var-get next-proposal-id)) ERR_NOT_FOUND)
    
    ;; Get proposal data
    (match (map-get? certification-proposals { proposal-id: proposal-id })
      proposal-data
      (begin
        ;; Validate proposal
        (asserts! (not (get is-executed proposal-data)) ERR_ALREADY_EXISTS)
        (asserts! (< current-height (get proposal-expiry proposal-data)) ERR_PROPOSAL_EXPIRED)
        
        ;; Check if signer is authorized for this issuer or is the issuer
        (asserts! 
          (or 
            (is-eq signer (get issuer proposal-data))
            (match (map-get? authorized-signers { issuer: (get issuer proposal-data), signer: signer })
              signer-data (get is-authorized signer-data)
              false
            )
          )
          ERR_UNAUTHORIZED
        )
        
        ;; Check if already signed
        (asserts! 
          (is-none (map-get? proposal-signatures { proposal-id: proposal-id, signer: signer }))
          ERR_ALREADY_SIGNED
        )
        
        ;; Add signature
        (map-set proposal-signatures
          { proposal-id: proposal-id, signer: signer }
          {
            has-signed: true,
            signature-date: current-height
          }
        )
        
        ;; Update proposal signature count
        (let ((new-sig-count (+ (get current-signatures proposal-data) u1)))
          (map-set certification-proposals
            { proposal-id: proposal-id }
            (merge proposal-data { current-signatures: new-sig-count })
          )
          
          ;; If enough signatures, execute the certification
          (if (>= new-sig-count (get required-signatures proposal-data))
            (match (execute-certification-proposal proposal-id)
              success (ok success)
              error (err error)
            )
            (ok u0)
          )
        )
      )
      ERR_NOT_FOUND
    )
  )
)

;; Execute certification proposal (private function)
(define-private (execute-certification-proposal (proposal-id uint))
  (match (map-get? certification-proposals { proposal-id: proposal-id })
    proposal-data
    (begin
      ;; Validate that proposal is not already executed
      (asserts! (not (get is-executed proposal-data)) ERR_ALREADY_EXISTS)
      
      ;; Mark proposal as executed
      (map-set certification-proposals
        { proposal-id: proposal-id }
        (merge proposal-data { is-executed: true })
      )
      
      ;; Issue the certification
      (issue-certification-direct
        (get holder proposal-data)
        (get skill-category proposal-data)
        (get certification-name proposal-data)
        (get certification-level proposal-data)
        (get validity-period proposal-data)
        (get metadata-uri proposal-data)
        (get issuer proposal-data)
      )
    )
    ERR_NOT_FOUND
  )
)

;; Update professional profile
(define-public (update-profile (name (string-ascii 100)))
  (let ((holder tx-sender))
    (asserts! (> (len name) u0) ERR_INVALID_INPUT)
    
    (match (map-get? professional-profiles { holder: holder })
      profile-data
      (begin
        (map-set professional-profiles
          { holder: holder }
          (merge profile-data { name: name })
        )
        (ok true)
      )
      (begin
        (map-set professional-profiles
          { holder: holder }
          {
            name: name,
            total-certifications: u0,
            active-certifications: u0,
            profile-created: stacks-block-height
          }
        )
        (ok true)
      )
    )
  )
)

;; Read-only functions

;; Get certification details
(define-read-only (get-certification (cert-id uint))
  (map-get? certifications { cert-id: cert-id })
)

;; Verify if certification is valid and not expired
(define-read-only (verify-certification (cert-id uint))
  (match (map-get? certifications { cert-id: cert-id })
    cert-data 
    (ok {
      is-valid: (and (get verified cert-data) (> (get expiry-date cert-data) stacks-block-height)),
      holder: (get holder cert-data),
      issuer: (get issuer cert-data),
      skill-category: (get skill-category cert-data),
      certification-name: (get certification-name cert-data),
      certification-level: (get certification-level cert-data),
      expires-at: (get expiry-date cert-data)
    })
    ERR_NOT_FOUND
  )
)

;; Get certification proposal details
(define-read-only (get-certification-proposal (proposal-id uint))
  (map-get? certification-proposals { proposal-id: proposal-id })
)

;; Check if user has signed a proposal
(define-read-only (has-signed-proposal (proposal-id uint) (signer principal))
  (is-some (map-get? proposal-signatures { proposal-id: proposal-id, signer: signer }))
)

;; Check if user is authorized signer for an issuer
(define-read-only (is-authorized-signer (issuer principal) (signer principal))
  (match (map-get? authorized-signers { issuer: issuer, signer: signer })
    signer-data (get is-authorized signer-data)
    false
  )
)

;; Get issuer information
(define-read-only (get-issuer-info (issuer principal))
  (map-get? certified-issuers { issuer: issuer })
)

;; Get professional profile
(define-read-only (get-professional-profile (holder principal))
  (map-get? professional-profiles { holder: holder })
)

;; Check if holder has a specific certification
(define-read-only (has-certification (holder principal) (cert-id uint))
  (is-some (map-get? holder-certifications { holder: holder, cert-id: cert-id }))
)

;; Get contract statistics
(define-read-only (get-contract-stats)
  (ok {
    total-certifications: (- (var-get next-cert-id) u1),
    total-certified-professionals: (var-get total-certified-professionals),
    total-proposals: (- (var-get next-proposal-id) u1)
  })
)