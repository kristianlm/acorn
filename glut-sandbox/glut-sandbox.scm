(module glut-sandbox *

(import scheme chicken)
(use gl glut glu
     srfi-18 srfi-1 srfi-4
     extras ports lolevel)

(declare (hide on-mouse on-draw))
(define (on-mouse . args) #f)
(define (on-draw . args) #f)

(define (get-width)
  (glut:Get glut:WINDOW_WIDTH))
(define (get-height)
  (glut:Get glut:WINDOW_HEIGHT))

(define (resize)
  (gl:MatrixMode gl:PROJECTION)
  (gl:LoadIdentity)
  (let* ([z-near 1]
         [z-far 2]
         [aspect (/ (get-width) (get-height))]
         [h (* (tan 0.8) z-near)] ; 45deg ~ 0.8 rad
         [w (* aspect h)])
    (gl:Frustum (- w) w
                (- h) h
                z-near z-far))
  (gl:MatrixMode gl:MODELVIEW)
  (gl:Viewport 0 0 (get-width) (get-height)))


(define glut-sandbox-thread #f)

(define (set-on-draw proc)
  (set! on-draw proc))
(define (set-on-mouse proc)
  (set! on-mouse proc))

(define (glut-sandbox-start)

  (glut:InitDisplayMode (+ glut:DOUBLE glut:RGBA  glut:DEPTH))
  (glut:InitWindowSize 400 300)
  (glut:CreateWindow "GLUT Sandbox")

  (glut:DisplayFunc (lambda _
                      (gl:Clear gl:COLOR_BUFFER_BIT)
                      (on-draw)
                      (glut:SwapBuffers)))
  (glut:IdleFunc (lambda _
                   (thread-sleep! 0.01)
                   (glut:PostRedisplay)))

  (glut:ReshapeFunc (lambda (w h)
                      (resize)))

  (glut:MouseFunc
   (lambda (b s x y)
     (define down? (case s ([0] #t)
                         ([1] #f)
                         (else (error "glut sent unexpected state" s))))
     (define button (case b
                      ([0] 'left)
                      ([1] 'middle)
                      ([2] 'right)
                      ([3] 'wheel-up)
                      ([4] 'wheel-down)))
       (on-mouse button down? (screen->world x y 0))))
  
  (gl:ClearColor .1 .2 .2 1)

  (set! glut-sandbox-thread
        (thread-start!
         (lambda ()
           (let ([last-exn #f])
             (let loop ()
               (handle-exceptions exn
                 (begin
                   (let ([exn-str (with-output-to-string
                                    (lambda () (print-error-message exn)))])
                     ;; don't print error is it's the same as the last
                     ;; so we don't get exn-floods
                     (if (not (equal? last-exn exn-str))
                         (begin
                           (print-error-message exn)
                           ;; don't (print-call-chain .. because it
                           ;; messes up swank output
                           (pp (drop-right (get-call-chain) 2))
                           (set! last-exn exn-str))))
                   (thread-sleep! 1)
                   #f)
                 (glut:MainLoop))
               (loop)))))))

(define (draw-primitive points #!optional (type gl:POLYGON))
    (let ([vec (cond ((f32vector? points) points)
                     (else (list->f32vector points) ))])
      (gl:VertexPointer 3 gl:FLOAT 0 (make-locative vec))
      (gl:DrawArrays type 0 (/ (f32vector-length vec) 3))))

(define (draw-line points)
    (draw-primitive points gl:LINES))

(define (draw-point point)
  (draw-primitive point gl:POINTS))

;; TODO make a world->screen function at some point
(define (screen->world x y z)
  (define modelview-matrix (make-f64vector 16))
  (define projection-matrix (make-f64vector 16))
  (define viewport (make-s32vector 4))
  (gl#gl:GetDoublev gl:MODELVIEW_MATRIX modelview-matrix)
  (gl#gl:GetDoublev gl:PROJECTION_MATRIX projection-matrix)
  (gl#gl:GetIntegerv gl:VIEWPORT viewport)

  (define dest1 (make-f64vector 1))
  (define dest2 (make-f64vector 1))
  (define dest3 (make-f64vector 1))

  (glu#glu:UnProject x (- (s32vector-ref viewport 3) y) z
                     modelview-matrix projection-matrix viewport dest1 dest2 dest3)
  (list (f64vector-ref dest1 0)
        (f64vector-ref dest2 0)
        (f64vector-ref dest3 0)))


) ;; end module


