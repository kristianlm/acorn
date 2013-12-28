(use acorn test)

(define space
  (nodes->space `(space ((gravity (0 -9.81)))
                        (body ((pos (1 2)))
                              (circle (radius 1)))
                        (body ((pos (3 4)))
                              (segment (radius 1)
                                       (endpoints ((-1 -1) (1 1)))))
                        (body ((static 1))
                              (box (vertices ((-1 -1) (-1 0)
                                              ( 1 -1) ( 1 0))))))))

(test '(poly segment circle) (map shape-get-type (space-shapes space)))

(test (list (v 3 4) (v 1 2)) (map body-get-pos (space-bodies space)))

(space-for-each-body space
                     (lambda (body)
                       (body-for-each-shape body
                                            (lambda (owner shape)
                                              (test #t (equal? owner body))
                                              (test #t (equal? body (shape-get-body shape)))))))





