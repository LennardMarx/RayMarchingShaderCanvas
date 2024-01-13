#version 410 core

uniform int u_Time;               // Time in ms.
float gTime = u_Time/1000000.0f;  // Time in s.

uniform float u_Resolution[2];
vec2 gResolution = vec2(u_Resolution[0], u_Resolution[1]);

uniform float u_CamPos[3];
vec3 gCamPos = vec3(u_CamPos[0], u_CamPos[1], u_CamPos[2]);

// uniform float u_CamRot[3];
// vec3 gCamRot = vec3(u_CamRot[0], u_CamRot[1], u_CamRot[2]);
uniform float u_MouseDelta[2];
vec2 gMouseDelta = vec2(u_MouseDelta[0], u_MouseDelta[1]);


in vec3 v_vertexPositions;

out vec4 color;


float sdBoxFrame( vec3 p, vec3 b, float e )
{
       p = abs(p  )-b;
  vec3 q = abs(p+e)-e;
  return min(min(
      length(max(vec3(p.x,q.y,q.z),0.0))+min(max(p.x,max(q.y,q.z)),0.0),
      length(max(vec3(q.x,p.y,q.z),0.0))+min(max(q.x,max(p.y,q.z)),0.0)),
      length(max(vec3(q.x,q.y,p.z),0.0))+min(max(q.x,max(q.y,p.z)),0.0));
}


// Cellular noise ("Worley noise") in 2D in GLSL.
// Copyright (c) Stefan Gustavson 2011-04-19. All rights reserved.
// This code is released under the conditions of the MIT license.
// See LICENSE file for details.
// https://github.com/stegu/webgl-noise

// Modulo 289 without a division (only multiplications)
vec2 mod289(vec2 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 mod289(vec4 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

// Modulo 7 without a division
vec4 mod7(vec4 x) {
  return x - floor(x * (1.0 / 7.0)) * 7.0;
}

// Permutation polynomial: (34x^2 + 6x) mod 289
vec4 permute(vec4 x) {
  return mod289((34.0 * x + 10.0) * x);
}

// Cellular noise, returning F1 and F2 in a vec2.
// Speeded up by using 2x2 search window instead of 3x3,
// at the expense of some strong pattern artifacts.
// F2 is often wrong and has sharp discontinuities.
// If you need a smooth F2, use the slower 3x3 version.
// F1 is sometimes wrong, too, but OK for most purposes.
vec2 cellular2x2(vec2 P) {
#define K 0.142857142857 // 1/7
#define K2 0.0714285714285 // K/2
#define jitter 0.8 // jitter 1.0 makes F1 wrong more often
	vec2 Pi = mod289(floor(P));
 	vec2 Pf = fract(P);
	vec4 Pfx = Pf.x + vec4(-0.5, -1.5, -0.5, -1.5);
	vec4 Pfy = Pf.y + vec4(-0.5, -0.5, -1.5, -1.5);
	vec4 p = permute(Pi.x + vec4(0.0, 1.0, 0.0, 1.0));
	p = permute(p + Pi.y + vec4(0.0, 0.0, 1.0, 1.0));
	vec4 ox = mod7(p)*K+K2;
	vec4 oy = mod7(floor(p*K))*K+K2;
	vec4 dx = Pfx + jitter*ox;
	vec4 dy = Pfy + jitter*oy;
	vec4 d = dx * dx + dy * dy; // d11, d12, d21 and d22, squared
	// Sort out the two smallest distances
#if 0
	// Cheat and pick only F1
	d.xy = min(d.xy, d.zw);
	d.x = min(d.x, d.y);
	return vec2(sqrt(d.x)); // F1 duplicated, F2 not computed
#else
	// Do it right and find both F1 and F2
	d.xy = (d.x < d.y) ? d.xy : d.yx; // Swap if smaller
	d.xz = (d.x < d.z) ? d.xz : d.zx;
	d.xw = (d.x < d.w) ? d.xw : d.wx;
	d.y = min(d.y, d.z);
	d.y = min(d.y, d.w);
	return sqrt(d.xy);
#endif
}

// Description : Array and textureless GLSL 2D simplex noise function.
//      Author : Ian McEwan, Ashima Arts.
//  Maintainer : stegu
//     Lastmod : 20110822 (ijm)
//     License : Copyright (C) 2011 Ashima Arts. All rights reserved.
//               Distributed under the MIT License. See LICENSE file.
//               https://github.com/ashima/webgl-noise
//               https://github.com/stegu/webgl-noise
// 

vec3 mod289(vec3 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

// vec2 mod289(vec2 x) {
//   return x - floor(x * (1.0 / 289.0)) * 289.0;
// }

vec3 permute(vec3 x) {
  return mod289(((x*34.0)+10.0)*x);
}

float snoise(vec2 v)
  {
  const vec4 C = vec4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
                      0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
                     -0.577350269189626,  // -1.0 + 2.0 * C.x
                      0.024390243902439); // 1.0 / 41.0
// First corner
  vec2 i  = floor(v + dot(v, C.yy) );
  vec2 x0 = v -   i + dot(i, C.xx);

// Other corners
  vec2 i1;
  //i1.x = step( x0.y, x0.x ); // x0.x > x0.y ? 1.0 : 0.0
  //i1.y = 1.0 - i1.x;
  i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
  // x0 = x0 - 0.0 + 0.0 * C.xx ;
  // x1 = x0 - i1 + 1.0 * C.xx ;
  // x2 = x0 - 1.0 + 2.0 * C.xx ;
  vec4 x12 = x0.xyxy + C.xxzz;
  x12.xy -= i1;

// Permutations
  i = mod289(i); // Avoid truncation effects in permutation
  vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
		+ i.x + vec3(0.0, i1.x, 1.0 ));

  vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
  m = m*m ;
  m = m*m ;

// Gradients: 41 points uniformly over a line, mapped onto a diamond.
// The ring size 17*17 = 289 is close to a multiple of 41 (41*7 = 287)

  vec3 x = 2.0 * fract(p * C.www) - 1.0;
  vec3 h = abs(x) - 0.5;
  vec3 ox = floor(x + 0.5);
  vec3 a0 = x - ox;

// Normalise gradients implicitly by scaling m
// Approximation of: m *= inversesqrt( a0*a0 + h*h );
  m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );

// Compute final noise value at P
  vec3 g;
  g.x  = a0.x  * x0.x  + h.x  * x0.y;
  g.yz = a0.yz * x12.xz + h.yz * x12.yw;
  return 130.0 * dot(m, g);
}

