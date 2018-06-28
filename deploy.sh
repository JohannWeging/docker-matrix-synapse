#!/bin/bash

set -x

if [ -z "${VERSION_STRIP_PATCH}" ]; then
	TAG_VERSION=${VERSION%.*}
else
	TAG_VERSION=${VERSION}
fi

docker tag "${DOCKER_USERNAME}/${DOCKER_IMAGE}:${VERSION}" "${DOCKER_USERNAME}/${DOCKER_IMAGE}:${TAG_VERSION}"

docker push "${DOCER_USERNAME}/${DOCKER_IMAGE}:${VERSION}"

if [ -z "${VERSION_STRIP_PATCH}" ]; then
	TAG_VERSION=${VERSION%.*}
    	docker tag "${DOCKER_USERNAME}/${DOCKER_IMAGE}:${VERSION}" "${DOCKER_USERNAME}/${DOCKER_IMAGE}:${TAG_VERSION}"
    	docker push "${DOCER_USERNAME}/${DOCKER_IMAGE}:${TAG_VERSION}"
fi


if [[ "${VERSION}" == "${LATEST}" ]]; then
    docker tag "${DOCKER_USERNAME}/${DOCKER_IMAGE}:${VERSION}" "${DOCKER_USERNAME}/${DOCKER_IMAGE}:latest"
    docker push "${DOCKER_UERNAME}/${DOCKER_IMAGE}:latest"
fi
