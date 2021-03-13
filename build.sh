#!/bin/bash

# after action will run this script


readonly CUR_DIR=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)


# 取当前时间的最后3个tag
RELEASE_TAG_COUNT=3

dist_dir=${CUR_DIR:=.}/dist/
artifact_dir=/tmp/artifact/


mkdir ${dist_dir} ${artifact_dir} 

(cd ${CUR_DIR}/compose; ls -al; ls -al .git; )

curl  \
  -H "Accept: application/vnd.github.v3+json"  \
   "https://api.github.com/repos/docker/compose/releases?per_page=${RELEASE_TAG_COUNT}" |  \
   jq -r ' .[] | "\(.name) \(.prerelease)"' | tac

curl  \
  -H "Accept: application/vnd.github.v3+json"  \
   "https://api.github.com/repos/docker/compose/releases?per_page=${RELEASE_TAG_COUNT}" |  \
   jq -r ' .[] | "\(.name) \(.prerelease)"' | tac > /tmp/release_info

while read tag pre;do

    if gh release list -R ${GITHUB_REPOSITORY} -L ${RELEASE_TAG_COUNT} | awk '{print $1}' | grep -w $tag;then
        continue
    fi
    echo "start build for $tag"
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
    cp dist/* ${dist_dir}/
    cp dist/* ${artifact_dir}
    rm -rf ${CUR_DIR}/compose/dist/*

    if [ "$pre" == "true" ];then
        gh release create -R ${GITHUB_REPOSITORY} --prerelease "$tag" ${dist_dir}/* --title ""
    else
        gh release create -R ${GITHUB_REPOSITORY} "$tag" ${dist_dir}/* --title ""
    fi

    cd ${CUR_DIR}


done < /tmp/release_info
# <( git --work-tree ${CUR_DIR}/compose tag --sort=committerdate  | tail -n -${RELEASE_TAG_COUNT} )
# gh release cannot list sort by commit time
# done < <(  gh release list -R docker/compose -L 30 | awk '{print $1}' )