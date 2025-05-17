;; collection-point-verification.clar
;; This contract validates waste receptacles and their authenticity

(define-data-var contract-owner principal tx-sender)

;; Map to store verified collection points
(define-map collection-points
  { point-id: uint }
  {
    location: (string-utf8 100),
    verified: bool,
    verifier: principal,
    last-verified: uint
  }
)

;; Map to track collection point operators
(define-map point-operators
  { point-id: uint }
  { operator: principal }
)

;; Public function to register a new collection point
(define-public (register-collection-point (point-id uint) (location (string-utf8 100)))
  (let ((caller tx-sender))
    (asserts! (is-eq caller (var-get contract-owner)) (err u1))
    (asserts! (is-none (map-get? collection-points { point-id: point-id })) (err u2))

    (map-set collection-points
      { point-id: point-id }
      {
        location: location,
        verified: false,
        verifier: caller,
        last-verified: block-height
      }
    )

    (map-set point-operators
      { point-id: point-id }
      { operator: caller }
    )

    (ok true)
  )
)

;; Public function to verify a collection point
(define-public (verify-collection-point (point-id uint))
  (let ((caller tx-sender)
        (point-data (unwrap! (map-get? collection-points { point-id: point-id }) (err u3))))

    (asserts! (is-eq caller (var-get contract-owner)) (err u4))

    (map-set collection-points
      { point-id: point-id }
      (merge point-data {
        verified: true,
        verifier: caller,
        last-verified: block-height
      })
    )

    (ok true)
  )
)

;; Public function to update collection point operator
(define-public (set-point-operator (point-id uint) (new-operator principal))
  (let ((caller tx-sender))
    (asserts! (is-eq caller (var-get contract-owner)) (err u5))
    (asserts! (is-some (map-get? collection-points { point-id: point-id })) (err u6))

    (map-set point-operators
      { point-id: point-id }
      { operator: new-operator }
    )

    (ok true)
  )
)

;; Read-only function to check if a collection point is verified
(define-read-only (is-point-verified (point-id uint))
  (match (map-get? collection-points { point-id: point-id })
    point-data (ok (get verified point-data))
    (err u7)
  )
)

;; Read-only function to get collection point details
(define-read-only (get-collection-point (point-id uint))
  (map-get? collection-points { point-id: point-id })
)

;; Read-only function to get collection point operator
(define-read-only (get-point-operator (point-id uint))
  (map-get? point-operators { point-id: point-id })
)

;; Function to transfer contract ownership
(define-public (transfer-ownership (new-owner principal))
  (let ((caller tx-sender))
    (asserts! (is-eq caller (var-get contract-owner)) (err u8))
    (var-set contract-owner new-owner)
    (ok true)
  )
)
