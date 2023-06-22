#!/bin/bash
# ./build_and_test.sh
# or
# ./build_and_test.sh "23-06-22-191220"

export BUILD_PATH="."
export USER="jecnua"
export IMAGE_NAME="wg-easy"
IMAGE_TAG=$(date "+%y-%m-%d-%H%M%S")
export IMAGE_TAG
export REGISTRY="docker.io"
export MANIFEST_NAME="${REGISTRY}/${USER}/${IMAGE_NAME}:${IMAGE_TAG}"
export MESSAGE="Push? [y/n] --- "

buildah login "$REGISTRY"

if [[ $# = 0 ]]
then
  # Cleanup
  yes | docker images purge
  yes | docker system prune
  # Build
  buildah build \
    --jobs=2 \
    --platform=linux/arm64,linux/amd64 \
    --manifest "$MANIFEST_NAME" .
  # Check the manifests
  buildah manifest inspect "${MANIFEST_NAME}"
else
  export IMAGE_TAG="$1"
  export MANIFEST_NAME="${REGISTRY}/${USER}/${IMAGE_NAME}:${IMAGE_TAG}"
fi

# Test with trivy
buildah push "${MANIFEST_NAME}" "oci:/tmp/${IMAGE_TAG}.tar"
trivy image --input "/tmp/${IMAGE_TAG}.tar"
rm -fr "/tmp/${IMAGE_TAG}.tar" # Cleanup

# Choose if you want to push or not
read -e -p "$MESSAGE" choice
if [[ "$choice" == [Yy]* ]]
then
  buildah manifest push --all "${MANIFEST_NAME}" docker://"${MANIFEST_NAME}"
  buildah rmi --all # Cleanup on successfull pull
fi

echo "$MANIFEST_NAME"