float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdSphere( vec3 p, float s )
{
  return length(p)-s;
}

float sdOctahedron( vec3 p, float s)
{
  p = abs(p);
  return (p.x+p.y+p.z-s)*0.57735027;
}

float smin( float a, float b, float k )
{
    float res = exp2( -k*a ) + exp2( -k*b );
    return -log2( res )/k;
}

mat2 rot2D(float angle){
  float s = sin(angle);
  float c = cos(angle);
  return mat2(c, -s, s, c);
}

vec3 rot3D(vec3 p, vec3 axis, float angle){
  // Rodrigues' rotation formula
  return mix(dot(axis, p) * axis, p, cos(angle)) + cross(axis, p) * sin(angle);
}

vec3 palette(float t){
  vec3 a = vec3(0.5f, 0.5f, 0.5f);
  vec3 b = vec3(0.5f, 0.5f, 0.5f);
  vec3 c = vec3(1.0f, 1.0f, 1.0f);
  vec3 d = vec3(0.263f, 0.416f, 0.557f);
  return a + b * cos(6.28318f * (c * t + d));
}

float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float sdCutHollowSphere( vec3 p, float r, float h, float t )
{
  // sampling independent computations (only depend on shape)
  float w = sqrt(r*r-h*h);
  
  // sampling dependant computations
  vec2 q = vec2( length(p.xz), p.y );
  return ((h*q.x<w*q.y) ? length(q-vec2(w,h)) : 
                          abs(length(q)-r) ) - t;
}

// float map(vec3 p){
//   vec3 pos = vec3(sin(gTime)*3.0f, 0,0);
//   float sphere = sdSphere(p-pos, 1.0f);
//
//   vec3 pBox = p;
//
//   // pBox.xy *= rot2D(gTime);
//   pBox.y -= gTime * 0.4f;
//   pBox = fract(pBox) - 0.5f;
//   
//   float box = sdBox(pBox, vec3(0.1f));
//   // float box = sdTorus(pBox, vec2(0.1f, 0.05f));
//
//   float ground = p.y + 0.75;
//   
//   return smin(ground, smin(sphere, box, 10.0f), 5.0f);
// }

