

(module chickmunk *
  (import chicken scheme foreign bind)
  

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
(bind-options default-renaming: "cp:" )
(bind-include-path "./include")
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

(define (cp:for-each/shape space callback) 
  ((foreign-safe-lambda void "forEachShape" (c-pointer "cpSpace") scheme-object)
   space (callback-wrapper callback)))

(define (cp:for-each/body space callback)
  ((foreign-safe-lambda void "forEachBody" (c-pointer "cpSpace") scheme-object)
   space (callback-wrapper callback)))

(define (cp:for-each/constraint space callback)
  ((foreign-safe-lambda void "forEachConstraint" (c-pointer "cpSpace") scheme-object)
   space (callback-wrapper callback)))

(define cp:v cp:make-vect)
(define cp:vzero (cp:make-vect 0 0))

(define cp:use-doubles (foreign-value "CP_USE_DOUBLES" int))
(define cp:sizeof-cpVect (foreign-value "sizeof(struct cpVect)" int))

)
