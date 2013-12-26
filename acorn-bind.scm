(use bind)

(begin-for-syntax
 (import chicken)
 (include "acorn-transformer.scm"))

;; hack! if we don't have this, we get:
;; Warning: reference to possibly unbound identifier `transformer',
;; even though it should only be referenced at compile-time
(define acorn-transformer (void))

(bind-rename/pattern "^cp" "")
(bind-rename/pattern "make-cp" "make")
(bind-options default-renaming: "" foreign-transformer: acorn-transformer)
(bind-include-path "./include")
(bind-include-path "./include/constraints/")
(bind-file "./include/chipmunk.h")


(define area-for-poly
  (foreign-lambda* float ((int numVerts)
                     (f32vector verts))
              "return(cpAreaForPoly(numVerts, (cpVect*)verts));"))

(define centroid-for-poly
  (lambda (verts)
    (let ((dest (make-f32vector 2)))
      ((foreign-safe-lambda* void ((f32vector destination)
                                   (int numVerts)
                                   (f32vector verts))
                             "
*((cpVect*)destination) = cpCentroidForPoly(numVerts, (cpVect*)verts);")
       dest
       (f32vector-length verts)
       verts)
      dest)))

(define CP_USE_DOUBLES (foreign-value "CP_USE_DOUBLES" int))
(define CP_SIZEOF_VECT (foreign-value "sizeof(struct cpVect)" int))

(define space-new
  (let ((%space-new space-new))
    (lambda ()
      (set-finalizer! (%space-new) (lambda (x) (space-free x))))))
