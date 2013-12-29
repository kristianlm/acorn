(use acorn srfi-1 extras test)


(define space
  (nodes->space `(space ()
                        (body
                         ()
                         (box (vertices ((-13 -13)
                                         (-13 -1)
                                         (-1 -13))))
                         (circle (radius 10)
                                 (offset (0 5)))
                         (circle (radius 10)
                                 (offset (12 -3)))))))

(test
 "point-query / raytrace"
 '((0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
   (0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
   (0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
   (0 0 0 1 1 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1)
   (0 0 0 1 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1)
   (0 0 0 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1)
   (0 0 0 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1)
   (0 0 0 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1)
   (0 0 0 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1)
   (0 0 0 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1)
   (0 0 0 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1)
   (0 0 0 1 1 0 0 0 0 0 0 1 1 1 1 1 1 1 2 2 1 1 1 1 1 1 1 1 1 1)
   (0 0 0 1 0 0 0 0 0 0 1 1 1 1 1 1 1 1 2 2 2 1 1 1 1 1 1 1 1 1)
   (0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 1 1 1 1 1 1 1)
   (0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 1 1 1 1 1 1 1)
   (0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 1 1 1 1 1 1)
   (0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 2 1 1 1 1 1)
   (0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 2 1 1 1 1 1)
   (0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 1 1 1 1 1)
   (0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 2 2 2 2 2 1 1 1 1 1)
   (0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 2 2 2 1 1 1 1 1)
   (0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 2 2 1 1 1 1 1)
   (0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 0 0 0 0)
   (0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 0 0 0 0)
   (0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 0 0 0 0)
   (0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 0 0 0 0 0)
   (0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0)
   (0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0)
   (0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0)
   (0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0))
 (map
  (lambda (scanline)
    (map (lambda (point)
           ;; space-point-query returns a list of shapes that
           ;; contain point at vec
           (length (space-point-query space point #xFF 0)))
         scanline))
  ;; construct a list of scanlines, each scanline contains a list of
  ;; vectors/points
  (map (lambda (y)
         (map  (lambda (x) (v x y))
               (iota 30 -15)))
       (iota 30 -15))))

(test "space-bb-query"
      '(poly circle)
      (map shape-get-type (space-bb-query space (bbnew -15 -15 0 0) #xff 0)))


(define (qs start end)
  (map (lambda (args) `(,(shape-get-type (car args)) ,@(cdr args)))
       (space-segment-query space start end #xff 0)))

(test "space-segment-query cirlce" '((circle 0.25 0.0 1.0)) (qs (v 0 20) (v 0 0)))
(test "space-segment-query poly" '((poly 1.0 -1.0 0.0)) (qs (v -20 -20) (v -13 -13)))

