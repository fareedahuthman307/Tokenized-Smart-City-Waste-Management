;; fill-level-monitoring.clar
;; This contract tracks container capacity and fill levels

(define-data-var contract-owner principal tx-sender)

;; Map to store container fill levels
(define-map container-fill-levels
  { container-id: uint }
  {
    point-id: uint,
    current-fill: uint,
    capacity: uint,
    last-updated: uint,
    reporter: principal
  }
)

;; Map to track fill level history
(define-map fill-level-history
  { container-id: uint, timestamp: uint }
  {
    fill-level: uint,
    reporter: principal
  }
)

;; Event for fill level updates
(define-data-var event-counter uint u0)

;; Public function to register a new container
(define-public (register-container (container-id uint) (point-id uint) (capacity uint))
  (let ((caller tx-sender))
    (asserts! (is-eq caller (var-get contract-owner)) (err u1))
    (asserts! (is-none (map-get? container-fill-levels { container-id: container-id })) (err u2))

    (map-set container-fill-levels
      { container-id: container-id }
      {
        point-id: point-id,
        current-fill: u0,
        capacity: capacity,
        last-updated: block-height,
        reporter: caller
      }
    )

    (ok true)
  )
)

;; Public function to update container fill level
(define-public (update-fill-level (container-id uint) (new-fill-level uint))
  (let ((caller tx-sender)
        (container-data (unwrap! (map-get? container-fill-levels { container-id: container-id }) (err u3)))
        (timestamp block-height))

    (asserts! (<= new-fill-level (get capacity container-data)) (err u4))

    ;; Update current fill level
    (map-set container-fill-levels
      { container-id: container-id }
      (merge container-data {
        current-fill: new-fill-level,
        last-updated: timestamp,
        reporter: caller
      })
    )

    ;; Record in history
    (map-set fill-level-history
      { container-id: container-id, timestamp: timestamp }
      {
        fill-level: new-fill-level,
        reporter: caller
      }
    )

    ;; Increment event counter
    (var-set event-counter (+ (var-get event-counter) u1))

    (ok true)
  )
)

;; Read-only function to get container fill level
(define-read-only (get-fill-level (container-id uint))
  (match (map-get? container-fill-levels { container-id: container-id })
    container-data (ok (get current-fill container-data))
    (err u5)
  )
)

;; Read-only function to get container fill percentage
(define-read-only (get-fill-percentage (container-id uint))
  (match (map-get? container-fill-levels { container-id: container-id })
    container-data
      (let ((current-fill (get current-fill container-data))
            (capacity (get capacity container-data)))
        (ok (/ (* current-fill u100) capacity)))
    (err u6)
  )
)

;; Read-only function to check if container needs emptying (>= 80% full)
(define-read-only (needs-emptying (container-id uint))
  (match (map-get? container-fill-levels { container-id: container-id })
    container-data
      (let ((current-fill (get current-fill container-data))
            (capacity (get capacity container-data))
            (threshold (/ (* capacity u80) u100)))
        (ok (>= current-fill threshold)))
    (err u7)
  )
)

;; Read-only function to get container details
(define-read-only (get-container-details (container-id uint))
  (map-get? container-fill-levels { container-id: container-id })
)

;; Read-only function to get historical fill level
(define-read-only (get-historical-fill-level (container-id uint) (timestamp uint))
  (map-get? fill-level-history { container-id: container-id, timestamp: timestamp })
)

;; Function to transfer contract ownership
(define-public (transfer-ownership (new-owner principal))
  (let ((caller tx-sender))
    (asserts! (is-eq caller (var-get contract-owner)) (err u8))
    (var-set contract-owner new-owner)
    (ok true)
  )
)
