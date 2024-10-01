#!/bin/bash

DOCKER_IMAGE="sknehc/zerotier-planet"

latest_tag=$(curl -s "https://api.github.com/repos/zerotier/ZeroTierOne/tags" | jq -r '.[].name' | grep -E "^[0-9]+\.[0-9]+\.[0-9]+$" | sort -V | tail -n 1)
latest_docker_tag=$(curl -s "https://hub.docker.com/v2/repositories/${DOCKER_IMAGE}/tags/" | jq -r '.results[].name' | grep -E "^[0-9]+\.[0-9]+\.[0-9]+$" | sort -V | tail -n 1)

if [ "$latest_tag" == "$latest_docker_tag" ]; then
    echo "none"
else
  echo "$latest_tag"
fi