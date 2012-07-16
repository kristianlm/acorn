
;;; Chickmunk component for adding bodies and shapes their shapes
;;; into a space using convenient tree-structured lists.

;;; Terminology is still being established. The idea is that a node is
;;; either a body or shape, with belonging properties. The properties
;;; are set as usual with body-properties-set!

;; remove optional header symbol
;; (strip-header 'body '(body ((pos (0 0)) ...)))
;; (strip-header 'body '(shape ((pos (0 0)) ...)))
;; (strip-header 'body '(((pos (0 0)) ...)))
;; (strip-header 'body '())
(declare (hide strip-header))
(define (strip-header header spec)
  (if (eq? (or (null? spec)
               (car spec))
           header)
        (cdr spec)
        spec))

;; add a single body to space
;; body-spec == <header-alist> '(body props [shape1] [shape2] ...)
;;            == <alist>        '(props [shape1] [shape2] ...)
;; props      == <alist>        '((sleeping 0) (pos (10 -10)) ...)
;; shape1/2.. == <alist>        '((type segment) ... )
(declare (hide space-add/body))
(define (space-add/body space body-spec)
  ;; remove body header if it's there
  ;; we only want alist
  ;; (cleanup-body-spec '(body ((mass 10)) (shapes (circle (radius 1)))))
  ;; (cleanup-body-spec '((mass 10) (id 12)))
  (define (cleanup-body-spec body-spec)
    (strip-header 'body body-spec))

  ;; (cleanup-shape-props '(circle (radius 1)))
  ;;      ==> ((type circle) (radius 1))
  ;; (cleanup-shape-props '((type segment) (radius 1)))
  (define (cleanup-shape-props shape-props)
    (if (symbol? (car shape-props))
        (cons (list 'type (car shape-props))
              (cdr shape-props))
        shape-props))


  (set! body-spec (cleanup-body-spec body-spec))
  (assert (list? (car body-spec)) "body-spec must be valid a-list")

  (define body-props (car body-spec))
  (define shapes-spec (cdr body-spec))
  (define static? (not (= 0 (car (or (alist-ref 'static body-props eq? '(0)))))))
  
  (define body (if static?
                   (space-get-static-body space)
                   (space-add-body space (body-new 1 1))))

  (if static? '()
      (body-properties-set! body body-props))

  (list body
        (map (lambda (shape-spec)
               (define shape-props (cleanup-shape-props shape-spec))
               (define new-shape-proc
                 (let ([shape-type (car (alist-ref 'type shape-props))])
                   (case shape-type
                     ([circle] (lambda () (circle-shape-new body 1 ; default radius 1
                                                       (v 0 0) ; default offset 0,0
                                                       )))
                     ([poly box] (lambda () (box-shape-new body 1 ; default width
                                                      1 ; default height
                                                      )))
                     ([segment] (lambda () (segment-shape-new body (v 0 0) ; default A
                                                         (v 0 1) ; default B
                                                         0))) ; default radius
                     (else (error "cannot create shape of type " shape-type)))))
          
               (define shape (new-shape-proc))
               (shape-properties-set! shape (alist-delete 'type shape-props))
               (space-add-shape space shape))
             shapes-spec)))

;; add one or more bodies to space
(define (space-add space graph)
  (if (eq? 'body (car graph))
      ;; add single body. return-type always list of bodies added
      (list (space-add/body space graph))
      ;; adding muliple bodies
      (map (cut space-add/body space <>)
           (strip-header 'bodies graph))))




;;; Creating a new space from nodes
(define (nodes->space nodes)
  (define space-props (car (strip-header 'space nodes)))
  (define spec (cdr (strip-header 'space nodes)))

  (define space (space-new))
  (space-properties-set! space space-props)
  (space-add space spec)
  
  space)

;;; Creating nodes from a space
;; TODO: add constraints
(define (space->nodes space)
  (define (give-header shape-properties)
    (let ([type (car (alist-ref 'type shape-properties))])
      `(,type ,@(alist-delete 'type shape-properties))))
  `(space
    ,(space-properties space)
    ,@(map (lambda (body)
             (cons 'body
                   (cons (body-properties body) 
                         (map (compose give-header shape-properties)
                              (body-shapes body)))))
           (cons (space-get-static-body space)
                 (space-bodies space)))))
