#!/bin/bash

IMAGE_NAME="nginx:latest"

docker pull zakhar15/nginx:latest

docker run -d -p 80:80 zakhar15/nginx:latest