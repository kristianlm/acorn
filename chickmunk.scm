

(module chickmunk *

  (import chicken scheme foreign bind)
  

#>
#include <chipmunk/chipmunk.h>
<#

  (bind-file "chipmunk.h")
  (define cpv make-cpVect)
  (define cpvzero (cpv 0 0))



)
