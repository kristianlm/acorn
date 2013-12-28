
(declare (hide *callback-proc*
               *exception*))

(define *callback-proc* #f)
(define *exception* #f)


;; we cannot pass the callback proc in the user-data field because
;; its unmanaged pointer would become invalid in the event of a GC.
(define-syntax (start-safe-callbacks x r t)
  (let ([callback-name (cadr x)]
        [foreign-lambda-call (caddr x)])
    `(begin
      (if *callback-proc* (error "acorn: nested callbacks not supported"))
      (set! *callback-proc* ,callback-name)
      (set! *exception* #f)
      ,foreign-lambda-call
      (set! *callback-proc* #f)
      (if *exception* (abort *exception*)))))

;; strategy for callbacks:
;; 1. allocate a non-gc'ed C_word to store a special callback-proc
;; 2. pass this C_word as data to all query functions
;; 3. n_ callbacks will receive this and will call this.
;; 4. it returns the potentially new callback-proc (gc move), so
;; updates the stack-allocated C_word.
;; 5. it calls the updated callback-proc next time

;; generate safe wrapper around callbacks
;; params:
;;   foreign-each: string-value of function name to invoke (eg
;;   cpSpaceEachBody)
;;
;;   foreign-callback: string-name of foreign function to invoke as
;;   each callback (can be define-external)
;; 
;; needs to call safe-lambda because callback may be external (back to scheme)
(define-syntax (make-safe-callbacks-space x r t)
  (let ([foreign-each (cadr x)]
        [foreign-callback (caddr x)])
    `(lambda (space callback)
       (start-safe-callbacks callback
        ((foreign-safe-lambda* void (((c-pointer void) subject) ; space / body
                                     ((c-pointer void) foreign_callback))
                               ,(conc foreign-each "(subject, foreign_callback, (void*)0);"))
         space (foreign-value ,foreign-callback c-pointer))))
    ))

;; Call *callback-proc*, but handle any exceptions by storing them for
;; later. we want to finish all for-each callbacks so that chipmunk
;; can return and cleanup (unlock space etc). if an error has occured,
;; do nothing on subsequent callbacks
(define (call-and-catch . args)
  (if (not *exception*)
      (handle-exceptions exn
        (begin (set! *exception* exn))
        (apply *callback-proc* args))))



;; call proc normally, removing the argument type information from args.
(define-syntax -argnames
  (er-macro-transformer
   (lambda (x r t)
     (let* ((fname (cadr x)) (argspecs (cddr x)))
       `(,fname ,@(map cadr argspecs))))))
;; (test '(myproc x y) (expand '(-argnames myproc (pointer x) (vect y))))


;; define an external proc which returns the procedure which it calls
(define-syntax -define-external-callback
  (syntax-rules (scheme-object -proc-)
    ((_ fname args ...)
     (define-external (fname args ... (scheme-object -proc-))
       scheme-object
       (-argnames -proc- args ...)
       -proc-))))
;; ********************
;; for-each callbacks for space (global bodies, shapes & constrains)

(-define-external-callback s_body_callback       ((c-pointer "cpBody") object))
(-define-external-callback s_shape_callback      ((c-pointer "cpShape") object))
(-define-external-callback s_constraint_callback ((c-pointer "cpConstraint") object))

(-define-external-callback s_body_shape_iterator
                           ((c-pointer "cpBody") body)
                           ((c-pointer "cpShape") shape))

(-define-external-callback s_body_constraint_iterator
                           ((c-pointer "cpBody") body)
                           ((c-pointer "cpConstraint") shape))

(-define-external-callback s_body_arbiter_iterator
                           ((c-pointer "cpBody") body)
                           ((c-pointer "cpArbiter") arbiter))

;; TODO: generate all these native functions from callback signature
#>

C_word s_body_callback(cpBody* object, C_word p);
C_word s_constraint_callback(cpConstraint* object, C_word p);
C_word s_shape_callback(cpShape* object, C_word p);

C_word s_body_shape_iterator(cpBody* body, cpShape* object, C_word p);
C_word s_body_constraint_iterator(cpBody* body, cpConstraint* object, C_word p);
C_word s_body_arbiter_iterator(cpBody* body, cpArbiter* object, C_word p);

void n_body_callback(cpBody *body, void *data) {
  C_word * d = (C_word*)data;
  *d = s_body_callback(body, *d) ;
}

void n_shape_callback(cpShape *shape, void *data) {
  C_word * d = (C_word*)data;
  *d = s_shape_callback(shape, *d) ;
}

void n_constraint_callback(cpConstraint *subject, void *data) {
  C_word * d = (C_word*)data;
  *d = s_constraint_callback(subject, *d) ;
}



void n_body_shape_iterator(cpBody* body, cpShape* shape, void *data) {
  C_word * d = (C_word*)data;
  *d = s_body_shape_iterator(body, shape, *d) ;
}
void n_body_constraint_iterator(cpBody* body, cpConstraint* constraint, void *data) {
  C_word * d = (C_word*)data;
  *d = s_body_constraint_iterator(body, constraint, *d) ;
}
void n_body_arbiter_iterator(cpBody* body, cpArbiter* arb, void *data) {
  C_word * d = (C_word*)data;
  *d = s_body_arbiter_iterator(body, arb, *d) ;
}
<#




;; produce a lambda which calls the chipmunk query-function, but the
;; callback is stored and kept on the stack in case the GC moves the
;; callback proc.
(define-syntax (-safe-foreign-callback x r t)
  (let* ([callback-handler (cadr x)]
         [foreign-query (caddr x)]
         [args (cdddr x)]
         [arg-names (map cadr args)]
         [arg-calls (map last args)])
    `(lambda (,@arg-names callback)
       ((foreign-safe-lambda* void (,@args (scheme-object cb))
                              ,(conc "C_word cb_holder = cb; "
                                     foreign-query ;; chipmunk query func
                                     (intersperse
                                      `(,@arg-calls
                                        ;; last two arguments are our
                                        ;; foreign-handler and a
                                        ;; pointer to a variable on
                                        ;; our stack which holds our
                                        ;; scheme callback-proc.
                                        ,callback-handler
                                        "(void*)&cb_holder" )
                                      " , ")
                                     ";"))
        ,@arg-names callback))))
(define-external (cb_space_each
                  ((c-pointer void) object) ; from callback: body/shape/constraint
                  ((c-pointer void) data) ; ignored
                  )
  void
  (call-and-catch object))



(define space-for-each-body (-safe-foreign-callback "n_body_callback" "cpSpaceEachBody"
                                                    ((c-pointer void) space)))
(define space-for-each-shape (-safe-foreign-callback "n_shape_callback" "cpSpaceEachShape"
                                                     ((c-pointer void) space)))
(define space-for-each-constraint (-safe-foreign-callback "n_constraint_callback" "cpSpaceEachConstraint"
                                                          ((c-pointer void) space)))

;; *********
;; for-each callbacks on body (shapes, constraints etc belonging to a body)
(define-external (cb_body_each ((c-pointer void) body) ; owner
                               ((c-pointer void) object) ; shape/constraint/arbiter
                               ((c-pointer void) data)) ; ignored
  void
  (call-and-catch body object))

;; using same callback signature
(define body-for-each-shape (-safe-foreign-callback "n_body_shape_iterator" "cpBodyEachShape"
                                                    ((c-pointer "cpBody") body)))
(define body-for-each-constraint (-safe-foreign-callback "n_body_constraint_iterator" "cpBodyEachConstraint"
                                                         ((c-pointer "cpBody") body)))
(define body-for-each-arbiter (-safe-foreign-callback "n_body_arbiter_iterator" "cpBodyEachArbiter"
                                                      ((c-pointer "cpBody") body)))


;; **********************
;; space body, shape and constrains lists
;; define convenience functions to get lists of global objects
(define (make-callback->list-proc for-each-proc #!optional (conv-proc (lambda (obj) obj)))
  (lambda args
     (let ([tmp-list '()])
       (apply for-each-proc (append args
                             (list (lambda args
                                (set! tmp-list (cons (apply conv-proc args) tmp-list))))))
       tmp-list)))

(define space-bodies      (make-callback->list-proc space-for-each-body))
(define space-shapes      (make-callback->list-proc space-for-each-shape))
(define space-constraints (make-callback->list-proc space-for-each-constraint))

(declare (hide get-body-subject-callback))
(define (get-body-subject-callback body subject)
  subject)

(define body-shapes      (make-callback->list-proc body-for-each-shape      get-body-subject-callback))
(define body-constraints (make-callback->list-proc body-for-each-constraint get-body-subject-callback))
(define body-arbiters    (make-callback->list-proc body-for-each-arbiter    get-body-subject-callback))

(define-external (cb_space_point_query ((c-pointer "cpShape") shape)
                                       ((c-pointer void) data))
  void
  (call-and-catch shape))

(define space-for-each-point-query
  (-safe-foreign-callback "n_shape_callback" "cpSpacePointQuery"
                          ((c-pointer void) space)
                          (f32vector point "*(cpVect*)point")
                          (unsigned-int layers)
                          (unsigned-int group)))


;; let's keep argument names for user convenience
(define (space-point-query space point layers group)
  ((make-callback->list-proc space-for-each-point-query) space point layers group))

;; **************************
;; Callbacks for segment query
#>
void cb_space_segment_query(cpShape*, float, float, float);
static void cb_space_segment_query_adapter(struct cpShape *shape, float t, cpVect n, void* data) {
  cb_space_segment_query(shape, t, n.x, n.y);
}
<#

(define-external (cb_space_segment_query ((c-pointer "cpShape") shape)
                                         (float t)
                                         (float nx)
                                         (float ny))
  void
  (call-and-catch shape t (list nx ny)))



(define (space-for-each-segment-query space start-point end-point layers group callback)
  (start-safe-callbacks callback
                        ((foreign-safe-lambda* void (((c-pointer "cpSpace") space)
                                                ((c-pointer "cpVect") start_point)
                                                ((c-pointer "cpVect") end_point)
                                                (unsigned-int layers)
                                                (unsigned-int group))
                                          "cpSpaceSegmentQuery(space, *start_point, *end_point,"
                                          "layers, group,"
                                          "(cpSpaceSegmentQueryFunc)cb_space_segment_query_adapter,"
                                          "(void*)0);")
                         space start-point end-point layers group)))


(define (space-segment-query space start-point end-point layers group)
  ((make-callback->list-proc
    space-for-each-segment-query (lambda s-t-n s-t-n) ; make list of all callback args
    ) space start-point end-point layers group))


;; ********* BB queries

(define-external (cb_space_bb_query ((c-pointer "cpShape") shape) ((c-pointer void) data))
  void
  (call-and-catch shape))

(define (space-for-each-bb-query space bb layers group callback)
  (start-safe-callbacks callback
                        ((foreign-safe-lambda* void (((c-pointer "cpSpace") space)
                                                ((c-pointer "cpBB") bb)
                                                (unsigned-int layers)
                                                (unsigned-int group))
                                          "cpSpaceBBQuery("
                                          "space, *bb, layers, group,"
                                          "(cpSpaceBBQueryFunc)cb_space_bb_query,"
                                          "(void*)0);")
                         space bb layers group)))

(define (space-bb-query space bb layers group)
  ((make-callback->list-proc space-for-each-bb-query) space bb layers group))
