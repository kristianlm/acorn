

(module chickmunk *
  (import chicken scheme foreign bind lolevel
          srfi-1 srfi-4
          data-structures)
  

#>
#include <chipmunk/chipmunk.h>

void cbSpaceEachPointerCallback(void *pointer, /*body,shape,contraint*/
                                C_word *data /*callback closure*/)
{
 C_word *ptr = C_alloc (C_SIZEOF_POINTER);
  C_word sp = C_mpointer (&ptr, pointer);
  C_word old = *data;
  C_save (sp);
  // our callback-wrapp returns the new closure (in case the old one
  // was moved by gc)
  *data = C_callback(*data, 1);
}
void forEachShape (cpSpace *space, C_word callback) {
 cpSpaceEachShape (space, cbSpaceEachPointerCallback, &callback);
}
void forEachBody (cpSpace *space, C_word callback) {
 cpSpaceEachBody (space, cbSpaceEachPointerCallback, &callback);
}
void forEachConstraint (cpSpace *space, C_word callback) {
 cpSpaceEachConstraint (space, cbSpaceEachPointerCallback, &callback);
}
<#


(bind-rename/pattern "^cp" "")
(bind-rename/pattern "make-cp" "make")
(bind-options default-renaming: "" )
(bind-include-path "./include")
(bind-include-path "./include/constraints/")
(bind-file "./include/chipmunk.h")

;; callback used by our C-function. It returns itself, thus, the
;; result of C_callback is the callback function itself -
;; this is useful because sometimes this callback-function
;; is moved by the GC! So the original callback would point
;; to the old location and be invalid.
(define (callback-wrapper proc)
  (let* ([self #f]
         [cbwrap (lambda (cp-pointer) ; coming from C-land
                   (proc cp-pointer) ; TODO: handle errors here
                                     ; (crashes otherwise)
                   self)])
    (set! self cbwrap)
    cbwrap))

(define (for-each/shape space callback) 
  ((foreign-safe-lambda void "forEachShape" (c-pointer "cpSpace") scheme-object)
   space (callback-wrapper callback)))

(define (for-each/body space callback)
  ((foreign-safe-lambda void "forEachBody" (c-pointer "cpSpace") scheme-object)
   space (callback-wrapper callback)))

(define (for-each/constraint space callback)
  ((foreign-safe-lambda void "forEachConstraint" (c-pointer "cpSpace") scheme-object)
   space (callback-wrapper callback)))

(define v make-vect)
(define vzero (make-vect 0 0))

(define CP_USE_DOUBLES (foreign-value "CP_USE_DOUBLES" int))
(define CP_SIZEOF_VECT (foreign-value "sizeof(struct cpVect)" int))

(define vect-locative->list
  (compose f32vector->list
          blob->f32vector/shared
          locative->object))

(define (body-info body)
  (let ([l vect-locative->list])
    `((sleeping ,(body-is-sleeping body))
      (static ,(body-is-static body))
      (rogue ,(body-is-rogue body))
      (mass  ,(body-get-mass body))
      (moment ,(body-get-moment body))
      (pos ,(l (body-get-pos body)))
      (vel ,(l (body-get-vel body)))
      (force ,(l (body-get-force body)))
      (angle ,(body-get-angle body))
      (ang-vel ,(body-get-ang-vel body))
      (torque ,(body-get-torque body))
      (vel-limit ,(body-get-vel-limit body))
      (ang-vel-limit ,(body-get-ang-vel-limit body))
      (user-data ,(body-get-user-data body))
      (shapes (TODO)))))

;; sample usage:
;; (body-info-set! body `((mass 1)
;;                        (pos (1 1.2))
;;                        (vel (1.1 0.2)))
(define (body-info-set! body assocl)
  (let ([tuple->v (lambda (pos-tuple)
                    (v (car pos-tuple) (cadr pos-tuple)))])
    (map
     (lambda (tuple)
       (let ([prop (car tuple)]
             [value (cadr tuple)])
         (list prop
               (case prop
                 ([sleeping] "not supported")
                 ([static]  "not supprted")
                 ([mass] (body-set-mass body value))
                 ([moment] (body-set-moment body value))
                 ([pos] (body-set-pos body (tuple->v value)))
                 ([vel] (body-set-vel body (tuple->v value)))
                 ([force] (body-set-force body (tuple->v value)))
                 ([angle] (body-set-angle body value))
                 ([ang-vel] (body-set-ang-vel body value))
                 ([torque] (body-set-torque body value))
                 ([vel-limit] (body-set-vel-limit body value))
                 ([ang-vel-limit] (body-set-ang-vel-limit body value))
                 ([user-data] (body-set-user-data body value))
                 ([shapes] "not supported")
                 (else "unknown")))))
     assocl)))

(define (shape-get-type shape)
  (let ([type ((foreign-lambda* integer (((c-pointer "cpShape") shape))
                           "C_return(shape->klass->type);")
               shape)])
    (cdr (assq type `((,(foreign-value "CP_CIRCLE_SHAPE" int) . circle)
                      (,(foreign-value "CP_SEGMENT_SHAPE" int) . segment)
                      (,(foreign-value "CP_POLY_SHAPE" int) . poly)
                      (,(foreign-value "CP_NUM_SHAPES" int) . num-shapes))))))

(define (poly-shape-get-verts shape)
  (map (compose
        vect-locative->list
        (cut poly-shape-get-vert shape <>))
       (iota (poly-shape-get-num-verts shape))) )

(define (shape-info shape)
    (let* ([l vect-locative->list]
           [type (shape-get-type shape)]
           [shape-info-all
            (lambda ()
              `((type ,type)
                (sensor ,(shape-get-sensor shape))
                (elasicity ,(shape-get-elasticity shape))
                (friction ,(shape-get-friction shape))
                (surface-velocity ,(l (shape-get-surface-velocity shape)))
                (user-data ,(shape-get-user-data shape))
                (collision-type ,(shape-get-collision-type shape))
                (group ,(shape-get-group shape))
                (layers ,(sprintf "~B" (shape-get-layers shape)))))]
           [shape-info-poly
            (lambda ()
              `((vertices ,(poly-shape-get-verts shape))))]
           [shape-info-segment
            (lambda ()
              `())])
      (append (shape-info-all) (case type
                                 ([poly] (shape-info-poly))
                                 ([circle] '())
                                 ([segment] (shape-info-segment))))))
)
