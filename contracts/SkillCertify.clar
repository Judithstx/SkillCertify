;; SkillCertify - Decentralized Professional Certification Platform
;; A smart contract for issuing and verifying professional certifications with multi-signature support and renewal system

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
(define-constant ERR_INSUFFICIENT_PAYMENT (err u414))
(define-constant ERR_RENEWAL_NOT_ELIGIBLE (err u415))
(define-constant ERR_INSUFFICIENT_CE_CREDITS (err u416))
(define-constant ERR_RENEWAL_TOO_EARLY (err u417))

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

;; Renewal fee constants (in microSTX)
(define-constant BASIC_RENEWAL_FEE u1000000) ;; 1 STX
(define-constant INTERMEDIATE_RENEWAL_FEE u2000000) ;; 2 STX
(define-constant ADVANCED_RENEWAL_FEE u3000000) ;; 3 STX
(define-constant EXPERT_RENEWAL_FEE u5000000) ;; 5 STX

;; CE (Continuing Education) requirements by level
(define-constant BASIC_CE_REQUIRED u10) ;; 10 CE credits
(define-constant INTERMEDIATE_CE_REQUIRED u15) ;; 15 CE credits
(define-constant ADVANCED_CE_REQUIRED u20) ;; 20 CE credits
(define-constant EXPERT_CE_REQUIRED u30) ;; 30 CE credits

;; Renewal eligibility window (blocks before expiry)
(define-constant RENEWAL_WINDOW u4320) ;; ~30 days before expiry

;; Data Variables
(define-data-var next-cert-id uint u1)
(define-data-var next-proposal-id uint u1)
(define-data-var next-renewal-id uint u1)
(define-data-var total-certified-professionals uint u0)
(define-data-var contract-treasury uint u0)

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
    metadata-uri: (string-ascii 200),
    renewal-count: uint,
    last-renewal-date: (optional uint)
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
    profile-created: uint,
    total-ce-credits: uint
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

;; Renewal system maps
(define-map renewal-requests
  { renewal-id: uint }
  {
    cert-id: uint,
    holder: principal,
    renewal-fee-paid: uint,
    ce-credits-earned: uint,
    request-date: uint,
    status: (string-ascii 20),
    metadata-uri: (string-ascii 200)
  }
)

(define-map continuing-education
  { holder: principal, cert-id: uint }
  {
    total-credits: uint,
    last-updated: uint,
    credits-since-renewal: uint
  }
)

(define-map ce-activities
  { holder: principal, activity-id: uint }
  {
    activity-name: (string-ascii 100),
    credits-earned: uint,
    completion-date: uint,
    verification-uri: (string-ascii 200),
    verified: bool
  }
)

