#version 410 core

layout(location=0) in vec3 position;
layout(location=1) in vec3 vertexColors;

// uniform float u_offset; // uniform - global var on GPU
uniform mat4 u_ModelMatrix;
uniform mat4 u_Projection;
uniform mat4 u_ViewMatrix;

// mat4 x_HOLDER;

// out vec3 v_vertexColors;
out vec3 v_vertexPositions;

void main()
{
  // v_vertexColors = vertexColors;
  v_vertexPositions = position;

   // x_HOLDER = u_Projection;
  
  vec4 newPosition = u_Projection * u_ViewMatrix *  u_ModelMatrix * vec4(position, 1.0f);
  
  // gl_Position = vec4(newPosition.x, newPosition.y, newPosition.z, newPosition.w);
  gl_Position = newPosition;
}
