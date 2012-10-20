

;; making convex hull from vertices
;; (applied automatically when adding from nodes/properties)

(define convex-hull
  (let ([foreign-convex-hull convex-hull])
    (lambda (verts)
      (let* ([r (make-f32vector (f32vector-length verts))]
             [new-length
              (foreign-convex-hull (fx/ (f32vector-length verts) 2) ;; numVerts
                                   verts r
                                   #f 0.0)])
        (subf32vector r 0 (fx* 2 new-length))))))

;; centroids

(define (poly-shape-get-centroid poly)
  (assert (eq? 'poly (shape-get-type poly)))
  (centroid-for-poly (poly-shape-get-num-verts poly)
                     (apply f32vector (flatten (poly-shape-get-vertices poly)))))

(define (circle-shape-get-centroid circle)
  (assert (eq? 'circle (shape-get-type circle)))
  (circle-shape-get-offset circle))

(define (segment-shape-get-centroid segment)
  (vlerp (segment-shape-get-a segment)
         (segment-shape-get-b segment)
         0.5))

(define (shape-get-centroid shape)
  ((case (shape-get-type shape)
     ([poly] poly-shape-get-centroid)
     ([circle] circle-shape-get-centroid)
     ([segment] segment-shape-get-centroid)
     (else (error "shape-get-centroid: unknown type" (shape-get-type shape)))) shape))

;; TODO: this should probably be rewritted in C for speed
(define (body-get-centroid body)
  (v* (fold (lambda (shape r)
              (vadd r (shape-get-centroid shape)))
            (v 0 0)
            (body-shapes body))
      (/ 1.0 (length (body-shapes body)))))



;; *** translate
(define (poly-shape-translate shape vect)
  (assert (eq? 'poly (shape-get-type shape)))
  (poly-shape-set-vertices shape
                           (map (lambda (pos)
                                  ;; todo: make verts support list of f32vectors
                                  (vect->list (vadd (apply v pos) vect)))
                                (poly-shape-get-vertices shape))))

(define (circle-shape-translate shape vect)
  (assert (eq? 'circle (shape-get-type shape)))
  (circle-shape-set-offset shape (vadd vect
                                       (circle-shape-get-offset shape))))

(define (segment-shape-translate shape vect)
  (assert (eq? 'segment (shape-get-type shape)))
  ;; TODO (segment-shape-set-endpoints)
  )

(define (shape-translate shape vect)
  ((case (shape-get-type shape)
     ((poly) poly-shape-translate)
     ((circle) circle-shape-translate)
     ((segment) segment-shape-translate)) shape vect))


;; *** recenter

(define (recenter-body body)
  (let ([cog (body-get-centroid body)])
    (body-set-pos body (vadd (body-get-pos body)
                             cog))
    (for-each (lambda (shape)
                (shape-translate shape (vneg cog)))
              (body-shapes body))))


;; *** area

(define shape-get-area
  (let ()
    (define (circle-shape-get-area circle)
      (assert (eq? 'circle (shape-get-type circle)))
      (area-for-circle 0 (circle-shape-get-radius circle)))

    (define (poly-shape-get-area poly)
      (assert (eq? 'poly (shape-get-type poly)))
      (area-for-poly (poly-shape-get-num-verts poly)
                     (apply f32vector (flatten (poly-shape-get-vertices poly)))))

    (define (segment-shape-get-area segment)
      (assert (eq? 'segment (shape-get-type segment)))
      (area-for-segment (segment-shape-get-a segment)
                        (segment-shape-get-b segment)
                        (segment-shape-get-radius segment)))

    (lambda (shape)
      ((case (shape-get-type shape)
         ((poly) poly-shape-get-area)
         ((circle) circle-shape-get-area)
         ((segment) segment-shape-get-area)) shape))))


(define (shape-get-mass shape #!optional (default-density #f))
  (let ([density (or (shape-get-density shape) default-density)])
    (and density (* density (shape-get-area shape)))))

(define (body-get-mass-from-density body #!optional (default-density #f))
  (let ([masses (map (cut shape-get-mass <> default-density) (body-shapes body))])
    (and (every identity masses) (fold + 0 masses))))

;; *** MoI

;; getting moments from shapes are always based on their densities
(define shape-get-moment
  (let ()
    (define (circle-shape-get-moment circle mass)
      (moment-for-circle mass 0
                         (circle-shape-get-radius circle)
                         (circle-shape-get-offset circle)))

    (define (poly-shape-get-moment poly mass)
      (assert (eq? 'poly (shape-get-type poly)))
      (let ([verts (apply f32vector (flatten (poly-shape-get-vertices poly)))])
        (moment-for-poly mass (fx/ (f32vector-length verts) 2)
                         verts (v 0 0) )))

    (define (segment-shape-get-moment segment mass)
      (assert (eq? 'segment (shape-get-type segment)))
      (moment-for-segment mass
                          (segment-shape-get-a segment)
                          (segment-shape-get-b segment)))

    (lambda (shape mass #!optional (density #f))
      (let ([mass (or mass (shape-get-mass shape density))])
        (and mass
            ((case (shape-get-type shape)
               ((poly) poly-shape-get-moment)
               ((circle) circle-shape-get-moment)
               ((segment) segment-shape-get-moment)) shape mass))))))


(define (body-get-moment-from-density body default-density)
  (let ([moments (map (cut shape-get-moment <> #f default-density) (body-shapes body))])
    (and (every identity moments) (fold + 0 moments))))


;; default-density will take affect if density for shape isn't known
;; (shape-get-density shape) => #f. default-density can also be #f
(define (body-calibrate body default-density)
  (recenter-body body)
  (let ([mass (body-get-mass-from-density body default-density)]
        [moment (body-get-moment-from-density body default-density)])
    ;; mass & moment could be #f. if so, ignore
    (and mass (body-set-mass body mass))
    (and moment (body-set-moment body moment))))

(define (space-calibrate space default-density)
  (for-each (cut body-calibrate <> default-density) (space-bodies space)))
