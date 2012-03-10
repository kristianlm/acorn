

(module chickmunk-draw *
  (import chicken scheme foreign bind)

#>
#include <chipmunk/chipmunk.h>
#include "ChipmunkDebugDraw.h"
<#

;(bind-file "chipmunk.h")
(bind-file "ChipmunkDebugDraw.h")

)