float map(vec3 p){
  
  vec3 q = p;
  // // q.x += sin(gTime);
  // float box1 = sdBox(q, vec3(10.0f));
  // 
  // q = p;
  // // q.x += sin(gTime);
  // float box2 = sdBox(q, vec3(9.0f));
  //
  // box1 = max(box1, -box2);
  float box1 = sdBoxFrame(q, vec3(10.0f), 1.0f);

  // q = p;
  // q.z += 9.0f;
  // q.y += 1.0f;
  // float box3 = sdBox(q, vec3(2.0f));
  // 
  // box1 = min(box1, box3);

  q = p;
  // q.x += 1.0f;
  float sphere1 = sdSphere(q,1.1f);

  q = p;
  q.y -= 0.3f;
  float sphere2 = sdSphere(q, 1.2f);

  sphere1 = max(sphere1, -sphere2);
  
  q = p;
  q.y -= 3.3f;
  float sphere3 = sdSphere(q, 1.0);

  sphere1 = min(sphere1, sphere3);

  box1 = min(sphere1, box1);

  // q=p;
  // q -= vec3(10, 30, 10);
  // float sphere3 = sdSphere(q, 0.5f);
  //
  // box1 = min(box1, sphere3);
  // 
  // q=p;
  // q -= vec3(10, 30, 10);
  // q += normalize(vec3(-1, -1, -0.5f));
  // float sphere4 = sdSphere(q, 0.3f);
  //
  // box1 = min(box1, sphere4); 
  
  float ground = p.y + 0.75f;

  float dist = smin(ground, box1, 5.0f);
  return dist;
}
float shadow(in vec3 ro, in vec3 rd, float mint, float maxt)
{
    float t = mint;
    for( int i=0; i<256 && t<maxt; i++ )
    {
        float h = map(ro + rd*t);
        if( h<0.001 )
            return 0.0;
        t += h;
    }
    return 1.0;
}
float softshadow( in vec3 ro, in vec3 rd, float mint, float maxt, float k )
{
    float res = 1.0;
    float t = mint;
    for( int i=0; i<256 && t<maxt; i++ )
    {
        float h = map(ro + rd*t);
        if( h<0.001 )
            return 0.0;
        res = min( res, k*h/t );
        t += h;
    }
    return res;
}
vec3 calcNormal( in vec3 p ) // for function f(p)
{
    const float eps = 0.0001; // or some other value
    const vec2 h = vec2(eps,0);
    return normalize( vec3(map(p+h.xyy) - map(p-h.xyy),
                           map(p+h.yxy) - map(p-h.yxy),
                           map(p+h.yyx) - map(p-h.yyx) ) );
}
void main()
{
  // Correcting for the ascpect ratio;
  vec2 uv = (v_vertexPositions.xy * 2.0f * gResolution) / gResolution.y;

  vec3 ro = vec3(0, 0, -20);         // ray origin
  vec3 rd = normalize(vec3(uv*0.5f, 1)); // ray direction, adjusting FOV with miltiplier
  vec3 col = vec3(0.0f);            // pixel color

  ro += gCamPos;

  rd.yz *= rot2D(gMouseDelta.y);
  rd.xz *= rot2D(-gMouseDelta.x);

  float t = 0.0f;                   // travelled distance of ray

  // Raymarching
  int i;
  vec3 p;
  for(i = 0; i < 80; i++){

    p = ro + rd * t;           // position along the ray 
    // p.y -= p.x*p.x * 0.02f;
    p.y -= 0.000001f*gTime*snoise(0.1f*p.xz);
    //
    // p.y -= sin(gTime)*5.0f*snoise(0.01f*p.xz);
    // p.y -= sin(gTime + 10.0f)*5.0f*snoise(0.01f*p.xz);
    // p.y -= cos(gTime)*5.0f*snoise(0.01f*p.xz);
    // p.y -= 100.0f*snoise(0.001f*p.xz);

    // p.xz += cellular2x2(vec2(1.0f, 2.0f));
    
    
    float d = map(p);               // current distance to the scene

    
    t += d;                         // march the ray


    if(d < 0.001f || t > 100.0f) break;
  }

  // col = vec3(t * 0.02f + float(i)*0.002f, t*0.05f + float(i)*0.005f, t*0.07f + float(i)*0.007f);
  // col = vec3(t* 0.04f + float(i)*0.004f);
  // col = palette(t * 0.04f + float(i)*0.005f);
  // col = 0.8f*palette(t*0.001f + 2.0f*3.14f + float(i)*0.01f);
  col = 1*palette(t*0.01f + 2.0f*3.14f + float(i)*0.001f);
  // col.xy = vec2(cellular2x2(vec2(1.0f, 2.0f)));
  // col = vec3(t* 0.04f + float(i)*0.004f);
  vec3 sun = normalize(vec3(-3f, 3.5f, -1f));
  // float sh = shadow(p, sun, 0.02f, 120.5f);
  float sh = softshadow(p, sun, 0.02f, 120.5f, 32);
  vec3 norm = calcNormal(p);
  float dot = dot(norm, sun);
  // float sh = shadow(ro, rd, 0.02f, 2.5f);
  col *= vec3(1*sh);
  col *= vec3(1*dot);
  
  
  if(t>100.0f) col = vec3(0.0f, 0.07f, 0.13f);
  color = vec4(col, 1.0f);
}

