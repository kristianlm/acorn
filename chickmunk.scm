

(module chickmunk *
  (import chicken scheme foreign bind lolevel
          srfi-1 srfi-4
          data-structures)
  

#>
#include <chipmunk/chipmunk.h>

void cbSpaceEachPointerCallback(void *pointer, /*body,shape,contraint*/
                                C_word *data /*callback closure*/)
{
 C_word *ptr = C_alloc (C_SIZEOF_POINTER);
  C_word sp = C_mpointer (&ptr, pointer);
  C_word old = *data;
  C_save (sp);
  // our callback-wrapp returns the new closure (in case the old one
  // was moved by gc)
  *data = C_callback(*data, 1);
}
void forEachShape (cpSpace *space, C_word callback) {
 cpSpaceEachShape (space, cbSpaceEachPointerCallback, &callback);
}
void forEachBody (cpSpace *space, C_word callback) {
 cpSpaceEachBody (space, cbSpaceEachPointerCallback, &callback);
}
void forEachConstraint (cpSpace *space, C_word callback) {
 cpSpaceEachConstraint (space, cbSpaceEachPointerCallback, &callback);
}
<#


(bind-rename/pattern "^cp" "")
(bind-rename/pattern "make-cp" "make")
(bind-options default-renaming: "" )
(bind-include-path "./include")
(bind-include-path "./include/constraints/")
(bind-file "./include/chipmunk.h")

;; callback used by our C-function. It returns itself, thus, the
;; result of C_callback is the callback function itself -
;; this is useful because sometimes this callback-function
;; is moved by the GC! So the original callback would point
;; to the old location and be invalid.
(define (callback-wrapper proc)
  (let* ([self #f]
         [cbwrap (lambda (cp-pointer) ; coming from C-land
                   (proc cp-pointer) ; TODO: handle errors here
                                     ; (crashes otherwise)
                   self)])
    (set! self cbwrap)
    cbwrap))

(define (for-each/shape space callback) 
  ((foreign-safe-lambda void "forEachShape" (c-pointer "cpSpace") scheme-object)
   space (callback-wrapper callback)))

(define (for-each/body space callback)
  ((foreign-safe-lambda void "forEachBody" (c-pointer "cpSpace") scheme-object)
   space (callback-wrapper callback)))

(define (for-each/constraint space callback)
  ((foreign-safe-lambda void "forEachConstraint" (c-pointer "cpSpace") scheme-object)
   space (callback-wrapper callback)))

(define v make-vect)
(define vzero (make-vect 0 0))

(define CP_USE_DOUBLES (foreign-value "CP_USE_DOUBLES" int))
(define CP_SIZEOF_VECT (foreign-value "sizeof(struct cpVect)" int))

(define vect-locative->list
  (compose f32vector->list
          blob->f32vector/shared
          locative->object))


;; neat little bugger:
;; expand any macros within lst once
;; (expand ...) does this only on first form
;; useful if you want to expand macros once, twice etc (use nested
;; calls) and if expand* is over-kill. eval into your repl
#|(define (my-expand lst)
(if (list? lst) 
    (expand (map my-expand lst))
    lst))|#

;; like list-ref but returns #f instead of failing
;; and returns original item on non-lists if idx == 0
;; (list-ref-maybe '(mass a b c) 3) ==> c
;; (list-ref-maybe '(mass a b c) 4) ==> #f
;; (list-ref-maybe 'mass 0) ==> mass
;; (list-ref-maybe 'mass 2) ==> #f
(define-for-syntax (list-ref-maybe lst idx . default)
  (if (list? lst)  
      (and (> (length lst) idx) (list-ref lst idx))
      (and (= idx 0) lst)))

;; generate a lambda which accepts a subject (pointer) and new properties (alist)
(define-syntax (make-info-setter x r t)
  (let* ([spec (caddr x)]
         [setter-prefix (cadr x)])
    `(lambda (struct info)
       (map
        (lambda (info-tuple)
          (let ([prop (car info-tuple)]
                [new-value (cadr info-tuple)])
            (list prop
                  (case prop
                    ,@(append
                       (map
                        ;; spec-item comes from macro-call,
                        ;; defines field-name, optional
                        ;; converters and getter/setter proc
                        ;; (defaults to (conc setter-prefix field))
                        (lambda (spec-item)
                          (let* ([field (list-ref-maybe spec-item 0)] 
                                 [set-conv (list-ref-maybe spec-item 2)] 
                                 [setter (list-ref-maybe spec-item 4)]
                                 [setter-proc-name
                                  (or setter 
                                      (string->symbol (conc setter-prefix field)))]
                                 [setter-proc-call
                                  (if (string? setter-proc-name)
                                      ;; proc is string => use
                                      ;; it as error msg
                                      setter-proc-name
                                      (list setter-proc-name 'struct
                                            (if set-conv
                                                (list set-conv 'new-value)
                                                'new-value)))])
                            `((,field) ,setter-proc-call)))
                        spec)
                       '((else "unknown")))))))
        info))))

