
(declare (hide *callback-proc*
               *exception*))

(define *callback-proc* #f)
(define *exception* #f)

;; generate safe wrapper around callbacks
;; params:
;;   foreign-each: string-value of function name to invoke (eg
;;   cpSpaceEachBody)
;;
;;   foreign-callback: string-name of foreign function to invoke as
;;   each callback (can be define-external)
;;
;; we cannot pass the callback proc in the user-data field because
;; its unmanaged pointer would become invalid in the event of a GC.
;; 
;; needs to call safe-lambda because callback may be external (back to scheme)
(define-syntax (shape-callback-wrapper x r t)
  (let ([foreign-each (cadr x)]
        [foreign-callback (caddr x)])
    `(lambda (space callback)
       (if *callback-proc* (error "chickmunk: nested for-each callbacks not supported"))
       (set! *callback-proc* callback)
       (set! *exception* #f)
       ((foreign-safe-lambda* void (((c-pointer void) subject) ; space / body
                                    ((c-pointer void) foreign_callback)
                                    ((c-pointer void) data))
                              ,(conc foreign-each "(subject, foreign_callback, (void*)0);"))
        space (foreign-value ,foreign-callback c-pointer) #f)
       (set! *callback-proc* #f)
       (if *exception* (abort *exception*)))))

;; call *callback-proc*, but handle any exceptions by storing them for
;; later. we want to finish all for-each callbacks so that chipmunk
;; can return and cleanup (unlock space etc). if an error has occured,
;; ignore do nothing on subsequent callbacks
(define (call-and-catch . args)
  (if (not *exception*)
      (handle-exceptions exn
        (begin (set! *exception* exn))
        (apply *callback-proc* args))))


;; ********************
;; for-each callbacks for space (global bodies, shapes & constrains)
(define-external (cb_space_each
                  ((c-pointer void) object) ; from callback: body/shape/constraint
                  ((c-pointer void) data) ; ignored
                  )
  void
  (call-and-catch object))



(define for-each-body (shape-callback-wrapper "cpSpaceEachBody" "cb_space_each"))
(define for-each-shape (shape-callback-wrapper "cpSpaceEachShape" "cb_space_each"))
(define for-each-constraint (shape-callback-wrapper "cpSpaceEachConstraint" "cb_space_each"))

;; *********
;; for-each callbacks on body (shapes, constraints etc belonging to a body)
(define-external (cb_body_each ((c-pointer void) body) ; owner
                               ((c-pointer void) object) ; shape/constraint/arbiter
                               ((c-pointer void) data)) ; ignored
  void
  (call-and-catch body object))

(define body-for-each-shape (shape-callback-wrapper "cpBodyEachShape" "cb_body_each"))
(define body-for-each-constraint (shape-callback-wrapper "cpBodyEachConstraint" "cb_body_each"))
(define body-for-each-arbiter (shape-callback-wrapper "cpBodyEachArbiter" "cb_body_each"))


;; **********************
;; space body, shape and constrains lists
;; define convenience functions to get lists of global objects
(define-syntax (make-callback->list-proc x r t)
  (let ([nm (cadr x)])
    `(lambda (space)
       (let ([tmp-list '()])
         (,nm space (lambda (obj) (set! tmp-list (cons obj tmp-list))))
         tmp-list))))

(define bodies (make-callback->list-proc for-each-body))
(define shapes (make-callback->list-proc for-each-shape))
(define constraints (make-callback->list-proc for-each-constraint))

