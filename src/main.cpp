// Third Party
#include "../include/glad/glad.h"
#include <SDL2/SDL.h>

// glm
#include "../include/glm/glm/glm.hpp"
#include "../include/glm/glm/gtc/matrix_transform.hpp"
#include "../include/glm/glm/mat4x4.hpp"
#include "../include/glm/glm/vec3.hpp"

// Standart library
#include <chrono>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include <time.h>
#include <vector>

// Own Files
#include "../include/camera.hpp"

// int gScreenWidth = 640;
// int gScreenHeight = 480;
int gScreenWidth = 1280;
int gScreenHeight = 840;
SDL_Window *gGraphicsApplicationWindow = nullptr;
SDL_GLContext gOpenGLContext = nullptr;

bool gQuit = false;

GLuint gVertexArrayObject = 0;
GLuint gVertexBufferObject = 0;
// GLuint gVertexBufferObject2 = 0;

// IBO used to store the indices that we want to draw from when doing indexed
// drawing.
GLuint gIndexBufferObject = 0;

float g_u_offset_z = -2.0f;
float g_u_offset_x = 0.0f;
float g_uRotate = 0.0f;
float g_uScale = 1.0f;

float u_xPos = 0.0f;
float u_yPos = 0.0f;
float u_zPos = 0.0f;

// static int mouseX = gScreenWidth / 2;
// static int mouseY = gScreenHeight / 2;
static int mouseX = 0;
static int mouseY = 0;

Camera gCamera;

// Program Object for our shaders
GLuint gGraphicsPipelineShaderProgram = 0;

// time_t start = time(0);

auto start_time = std::chrono::high_resolution_clock::now();

void passTime() {
  auto current_time = std::chrono::high_resolution_clock::now();

  GLuint milliseconds_since_start =
      std::chrono::duration_cast<std::chrono::microseconds>(current_time -
                                                            start_time)
          .count();

  // std::cout << "Program has been running for " << milliseconds_since_start
  //           << " seconds" << std::endl;

  // double seconds_since_start = difftime(time(0), start);
  // std::cout << seconds_since_start << std::endl;

  GLint u_TimeLocation =
      glGetUniformLocation(gGraphicsPipelineShaderProgram, "u_Time");
  if (u_TimeLocation >= 0) {
    // std::cout << "location of u_offset: " << location << std::endl;
    // glUniformMatrix4fv(u_TimeLocation, 1, GL_FALSE, &model[0][0]);
    glUniform1i(u_TimeLocation, milliseconds_since_start);
  } else {
    std::cout << "Could not find u_TimeLocation in memory." << std::endl;
    exit(EXIT_FAILURE);
  }
}

//===================== Error Handling Routine. =====================
static void GLClearAllErrors() {
  while (glGetError() != GL_NO_ERROR) {
  }
}
static bool GLCheckErrorStatus(const char *function, int line) {
  while (GLenum error = glGetError()) {
    std::cout << "OpenGL Error: " << error << "\tLine: " << line
              << "\tfunction: " << function << std::endl;
    return true;
  }
  return false;
}

