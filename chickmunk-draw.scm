

(module chickmunk-draw *
  (import chicken scheme foreign bind)

#>
#include <chipmunk/chipmunk.h>
#include "ChipmunkDebugDraw.h"
<#

;(bind-file "chipmunk.h")
(bind-options default-renaming: "")
;;chickmunk-draw#chipmunk-debug-draw-segment
(bind-rename/pattern "^chipmunk-debug-" "")
(bind-file "ChipmunkDebugDraw.h")

)
