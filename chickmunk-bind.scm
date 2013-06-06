(use bind)

(begin-for-syntax
 (import chicken)
 (include "chickmunk-transformer.scm"))

;; hack! if we don't have this, we get:
;; Warning: reference to possibly unbound identifier `transformer',
;; even though it should only be referenced at compile-time
(define chickmunk-transformer (void))

(bind-rename/pattern "^cp" "")
(bind-rename/pattern "make-cp" "make")
(bind-options default-renaming: "" foreign-transformer: chickmunk-transformer)
(bind-include-path "./include")
(bind-include-path "./include/constraints/")
(bind-file "./include/chipmunk.h")


(define area-for-poly
  (foreign-lambda* float ((int numVerts)
                     (f32vector verts))
              "return(cpAreaForPoly(numVerts, (cpVect*)verts));"))

(define centroid-for-poly
  (foreign-safe-lambda* scheme-object ((int numVerts)
                          (f32vector verts))
                   "
cpVect pos = cpCentroidForPoly(numVerts, (cpVect*)verts);
return(make_f32vector2d(pos.x, pos.y));"))

(define CP_USE_DOUBLES (foreign-value "CP_USE_DOUBLES" int))
(define CP_SIZEOF_VECT (foreign-value "sizeof(struct cpVect)" int))
