#!/bin/bash

# Check if three arguments are provided
if [ $# -ne 3 ]; then
    echo "Usage: $0 <repo> <name> <tag>"
    echo "Example: $0 docker.io elastic/kibana 7.17.27"
    echo "         $0 docker.io postgres latest"
    exit 1
fi

# Extract parameters
REPO="$1"
NAME="$2"
TAG="$3"

# Handle images with and without a namespace
if [[ "$NAME" == *"/"* ]]; then
    IMAGE_NAMESPACE="${NAME%/*}"   # Everything before the last "/"
    IMAGE_NAME="${NAME##*/}"       # Everything after the last "/"
else
    IMAGE_NAMESPACE=""             # No namespace
    IMAGE_NAME="${NAME}"             # The entire name is the image name
fi

# Construct full image path with registry
FULL_IMAGE_PATH="${REPO}/${NAME}:${TAG}"

# Define local image tag (removes registry, keeps namespace and name)
LOCAL_IMAGE_TAG="${NAME}:${TAG}"

echo "Pulling Docker image: ${FULL_IMAGE_PATH}..."
docker pull "${FULL_IMAGE_PATH}"
if [ $? -ne 0 ]; then
    echo "Error: Failed to pull Docker image: ${FULL_IMAGE_PATH}"
    exit 1
fi

echo "Tagging Docker image as: ${LOCAL_IMAGE_TAG}"
docker tag "${FULL_IMAGE_PATH}" "${LOCAL_IMAGE_TAG}"
if [ $? -ne 0 ]; then
    echo "Error: Failed to tag Docker image as: ${LOCAL_IMAGE_TAG}"
    exit 1
fi

# Set output directory inside the script's location
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
OUTPUT_DIR="${SCRIPT_DIR}/${IMAGE_NAME}"

mkdir -p "${OUTPUT_DIR}"

# Set output file path
OUTPUT_FILE="${OUTPUT_DIR}/${IMAGE_NAME}-${TAG}.tar"

echo "Saving Docker image to ${OUTPUT_FILE}..."
docker save "${LOCAL_IMAGE_TAG}" -o "${OUTPUT_FILE}"

if [ $? -ne 0 ]; then
    echo "Error: Failed to save Docker image: ${LOCAL_IMAGE_TAG}"
    exit 1
fi

# gzip the output
gzip "${OUTPUT_FILE}"

echo "Docker image saved as: ${OUTPUT_FILE}"