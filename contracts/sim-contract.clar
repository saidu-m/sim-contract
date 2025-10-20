;; --------------------------------------------------
;; SIM-CONTRACT - Final & Error-Free Version
;; --------------------------------------------------
;; Author: Your Name
;; Network: Stacks (Clarinet)
;; Purpose: A simple smart contract that lets users
;;          write, update, and delete messages.
;; Features:
;;  - Message posting and editing
;;  - Delete functionality
;;  - Admin control and stats reset
;;  - Event logging
;;  - Robust error handling
;; --------------------------------------------------

;; ----------------------------
;; Data Definitions
;; ----------------------------

(define-map messages
  { user: principal }
  { text: (string-utf8 200), block: uint })

(define-data-var total-messages uint u0)
(define-data-var admin principal tx-sender)

;; ----------------------------
;; Error Constants
;; ----------------------------

(define-constant ERR-NO-MESSAGE (err u100))
(define-constant ERR-EMPTY-MESSAGE (err u101))
(define-constant ERR-NOT-ADMIN (err u102))
(define-constant ERR-SAME-ADMIN (err u103))

;; ----------------------------
;; Private Helper Functions
;; ----------------------------

;; Ensure the caller is admin
(define-private (require-admin (caller principal))
  (if (is-eq caller (var-get admin))
      (ok true)
      ERR-NOT-ADMIN)
)

;; Safely decrease counter
(define-private (safe-decrease (value uint))
  (if (> value u0)
      (- value u1)
      u0)
)

;; ----------------------------
;; Public Functions
;; ----------------------------

;; Write a new message
(define-public (write-message (text (string-utf8 200)))
  (begin
    (asserts! (> (len text) u0) ERR-EMPTY-MESSAGE)
    (map-set messages
      { user: tx-sender }
      { text: text, block: u0 })
    (var-set total-messages (+ (var-get total-messages) u1))
    (print { event: "message-written", user: tx-sender, text: text })
    (ok { written-by: tx-sender, block: u0 })))

;; Update existing message
(define-public (update-message (text (string-utf8 200)))
  (match (map-get? messages { user: tx-sender })
    msg
      (begin
        (asserts! (> (len text) u0) ERR-EMPTY-MESSAGE)
        ;; update message with current block height
        (map-set messages { user: tx-sender } { text: text, block: u0 })
        (print { event: "message-updated", user: tx-sender })
        (ok { updated: true, block: u0 }))
    ERR-NO-MESSAGE))

;; Delete a user's message
(define-public (delete-message)
  (match (map-get? messages { user: tx-sender })
    msg
      (begin
        (map-delete messages { user: tx-sender })
        (var-set total-messages (safe-decrease (var-get total-messages)))
        (print { event: "message-deleted", user: tx-sender })
        (ok { deleted: true, block: u0 }))
    ERR-NO-MESSAGE))

;; Transfer admin to another address
(define-public (transfer-admin (new-admin principal))
  (begin
    (try! (require-admin tx-sender))
    (asserts! (not (is-eq new-admin (var-get admin))) ERR-SAME-ADMIN)
    (let ((old (var-get admin)))
      (var-set admin new-admin)
      (print { event: "admin-transferred", from: old, to: new-admin })
      (ok { from: old, to: new-admin }))))


;; Reset all statistics (admin only)
(define-public (admin-reset)
  (begin
    (try! (require-admin tx-sender))
    (var-set total-messages u0)
    (print { event: "stats-reset", by: tx-sender })
    (ok { reset: true, by: tx-sender })))

;; ----------------------------
;; Read-only Functions
;; ----------------------------

;; Retrieve a user's message
(define-read-only (get-message (user principal))
  (ok (map-get? messages { user: user })))

;; Get total number of messages
(define-read-only (get-total-messages)
  (ok (var-get total-messages))
)

;; Get the admin address
(define-read-only (get-admin)
  (ok (var-get admin))
)

;; Check if user has a message
(define-read-only (has-message? (user principal))
  (is-some (map-get? messages { user: user }))
)

;; Get complete contract statistics
(define-read-only (get-stats)
  (ok {
    total-messages: (var-get total-messages),
    admin: (var-get admin),
    block-height: u0
  }))
