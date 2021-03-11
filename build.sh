#!/bin/bash

# after action will run this script

# docker-practice/actions-setup-docker@master will run the `ghcr.io/dpsigs/tonistiigi-binfmt:latest --install all`
#docker run --rm --privileged ghcr.io/dpsigs/tonistiigi-binfmt:latest --install all
# 
#docker run --rm --privileged multiarch/qemu-user-static:register
#https://github.com/multiarch/qemu-user-static
#docker run --rm --privileged multiarch/qemu-user-static:register --reset

readonly CUR_DIR=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)


# 取当前时间的最后30个tag
RELEASE_TAG_COUNT=30

curl -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/${GITHUB_REPOSITORY:=zhangguanzhang/docker-compose-aarch64}/releases?per_page=${RELEASE_TAG_COUNT}&page=1"

dist_dir=${CUR_DIR:=.}/dist/

mkdir ${dist_dir}

while read tag;do

    rm -rf ${dist_dir}/*
    cd ${CUR_DIR}/compose
    git checkout $tag;
    [ -f ./script/clean ] && ./script/clean;

    DOCKER_COMPOSE_GITSHA="$(git --work-tree ${CUR_DIR}/compose rev-parse --short HEAD)"
    if [[ "${?}" != "0" ]]; then
        echo "Couldn't get revision of the git repository. Setting to 'unknown' instead"
        DOCKER_COMPOSE_GITSHA="unknown"
    fi
    echo "tag: $tag commitID: ${DOCKER_COMPOSE_GITSHA}"

    docker buildx build --platform linux/arm64 . \
    --target bin \
    --build-arg DISTRO=debian \
    --build-arg GIT_COMMIT="${DOCKER_COMPOSE_GITSHA}" \
    --output dist/ || : ;
    ls -l dist;
    docker run --platform linux/arm64 \
    --rm -v $PWD/dist:/root/ \
    arm64v8/python:3.7.10-stretch /root/docker-compose-linux-arm64 version;
    cp dist/* ${CUR_DIR}/dist/

    cd ${CUR_DIR}
done <( git --work-tree ${CUR_DIR}/compose tag --sort=committerdate  | tail -n -${RELEASE_TAG_COUNT} )



func create_release(){
    local version=$1 prerelease=$2
    echo "Creating a new release on GitHub"
    API_JSON=$(printf '{"tag_name": "%s","target_commitish": "master","name": "%s","body": "Release of version %s","draft": false,"prerelease": %s}' $NEWVERSION $NEWVERSION $NEWVERSION)
    curl --data "$API_JSON" https://api.github.com/repos/${GITHUB_REPOSITORY}/releases?access_token=${ACCESSTOKEN}
}