(define-map holder-ce-activity-count
  { holder: principal }
  { count: uint }
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

;; Get renewal fee for certification level
(define-private (get-renewal-fee (level uint))
  (if (is-eq level LEVEL_BASIC)
    BASIC_RENEWAL_FEE
    (if (is-eq level LEVEL_INTERMEDIATE)
      INTERMEDIATE_RENEWAL_FEE
      (if (is-eq level LEVEL_ADVANCED)
        ADVANCED_RENEWAL_FEE
        (if (is-eq level LEVEL_EXPERT)
          EXPERT_RENEWAL_FEE
          BASIC_RENEWAL_FEE
        )
      )
    )
  )
)

;; Get required CE credits for certification level
(define-private (get-required-ce-credits (level uint))
  (if (is-eq level LEVEL_BASIC)
    BASIC_CE_REQUIRED
    (if (is-eq level LEVEL_INTERMEDIATE)
      INTERMEDIATE_CE_REQUIRED
      (if (is-eq level LEVEL_ADVANCED)
        ADVANCED_CE_REQUIRED
        (if (is-eq level LEVEL_EXPERT)
          EXPERT_CE_REQUIRED
          BASIC_CE_REQUIRED
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
        metadata-uri: metadata-uri,
        renewal-count: u0,
        last-renewal-date: none
      }
    )
    
    ;; Link certification to holder
    (map-set holder-certifications
      { holder: holder, cert-id: cert-id }
      { exists: true }
    )
    
    ;; Initialize CE tracking for the certification
    (map-set continuing-education
      { holder: holder, cert-id: cert-id }
      {
        total-credits: u0,
        last-updated: current-height,
        credits-since-renewal: u0
      }
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
          profile-created: stacks-block-height,
          total-ce-credits: u0
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

;; Add continuing education activity
(define-public (add-ce-activity
  (activity-name (string-ascii 100))
  (credits-earned uint)
  (verification-uri (string-ascii 200)))
  
  (let (
    (holder tx-sender)
    (current-height stacks-block-height)
    (activity-count (default-to u0 (get count (map-get? holder-ce-activity-count { holder: holder }))))
    (activity-id (+ activity-count u1))
  )
    ;; Validate inputs
    (asserts! (> (len activity-name) u0) ERR_INVALID_INPUT)
    (asserts! (> credits-earned u0) ERR_INVALID_INPUT)
    (asserts! (> (len verification-uri) u0) ERR_INVALID_INPUT)
    (asserts! (<= credits-earned u50) ERR_INVALID_INPUT) ;; Max 50 credits per activity
    
    ;; Add CE activity
    (map-set ce-activities
      { holder: holder, activity-id: activity-id }
      {
        activity-name: activity-name,
        credits-earned: credits-earned,
        completion-date: current-height,
        verification-uri: verification-uri,
        verified: true ;; Auto-verified for now, could require issuer verification
      }
    )
    
    ;; Update activity count
    (map-set holder-ce-activity-count
      { holder: holder }
      { count: activity-id }
    )
    
    ;; Update professional profile with total CE credits
    (match (map-get? professional-profiles { holder: holder })
      profile-data
      (map-set professional-profiles
        { holder: holder }
        (merge profile-data { total-ce-credits: (+ (get total-ce-credits profile-data) credits-earned) })
      )
      ;; Create profile if doesn't exist
      (map-set professional-profiles
        { holder: holder }
        {
          name: "",
          total-certifications: u0,
          active-certifications: u0,
          profile-created: current-height,
          total-ce-credits: credits-earned
        }
      )
    )
    
    (ok activity-id)
  )
)

;; Request certification renewal
(define-public (request-certification-renewal
  (cert-id uint)
  (metadata-uri (string-ascii 200)))
  
  (let (
    (holder tx-sender)
    (current-height stacks-block-height)
    (renewal-id (var-get next-renewal-id))
  )
    ;; Validate inputs
    (asserts! (> cert-id u0) ERR_INVALID_INPUT)
    (asserts! (< cert-id (var-get next-cert-id)) ERR_NOT_FOUND)
    (asserts! (> (len metadata-uri) u0) ERR_INVALID_INPUT)
    
    ;; Get certification data
    (match (map-get? certifications { cert-id: cert-id })
      cert-data
      (begin
        ;; Verify holder owns the certification
        (asserts! (is-eq (get holder cert-data) holder) ERR_UNAUTHORIZED)
        
        ;; Check if certification is within renewal window
        (let ((time-to-expiry (- (get expiry-date cert-data) current-height)))
          (asserts! (<= time-to-expiry RENEWAL_WINDOW) ERR_RENEWAL_TOO_EARLY)
          
          ;; Check if certification is not yet expired
          (asserts! (> (get expiry-date cert-data) current-height) ERR_EXPIRED)
          
          (let (
            (cert-level (get certification-level cert-data))
            (renewal-fee (get-renewal-fee cert-level))
            (required-ce (get-required-ce-credits cert-level))
          )
            ;; Get CE credits for this certification
            (let (
              (ce-data (default-to 
                { total-credits: u0, last-updated: u0, credits-since-renewal: u0 }
                (map-get? continuing-education { holder: holder, cert-id: cert-id })
              ))
              (available-credits (get credits-since-renewal ce-data))
            )
              ;; Check CE requirements
              (asserts! (>= available-credits required-ce) ERR_INSUFFICIENT_CE_CREDITS)
              
              ;; Transfer renewal fee to contract
              (try! (stx-transfer? renewal-fee holder (as-contract tx-sender)))
              
              ;; Create renewal request
              (map-set renewal-requests
                { renewal-id: renewal-id }
                {
                  cert-id: cert-id,
                  holder: holder,
                  renewal-fee-paid: renewal-fee,
                  ce-credits-earned: available-credits,
                  request-date: current-height,
                  status: "approved", ;; Auto-approve if requirements met
                  metadata-uri: metadata-uri
                }
              )
              
              ;; Process the renewal immediately
              (try! (process-renewal renewal-id))
              
              ;; Update treasury
              (var-set contract-treasury (+ (var-get contract-treasury) renewal-fee))
              
              ;; Increment renewal ID
              (var-set next-renewal-id (+ renewal-id u1))
              
              (ok renewal-id)
            )
          )
        )
      )
      ERR_NOT_FOUND
    )
  )
)

;; Process approved renewal (private function)
(define-private (process-renewal (renewal-id uint))
  (match (map-get? renewal-requests { renewal-id: renewal-id })
    renewal-data
    (begin
      (let (
        (cert-id (get cert-id renewal-data))
        (holder (get holder renewal-data))
        (current-height stacks-block-height)
      )
        ;; Get certification data
        (match (map-get? certifications { cert-id: cert-id })
          cert-data
          (let (
            (validity-period (- (get expiry-date cert-data) (get issue-date cert-data)))
            (new-expiry (+ current-height validity-period))
          )
            ;; Update certification with new expiry date and renewal info
            (map-set certifications
              { cert-id: cert-id }
              (merge cert-data {
                expiry-date: new-expiry,
                renewal-count: (+ (get renewal-count cert-data) u1),
                last-renewal-date: (some current-height)
              })
            )
            
            ;; Reset CE credits counter for this certification
            (match (map-get? continuing-education { holder: holder, cert-id: cert-id })
              ce-data
              (map-set continuing-education
                { holder: holder, cert-id: cert-id }
                (merge ce-data {
                  credits-since-renewal: u0,
                  last-updated: current-height
                })
              )
              false ;; Should not happen
            )
            
            (ok true)
          )
          ERR_NOT_FOUND
        )
      )
    )
    ERR_NOT_FOUND
  )
)

;; Update CE credits for a specific certification
(define-public (update-ce-credits-for-cert (cert-id uint) (credits-to-add uint))
  (let (
    (holder tx-sender)
    (current-height stacks-block-height)
  )
    ;; Validate inputs
    (asserts! (> cert-id u0) ERR_INVALID_INPUT)
    (asserts! (< cert-id (var-get next-cert-id)) ERR_NOT_FOUND)
    (asserts! (> credits-to-add u0) ERR_INVALID_INPUT)
    (asserts! (<= credits-to-add u100) ERR_INVALID_INPUT) ;; Max 100 credits at once
    
    ;; Verify holder owns the certification
    (match (map-get? certifications { cert-id: cert-id })
      cert-data
      (begin
        (asserts! (is-eq (get holder cert-data) holder) ERR_UNAUTHORIZED)
        
        ;; Update CE credits
        (match (map-get? continuing-education { holder: holder, cert-id: cert-id })
          ce-data
          (map-set continuing-education
            { holder: holder, cert-id: cert-id }
            (merge ce-data {
              total-credits: (+ (get total-credits ce-data) credits-to-add),
              credits-since-renewal: (+ (get credits-since-renewal ce-data) credits-to-add),
              last-updated: current-height
            })
          )
          ;; Create new CE tracking if doesn't exist
          (map-set continuing-education
            { holder: holder, cert-id: cert-id }
            {
              total-credits: credits-to-add,
              last-updated: current-height,
              credits-since-renewal: credits-to-add
            }
          )
        )
        (ok true)
      )
      ERR_UNAUTHORIZED
    )
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
            profile-created: stacks-block-height,
            total-ce-credits: u0
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
      expires-at: (get expiry-date cert-data),
      renewal-count: (get renewal-count cert-data)
    })
    ERR_NOT_FOUND
  )
)

;; Check renewal eligibility
(define-read-only (check-renewal-eligibility (cert-id uint))
  (match (map-get? certifications { cert-id: cert-id })
    cert-data
    (let (
      (current-height stacks-block-height)
      (time-to-expiry (- (get expiry-date cert-data) current-height))
      (cert-level (get certification-level cert-data))
      (required-ce (get-required-ce-credits cert-level))
      (renewal-fee (get-renewal-fee cert-level))
      (holder (get holder cert-data))
    )
      ;; Get CE credits for this certification
      (let (
        (ce-data (default-to 
          { total-credits: u0, last-updated: u0, credits-since-renewal: u0 }
          (map-get? continuing-education { holder: holder, cert-id: cert-id })
        ))
        (available-credits (get credits-since-renewal ce-data))
      )
        (ok {
          eligible: (and 
            (<= time-to-expiry RENEWAL_WINDOW)
            (> (get expiry-date cert-data) current-height)
            (>= available-credits required-ce)
          ),
          time-to-expiry: time-to-expiry,
          renewal-window: RENEWAL_WINDOW,
          required-ce-credits: required-ce,
          available-ce-credits: available-credits,
          renewal-fee: renewal-fee,
          is-expired: (<= (get expiry-date cert-data) current-height)
        })
      )
    )
    ERR_NOT_FOUND
  )
)

;; Get renewal request details
(define-read-only (get-renewal-request (renewal-id uint))
  (map-get? renewal-requests { renewal-id: renewal-id })
)

;; Get CE credits for a certification
(define-read-only (get-ce-credits (holder principal) (cert-id uint))
  (map-get? continuing-education { holder: holder, cert-id: cert-id })
)

;; Get CE activity details
(define-read-only (get-ce-activity (holder principal) (activity-id uint))
  (map-get? ce-activities { holder: holder, activity-id: activity-id })
)

;; Get total CE activities count for holder
(define-read-only (get-ce-activity-count (holder principal))
  (default-to u0 (get count (map-get? holder-ce-activity-count { holder: holder })))
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

;; Get renewal fee for certification level (read-only)
(define-read-only (get-renewal-fee-for-level (level uint))
  (get-renewal-fee level)
)

;; Get required CE credits for certification level (read-only)
(define-read-only (get-required-ce-for-level (level uint))
  (get-required-ce-credits level)
)

;; Get contract treasury balance
(define-read-only (get-contract-treasury)
  (var-get contract-treasury)
)

;; Get contract statistics
(define-read-only (get-contract-stats)
  (ok {
    total-certifications: (- (var-get next-cert-id) u1),
    total-certified-professionals: (var-get total-certified-professionals),
    total-proposals: (- (var-get next-proposal-id) u1),
    total-renewals: (- (var-get next-renewal-id) u1),
    contract-treasury: (var-get contract-treasury)
  })
)