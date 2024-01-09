#!/bin/bash

g++ ./src/* -I./include/ -o ./bin/prog -lSDL2 -ldl 
# g++ src/main.cpp src/glad.c -Iinclude/ -o bin/prog -lSDL2 -ldl 
