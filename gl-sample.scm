
(require-extension gl
                   glut
                   glu

                   srfi-4 ; for #f32( 1 2 3) 
                   lolevel ; (make-locative ...
                   chicken-syntax ; for cut,  #!optional etc
                   chickmunk
                   chickmunk-draw)

(load "/tmp/loop-repl.scm")
(begin
  (define *display-mode* (+ glut:DOUBLE glut:RGBA glut:DEPTH))
  (glut:InitDisplayMode *display-mode*)
  (glut:InitWindowSize 1280 800)
  (glut:CreateWindow "hello")

  (begin
    (define aspect (/ 800 1280))
    (define w 5)
    (define h (* aspect w))
    
    (define -w (- w))
    (define -h (- h))

    
    (gl:MatrixMode gl:PROJECTION)
    (gl:LoadIdentity)
    (gl:Frustum  -w  w
                 -h  h
                 5   30)
    
    (gl:MatrixMode gl:MODELVIEW))

  (gl:ClearColor 0 0 (/ (random 100) 100) 1)
  (gl:Clear (+ gl:COLOR_BUFFER_BIT))
  (gl:Color3f 1 1 1)
  (gl:EnableClientState gl:VERTEX_ARRAY)

  (define (gl:reset-camera)
    (gl:LoadIdentity)
    (gl:Translatef 0 0 -20))
  (gl:reset-camera)

  (define (draw-polygon points #!optional (type gl:POLYGON))
    (let ([vec (cond ((f32vector? points) points)
                     (else (list->f32vector points) ))])
      (gl:VertexPointer 3 gl:FLOAT 0 (make-locative vec))
      (gl:DrawArrays type 0 (/ (f32vector-length vec) 3))))

  (define (draw-line points)
    (draw-polygon points gl:LINES)))



(begin
  (define space (cpSpaceNew))
  (cpSpaceSetIterations space 10)
  (cpSpaceSetGravity space (cpv 0 -0.1)))

(define (draw-shapes)
  (cp:for-each/shape
   space
   (lambda (shape)
     (if #t
         (let* ((a (cpSegmentShape-a shape))
                [b (cpSegmentShape-b shape)]
                [body (cpShape-body shape)]
                [pos (cpBody-p body)])
           (gl:PushMatrix)
           (gl:Translatef (cpVect-x pos) (cpVect-y pos) 0)
                          ;   (print "body @ " (cpVect-x pos) "," (cpVect-y pos))
           (draw-line '(0 0 0 .5 .5 0))
           ;           (list (cpVect-x a) (cpVect-y a) 0
           ;      (cpVect-x b) (cpVect-y b) 0
           
           (gl:PopMatrix)
           (begin)
           ))
        )))




(define (game-loop)
 (begin
   (yield)
   (gl:reset-camera)
   (cpSpaceStep space (/ 1 60))
   (gl:Clear gl:COLOR_BUFFER_BIT)
   (ChipmunkDebugDrawShapes space)
;   (draw-shapes)
   (gl:Flush)
   (glut:SwapBuffers)))


(let ([count 0])
  (cp:for-each/body space
                    (lambda (body)
                      (set! count (add1 count))
                      (if (zero? (modulo  count 5))
                          (begin (cpBodyActivate body)
                                 (cpBodySetVel body (cpv 10 0)))))))
(cp:for-each/shape space
                   (lambda (shape)
                     (if (= 0 (random 10)) (cpShapeSetBody shape static-body))
                     (cpShapeSetElasticity shape 1)
                     (cpShapeSetFriction shape 0)))



(begin
  (gl:Enable gl:BLEND)                                
  (gl:BlendFunc gl:SRC_ALPHA gl:ONE_MINUS_SRC_ALPHA) 

  (gl:Hint gl:POINT_SMOOTH gl:NICEST)    
  (gl:Hint gl:LINE_SMOOTH gl:NICEST)     
  (gl:Hint gl:POLYGON_SMOOTH gl:NICEST)  

  (gl:Enable gl:POINT_SMOOTH)             
  (gl:Enable gl:LINE_SMOOTH)              
  (gl:Enable gl:POLYGON_SMOOTH))

(glut:TimerFunc 1 (lambda (dt) (game-loop)) 0)
(glut:DisplayFunc (lambda args (apply game-loop args)))
(glut:IdleFunc (lambda _ (glut:PostRedisplay)))
(fork (lambda ()
        (glut:MainLoop)))
(define static-body (cpSpaceGetStaticBody space))

(define *S* #f)

(let* ([radius 0.1]
       [body (cpSpaceAddBody space
                             (cpBodyNew 10 (cpMomentForCircle 10 0 radius cpvzero)))]
       [shape (cpCircleShapeNew body radius cpvzero)])
  (cpShapeSetElasticity shape 1)
  (cpShapeSetFriction shape 0.5)
  (cpSpaceAddShape space shape)

;  (cpBodySetVel (cpv 1 1))
  )
;(cpSpaceAddShape space (cpSegment))
(begin ; make walls
  (let* ((static-body (cpSpaceGetStaticBody space))
        [s 1.5]
        [-s (- s)]
        [cp (lambda (x1 y1 x2 y2)
              (cpSpaceAddShape space
                               (cpSegmentShapeNew static-body
                                                  (make-cpVect x1 y1)
                                                  (make-cpVect x2 y2)
                                                  0)))]
        ;(cpSet)
        )
    (cp -s -s
        -s  s)
    (cp -s -s
         s -s)
    (cp -s s
        s s)
    (cp s -s
        s s)))

(cpBodySetVel body (cpv 0 170))
(define B (cpShape-body *S*))
(define bodypos (%cpBodyGetPos body))
(print bodypos " @ " (cpVect-x bodypos) "," (cpVect-y bodypos))

(glut:KeyboardFunc (lambda (key s k)
                     (print "key: " key)
                     (cond [(eq? #\w key)
                            (cpBodySetVel B
                                          (cpvadd (cpv 0 0.1) (cpBodyGetVel B)))])))


(cpSpaceAddShape space (cpCircleShapeNew (cpSpaceGetStaticBody space) 15 (make-cpVect 12 13)))


(cp:for-each/body
 space
 (lambda (body)
   (print "body callback for " body " @ " (cpVect-y (cpBody-p body)))))

(cpSpaceStep space (/ 1 60))
