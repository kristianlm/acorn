/* Copyright (c) 2007 Scott Lembcke
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
 
/// @defgroup cpShape cpShape
/// The cpShape struct defines the shape of a rigid body.
/// @{

typedef struct cpShapeClass cpShapeClass;

/// Segment query info struct.
typedef struct cpSegmentQueryInfo {
	/// The shape that was hit, NULL if no collision occured.
	cpShape *shape;
	/// The normalized distance along the query segment in the range [0, 1].
	cpFloat t;
	/// The normal of the surface hit.
	cpVect n;
} cpSegmentQueryInfo;

/// @private
typedef enum cpShapeType{
	CP_CIRCLE_SHAPE,
	CP_SEGMENT_SHAPE,
	CP_POLY_SHAPE,
	CP_NUM_SHAPES
} cpShapeType;

typedef cpBB (*cpShapeCacheDataImpl)(cpShape *shape, cpVect p, cpVect rot);
typedef void (*cpShapeDestroyImpl)(cpShape *shape);
typedef cpBool (*cpShapePointQueryImpl)(cpShape *shape, cpVect p);
typedef void (*cpShapeSegmentQueryImpl)(cpShape *shape, cpVect a, cpVect b, cpSegmentQueryInfo *info);

/// @private
struct cpShapeClass {
	cpShapeType type;
	
	cpShapeCacheDataImpl cacheData;
	cpShapeDestroyImpl destroy;
	cpShapePointQueryImpl pointQuery;
	cpShapeSegmentQueryImpl segmentQuery;
};

/// Opaque collision shape struct.
struct cpShape {
  //	CP_PRIVATE(const cpShapeClass *klass); TODO: this may cause
  //	trouble. our bindings offer make-cpShape functions which would
  //	initialize only a portion of the fields. when we compile,
  //	however, we use the real struct for cpShape (this is only used
  //	during chicken-bind phase) so it shouldn't be too bad.
	
	/// The rigid body this collision shape is attached to.
	cpBody *body;

	/// The current bounding box of the shape.
	cpBB bb;
	
	/// Sensor flag.
	/// Sensor shapes call collision callbacks but don't produce collisions.
	cpBool sensor;
	
	/// Coefficient of restitution. (elasticity)
	cpFloat e;
	/// Coefficient of friction.
	cpFloat u;
	/// Surface velocity used when solving for friction.
	cpVect surface_v;

	/// User definable data pointer.
	/// Generally this points to your the game object class so you can access it
	/// when given a cpShape reference in a callback.
	cpDataPointer data;
	
	/// Collision type of this shape used when picking collision handlers.
	cpCollisionType collision_type;
	/// Group of this shape. Shapes in the same group don't collide.
	cpGroup group;
	// Layer bitmask for this shape. Shapes only collide if the bitwise and of their layers is non-zero.
	cpLayers layers;
	
	/* CP_PRIVATE(cpSpace *space); */
	
	/* CP_PRIVATE(cpShape *next); */
	/* CP_PRIVATE(cpShape *prev); */
	
	/* CP_PRIVATE(cpHashValue hashid); */
};

/// Destroy a shape.
void cpShapeDestroy(cpShape *shape);
/// Destroy and Free a shape.
void cpShapeFree(cpShape *shape);

/// Update, cache and return the bounding box of a shape based on the body it's attached to.
cpBB cpShapeCacheBB(cpShape *shape);
/// Update, cache and return the bounding box of a shape with an explicit transformation.
cpBB cpShapeUpdate(cpShape *shape, cpVect pos, cpVect rot);

/// Test if a point lies within a shape.
cpBool cpShapePointQuery(cpShape *shape, cpVect p);

/* #define CP_DefineShapeStructGetter(type, member, name) \ */
/* static inline type cpShapeGet##name(const cpShape *shape){return shape->member;} */

/* #define CP_DefineShapeStructSetter(type, member, name, activates) \ */
/* static inline void cpShapeSet##name(cpShape *shape, type value){ \ */
/* 	if(activates && shape->body) cpBodyActivate(shape->body); \ */
/* 	shape->member = value; \ */
/* } */

/* #define CP_DefineShapeStructSetter(type, member, name, activates) \ */;
//CP_DefineShapeStructGetter(type, member, name, activates) \ */;
/* CP_DefineShapeStructGetter(type, member, name) \ */
/* CP_DefineShapeStructSetter(type, member, name, activates) */

cpSpace* cpShapeGetSpace(const cpShape *shape);