// Macro to execute on specific line.
#define GLCheck(x)                                                             \
  GLClearAllErrors();                                                          \
  x;                                                                           \
  GLCheckErrorStatus(#x, __LINE__);
//====================================================================

std::string LoadSchaderAsString(const std::string &filename) {
  std::string result = "";
  std::string line = "";
  std::ifstream myFile(filename.c_str());

  if (myFile.is_open()) {
    while (std::getline(myFile, line)) {
      result += line + '\n';
    }
    myFile.close();
  }
  return result;
}

GLuint CompileShader(GLuint type, const std::string &source) {
  GLuint shaderObject;
  if (type == GL_VERTEX_SHADER) {
    shaderObject = glCreateShader(GL_VERTEX_SHADER);
  } else if (type == GL_FRAGMENT_SHADER) {
    shaderObject = glCreateShader(GL_FRAGMENT_SHADER);
  }
  const char *src = source.c_str();
  glShaderSource(shaderObject, 1, &src, nullptr);
  glCompileShader(shaderObject);

  return shaderObject;
}

GLuint CreateShaderProgram(const std::string &vertexShaderSource,
                           const std::string &fragmentShaderSource) {
  GLuint programObject = glCreateProgram();
  GLuint myVertexShader = CompileShader(GL_VERTEX_SHADER, vertexShaderSource);
  GLuint myFragmentShader =
      CompileShader(GL_FRAGMENT_SHADER, fragmentShaderSource);

  glAttachShader(programObject, myVertexShader);
  glAttachShader(programObject, myFragmentShader);
  glLinkProgram(programObject);

  // Vaildate
  glValidateProgram(programObject);
  return programObject;
}

// Get Project directory path from executable path.
std::string GetBaseDirectory() {
  std::filesystem::path executablePath =
      std::filesystem::read_symlink("/proc/self/exe");

  executablePath = executablePath.parent_path().parent_path();

  return executablePath.string();
}

void CreateGraphicsPipeline() {
  std::string vertexShaderSource =
      LoadSchaderAsString(GetBaseDirectory() + "/shaders/vert.glsl");

  std::string fragmentShaderSource =
      LoadSchaderAsString(GetBaseDirectory() + "/shaders/frag.glsl");

  gGraphicsPipelineShaderProgram =
      CreateShaderProgram(vertexShaderSource, fragmentShaderSource);
}

void GetOpenGLVersionInfo() {

  std::cout << "Vendor: " << glGetString(GL_VENDOR) << std::endl;
  std::cout << "Renderer: " << glGetString(GL_RENDERER) << std::endl;
  std::cout << "Version: " << glGetString(GL_VERSION) << std::endl;
  std::cout << "Shading Language: " << glGetString(GL_SHADING_LANGUAGE_VERSION)
            << std::endl;
}

void VertexSpecification() {
  // On CPU:
  const std::vector<GLfloat> vertexData{
      -1.0f, -1.0f, 0.0f, //
      0.5f,  0.3f,  0.1f, //
      1.0f,  -1.0f, 0.0f, //
      0.5f,  0.3f,  0.1f, //
      -1.0f, 1.0f,  0.0f, //
      0.2f,  0.9f,  0.9f, //
      1.0f,  1.0f,  0.0f, //
      0.2f,  0.9f,  0.9f, //
                          //
                          // 0.5f, 0.5f, -1.0f,  //
                          // 0.5f, 0.3f, 0.1f,   //
                          // -0.5f, 0.5f, -1.0f, //
                          // 0.5f, 0.3f, 0.1f,   //
                          //
                          // -0.5f, -0.5f, -1.0f, //
                          // 0.2f, 0.9f, 0.9f,    //
                          // 0.5f, -0.5f, -1.0f,  //
                          // 0.2f, 0.9f, 0.9f,    //
  };

  // Setting things up on GPU: (VAO)
  glGenVertexArrays(1, &gVertexArrayObject);
  glBindVertexArray(gVertexArrayObject);

  // Generate VBO
  glGenBuffers(1, &gVertexBufferObject);
  glBindBuffer(GL_ARRAY_BUFFER, gVertexBufferObject);
  glBufferData(GL_ARRAY_BUFFER, vertexData.size() * sizeof(GLfloat),
               vertexData.data(), GL_STATIC_DRAW);

  const std::vector<GLuint> indexBufferData{2, 0, 1, 3, 2, 1, 4, 3, 2, 5, 2, 4,
                                            4, 5, 6, 6, 7, 4, 6, 7, 0, 0, 1, 7};
  // Set up index Buffer Object
  glGenBuffers(1, &gIndexBufferObject);
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, gIndexBufferObject);
  // Populate our Index Buffer
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, indexBufferData.size() * sizeof(GLuint),
               indexBufferData.data(), GL_STATIC_DRAW);

  // For the position data.
  glEnableVertexAttribArray(0);
  glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, sizeof(GL_FLOAT) * 6,
                        (void *)0);

  // glBindVertexArray(0); // Setting to 0 cleans up
  // glDisableVertexAttribArray(0);

  // Colors
  // glGenBuffers(1, &gVertexBufferObject2);
  // glBindBuffer(GL_ARRAY_BUFFER, gVertexBufferObject2);
  // glBufferData(GL_ARRAY_BUFFER, vertexColors.size() * sizeof(GLfloat),
  //              vertexColors.data(), GL_STATIC_DRAW);

  // For the colors.
  glEnableVertexAttribArray(1);
  glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, sizeof(GL_FLOAT) * 6,
                        (void *)(sizeof(GL_FLOAT) * 3));

  // Clean up.
  glBindVertexArray(0); // Setting to 0 cleans up
  glDisableVertexAttribArray(0);
  glDisableVertexAttribArray(1);
}

