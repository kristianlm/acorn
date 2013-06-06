

(module chickmunk-draw *
  (import chicken scheme foreign bind)

#>
#include <chipmunk/chipmunk.h>
#include "ChipmunkDebugDraw.h"
<#

(begin-for-syntax
 (import chicken)
 (include "chickmunk-transformer.scm")
 (define chickmunk-draw#chickmunk-transformer chickmunk#chickmunk-transformer))

;; hack! same as in chickmunk-bind.scm
(define chickmunk-transformer (void))

;(bind-file "chipmunk.h")
(bind-options default-renaming: "" foreign-transformer: chickmunk-transformer)
;;chickmunk-draw#chipmunk-debug-draw-segment
(bind-rename/pattern "^chipmunk-debug-" "")
(bind-file "ChipmunkDebugDraw.h")

)
