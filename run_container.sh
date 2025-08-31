#!/bin/bash

CONTAINER_NAME="ball_butler"
IMAGE="bb_cont:latest"
WORKING_DIR="/home/ball_butler"
EXCLUDE_DIRS=("onshape_urdf")

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if the container is running
if docker ps --filter "name=^/${CONTAINER_NAME}$" --filter "status=running" --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "${CONTAINER_NAME} is already running."
    docker exec -it ${CONTAINER_NAME} /bin/bash
else
    echo "${CONTAINER_NAME} is NOT running."

    # Allow local X connections
    xhost +local:docker

    # Mount all directories from SCRIPT_DIR
    VOLUME_MOUNTS=""
    echo "Mounting directories from: ${SCRIPT_DIR}"

	for dir in "${SCRIPT_DIR}"/*; do
		if [ -d "${dir}" ]; then
				dir_name=$(basename "${dir}")

				# Check if dir_name is in EXCLUDE_DIRS
				if [[ " ${EXCLUDE_DIRS[@]} " =~ " ${dir_name} " ]]; then
						echo "  Skipping: ${dir_name}"
						continue
				fi

				echo "  Mounting: ${dir_name}"
				VOLUME_MOUNTS="${VOLUME_MOUNTS} -v ${dir}:${WORKING_DIR}/src/${dir_name}"
		fi
    done



    if [ -z "${VOLUME_MOUNTS}" ]; then
        echo "Warning: No directories found to mount in ${SCRIPT_DIR}"
    fi

    # Run the Docker container
    docker run -it --rm \
        --network host \
        --name ${CONTAINER_NAME} \
        --privileged \
        -e DISPLAY=$DISPLAY \
        -v /tmp/.X11-unix:/tmp/.X11-unix:ro \
        ${VOLUME_MOUNTS} \
        -w ${WORKING_DIR} \
        ${IMAGE} \
        /bin/bash
fi
