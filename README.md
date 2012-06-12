  [Chicken Scheme]: http://call-cc.org/
  [Chipmunk]: http://chipmunk-physics.net/
  [chicken-bind]:(http://wiki.call-cc.org/eggref/4/bind)

# [Chicken Scheme] bindings for [Chipmunk Physics]

Give your chicken some physics! This API currently follows the 
[original C-API](http://chipmunk-physics.net/documentation.php) closely, 
which thus is probably your best source of information. It is in Alpha stage because:

* It's just a wrapper around C functions (Scheme should allow for a much easier API)
* Its [chicken-bind] dependency needs some love and care

Take a look at the examples for a quick introduction.

## Requirements

[Chipmunk] loves passing the `cpVect struct` by value, which the official 
[chicken-bind] does not support. 
My [patched version](https://github.com/kristianlm/chicken-bind)
supports this but the test coverage is questionable. You'll need my version in order to generate the wrappers for [Chipmunk].

## Example

See [sample.scm](/kristianlm/chickmunk/blob/master/sample.scm).

## Troubleshooting

### Error: illegal foreign argument type `(struct cpBB)'

Try installing the alternative chicken-bind version from my (kristianlm) github repo.