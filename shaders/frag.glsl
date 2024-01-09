#version 410 core

// in vec3 v_vertexColors;
// uniform float u_offset; // uniform - global var on GPU

uniform int u_Time;
// uniform float u_AspectRatio;
uniform float u_Resolution[2];

in vec3 v_vertexPositions;

out vec4 color;

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

float map(vec3 p){
  float time = u_Time/1000000.0f;
  vec3 pos = vec3(sin(time)*3.0f, 0,0);
  float sphere = sdSphere(p-pos, 1.0f);
  float box = sdBox(p, vec3(0.75f));
  return smin(sphere, box, 10.0f);
}

void main()
{
  // Correcting for the ascpect ratio;
  vec2 resolution = vec2(u_Resolution[0], u_Resolution[1]);
  vec2 uv = (v_vertexPositions.xy * 2.0f * resolution) / resolution.y;

  vec3 ro = vec3(0, 0, -3);         // ray origin
  vec3 rd = normalize(vec3(uv*0.5f, 1)); // ray direction, adjusting FOV with miltiplier
  vec3 col = vec3(0.0f);            // pixel color

  float t = 0.0f;                   // travelled distance of ray

  // Raymarching
  int i;
  for(i = 0; i < 80; i++){
    vec3 p = ro + rd * t;           // position along the ray 
    
    float d = map(p);               // current distance to the scene

    t += d;                         // march the ray


    if(d < 0.001f || t > 100.0f) break;
  }

  col = vec3(t * 0.2f);
  
  color = vec4(col, 1.0f);
}