void InitializeProgram() {
  if (SDL_Init(SDL_INIT_VIDEO) < 0) {
    std::cout << "SDL2 could not initialize video subsystem." << std::endl;
    exit(1);
  }

  SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 4);
  SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 1);
  SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
  SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
  SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);

  gGraphicsApplicationWindow = SDL_CreateWindow(
      "OpenGL Window", 0, 0, gScreenWidth, gScreenHeight, SDL_WINDOW_OPENGL);
  if (gGraphicsApplicationWindow == nullptr) {
    std::cout << "SDL_Window could not be created." << std::endl;
    exit(1);
  }

  gOpenGLContext = SDL_GL_CreateContext(gGraphicsApplicationWindow);
  if (gOpenGLContext == nullptr) {
    std::cout << "OpenGL context could not be initialized." << std::endl;
    exit(1);
  }

  if (!gladLoadGLLoader(SDL_GL_GetProcAddress)) {
    std::cout << "glad was not initialized." << std::endl;
    exit(1);
  }

  // Enable drawing in order of view -> closest last.
  glEnable(GL_DEPTH_TEST);

  // Enable making clockwise facing drawn vertices invisible.
  // glEnable(GL_CULL_FACE);

  GetOpenGLVersionInfo();
}

void Input() {
  // static int mouseX = gScreenWidth / 2;
  // static int mouseY = gScreenHeight / 2;
  //
  SDL_Event e;
  while (SDL_PollEvent(&e) != 0) {
    if (e.type == SDL_QUIT) {
      std::cout << "SDL Quit" << std::endl;
      gQuit = true;
    } else if (e.type == SDL_MOUSEMOTION) {
      mouseX += e.motion.xrel;
      mouseY += e.motion.yrel;

      // std::cout << "Mouse pos: " << glm::radians((float)mouseX) << ", "
      //           << glm::radians((float)mouseY) << std::endl;
      // gCamera.MouseLook(mouseX, mouseY);
    }
  }
  // std::cout << "Eye pos: " << u_zPos << ", " << u_xPos << std::endl;

  float speed = 0.15f;
  const Uint8 *state = SDL_GetKeyboardState(NULL);
  if (state[SDL_SCANCODE_W]) {
    // gCamera.MoveForward(speed);
    // u_zPos += speed;
    u_zPos += cosf(-glm::radians((float)mouseX)) * speed;
    u_xPos -= sinf(-glm::radians((float)mouseX)) * speed;
  }
  if (state[SDL_SCANCODE_S]) {
    // gCamera.MoveBackward(speed);
    // u_zPos -= speed;
    u_zPos -= cosf(-glm::radians((float)mouseX)) * speed;
    u_xPos += sinf(-glm::radians((float)mouseX)) * speed;
  }
  if (state[SDL_SCANCODE_D]) {
    // gCamera.MoveRight(speed);
    // u_xPos += speed;
    u_zPos += sinf(-glm::radians((float)mouseX)) * speed;
    u_xPos += cosf(-glm::radians((float)mouseX)) * speed;
  }
  if (state[SDL_SCANCODE_A]) {
    // gCamera.MoveLeft(speed);
    // u_xPos -= speed;
    u_zPos -= sinf(-glm::radians((float)mouseX)) * speed;
    u_xPos -= cosf(-glm::radians((float)mouseX)) * speed;
  }
  if (state[SDL_SCANCODE_SPACE]) {
    // gCamera.MoveUp(speed);
    u_yPos += speed;
  }
  if (state[SDL_SCANCODE_LSHIFT]) {
    // gCamera.MoveDown(speed);
    u_yPos -= speed;
  }
}