cpBody* cpShapeGetBody(const cpShape *shape);
void    cpShapeSetBody(cpShape *shape, cpBody *body);

cpBB            cpShapeGetBB(const cpShape *shape);
void            cpShapeSetSensor(cpShape *shape, cpBool sensor);
cpBool          cpShapeGetSensor(const cpShape *shape);
void            cpShapeSetElasticity(cpShape *shape, cpFloat e);
cpFloat         cpShapeGetElasticity(const cpShape *shape);
void            cpShapeSetFriction(cpShape *shape, cpFloat u);
cpFloat         cpShapeGetFriction(const cpShape *shape);
void            cpShapeSetSurfaceVelocity(cpShape *shape, cpVect surface_v);
cpVect          cpShapeGetSurfaceVelocity(const cpShape *shape);
void            cpShapeSetUserData(cpShape *shape, cpDataPointer data);
cpDataPointer   cpShapeGetUserData(const cpShape *shape);
void            cpShapeSetCollisionType(cpShape *shape, cpCollisionType collision_type);
cpCollisionType cpShapeGetCollisionType(const cpShape *shape);
void            cpShapeSetGroup(cpShape *shape, cpGroup group);
cpGroup         cpShapeGetGroup(const cpShape *shape);
void            cpShapeSetLayers(cpShape *shape, cpLayers layers);
cpLayers        cpShapeGetLayers(const cpShape *shape);

/// When initializing a shape, it's hash value comes from a counter.
/// Because the hash value may affect iteration order, you can reset the shape ID counter
/// when recreating a space. This will make the simulation be deterministic.
void cpResetShapeIdCounter(void);

/// Perform a segment query against a shape. @c info must be a pointer to a valid cpSegmentQueryInfo structure.
cpBool cpShapeSegmentQuery(cpShape *shape, cpVect a, cpVect b, cpSegmentQueryInfo *info);

/// Get the hit point for a segment query.
static inline cpVect cpSegmentQueryHitPoint(const cpVect start, const cpVect end, const cpSegmentQueryInfo info)
{
	return cpvlerp(start, end, info.t);
}

/// Get the hit distance for a segment query.
static inline cpFloat cpSegmentQueryHitDist(const cpVect start, const cpVect end, const cpSegmentQueryInfo info)
{
	return cpvdist(start, end)*info.t;
}

/* #define CP_DeclareShapeGetter(struct, type, name) type struct##Get##name(const cpShape *shape) */

/// @}
/// @defgroup cpCircleShape cpCircleShape

/// @private
typedef struct cpCircleShape {
	cpShape shape;
	
	cpVect c, tc;
	cpFloat r;
} cpCircleShape;

/// Allocate a circle shape.
cpCircleShape* cpCircleShapeAlloc(void);
/// Initialize a circle shape.
cpCircleShape* cpCircleShapeInit(cpCircleShape *circle, cpBody *body, cpFloat radius, cpVect offset);
/// Allocate and initialize a circle shape.
cpShape* cpCircleShapeNew(cpBody *body, cpFloat radius, cpVect offset);

/* CP_DeclareShapeGetter(cpCircleShape, cpVect, Offset); */
/* CP_DeclareShapeGetter(cpCircleShape, cpFloat, Radius); */

/// @}
/// @defgroup cpSegmentShape cpSegmentShape

/// @private
typedef struct cpSegmentShape {
	cpShape shape;
	
	cpVect a, b, n;
	cpVect ta, tb, tn;
	cpFloat r;
	
	cpVect a_tangent, b_tangent;
} cpSegmentShape;

/// Allocate a segment shape.
cpSegmentShape* cpSegmentShapeAlloc(void);
/// Initialize a segment shape.
cpSegmentShape* cpSegmentShapeInit(cpSegmentShape *seg, cpBody *body, cpVect a, cpVect b, cpFloat radius);
/// Allocate and initialize a segment shape.
cpShape* cpSegmentShapeNew(cpBody *body, cpVect a, cpVect b, cpFloat radius);

void cpSegmentShapeSetNeighbors(cpShape *shape, cpVect prev, cpVect next);

/* CP_DeclareShapeGetter(cpSegmentShape, cpVect, A); */
/* CP_DeclareShapeGetter(cpSegmentShape, cpVect, B); */
/* CP_DeclareShapeGetter(cpSegmentShape, cpVect, Normal); */
/* CP_DeclareShapeGetter(cpSegmentShape, cpFloat, Radius); */

/// @}
