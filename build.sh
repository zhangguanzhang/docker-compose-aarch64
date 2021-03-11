#!/bin/bash

# after action will run this script


docker run --rm --privileged multiarch/qemu-user-static:register

#https://github.com/multiarch/qemu-user-static




docker run --rm --privileged multiarch/qemu-user-static:register --reset
