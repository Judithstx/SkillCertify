;; SkillCertify - Decentralized Professional Certification Platform
;; A smart contract for issuing and verifying professional certifications

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u401))
(define-constant ERR_NOT_FOUND (err u404))
(define-constant ERR_ALREADY_EXISTS (err u409))
(define-constant ERR_INVALID_INPUT (err u400))
(define-constant ERR_EXPIRED (err u410))

;; Data Variables
(define-data-var next-cert-id uint u1)
(define-data-var total-certified-professionals uint u0)

;; Data Maps
(define-map certifications
  { cert-id: uint }
  {
    holder: principal,
    issuer: principal,
    skill-category: (string-ascii 50),
    certification-name: (string-ascii 100),
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

;; Issue a new certification
(define-public (issue-certification 
  (holder principal)
  (skill-category (string-ascii 50))
  (certification-name (string-ascii 100))
  (validity-period uint)
  (metadata-uri (string-ascii 200)))
  
  (let (
    (cert-id (var-get next-cert-id))
    (issuer tx-sender)
    (current-height stacks-block-height)
    (expiry-date (+ current-height validity-period))
  )
    ;; Validate inputs
    (asserts! (> (len skill-category) u0) ERR_INVALID_INPUT)
    (asserts! (> (len certification-name) u0) ERR_INVALID_INPUT)
    (asserts! (> validity-period u0) ERR_INVALID_INPUT)
    (asserts! (> (len metadata-uri) u0) ERR_INVALID_INPUT)
    (asserts! (not (is-eq holder issuer)) ERR_INVALID_INPUT)
    
    ;; Check if issuer is registered and active
    (match (map-get? certified-issuers { issuer: issuer })
      issuer-data 
      (begin
        (asserts! (get is-active issuer-data) ERR_UNAUTHORIZED)
        
        ;; Create certification
        (map-set certifications
          { cert-id: cert-id }
          {
            holder: holder,
            issuer: issuer,
            skill-category: skill-category,
            certification-name: certification-name,
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
        (map-set certified-issuers
          { issuer: issuer }
          (merge issuer-data { certification-count: (+ (get certification-count issuer-data) u1) })
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
      expires-at: (get expiry-date cert-data)
    })
    ERR_NOT_FOUND
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
    total-certified-professionals: (var-get total-certified-professionals)
  })
)