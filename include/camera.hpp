#ifndef CAMERA_HPP
#define CAMERA_HPP

#define GLM_ENABLE_EXPERIMENTAL

#include "glm/glm/glm.hpp"
#include "glm/glm/gtc/matrix_transform.hpp"
#include "glm/glm/gtx/rotate_vector.hpp"
#include <iostream>

class Camera {
public:
  Camera();
  glm::mat4 GetViewMatrix() const;

  void MouseLook(int mouseX, int mouseY);
  void MoveForward(float speed);
  void MoveBackward(float speed);
  void MoveLeft(float speed);
  void MoveRight(float speed);
  void MoveUp(float speed);
  void MoveDown(float speed);

  glm::vec3 GetCamPos();
  glm::vec3 GetCamRot();
  glm::vec2 GetMouseDelta();
  // glm::vec2 GetRotAngle(int mouseX, int mouseY);

private:
  glm::vec3 mEye;
  glm::vec3 mViewDirection;
  glm::vec3 mUpVector;

  glm::vec2 mouseDelta;
  glm::vec2 mOldMousePosition;
};

#endif
