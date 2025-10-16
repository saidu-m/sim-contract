;; ---------------------------------------------------
;; SIM-CONTRACT - Complete & Robust Version
;; ---------------------------------------------------
;; Author: Your Name
;; Network: Stacks
;; Tools: Clarinet, Clarity
;;
;; Features:
;;  - Write / update / delete personal messages
;;  - Read messages and timestamps
;;  - Track unique signers and list them
;;  - Admin controls (transfer admin, reset stats)
;;  - Events emitted for key actions
;; ---------------------------------------------------

;; ----------------------------
;; Data Definitions
;; ----------------------------
(define-map messages
  { user: principal }
  { text: (string-utf8 200), timestamp: uint })

(define-data-var total-messages uint u0)
(define-data-var signers (list 500 principal) (list))
(define-data-var admin principal tx-sender)

;; ----------------------------
;; Error constants
;; ----------------------------
(define-constant ERR-NO-MESSAGE (err u100))
(define-constant ERR-EMPTY-MESSAGE (err u101))
(define-constant ERR-NOT-ADMIN (err u102))
(define-constant ERR-ALREADY-ADMIN (err u103))

;; ----------------------------
;; Private helpers
;; ----------------------------

;; Check whether a user has a message
(define-read-only (is-signed? (user principal))
  (is-some (map-get? messages { user: user })))

;; Internal: add signer to signers list if not present
(define-private (internal-add-signer (user principal))
  (let ((s (var-get signers)))
    (if (is-none (index-of s user))
        (begin
          (var-set signers (unwrap-panic (as-max-len? (append s user) u500)))
          (var-set total-messages (+ (var-get total-messages) u1))
          (ok true))
        (ok false))))

;; Internal: remove signer from signers list (if present) and decrement count
(define-private (internal-remove-signer (user principal))
  (let ((s (var-get signers)))
    (let ((filtered (filter is-not-user s)))
      (begin
        (var-set signers filtered)
        ;; adjust total-messages safely (only when previously existed)
        (var-set total-messages (if (> (var-get total-messages) u0) (- (var-get total-messages) u1) u0))
        (ok true)))))

(define-private (is-not-user (p principal))
  (not (is-eq p tx-sender)))

;; Internal: require admin caller
(define-private (require-admin (caller principal))
  (if (is-eq caller (var-get admin))
      (ok true)
      ERR-NOT-ADMIN))

;; ----------------------------
;; Public functions
;; ----------------------------

;; Write a new message (or overwrite if they already have one)
(define-public (write-message (text (string-utf8 200)))
  (begin
    (asserts! (> (len text) u0) ERR-EMPTY-MESSAGE)
    (let ((now block-height))
      (map-set messages
        { user: tx-sender }
        { text: text, timestamp: now })
      ;; ensure signer is recorded
      (try! (internal-add-signer tx-sender))
      ;; emit event using print instead of emit-event
      (print { event: "message-written", who: tx-sender, ts: now })
      (ok { sender: tx-sender, written: true, timestamp: now })
    )
  )
)

;; Update existing message (errors if none exists)
(define-public (update-message (text (string-utf8 200)))
  (begin
    (asserts! (> (len text) u0) ERR-EMPTY-MESSAGE)
    (match (map-get? messages { user: tx-sender })
      entry
        (let ((now block-height))
          (map-set messages
            { user: tx-sender }
            { text: text, timestamp: now })
          ;; emit event using print instead of emit-event
          (print { event: "message-updated", who: tx-sender, ts: now })
          (ok { updated: true, timestamp: now }))
      ERR-NO-MESSAGE)
  )
)

;; Delete your message (removes entry and signer)
(define-public (delete-message)
  (match (map-get? messages { user: tx-sender })
    entry
      (let ((now block-height))
        (map-delete messages { user: tx-sender })
        (try! (internal-remove-signer tx-sender))
        ;; emit event using print instead of emit-event
        (print { event: "message-deleted", who: tx-sender, ts: now })
        (ok { deleted: true, timestamp: now }))
    ERR-NO-MESSAGE)
)

;; Transfer admin role to another principal
(define-public (transfer-admin (new-admin principal))
  (begin
    (try! (require-admin tx-sender))
    (asserts! (not (is-eq new-admin (var-get admin))) ERR-ALREADY-ADMIN)
    (let ((old (var-get admin)))
      (var-set admin new-admin)
      ;; emit event using print instead of emit-event
      (print { event: "admin-transferred", from: old, to: new-admin })
      (ok { from: old, to: new-admin })))
)

;; Admin-only: reset stats (clears signers list and total counter; DOES NOT remove messages)
(define-public (admin-reset)
  (begin
    (try! (require-admin tx-sender))
    (var-set signers (list))
    (var-set total-messages u0)
    ;; emit event using print instead of emit-event
    (print { event: "stats-reset", by: tx-sender, ts: block-height })
    (ok { reset: true, by: tx-sender, ts: block-height })))

;; ----------------------------
;; Read-only functions
;; ----------------------------

;; Get message for a user (text + timestamp). Returns a tuple.
(define-read-only (get-message (user principal))
  (match (map-get? messages { user: user })
    entry (ok entry)
    (ok { text: u"No message found", timestamp: u0 })))

;; Check if a user has a message
(define-read-only (has-message? (user principal))
  (is-some (map-get? messages { user: user })))

;; List all signers (array of principals)
(define-read-only (list-signers)
  (var-get signers))

;; Total unique messages count
(define-read-only (get-total-messages)
  (var-get total-messages))

;; Contract stats
(define-read-only (get-stats)
  {
    total-messages: (var-get total-messages),
    signer-count: (len (var-get signers)),
    admin: (var-get admin),
    current-block: block-height
  })

;; Get admin
(define-read-only (get-admin) (var-get admin))
