;; Define token for rewards
(define-fungible-token reward-token)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-family-member (err u101))
(define-constant err-chore-not-found (err u102))
(define-constant err-already-completed (err u103))
(define-constant err-insufficient-balance (err u104))
(define-constant err-invalid-reward (err u105))
(define-constant max-reward-amount u1000)

;; Events
(define-data-var last-event-id uint u0)
(define-map events 
  uint 
  {
    event-type: (string-ascii 20),
    chore-id: uint,
    user: principal,
    amount: uint
  }
)

;; Data structures
(define-map families 
  principal 
  (list 10 principal)
)

(define-map chores
  uint 
  {
    description: (string-ascii 50),
    reward: uint,
    assigned-to: principal,
    completed: bool,
    parent: principal
  }
)

(define-data-var chore-id-nonce uint u0)

;; Helper functions
(define-private (emit-event (event-type (string-ascii 20)) (chore-id uint) (user principal) (amount uint))
  (let
    ((event-id (+ (var-get last-event-id) u1)))
    (var-set last-event-id event-id)
    (map-set events event-id {
      event-type: event-type,
      chore-id: chore-id,
      user: user,
      amount: amount
    })
    event-id
  )
)

;; Create family
(define-public (create-family (members (list 10 principal)))
  (if (is-eq tx-sender contract-owner)
    (begin
      (map-set families tx-sender members)
      (emit-event "family-created" u0 tx-sender u0)
      (ok true)
    )
    err-owner-only
  )
)

;; Add chore
(define-public (add-chore (description (string-ascii 50)) (reward uint) (assigned-to principal))
  (let
    (
      (chore-id (+ (var-get chore-id-nonce) u1))
      (members (unwrap! (map-get? families tx-sender) err-not-family-member))
    )
    (asserts! (<= reward max-reward-amount) err-invalid-reward)
    (if (is-some (index-of members assigned-to))
      (begin
        (map-set chores chore-id {
          description: description,
          reward: reward,
          assigned-to: assigned-to,
          completed: false,
          parent: tx-sender
        })
        (var-set chore-id-nonce chore-id)
        (emit-event "chore-added" chore-id assigned-to reward)
        (ok chore-id)
      )
      err-not-family-member
    )
  )
)

;; Complete chore
(define-public (complete-chore (chore-id uint))
  (let
    (
      (chore (unwrap! (map-get? chores chore-id) err-chore-not-found))
    )
    (if (and
      (is-eq (get assigned-to chore) tx-sender)
      (not (get completed chore))
    )
      (begin
        (try! (ft-mint? reward-token (get reward chore) tx-sender))
        (map-set chores chore-id (merge chore { completed: true }))
        (emit-event "chore-completed" chore-id tx-sender (get reward chore))
        (ok true)
      )
      err-already-completed
    )
  )
)

;; Get reward balance
(define-read-only (get-reward-balance (account principal))
  (ok (ft-get-balance reward-token account))
)

;; Transfer rewards
(define-public (transfer-rewards (amount uint) (recipient principal))
  (let
    (
      (sender-balance (ft-get-balance reward-token tx-sender))
    )
    (if (>= sender-balance amount)
      (begin
        (try! (ft-transfer? reward-token amount tx-sender recipient))
        (emit-event "reward-transfer" u0 recipient amount)
        (ok true)
      )
      err-insufficient-balance
    )
  )
)
