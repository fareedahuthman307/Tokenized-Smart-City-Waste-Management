;; performance-analytics.clar
;; This contract monitors system efficiency and performance metrics

(define-data-var contract-owner principal tx-sender)

;; Map to store system metrics
(define-map system-metrics
  { metric-id: uint }
  {
    metric-name: (string-utf8 50),
    description: (string-utf8 100),
    active: bool
  }
)

;; Map to store metric values
(define-map metric-values
  { metric-id: uint, period: uint }
  {
    value: uint,
    timestamp: uint,
    reporter: principal
  }
)

;; Map to store performance targets
(define-map performance-targets
  { metric-id: uint }
  {
    target-value: uint,
    min-acceptable: uint,
    max-acceptable: uint,
    last-updated: uint
  }
)

;; Map to store performance rewards
(define-map performance-rewards
  { period: uint }
  {
    total-reward: uint,
    distributed: bool
  }
)

;; Public function to register a new metric
(define-public (register-metric
                (metric-id uint)
                (metric-name (string-utf8 50))
                (description (string-utf8 100)))
  (let ((caller tx-sender))
    (asserts! (is-eq caller (var-get contract-owner)) (err u1))
    (asserts! (is-none (map-get? system-metrics { metric-id: metric-id })) (err u2))

    (map-set system-metrics
      { metric-id: metric-id }
      {
        metric-name: metric-name,
        description: description,
        active: true
      }
    )

    (ok true)
  )
)

;; Public function to set performance target
(define-public (set-performance-target
                (metric-id uint)
                (target-value uint)
                (min-acceptable uint)
                (max-acceptable uint))
  (let ((caller tx-sender))
    (asserts! (is-eq caller (var-get contract-owner)) (err u3))
    (asserts! (is-some (map-get? system-metrics { metric-id: metric-id })) (err u4))
    (asserts! (<= min-acceptable target-value) (err u5))
    (asserts! (>= max-acceptable target-value) (err u6))

    (map-set performance-targets
      { metric-id: metric-id }
      {
        target-value: target-value,
        min-acceptable: min-acceptable,
        max-acceptable: max-acceptable,
        last-updated: block-height
      }
    )

    (ok true)
  )
)

;; Public function to report metric value
(define-public (report-metric-value (metric-id uint) (period uint) (value uint))
  (let ((caller tx-sender)
        (metric-data (unwrap! (map-get? system-metrics { metric-id: metric-id }) (err u7))))

    ;; Check if metric is active
    (asserts! (get active metric-data) (err u8))

    ;; Check if caller is authorized (for simplicity, only contract owner can report)
    (asserts! (is-eq caller (var-get contract-owner)) (err u9))

    (map-set metric-values
      { metric-id: metric-id, period: period }
      {
        value: value,
        timestamp: block-height,
        reporter: caller
      }
    )

    (ok true)
  )
)

;; Public function to set performance reward for a period
(define-public (set-performance-reward (period uint) (reward-amount uint))
  (let ((caller tx-sender))
    (asserts! (is-eq caller (var-get contract-owner)) (err u10))

    (map-set performance-rewards
      { period: period }
      {
        total-reward: reward-amount,
        distributed: false
      }
    )

    (ok true)
  )
)

;; Read-only function to get metric details
(define-read-only (get-metric-details (metric-id uint))
  (map-get? system-metrics { metric-id: metric-id })
)

;; Read-only function to get metric value
(define-read-only (get-metric-value (metric-id uint) (period uint))
  (map-get? metric-values { metric-id: metric-id, period: period })
)

;; Read-only function to get performance target
(define-read-only (get-performance-target (metric-id uint))
  (map-get? performance-targets { metric-id: metric-id })
)

;; Read-only function to get performance reward
(define-read-only (get-performance-reward (period uint))
  (map-get? performance-rewards { period: period })
)

;; Read-only function to check if metric meets target
(define-read-only (is-target-met (metric-id uint) (period uint))
  (let ((value-data (unwrap! (map-get? metric-values { metric-id: metric-id, period: period }) (err u11)))
        (target-data (unwrap! (map-get? performance-targets { metric-id: metric-id }) (err u12))))

    (ok (and (>= (get value value-data) (get min-acceptable target-data))
             (<= (get value value-data) (get max-acceptable target-data))))
  )
)

;; Function to deactivate a metric
(define-public (deactivate-metric (metric-id uint))
  (let ((caller tx-sender)
        (metric-data (unwrap! (map-get? system-metrics { metric-id: metric-id }) (err u13))))

    (asserts! (is-eq caller (var-get contract-owner)) (err u14))

    (map-set system-metrics
      { metric-id: metric-id }
      (merge metric-data { active: false })
    )

    (ok true)
  )
)

;; Function to transfer contract ownership
(define-public (transfer-ownership (new-owner principal))
  (let ((caller tx-sender))
    (asserts! (is-eq caller (var-get contract-owner)) (err u15))
    (var-set contract-owner new-owner)
    (ok true)
  )
)
