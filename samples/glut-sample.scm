;;; Small testbed for Acorn
;;;
;;; Starts a glut main-loop in a different thread
;;; so the REPL is still available
;;;
;;; Before running this you should install glut-sandbox:
;;; cd glut-sandbox ; chicken-install

(use acorn
     acorn-draw gl glut glu
     glut-sandbox)

(define space (space-new))

(space-set-gravity space (v 0 -9.8))
(space-set-iterations space 6)

(for-each
 (lambda (endpoints) ;; make walls
   (space-add space
              `(body ((static 1))
                     (segment (endpoints ,endpoints)
                              (radius 0.1)))))
 '(((-1 -1) (-1  1))
   ((-1 -1) (1 -1))
   ((-1  1) (1  1))
   (( 1 -1) (1  1))))

;; mass & inertia currnetly defaults to 1 unfortunately
;; should default to area of attached shapes!
(space-add space
           `((body ()
                   (circle (radius 0.2)))
             (body ()
                   (circle (radius 0.3)
                           (friction 0.5)))))



;; list of selected bodies (select with right-click)
(define *body-sel* '())
;; camera zoom 
(define *scale* `(0.3 0.3))
(define *paused* #f)

(define cursor-pos1 '(0 0 0))
(define cursor-pos2 '(0 0 0))

(define (on-draw)

  (unless *paused*
    (space-step space (/ 1 120)))
  
  (gl:LoadIdentity)
  
  (apply gl:Scalef (list (car *scale*) (cadr *scale*) 1))
  (gl:Translatef 0 0 -1)

  (gl:Color4f 1 1 1 1)
  (draw-point cursor-pos1)
  (gl:Color4f 1 0 1 1)
  (draw-point cursor-pos2)

  (draw-shapes space)
  (draw-constraints space))

(define (on-mouse button down cursor-pos)

  (define (list->vect lst)
    (v (car lst) (cadr lst)))
  
  (print "on-mouse: " button " down: " down " @ " cursor-pos)
  (case button
    ([left]
     (set! cursor-pos1 cursor-pos)
     (for-each (cut body-set-pos <> (list->vect cursor-pos)) *body-sel*))
    ([right]                            ; select a body
     (set! cursor-pos2 cursor-pos)
     (define shapes (acorn#space-point-query space (list->vect cursor-pos) #xFF 0))
     (set! *body-sel* (map shape-get-body shapes)))
    ([wheel-down] (set! *scale* (map (cut * <> 0.9) *scale*)))
    ([wheel-up] (set! *scale* (map (cut / <> 0.9) *scale*))))
  
  (set! cursor-pos1-vect (v (car cursor-pos1)
                            (cadr cursor-pos1))))

(glut:KeyboardFunc
 (lambda (char dunno dunno2)
   (case char
     ([#\space] (set! *paused* (not *paused*))))))

(set-on-draw (lambda () (on-draw)))
(set-on-mouse (lambda args (apply on-mouse args)))

(define thread (glut-sandbox-start))
;; acorn-draw requires client-state to be enabled
;; must be set after glut main-loop starts
(gl:EnableClientState gl:VERTEX_ARRAY)

(thread-join! thread)

