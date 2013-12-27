(use acorn acorn-draw sdl-base)
(use gl miscmacros)

(define *stop* #f)
(define *thread* (make-thread #f))

(define (clear)
  (gl:ClearColor 0.1 0.1 0.1 1)
  (gl:Clear gl:COLOR_BUFFER_BIT)

  (gl:LoadIdentity))

(define (init)
  (sdl-gl-set-attribute SDL_GL_RED_SIZE 5)
  (sdl-gl-set-attribute SDL_GL_GREEN_SIZE 5)
  (sdl-gl-set-attribute SDL_GL_BLUE_SIZE 5)
  (sdl-gl-set-attribute SDL_GL_DEPTH_SIZE 16)
  (sdl-gl-set-attribute SDL_GL_DOUBLEBUFFER 1)
  
  (gl:Enable gl:VERTEX_ARRAY))

(define s (sdl-set-video-mode 480 200 0 (+ SDL_HWSURFACE SDL_OPENGL)))
(init)

(define space
  (nodes->space
   `(space ((gravity (0 -9.81)))
           (body ((pos (0 0))
                  (vel (1 1)))
                 (circle (radius .1)))
           (body ((pos (1 1))
                  (vel (-1 1)))
                 (circle (radius .1))))))

(pp (map shape-properties (space-shapes space)))
(pp (map body-properties (space-bodies space)))

(begin
  (thread-terminate! *thread*)
  (define *thread*
    (thread-start!
     (lambda ()
       (let loop ()
         (clear)
         (space-step space 1/120)
         (draw-shapes space)
         (sdl-gl-swap-buffers)
         (thread-sleep! 0.01)
         (if *stop* #f (loop)))))))

(thread-join! *thread*)
