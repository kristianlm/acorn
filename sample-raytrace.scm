(use acorn srfi-1 extras)


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


(pp
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

(space-free space)