void PreDraw() {
  // glDisable(GL_DEPTH_TEST);
  // glDisable(GL_CULL_FACE);

  glViewport(0, 0, gScreenWidth, gScreenHeight);
  // glClearColor(0.1f, 0.5f, 0.55f, 1.f);
  glClearColor(60.0f / 255.0f, //
               56.0f / 255.0f, //
               54.0f / 255.0f, //
               1.0f);
  // glClearColor(0.25f, //
  //              0.2f,  //
  //              0.2f,  //
  //              1.0f);

  glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);

  // g_uRotate -= 1.0f;

  glUseProgram(gGraphicsPipelineShaderProgram);

  glm::mat4 model = glm::translate(glm::mat4(1.0f),
                                   glm::vec3(g_u_offset_x, 0.0f, g_u_offset_z));

  model =
      glm::rotate(model, glm::radians(g_uRotate), glm::vec3(0.0f, 1.0f, 0.0f));

  model = glm::scale(model, glm::vec3(g_uScale, g_uScale, g_uScale));

  GLint u_ModelMatrixLocation =
      glGetUniformLocation(gGraphicsPipelineShaderProgram, "u_ModelMatrix");
  if (u_ModelMatrixLocation >= 0) {
    // std::cout << "location of u_offset: " << location << std::endl;
    glUniformMatrix4fv(u_ModelMatrixLocation, 1, GL_FALSE, &model[0][0]);
  } else {
    std::cout << "Could not find u_ModelMatrix in memory." << std::endl;
    exit(EXIT_FAILURE);
  }

  glm::mat4 view = gCamera.GetViewMatrix();
  GLint u_ViewLocation =
      glGetUniformLocation(gGraphicsPipelineShaderProgram, "u_ViewMatrix");
  if (u_ViewLocation >= 0) {
    // std::cout << "location of u_offset: " << location << std::endl;
    glUniformMatrix4fv(u_ViewLocation, 1, GL_FALSE, &view[0][0]);
  } else {
    std::cout << "Could not find u_ViewMatrix in memory." << std::endl;
    exit(EXIT_FAILURE);
  }

  glm::mat4 perspective = glm::perspective(
      glm::radians(45.0f),
      /* (float)gScreenWidth / (float)gScreenHeight */ 1.0f, 0.1f, 20.0f);

  GLint u_ProjectionLocation =
      glGetUniformLocation(gGraphicsPipelineShaderProgram, "u_Projection");
  if (u_ProjectionLocation >= 0) {
    // std::cout << "location of u_offset: " << location << std::endl;
    glUniformMatrix4fv(u_ProjectionLocation, 1, GL_FALSE, &perspective[0][0]);
  } else {
    std::cout << "Could not find u_Perspective in memory." << std::endl;
    exit(EXIT_FAILURE);
  }

  GLfloat resolution[] = {(float)gScreenWidth, (float)gScreenHeight};
  // glm::vec2 resolution = {(float)gScreenWidth, (float)gScreenHeight};
  // GLuint aspectRatio = gScreenWidth;
  // Pass aspect ratio to shader.
  GLint u_ResolutionLocation =
      glGetUniformLocation(gGraphicsPipelineShaderProgram, "u_Resolution");
  if (u_ResolutionLocation >= 0) {
    // std::cout << "location of u_offset: " << location << std::endl;
    // glUniformMatrix4fv(u_TimeLocation, 1, GL_FALSE, &model[0][0]);
    glUniform1fv(u_ResolutionLocation, 2, resolution);
  } else {
    std::cout << "Could not find u_ResolutionLocation in memory." << std::endl;
    exit(EXIT_FAILURE);
  }

  // GLfloat camPos[] = {u_xPos, u_yPos, u_zPos};
  // glm::vec3 camPos = gCamera.GetCamPos();
  glm::vec3 camPos = glm::vec3(u_xPos, u_yPos, u_zPos);
  // glm::vec2 resolution = {(float)gScreenWidth, (float)gScreenHeight};
  // GLuint aspectRatio = gScreenWidth;
  // Pass aspect ratio to shader.
  GLint u_CamPosLocation =
      glGetUniformLocation(gGraphicsPipelineShaderProgram, "u_CamPos");
  if (u_CamPosLocation >= 0) {
    // std::cout << "location of u_offset: " << location << std::endl;
    // glUniformMatrix4fv(u_TimeLocation, 1, GL_FALSE, &model[0][0]);
    glUniform1fv(u_CamPosLocation, 3, &camPos[0]);
  } else {
    std::cout << "Could not find u_CamPosLocation in memory." << std::endl;
    exit(EXIT_FAILURE);
  }

  // glm::vec2 mouseDelta = gCamera.GetMouseDelta();
  // glm::vec2 mouseDelta =
  //     glm::vec2((float)mouseX / 100.0f, (float)mouseY / 100.0f);
  // currentMouseX = mouseX;
  glm::vec2 mouseDelta =
      glm::vec2(glm::radians((float)mouseX), glm::radians((float)mouseY));
  // glm::vec2 resolution = {(float)gScreenWidth, (float)gScreenHeight};
  // GLuint aspectRatio = gScreenWidth;
  // Pass aspect ratio to shader.
  GLint u_MouseDeltaLocation =
      glGetUniformLocation(gGraphicsPipelineShaderProgram, "u_MouseDelta");
  if (u_MouseDeltaLocation >= 0) {
    // std::cout << "location of u_offset: " << location << std::endl;
    // glUniformMatrix4fv(u_TimeLocation, 1, GL_FALSE, &model[0][0]);
    glUniform1fv(u_MouseDeltaLocation, 3, &mouseDelta[0]);
  } else {
    std::cout << "Could not find u_MouseDeltaLocation in memory." << std::endl;
    exit(EXIT_FAILURE);
  }
  // std::cout << "Mouse Delta: " << gCamera.GetMouseDelta().x << std::endl;
  // glm::vec3 camRot = gCamera.GetCamRot();
  // // glm::vec2 resolution = {(float)gScreenWidth, (float)gScreenHeight};
  // // GLuint aspectRatio = gScreenWidth;
  // // Pass aspect ratio to shader.
  // GLint u_CamRotLocation =
  //     glGetUniformLocation(gGraphicsPipelineShaderProgram, "u_CamRot");
  // if (u_CamRotLocation >= 0) {
  //   // std::cout << "location of u_offset: " << location << std::endl;
  //   // glUniformMatrix4fv(u_TimeLocation, 1, GL_FALSE, &model[0][0]);
  //   glUniform1fv(u_CamRotLocation, 3, &camRot[0]);
  // } else {
  //   std::cout << "Could not find u_CamRotLocation in memory." << std::endl;
  //   exit(EXIT_FAILURE);
  // }

  passTime();
}
void Draw() {
  glBindVertexArray(gVertexArrayObject);
  glBindBuffer(GL_ARRAY_BUFFER, gVertexBufferObject);

  // glDrawArrays(GL_TRIANGLES, 0, 6);
  glDrawElements(GL_TRIANGLES, 90, GL_UNSIGNED_INT, 0);
  glUseProgram(0); // Setting to 0 cleans up.
}
void MainLoop() {
  SDL_WarpMouseInWindow(gGraphicsApplicationWindow, gScreenWidth / 2,
                        gScreenHeight / 2);
  SDL_SetRelativeMouseMode(SDL_TRUE);
  while (!gQuit) {
    Input();
    PreDraw();
    Draw();
    // Update Screen
    SDL_GL_SwapWindow(gGraphicsApplicationWindow);
  }
}
void CleanUp() {

  SDL_DestroyWindow(gGraphicsApplicationWindow);
  SDL_Quit();
}

int main() {
  InitializeProgram();
  VertexSpecification();
  CreateGraphicsPipeline();
  MainLoop();
  CleanUp();
  return 0;
}
