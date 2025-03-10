;; Computational Resource Tokenization Contract
;; Tokenizes computational resources across the universe

;; Error codes
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u102))

;; Data maps
(define-map resources
  { id: uint }
  {
    owner: principal,
    type: (string-utf8 64),
    capacity: uint,
    efficiency: uint,
    active: bool
  }
)

(define-map balances
  { owner: principal, resource-id: uint }
  { amount: uint }
)

;; Variables
(define-data-var resource-count uint u0)

;; Read-only functions
(define-read-only (get-resource (id uint))
  (map-get? resources { id: id })
)

(define-read-only (get-balance (owner principal) (resource-id uint))
  (default-to
    { amount: u0 }
    (map-get? balances { owner: owner, resource-id: resource-id })
  )
)

;; Public functions
(define-public (register-resource
    (type (string-utf8 64))
    (capacity uint)
    (efficiency uint))
  (let ((new-id (+ (var-get resource-count) u1)))
    (map-set resources
      { id: new-id }
      {
        owner: tx-sender,
        type: type,
        capacity: capacity,
        efficiency: efficiency,
        active: true
      }
    )
    (var-set resource-count new-id)
    (ok new-id)
  )
)

(define-public (mint-token (resource-id uint) (amount uint))
  (let ((resource (unwrap! (get-resource resource-id) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get owner resource)) ERR_UNAUTHORIZED)

    (map-set balances
      { owner: tx-sender, resource-id: resource-id }
      { amount: (+ (get amount (get-balance tx-sender resource-id)) amount) }
    )

    (ok true)
  )
)

(define-public (transfer (resource-id uint) (amount uint) (recipient principal))
  (let ((sender-balance (get amount (get-balance tx-sender resource-id))))
    (asserts! (>= sender-balance amount) ERR_UNAUTHORIZED)

    (map-set balances
      { owner: tx-sender, resource-id: resource-id }
      { amount: (- sender-balance amount) }
    )

    (map-set balances
      { owner: recipient, resource-id: resource-id }
      { amount: (+ (get amount (get-balance recipient resource-id)) amount) }
    )

    (ok true)
  )
)

