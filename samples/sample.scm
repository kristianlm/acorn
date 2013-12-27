(use acorn)

(define space
  (nodes->space `(space ()
                        (body
                         ()
                         (circle (radius 1))))))

;; give our world a little gravity
(space-set-gravity space (v 0 -1))

;; run our simulation for a while,
;; letting our ball fall
(do ((i 0 (add1 i)))
    ((> i 100))
  (space-step space (/ 1 120)))

;; y-coordinate of pos and vel should be altered by gravity
(pp (space->nodes space))
(space-free space)
