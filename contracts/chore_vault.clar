;; Define token for rewards
(define-fungible-token reward-token)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-family-member (err u101))
(define-constant err-chore-not-found (err u102))
(define-constant err-already-completed (err u103))
(define-constant err-insufficient-balance (err u104))

;; Data structures
(define-map families 
  principal ;; parent address
  (list 10 principal) ;; family members
)

(define-map chores
  uint ;; chore id  
  {
    description: (string-ascii 50),
    reward: uint,
    assigned-to: principal,
    completed: bool,
    parent: principal
  }
)

(define-data-var chore-id-nonce uint u0)

;; Create family
(define-public (create-family (members (list 10 principal)))
  (if (is-eq tx-sender contract-owner)
    (begin
      (map-set families tx-sender members)
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
        (ok true)
      )
      err-insufficient-balance
    )
  )
)
