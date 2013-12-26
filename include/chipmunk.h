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

#ifndef CHIPMUNK_HEADER
#define CHIPMUNK_HEADER

#define CP_USE_DOUBLES=0

#ifndef CP_ALLOW_PRIVATE_ACCESS
	#define CP_ALLOW_PRIVATE_ACCESS 1
#endif



//#if CP_ALLOW_PRIVATE_ACCESS == 1
#define CP_PRIVATE(symbol) symbol
//#else
//#define CP_PRIVATE(symbol) symbol##_private
//#endif

//void cpMessage(const char *condition, const char *file, int line, int isError, int isHardError, const char *message, ...);
#ifdef NDEBUG
	#define	cpAssertWarn(condition, ...)
#else
//	#define cpAssertWarn(condition, ...) if(!(condition)) cpMessage(#condition, __FILE__, __LINE__, 0, 0, __VA_ARGS__)
#endif

#ifdef NDEBUG
	#define	cpAssertSoft(condition, ...)
#else
//	#define cpAssertSoft(condition, ...) if(!(condition)) cpMessage(#condition, __FILE__, __LINE__, 1, 0, __VA_ARGS__)
#endif

// Hard assertions are important and cheap to execute. They are not disabled by compiling as debug.
//#define cpAssertHard(condition, ...) if(!(condition)) cpMessage(#condition, __FILE__, __LINE__, 1, 1, __VA_ARGS__)


#include "chipmunk_types.h"
	
/// @defgroup misc Misc
/// @{

/// Allocated size for various Chipmunk buffers
#ifndef CP_BUFFER_BYTES
	#define CP_BUFFER_BYTES (32*1024)
#endif

#ifndef cpcalloc
	/// Chipmunk calloc() alias.
	#define cpcalloc calloc
#endif

#ifndef cprealloc
	/// Chipmunk realloc() alias.
	#define cprealloc realloc
#endif

#ifndef cpfree
	/// Chipmunk free() alias.
	#define cpfree free
#endif

typedef struct cpArray cpArray;
typedef struct cpHashSet cpHashSet;

typedef struct cpBody cpBody;
typedef struct cpShape cpShape;
typedef struct cpConstraint cpConstraint;

typedef struct cpCollisionHandler cpCollisionHandler;
typedef struct cpArbiter cpArbiter;

typedef struct cpSpace cpSpace;

#include "cpVect.h"
#include "cpBB.h"
//#include "cpSpatialIndex.h"

#include "cpBody.h"
#include "cpShape.h"
#include "cpPolyShape.h"

//#include "cpArbiter.h"	
 #include "constraints/cpConstraint.h"

#include "cpSpace.h"

/// Version string.
extern const char *cpVersionString;

/// Calculate the moment of inertia for a circle.
/// @c r1 and @c r2 are the inner and outer diameters. A solid circle has an inner diameter of 0.
cpFloat cpMomentForCircle(cpFloat m, cpFloat r1, cpFloat r2, cpVect offset);

/// Calculate area of a hollow circle.
/// @c r1 and @c r2 are the inner and outer diameters. A solid circle has an inner diameter of 0.
cpFloat cpAreaForCircle(cpFloat r1, cpFloat r2);

/// Calculate the moment of inertia for a line segment.
/// Beveling radius is not supported.
cpFloat cpMomentForSegment(cpFloat m, cpVect a, cpVect b);

/// Calculate the area of a fattened (capsule shaped) line segment.
cpFloat cpAreaForSegment(cpVect a, cpVect b, cpFloat r);

/// Calculate the moment of inertia for a solid polygon shape assuming it's center of gravity is at it's centroid. The offset is added to each vertex.
cpFloat cpMomentForPoly(cpFloat m, int numVerts, const cpVect *verts, cpVect offset);

/// Calculate the signed area of a polygon. A Clockwise winding gives positive area.
/// This is probably backwards from what you expect, but matches
/// Chipmunk's the winding for poly shapes.

// making custom version of this with float* instead of cpVect*
// (which casts, no compile warnings)
// cpFloat cpAreaForPoly(const int numVerts, const cpVect *verts);

/// Calculate the natural centroid of a polygon.
// custom signature:
// cpVect cpCentroidForPoly(const int numVerts, const cpVect *verts);

/// Center the polygon on the origin. (Subtracts the centroid of the polygon from each vertex)
void cpRecenterPoly(const int numVerts, cpVect *verts);

/// Calculate the moment of inertia for a solid box.
cpFloat cpMomentForBox(cpFloat m, cpFloat width, cpFloat height);

/// Calculate the moment of inertia for a solid box.
cpFloat cpMomentForBox2(cpFloat m, cpBB box);

// as of version 6.0.3, we can make convex hulls.
// this is rewritten in acorn.scm
int cpConvexHull(int count, cpVect *verts, cpVect *result, int *first, cpFloat tol);
/* //@} */

#endif
