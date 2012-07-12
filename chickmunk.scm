

(module chickmunk *
  (import chicken scheme foreign bind lolevel
          srfi-1 srfi-4
          data-structures)
  

#>
#include <chipmunk/chipmunk.h>

// for declarations of cpCircleShapeSetRadius etc
#include <chipmunk/chipmunk_unsafe.h>
<#

(bind-rename/pattern "^cp" "")
(bind-rename/pattern "make-cp" "make")
(bind-options default-renaming: "" )
(bind-include-path "./include")
(bind-include-path "./include/constraints/")
(bind-file "./include/chipmunk.h")

;; TODO: redefine make-vect to allocate scheme-object, not malloc
(define v make-vect)
(define vzero (make-vect 0 0))

(define CP_USE_DOUBLES (foreign-value "CP_USE_DOUBLES" int))
(define CP_SIZEOF_VECT (foreign-value "sizeof(struct cpVect)" int))

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
       (filter-map
        (lambda (info-tuple)
          (let ([prop (car info-tuple)]
                [new-value (cadr info-tuple)])
            (case prop
              ,@(append
                 (map
                  ;; spec-item comes from macro-call,
                  ;; defines field-name, optional
                  ;; converters and getter/setter proc
                  ;; (getter/setter defaults to (conc setter-prefix field))
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
                                `(list (quote ,field) ,setter-proc-name)
                                `(begin
                                   (,setter-proc-name struct
                                                      ,(if set-conv
                                                           (list set-conv 'new-value)
                                                           'new-value))
                                   (quote ,field)))])
                      `((,field) ,setter-proc-call)))
                  spec)
                 ;; return #f for unknown properties, will disappear through filter-map
                 '((else #f))))))
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

;; convenience functions for cpVect struct -> list
(define (vect->list vect)
  (list (vect-x vect) (vect-y vect)))

(define (list->vect pos-tuple)
  (v (car pos-tuple) (cadr pos-tuple)))

;; helper to create bb (easier to use than bbnew) 
;; (list->bb '((5 2) (0 1)))
(define (list->bb lst)
  ;; flatten
  (define l (case (length lst)
              ([4] lst)
              ([2] (list (caar lst) (cadar lst)
                         (caadr lst) (cadadr lst)))
              (else (error "list must be ((x1 y1) (x2 y2)) or (x1 y1 x2 y2)"))))
  (bbnew (min (first l) (third l))      ; left
         (min (second l) (fourth l))    ; bottom
         (max (first l) (third l))      ; right
         (max (second l) (fourth l))    ; top
         ))

(define-info-supporters
  space-properties space-properties-set!
  space-get- space-set-
  (  (gravity vect->list list->vect)
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
     (pos      vect->list list->vect)
     (vel      vect->list list->vect)
     mass
     moment
     angle
     ang-vel
     torque
     (force vect->list list->vect)
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

(define (poly-shape-get-vertices shape)
  (map (compose
        vect->list
        (cut poly-shape-get-vert shape <>))
       (iota (poly-shape-get-num-verts shape))) )

(define (poly-shape-set-vertices shape verts)
  ;; ((1 2) (2 3)) ==> (1 2 2 3)
  (define (flatten verts)
    (reverse
     (fold (lambda (e s)
             (cons (second e)
                   (cons (first e) s)))
           '() verts)))

  ((foreign-lambda* void (((c-pointer "cpShape") poly)
                     (int num_verts)
                     (f32vector verts))
               "cpPolyShapeSetVerts(poly, num_verts, (cpVect*)verts, cpvzero);")
   shape (length verts) (list->f32vector (flatten verts))))


(define (segment-shape-get-endpoints shape)
  (assert (eq? (shape-get-type shape) 'segment) "shape is not of type segment")
  (list (vect->list (segment-shape-get-a shape))
        (vect->list (segment-shape-get-b shape))))

;; convert from three arguments to two argument signature like the rest
(define segment-shape-set-endpoints
  (let ([foreign-set-endpoints segment-shape-set-endpoints])
    (lambda (shape new-value)
      (foreign-set-endpoints shape
                             (list->vect (car new-value))
                             (list->vect (cadr new-value))))))


;; layer helpers
;; (layers->mask 1 2 3 20 21)
(define (layers->mask . layers)
  (fold (lambda (laynum sum)
          (assert (fx<= laynum fixnum-precision)
                  (conc fixnum-precision "-bit integers cannot hold layer of size " laynum))
          (bitwise-ior sum (fxshl 1 (sub1 laynum))))
        0 layers))

;; (mask->layers 1572871)
(define (mask->layers mask)
  (let loop ([n 1]
             [mask mask]
             [res '()])
    (if (zero? mask)
        (reverse res)
        (if (fx= 1 (bitwise-and mask 1))
            (loop (add1 n) (fxshr mask 1) (cons n res))
            (loop (add1 n) (fxshr mask 1) res)))))

(define-values [shape-properties shape-properties-set!]
  ;; define hidden getter and setter procedures for each
  ;; shape type. then shape-properties and shape-properties-set!
  ;; will dispatch
  (let ()
    (define-info-supporters
      common-shape-properties common-shape-properties-set!
      shape-get- shape-set-
      (  (type #f #f #f "cannot change shape type")
         sensor
         elasticity
         friction
         (surface-velocity vect->list list->vect)
         user-data
         collision-type
         group
         (layers (lambda (l) (sprintf "~B" l))
                 (lambda (l) (cond
                         ((string? l) (string->number (conc "#b" l)))
                         ((list? l) (layers->mask l))
                         (else l))))))

    (define-info-supporters
      circle-shape-properties circle-shape-properties-set!
      circle-shape-get- circle-shape-set-
      (  (offset vect->list list->vect)
         radius))

    (define-info-supporters
      poly-shape-properties poly-shape-properties-set!
      poly-shape-get- poly-shape-set-
      (  vertices  ))

    (define-info-supporters
      segment-shape-properties segment-shape-properties-set!
      segment-shape-get- segment-shape-set-
      (  endpoints
         radius  ))

    (define (shape-properties shape)
      (append (common-shape-properties shape)
              (case (shape-get-type shape)
                ([circle] (circle-shape-properties shape))
                ([poly] (poly-shape-properties shape))
                ([segment] (segment-shape-properties shape))
                (else '((error "don't know this shape type"))))))

    (define (shape-properties-set! shape new-value)
      (append
       (common-shape-properties-set! shape new-value)
       (case (shape-get-type shape)
         ([circle] (circle-shape-properties-set! shape new-value))
         ([poly] (poly-shape-properties-set! shape new-value))
         ([segment] (segment-shape-properties-set! shape new-value))
         (else '((error "shape type unknown"))))))

    (values
     shape-properties
     shape-properties-set!)))


(include "chickmunk-callback.scm")

)
