ARG PYTHON_VERSION=3.7.10 
# https://github.com/docker/compose/blob/master/Dockerfile#L2


FROM arm64v8/python:${PYTHON_VERSION}-stretch
# FROM arm64v8/python:3.8.3-buster # /libpython3.8.so.1.0 not found
# FROM arm64v8/python:3.6-buster   # buster use GLIBC_2.28, not available on RPI 18.04.4 bionic

ARG PYINSTALLER_VER=4.1 
# https://github.com/docker/compose/blob/master/requirements-build.txt

