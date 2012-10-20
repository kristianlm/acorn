;; eval this to do some repl experiments:
;; (use bind-adapters matchable)
;; (remove-all-cexp-adapters)
;; (add-adapter (lambda (x) (cpvect-adapter x)))

(import-for-syntax matchable bind-adapters chicken)

;; neat little trick: generate a f32vector from C
;; TODO: write in C for speed
(define-external (make_f32vector2d (float x) (float y)) scheme-object
  (f32vector x y))

;; custom transformer (foreign-lambda cpVect "foo" ...) => (foreign-lambda*
;; scheme-object ... (make_f32vector ...))
(begin-for-syntax
 ;; second adapter:
 ;; make any function that returns a cpVect return a f32vector instead
 (add-adapter
  (lambda (x)
    (match (strip-syntax x)
      (('define sfunc ('foreign-lambda* (struct "cpVect") argdefs body ...))
       `(define ,sfunc
          (foreign-safe-lambda* scheme-object ,argdefs
                                (stmt
                                 (= "cpVect _r" ,@body)
                                 (return ("make_f32vector2d" "_r.x" "_r.y"))))))
      (else #f))))
 ;; first adapter:
 ;; change any arguments of type cpVect or cpVect* into f32vector,
 ;; because these are binary compatible. they are cast to cpVect* in
 ;; the C-body.
 (add-adapter
  (lambda (x)
    (match (strip-syntax x)
      (('foreign-lambda* rtype argdefs body)
       (pp x)
       (let* ([arg-structnames (map (compose foreign-type-struct-name car) argdefs) ]
              [wrapped-cpVects (map (lambda (adef sname)
                                      (if (equal? sname "cpVect")
                                          `(f32vector ,(cadr adef))
                                          adef))
                                    argdefs arg-structnames)])

         (define (body-transformer x)
           (and (symbol? x)
                (let* ([type (foreign-variable-type x argdefs)]
                       [pointer? (foreign-type-pointer? type)])
                  (and (equal? (foreign-type-struct-name type) "cpVect")
                       (conc "(" (if pointer? "" "*")
                             "(cpVect*)"
                             x ")")))))

         (and (any (cut equal? <> "cpVect") arg-structnames )
              `(foreign-lambda* ,rtype ,wrapped-cpVects
                           ,(transform body body-transformer)))))

      (else #f))))
 )

(bind-rename/pattern "^cp" "")
(bind-rename/pattern "make-cp" "make")
(bind-options default-renaming: "" )
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
