#!/bin/sh

export REDUCE_RELEASE_TAG=v4.14
docker build . -t reduce-appimage --build-arg REDUCE_RELEASE_TAG=$REDUCE_RELEASE_TAG

docker rm -f reducecontainer
docker create -ti --name reducecontainer reduce-appimage bash
docker cp reducecontainer:/opt/build/reduce.appimage .
docker rm -f reducecontainer
