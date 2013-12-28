(use acorn test)


(define space (space-new))
(define body (body-new 5 6))
(define circle (circle-shape-new body 3 (v 31 32)))
(define box (box-shape-new body 22 44))
(define segment (acorn#segment-shape-new body (v -1 -1) (v 1 1) 33))

(test-group
 "chipmunk vector opertations"

 (test-assert "vadd" (equal? (v 0.0 0.0)
                             (vadd (v -1.5 1.5)
                                   (v 1.5 -1.5))) )

 (test-assert "vnormalize" (equal? (v 0.0 1.0)
                                   (vnormalize (vadd (v 0.0 100)
                                                     (v 0.0 29)))) ))


(test-group
 "raw getters and setters"
 (test-group
  "body"
             (test 5.0 (body-get-mass body))
             (test 6.0 (acorn#body-get-moment body))

             (body-set-mass body 8)
             (test 8.0 (body-get-mass body))

             (body-set-pos body (v 99 98))
             (test '(99.0 98.0) (vect->list (body-get-pos body)))

             (body-set-angle body 13)
             (test 13.0 (body-get-angle body)))

 (test-group "shape"

             (shape-set-friction circle -12)
             (test "shape set-friction" -12.0 (shape-get-friction circle))

             (shape-set-layers circle #b11001100)
             (test "shape set-layers" #b11001100 (shape-get-layers circle)))

 (test-group "cirche shape"
                        
             (test "circle init-radius" 3.0 (circle-shape-get-radius circle))
             (test "circle init-offset" '(31.0 32.0) (vect->list (circle-shape-get-offset circle)))

             (circle-shape-set-radius circle 101)
             (test "circle set-radius" 101.0 (circle-shape-get-radius circle))

             (circle-shape-set-offset circle (v -31.0 -32.0))
             (test "circle set-offset" '(-31.0 -32.0) (vect->list (circle-shape-get-offset circle))))

 (test-group "segment shape"

             (test "segment init-radius" 33.0 (segment-shape-get-radius segment))

             (segment-shape-set-radius segment -12.0)
             (test "segment set-radius" -12.0 (segment-shape-get-radius segment))

             (segment-shape-set-endpoints segment '((-104 -102) (202 203)) )
             (test "segment set-engpoints"
                   '((-104.0 -102.0) (202.0 203.0)) (segment-shape-get-endpoints segment)))
 )

(define (alist-equal? master slave)
  (every (lambda (tuple)
           (let ([expected (cdr tuple)]
                 [actual (or (alist-ref (car tuple) slave)
                             (error (conc "missing property " (car tuple) " in " slave)))])
             (unless (equal? expected actual)
               (error (conc "property mismatch on '" (car tuple) ", expected " expected ", got " actual) ))))
         master))

(test-group
 "alist"

 (test-assert "alist-equal? unsorted"
              (alist-equal? '((a 2) (b (1 2)))
                            '((b (1 2)) (a 2) (c whatever))))
  
  (test-error "alist-equal? not"
              (alist-equal? '((a 2) (b 3))
                            '((b 3) (a 3000))))

  (test-error "alist-equal? missing"              
              (alist-equal? '((a 2) (b 3))
                            '((a 2)))))

(test-group
 "properties"

 (define circle (circle-shape-new body 14 (v 15 16)))
 
 (test-assert "circle shape init"
              (alist-equal? '((offset (15.0 16.0))
                              (radius 14.0))
                            (shape-properties circle)))
  
 (shape-properties-set! circle '( (radius 4)
                                  (offset (5 6))
                                  (friction 0.5)
                                  (elasticity 2)
                                  (collitions-type 0)))

 (test-assert "circle shape"
              ;; for now, we ignore certain properties here
              ;; like group and collision
              (alist-equal? '((type circle)
                              (elasticity 2.0)
                              (friction 0.5)
                              (offset (5.0 6.0))
                              (radius 4.0))
                            (shape-properties circle)))

 (define segment (segment-shape-new body (v 1 2) (v 3 4) 1))
 
 (test-assert "segment shape init"
              (alist-equal? '((endpoints ((1.0 2.0) (3.0 4.0)))
                              (radius 1.0))
                            (shape-properties segment)))
  
 (shape-properties-set! segment '( (radius 414)
                                  (endpoints ((12 23) (45 67)))
                                  (friction 0.5)
                                  (elasticity 2)
                                  (collitions-type 0)))

 (test-assert "segment shape"
              ;; for now, we ignore certain properties here
              ;; like group and collision
              (alist-equal? '((type segment)
                              (elasticity 2.0)
                              (friction 0.5)
                              (endpoints ((12.0 23.0) (45.0 67.0)))
                              (radius 414.0))
                            (shape-properties segment))))

;; TODO: add test for centroid-for-poly and friends
(test-group "for-each"    (include "shape-for-each.scm"))
(test-group "point-query" (include "point-query.scm"))
