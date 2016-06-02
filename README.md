  [Chicken Scheme]: http://call-cc.org/
  [Chipmunk]: http://chipmunk-physics.net/
  [chicken-bind]:http://wiki.call-cc.org/eggref/4/bind



# Obsolete

Unfortunately, I don't have time to maintain this. The good news is that there a better solutions out there! I recommend that you check out [chicken-physics](https://github.com/pluizer/chicken-physics) and its dependency [chicken-chipmunk](https://github.com/pluizer/chicken-chipmunk) instead! Both of these are more feature-complete and "production ready". And they use the same underlying C-library (chipmunk).

I'm leaving the rest of this Readme.md out for reference.


# [Chicken Scheme] bindings for [Chipmunk]

Give your chicken some physics! This API currently follows the 
[original C-API](http://chipmunk-physics.net/documentation.php) closely, 
which thus is probably your best source for information.

This is an alpha-release, however, Acorn provides bindings to most C
functions of Chipmunk. Bodies, shapes and constraints should be
available.

There is still much room for improvement and contributions are
welcome.
 
Acorn adds to Chipmunk:
* properties: shape-properties, shape-properties-set!, body-properties etc
* nodes: space->nodes and nodes->space

Have a look at the examples for a quick introduction.

## Requirements

* [Chicken Scheme]
* Newest version of [chicken-bind](http://wiki.call-cc.org/eggref/4/bind)
  Because we're using `chicken-bind`'s adapter feature. Do
  `chicken-install -s bind` to reinstall.

The sources of Chipmunk 6.2.1 is embedded in the egg for convenience.
If you want to build against a different version, see `acorn.setup`.

## Installing

```bash
$ git clone https://github.com/kristianlm/acorn
$ cd acorn
$ chicken-install -s # or try with sudo
```

## Nodes

Nodes provide a convenient way to add shapes and bodies to a space. These two are equivalent:

```scheme
(use acorn)
(space-add space
           `((body ((mass 10))
                   (circle (radius 0.2)
                           (friction 0.5))))
```

```scheme
(let ()
  (define body (body-new 10 1))
  (define shape (circle-shape-new body 0.2 (v 0 0)))
  (shape-set-friction shape 0.5 )
  (space-add-body space body)
  (space-add-shape space shape))
```

## Examples

```scheme
(use acorn)
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
(use acorn)

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

See todo.org

## Troubleshooting

### Error: illegal foreign argument type `(struct cpBB)'

Make sure you have the latest [chicken-bind] version 1.0. Upgrade with `chicken-install bind`.
