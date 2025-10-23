;; Crowdfunding Contract
;; A secure and decentralized crowdfunding platform on Stacks blockchain

;; Constants
(define-constant ERR-NOT-FOUND (err u100))
(define-constant ERR-NOT-OWNER (err u101))
(define-constant ERR-GOAL-MET (err u102))
(define-constant ERR-LOW-AMOUNT (err u103))
(define-constant ERR-REFUNDED (err u104))
(define-constant ERR-TRANSFER (err u105))
(define-constant ERR-NOT-AUTH (err u106))
(define-constant ERR-NO-SUCCESS (err u107))
(define-constant ERR-NOT-DONE (err u108))
(define-constant ERR-CLAIMED (err u109))

;; Storage
(define-data-var admin principal tx-sender)
(define-data-var counter uint u0)

(define-map projects uint 
  {creator: principal, 
   title: (string-ascii 64), 
   desc: (string-ascii 256), 
   goal: uint, 
   raised: uint, 
   end: uint, 
   claimed: bool})

(define-map funds 
  {pid: uint, user: principal} 
  uint)

;; Public functions
(define-public (new-project (title (string-ascii 64)) (desc (string-ascii 256)) (goal uint) (days uint))
  (begin 
    (asserts! (and (> goal u0) (> days u0)) ERR-LOW-AMOUNT)
    (asserts! (>= (len title) u1) ERR-NOT-FOUND)
    (asserts! (>= (len desc) u1) ERR-NOT-FOUND)
    (let ((pid (+ (var-get counter) u1)))
      (var-set counter pid)
      (map-set projects pid 
        {creator: tx-sender,
         title: title,
         desc: desc,
         goal: goal,
         raised: u0,
         end: (+ burn-block-height (* days u144)),
         claimed: false})
      (ok pid))))

(define-public (fund (pid uint))
  (let ((project (unwrap! (map-get? projects pid) ERR-NOT-FOUND)))
    (let ((amount (stx-get-balance tx-sender))
          (prev (default-to u0 (map-get? funds {pid: pid, user: tx-sender}))))
      (asserts! (> amount u0) ERR-LOW-AMOUNT)
      (asserts! (<= burn-block-height (get end project)) ERR-NOT-DONE)
      (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
      (map-set funds {pid: pid, user: tx-sender} (+ prev amount))
      (map-set projects pid (merge project {raised: (+ (get raised project) amount)}))
      (ok amount))))

(define-public (claim (pid uint))
  (let ((project (unwrap! (map-get? projects pid) ERR-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get creator project)) ERR-NOT-AUTH)
    (asserts! (>= (get raised project) (get goal project)) ERR-NO-SUCCESS)
    (asserts! (>= burn-block-height (get end project)) ERR-NOT-DONE)
    (asserts! (not (get claimed project)) ERR-CLAIMED)
    (try! (stx-transfer? (get raised project) (as-contract tx-sender) tx-sender))
    (map-set projects pid (merge project {claimed: true}))
    (ok (get raised project))))

(define-public (refund (pid uint))
  (let ((project (unwrap! (map-get? projects pid) ERR-NOT-FOUND))
        (amount (unwrap! (map-get? funds {pid: pid, user: tx-sender}) ERR-NOT-FOUND)))
    (asserts! (< (get raised project) (get goal project)) ERR-GOAL-MET)
    (asserts! (>= burn-block-height (get end project)) ERR-NOT-DONE)
    (asserts! (> amount u0) ERR-REFUNDED)
    (try! (stx-transfer? amount (as-contract tx-sender) tx-sender))
    (map-set funds {pid: pid, user: tx-sender} u0)
    (ok amount)))

;; Read-only functions
(define-read-only (get-project (pid uint)) 
  (ok (map-get? projects pid)))

(define-read-only (get-funds (pid uint) (user principal)) 
  (ok (map-get? funds {pid: pid, user: user})))

(define-read-only (get-count) 
  (ok (var-get counter)))
