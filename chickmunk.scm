

(module chickmunk *
(import chicken scheme foreign bind)
(use srfi-4 srfi-1 data-structures lolevel)

#>
#include <chipmunk/chipmunk.h>

// for declarations of cpCircleShapeSetRadius etc
#include <chipmunk/chipmunk_unsafe.h>
<#

(include "chickmunk-bind.scm")

;; TODO: redefine make-vect to allocate scheme-object, not malloc
;;(define v make-vect)
(define v (lambda (x y) (f32vector x y))  )

;; allow list of points, list of f32vectors and f32vectors directly to
;; be converted to verticies as used by chipmunk.
;; (verts 1 -1 2 -2 )
;; (verts 1 -1 2 -2 5)
;; (verts '(1 -1) '(2 -2) '(3 -3))
;; (verts '((1 -1) (2 -2) (3 -3) (4 -4)))
(define (verts . verts)
  (if (null? verts) (f32vector)
      (begin
        (if (list? (car verts))
            ;; verts is list of '(x y)s
            (begin
              (apply f32vector
                     (flatten
                      (map (lambda (pos) (list (car pos) (cadr pos)))
                           (if (list? (caar verts)) (car verts)
                               verts)))))
            ;; verts is flat
            (begin
              ;; even number of vertex coords
              (assert (= 0 (remainder (length verts) 2)))
              (apply f32vector verts))))))

(define vzero (v 0 0))

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

;; TODO: add optional compression (removing properties that = defaults)
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
(define v.x vect-x)
(define v.y vect-y)

;; TODO: find out which one is faster
;; (vect-x ...) casts f32vector to cpVect
;; (define (vect->list vect)
;;   (list (f32vector-ref vect 0)
;;         (f32vector-ref vect 1)))
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


;;; remove all objects of space
(define (space-remove-all space)
  (for-each (lambda (body)
              (for-each (cut space-remove-shape space <>) (body-shapes body))
              (for-each (cut space-remove-constraint space <>) (body-constraints body)))
            (cons (space-get-static-body space)
                  (space-bodies space))))


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

(include "chickmunk-shape-properties.scm")
(include "chickmunk-nodes.scm")
(include "chickmunk-callback.scm")

;; TODO: set-finalizer on space object to free it automatically

;; currently we only support 32-bit floats
;; make sure the chipmunk native library is
;; configured to use it.
(assert (fp= 0.5 (moment-for-circle 1 0 1 vzero))
        "Moment for circle incorrect.
Make sure your Chipmunk installation
is configured to use floats and not doubles.
Configure preprocessor with -DCP_USE_DOUBLES=0")


)
