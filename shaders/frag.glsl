#version 410 core

uniform int u_Time;               // Time in ms.
volatile float gTime = u_Time/1000000.0f;  // Time in s.

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

//
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

vec2 mod289(vec2 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

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
  vec3 c = vec3(1.0f, 1.0f, 0.5f);
  vec3 d = vec3(0.8f, 0.9f, 0.3f);
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

float rotatingSpineQuarter(vec3 p, vec2 pos, float oX, float oZ, float timing){

  vec3 pBox = p;

  pBox.xz += pos;
  
  pBox.xz = mod(pBox.xz, 15.0f) - 7.5f;
  
  pBox.y += 1.7f + (3.0f * sin(1.5f*gTime + timing) - 0.0f);
  pBox.xz *= rot2D(1.2f*pBox.y*sin(1.5f*gTime + timing));
  // pBox.xz *= -rot2D(sin(1.5f*gTime + timing));
  
  pBox.x += oX;
  pBox.z += oZ;
  pBox.xz *= rot2D(1.0f*cos(1.5f*gTime + timing));
  
  pBox.x += 0.14f*(pBox.y)*sign(-oX);
  pBox.z += 0.14f*(pBox.y)*sign(-oZ);
  
  float box = sdBox(pBox, vec3(0.1f, 3.0f, 0.1f));
  return box;
}

float rotatingSpine(vec3 p, vec2 pos, float offset, float timing){
  float box1 = rotatingSpineQuarter(p, pos, -offset, -offset, timing);
  float box2 = rotatingSpineQuarter(p, pos,  offset, -offset, timing);
  float box3 = rotatingSpineQuarter(p, pos, -offset,  offset, timing);
  float box4 = rotatingSpineQuarter(p, pos,  offset,  offset, timing);

  return min(box1, min(box2, min(box3, box4)));
}

float rand(vec2 co){
  return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}
 
float randomSpines(vec3 p, int amount){
  // float dist = rotatingSpine(p, vec2(rand(vec2(float(amount), float(amount)))), rand(vec2(float(amount), float(amount))), 0.3f, rand(vec2(float(amount), float(amount))));
  // float dist = rotatingSpine(p, vec2(rand(gCamPos.xz), rand(gCamPos.xz)), 0.3f, rand(gCamPos.xz));
  
  float i_float = float(amount);
  vec2 r = vec2(i_float, i_float);
  // vec2 r = vec2(1.0f, 1.0f);
  float dist = rotatingSpine(p, vec2(rand(r), rand(r)), 0.4f, rand(r));
  
  for (int i = 0; i < amount-1; i++){
    i_float = float(i);
    float r = rand(vec2(i_float+9.213f, i_float+3.546f))*50.0f;
    float r2 = rand(vec2(i_float+3.387f, i_float+7.189f))*50.0f;
    float r3 = rand(vec2(i_float+3.907f, i_float+7.028f))*50.0f;
    float dist2 = rotatingSpine(p, vec2(r, r2), 0.4f, r3);
    dist = min(dist, dist2);
  }
  return dist;
}

float map(vec3 p){
  // p.z += gTime*2.4f;
  
  // float box1 = rotatingSpine(p, vec2(0.0f, 0.0f), 0.3f, 0.0f);
  // float box2 = rotatingSpine(p, vec2(2.0f, 0.0f), 0.3f, 2.0f);
  // float box3 = rotatingSpine(p, vec2(3.0f, -1.0f), 0.3f, 3.9f);

  // box1 = min(box1, min(box2, box3));
  float box1 = randomSpines(p, 10);
  
  float ground = p.y + 0.75f;

  float dist = smin(ground, box1, 5.0f);
  return dist;
}
void main()
{
  // Correcting for the ascpect ratio;
  vec2 uv = (v_vertexPositions.xy * 2.0f * gResolution) / gResolution.y;

  vec3 ro = vec3(0, 0, -3);         // ray origin
  vec3 rd = normalize(vec3(uv*0.5f, 1)); // ray direction, adjusting FOV with miltiplier
  vec3 col = vec3(0.0f);            // pixel color

  ro += gCamPos;

  rd.yz *= rot2D(gMouseDelta.y);
  rd.xz *= rot2D(-gMouseDelta.x);

  float t = 0.0f;                   // travelled distance of ray

  // Raymarching
  int i;
  for(i = 0; i < 80; i++){
    vec3 p = ro + rd * t;           // position along the ray 
    
    // p.xy *= rot2D(0.01f*gTime + 0.001f*sin(gTime) + t*0.02f + t*0.005f*sin(0.5f*gTime)); // Const Rotation, changing rotation speed, constant twist, changing twist amount
    // p.xy *= rot2D(t*0.02f*sin(gTime + 10.0f) + 0.01f*sin(gTime));
    // p.xz *= rot2D(t*0.01f*cos(gTime));

    // p.xy *= rot2D(t*0.005f*cos(gTime + 10.0f));
    // p.zy *= rot2D(t*0.005f*sin(gTime));
    p.y -= p.x*p.x * 0.02f;
    // p.y += p.z*p.z * 0.02f;

    p.y -= 2.0f*snoise(0.05f*p.xz);


    
    // p.y = abs(p.y); // some kind of mirror

    // p.y += sin(t)*0.35f;
    
    float d = map(p);               // current distance to the scene

    t += d;                         // march the ray


    if(d < 0.001f || t > 100.0f) break;
  }

  // col = vec3(t * 0.02f + float(i)*0.002f, t*0.05f + float(i)*0.005f, t*0.07f + float(i)*0.007f);
  // col = palette(t * 0.004f + float(i)*0.0005f - 20.0f);
  col = 0.8f*palette(t*0.005f + 2.0f*3.14f + float(i)*0.003f);
  if(t>100.0f) col = vec3(0.0f, 0.07f, 0.13f);
  
  color = vec4(col, 1.0f);
}