;; generate a lambda which accepts a subject (pointer) and returns all its
;; properties as an alist
(define-syntax (make-info-getter x r t)
  (let* ([spec (caddr x)]
         [getter-prefix (cadr x)])
    `(lambda (struct)
       (list ,@(map (lambda (item)
                      (let* ([field (list-ref-maybe item 0)]
                             [get-conv (list-ref-maybe item 1)] 
                             [getter (list-ref-maybe item 3)] 
                             [getter-proc-name (or getter 
                                                   (string->symbol (conc getter-prefix field)))]
                             [getter-proc-call (list getter-proc-name 'struct)])
                        `(list (quote ,field)
                               ;; call getter with body as parameter
                               ,(if get-conv
                                    `(,get-conv ,getter-proc-call)
                                    getter-proc-call))))
                    spec)))))

(define-syntax (define-info-supporters x r t)
  (let ([get-info-name (list-ref x 1)]
        [set-info-name (list-ref x 2)]
        [getter-prefix (list-ref x 3)]
        [setter-prefix (list-ref x 4)]
        [spec (list-ref x 5)])
    `(begin
       (define ,get-info-name (make-info-getter ,getter-prefix ,spec))
       (define ,set-info-name (make-info-setter ,setter-prefix ,spec)))))

(declare (hide loc->lis lis->loc))
(define loc->lis vect-locative->list)
(define (lis->loc pos-tuple)
  (v (car pos-tuple) (cadr pos-tuple)))


(define-info-supporters
  space-properties space-properties-set!
  space-get- space-set-
  (  (gravity loc->lis lis->loc)
     iterations
     damping 
     idle-speed-threshold 
     sleep-time-threshold
     collision-slop
     collision-bias
     collision-persistence
     enable-contact-graph
     user-data))

(define-info-supporters
  body-properties body-properties-set!
  body-get- body-set-
  (  (sleeping #f #f body-is-sleeping "not supported")
     (static   #f #f body-is-static "not supported")
     (rogue    #f #f body-is-rogue "not supported")
     (pos      loc->lis lis->loc)
     (vel      loc->lis lis->loc)
     mass
     moment
     angle
     ang-vel
     torque
     force
     vel-limit
     ang-vel-limit
     user-data))


(define (shape-get-type shape)
  (let ([type ((foreign-lambda* integer (((c-pointer "cpShape") shape))
                           "C_return(shape->klass->type);")
               shape)])
    (cdr (assq type `((,(foreign-value "CP_CIRCLE_SHAPE" int) . circle)
                      (,(foreign-value "CP_SEGMENT_SHAPE" int) . segment)
                      (,(foreign-value "CP_POLY_SHAPE" int) . poly)
                      (,(foreign-value "CP_NUM_SHAPES" int) . num-shapes))))))

(define (poly-shape-get-verts shape)
  (map (compose
        vect-locative->list
        (cut poly-shape-get-vert shape <>))
       (iota (poly-shape-get-num-verts shape))) )

(define (shape-info shape)
    (let* ([l vect-locative->list]
           [type (shape-get-type shape)]
           [shape-info-all
            (lambda ()
              `((type ,type)
                (sensor ,(shape-get-sensor shape))
                (elasicity ,(shape-get-elasticity shape))
                (friction ,(shape-get-friction shape))
                (surface-velocity ,(l (shape-get-surface-velocity shape)))
                (user-data ,(shape-get-user-data shape))
                (collision-type ,(shape-get-collision-type shape))
                (group ,(shape-get-group shape))
                (layers ,(sprintf "~B" (shape-get-layers shape)))))]
           [shape-info-poly
            (lambda ()
              `((vertices ,(poly-shape-get-verts shape))))]
           [shape-info-segment
            (lambda ()
              `())])
      (append (shape-info-all) (case type
                                 ([poly] (shape-info-poly))
                                 ([circle] '())
                                 ([segment] (shape-info-segment))))))
)
