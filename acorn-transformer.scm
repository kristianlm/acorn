;;; Helpers that transform foreign-lambda expressions from chicken-bind
;;; so that they can return cpVect etc which is frequently used in the API.
;;; note: loaded at compile-time!

(import bind-translator matchable chicken)
(import-for-syntax bind-translator matchable)

(define f32structs `(("cpVect" 2 f32vector)
                     ("cpBB"   4 f32vector)
                     ("cpSeqmentQueryInfo" (foreign-value int "sizeof(struct cpSeqmentQueryInfo)") u8vector)))

(define (f32struct-length struct)
  (car (or (alist-ref struct f32structs equal?)
           (error "invalid f32struct" struct))))

(define (f32struct? type)
  (match type
    [('struct sname) (member sname (map car f32structs))]
    [('const rest) (f32struct? rest)]
    [else #f]))

(define (struct-name type)
  (match type
    [('struct sname) sname]
    [('const x) (struct-name x)]
    [else #f]))

;; ((struct "cpVect") var1) => (f32vector var1)
(define (f32struct->f32vector as)
  (if (f32struct? (car as))
      `(f32vector ,(cadr as))
      (if (struct-name (car as))
          `((c-pointer ,(car as)) ,(cadr as))
          as)))

;; convert any foreign-lambda with a point2d struct return-type,
;; and make it return a 2-element f32vector instead.
(define (f32struct-ret-transformer x rename)
  (match x
    ;; return-type is a point2d, need to convert
    ((foreign-lambda* ('struct (? string? struct-name)) args body)
     ;; (print "match") ;; (pp x)
     ;; (print "=>")
     (let* ((argnames (map cadr args))
            ;; return-type -> void, add f32vector destination
            ;; argument, and cast to point2d.
            (lambda-with-destination
             (bind-foreign-lambda*
              `(,foreign-lambda*
                void                           ;; new return type
                ,(cons '(f32vector dest) args) ;; add destination arg
                (stmt
                 (= ,(conc "struct " struct-name " _r") ,body) ;; allocate, cast & assign
                 (= (deref ,(conc "((struct " struct-name "*)dest)")) _r)))
              rename))
            ;; allocate a f32vector and use it as desination
            (destination-wrapper
             `(lambda ,argnames
                (,(rename 'let) ((destination (make-f32vector ,(f32struct-length struct-name))))
                 (,lambda-with-destination destination ,@argnames)
                 destination)))
            )
       ;;(pp destination-wrapper)
       destination-wrapper))
    ;; ignore other return-types
    (else (bind-foreign-lambda* x rename))))

;; convert any arguments of type (struct "cpVect") to f32vectors,
;; and cast & dereference from C.
(begin
  (define (f32struct-arg-transformer x rename)
    (match x
      ;; return-type is a cpVect, need to convert
      ((foreign-lambda* rtype args body)

       (define (type varname)
         (any (lambda (spec)
                (and (eq? (cadr spec) varname)
                     (car spec))) args))

       ;; recursively look for variables which reference arguments of
       ;; type struct and cast from f32vector to struct point2d*.
       (define (dereference body)
         (if (list? body)
             (map dereference body)
             (if (and (symbol? body) (f32struct? (type body)))
                 `(deref ,(conc "((struct " (struct-name (type body)) "*)" body ")"))
                 (if (struct-name (type body))
                     `(deref ,body)
                     body))))

       (f32struct-ret-transformer
        `(,foreign-lambda* ,rtype
                           ,(map f32struct->f32vector args)
                           ,(dereference body))
        rename))))

  `(pp (f32struct-arg-transformer
       '(foreign-lambda*1969
         (struct "cpVect")
         (((const (struct "cpVect")) a0)
          ((const (struct "cpBB")) a1)
          ((c-pointer (struct "cpVect")) untouched)
          ((const (struct "cpSegmentQueryInfo")) a2))
         ("cpSegmentQueryHitPoint" a0 a1 a2 untouched))
       identity)))

(define acorn#acorn-transformer f32struct-arg-transformer)
