(use chickmunk)


(if (not (fp= 0.5 (cp:moment-for-circle 1 0 1 cp:vzero)))
    (signal "Cannot calculate moment for circle.
Make sure your Chipmunk installation
is configured to use floats and not doubles.
Configure preprocessor with -DCP_USE_DOUBLES=0"))

(define space (cp:space-new))

(cp:space-set-iterations space 10)

;; cp:v == cp:make-vect
(cp:space-set-gravity space (cp:v 0 -100))

(define static-body (cp:space-get-static-body space))

(cp:segment-shape-new static-body
                   (cp:make-vect -320 -240)
                   (cp:make-vect -320 240)
                   0)

(define radius 15)
(define body (cp:space-add-body space
                                (cp:body-new 10 (cp:moment-for-circle 10 ;; mass
                                                                      0 ;; inner radius
                                                                      radius ;; outer radius
                                                                      (cp:v 0 0) ;; offset
                                                                      ))))

(cp:space-add-shape space (cp:circle-shape-new body radius cp:vzero))
(cp:body-set-vel body (cp:v 0 170))

(cp:space-step space (/ 1 60))

(let ([bodypos (cp:body-get-pos body)])
  ;; you should see body's position altered by gravity
  (print bodypos " @ " (cp:vect-x bodypos) ", " (cp:vect-y bodypos)))
