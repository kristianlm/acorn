(use srfi-69)
;;; shape properties helper functions

(define (shape-get-type shape)
  (let ([type ((foreign-lambda* integer (((c-pointer "cpShape") shape))
                           "C_return(shape->klass->type);")
               shape)])
    (cdr (assq type `((,(foreign-value "CP_CIRCLE_SHAPE" int) . circle)
                      (,(foreign-value "CP_SEGMENT_SHAPE" int) . segment)
                      (,(foreign-value "CP_POLY_SHAPE" int) . poly))))))



;; added property: density
;; this is a conveniency property added to all shapes
;; so that mass and intertia can be automatically calculated
;; on all bodies.
;; TODO: remove shapes from hash-table when space is freed
(declare (hide *space-densities*))
(define *space-densities* (make-hash-table))

(define (shape-set-density shape value)
  (hash-table-update!/default
   *space-densities* shape (lambda _ value) #f))

(define (shape-get-density shape)
  (hash-table-ref/default *space-densities* shape #f))
(define (poly-shape-get-vertices shape)
  (map (compose
        vect->list
        (cut poly-shape-get-vert shape <>))
       (iota (poly-shape-get-num-verts shape))) )

(define (poly-shape-set-vertices shape v)
  ;; ((1 2) (2 3)) ==> (1 2 2 3)
  (let ([vv (convex-hull (verts v))])
   ((foreign-lambda* void (((c-pointer "cpShape") poly)
                           (int num_verts)
                           (f32vector verts))
                     "cpPolyShapeSetVerts(poly, num_verts, (cpVect*)verts, cpvzero);")
    shape (fx/ (f32vector-length vv) 2) vv)))


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
                  "platform integer precision cannot hold layer of size " laynum)
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
                         (else l))))
         density))

    (define-info-supporters
      circle-shape-properties circle-shape-properties-set!
      circle-shape-get- circle-shape-set-
      (  (offset vect->list list->vect)
         radius))

    ;; TODO: add setters for size (width height) to make a box easily    
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

