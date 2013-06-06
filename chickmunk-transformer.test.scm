

(test-group
 "argument wrapper"
 (test '(f32vector v) (f32struct->f32vector '((struct "cpVect") v)))
 (test '(f32vector v) (f32struct->f32vector '((const (struct "cpVect")) v)))
 (test '((c-pointer (struct "cpVect")) v) (f32struct->f32vector '((c-pointer (struct "cpVect")) v)))
 (test '(f32vector v) (f32struct->f32vector '((struct "cpBB") v))))

(test-group
 "special struct wrapper"
 (test #t (and (f32struct? '(struct "cpVect")) #t))
 (test #t (and (f32struct? '(const (struct "cpVect"))) #t))
 (test #f (f32struct? '(c-pointer (struct "cpVect")))))
