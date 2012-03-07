

(require-extension chickmunk)


(define space (cpSpaceNew))
(print "space=" space)

(cpSpaceSetIterations space 10)
(cpSpaceSetGravity space (cpv 0 -100))

                                        ;(cpSpaceAddShape space )

(define d (make-cpVect 0 0))
(%cpvadd d (make-cpVect 1 2) (cpv 3 4))
(print "vector sum: " (cpVect-x d))


(define static-body (cpSpaceGetStaticBody space))
(print "static-body = " static-body)
(cpSegmentShapeNew static-body
                   (make-cpVect -320 -240)
                   (make-cpVect -320 240)
                   0)
(define radius 15)
(define body (cpSpaceAddBody space
                             (cpBodyNew 10 (cpMomentForCircle 10 0 radius cpvzero))))
(cpSpaceAddShape space (cpCircleShapeNew body radius cpvzero))
(cpBodySetVel body (cpv 0 170))

(define bodypos (cpBodyGetPos body))
(print bodypos " @ " (cpVect-x bodypos) "," (cpVect-y bodypos))
