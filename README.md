  [Chicken Scheme]: http://call-cc.org/
  [Chipmunk]: http://chipmunk-physics.net/
  [chicken-bind]:http://wiki.call-cc.org/eggref/4/bind

# [Chicken Scheme] bindings for [Chipmunk]

Give your chicken some physics! This API currently follows the 
[original C-API](http://chipmunk-physics.net/documentation.php) closely, 
which thus is probably your best source for information.

Chickmunk should provide bindings to all C functions and thus 
all parts of Chipmunk (bodies, shapes, constraints)
should be accessible.
 
It also adds:
* properties: shape-properties, shape-properties-set!, body-properties etc
* nodes: space->nodes and nodes->space

Have a look at the examples for a quick introduction.

## Requirements

* [Chicken Scheme]
* [chicken-bind], version 1.0
* [Chipmunk 6][Chipmunk], configured with CP_USE_DOUBLES=0. I'm using version 6.0.3.

I couldn't figure out how to add `CP_USE_DOUBLES=0` to the preprocessor from the command line, so I did this:

```diff
diff --git a/CMakeLists.txt b/CMakeLists.txt
index ea9d0fd..6915b44 100644
--- a/CMakeLists.txt
+++ b/CMakeLists.txt
@@ -37 +37 @@ endif()
-set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -std=gnu99") # always use gnu99
+set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -std=gnu99 -lm -DCP_USE_DOUBLES=0") # always use gnu99
```
## Installing

```bash
$ git clone https://github.com/kristianlm/chickmunk
$ cd chickmunk
$ chicken-install # or try with sudo
```

## Nodes

Nodes provide a convenient way to add shapes and bodies to a space. These two are equivalent:

```scheme
(space-add space
           `((body ((mass 10))
                   (circle (radius 0.2)))))
```

```scheme
(let ()
  (define body (body-new 10 1))
  (define shape (circle-shape-new body 0.2 (v 0 0)))
  (space-add-body space body)
  (space-add-shape space shape))
```

## Examples

```scheme
(use chickmunk)
(pp (body-properties (body-new 1 1)))
  ===>
  ((sleeping 0)
   (static 0)
   (rogue 1)
   (pos (0.0 0.0))
   (vel (0.0 0.0))
   (mass 1.0)
   (moment 1.0)
   (angle 0.0)
   (ang-vel 0.0)
   (torque 0.0)
   (force (0.0 0.0))
   (vel-limit +inf)
   (ang-vel-limit +inf)
   (user-data #f))
```

```scheme
(use chickmunk)

(define space
  (nodes->space
    `(space ()
            (body ()
                  (circle (radius 0.1)))
            (body ((static 1))
                  (segment (endpoints ((-1 -1)
                                       ( 1 -1))))))))

;; give our world a little gravity
(space-set-gravity space (v 0 -1))

;; run our simulation for a while,
;; letting our ball fall onto the segment
(do ((i 0 (add1 i)))
    ((> i 1000))
  (space-step space (/ 1 120)))

;; dump entire scene-graph to screen as a tree
;; the circle should be on top of the segment (0,-0.9)
(pp (space->nodes space))
(space-free space)
```

## Todo's

* Add support for automatically calculate a body's mass and interia based on density and its shapes' area.
* Store constraints in (space->nodes ...)

## Troubleshooting

### Error: illegal foreign argument type `(struct cpBB)'

Make sure you have the latest [chicken-bind] version 1.0. Upgrade with `chicken-install bind`.
