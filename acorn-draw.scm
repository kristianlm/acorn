

(module acorn-draw *
  (import chicken scheme foreign bind)

#>
#include <chipmunk/chipmunk.h>
#include "ChipmunkDebugDraw.h"
<#

(begin-for-syntax
 (import chicken)
 (include "acorn-transformer.scm")
 (define acorn-draw#acorn-transformer acorn#acorn-transformer))

;; hack! same as in acorn-bind.scm
(define acorn-transformer (void))

;(bind-file "chipmunk.h")
(bind-options default-renaming: "" foreign-transformer: acorn-transformer)
;;acorn-draw#chipmunk-debug-draw-segment
(bind-rename/pattern "^chipmunk-debug-" "")
(bind-file "ChipmunkDebugDraw.h")

)
