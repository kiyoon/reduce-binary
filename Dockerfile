FROM ubuntu:18.04 as builder
## USAGE: docker build . -t reduce-appimage --build-arg REDUCE_RELEASE_TAG=v4.14
RUN apt-get update && apt-get install -y \
            g++ make cmake file gnupg appstream \
            curl git
## linuxdeploy appimage must use --appimage-extract within a docker container.
RUN curl -OL https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage \
    && chmod +x linuxdeploy-x86_64.AppImage \
    && ./linuxdeploy-x86_64.AppImage --appimage-extract \
    && ln -nfs /squashfs-root/usr/bin/linuxdeploy /usr/bin/linuxdeploy


ENV BUILD_DIR=/opt/build
RUN mkdir -p $BUILD_DIR/AppDir/usr

FROM builder as appimage
ARG REDUCE_RELEASE_TAG='master'
## Fetch Code
WORKDIR /opt
RUN git clone -b $REDUCE_RELEASE_TAG --depth 1 https://github.com/rlabduke/reduce
ENV REPO_ROOT=/opt/reduce

## Build
WORKDIR $REPO_ROOT
ENV LD_LIBRARY_PATH="$BUILD_DIR/AppDir/usr/lib"
ENV CPPFLAGS="-I$BUILD_DIR/AppDir/usr/include"
ENV LDFLAGS="-L$BUILD_DIR/AppDir/usr/lib"
RUN cmake . -DCMAKE_INSTALL_PREFIX="$BUILD_DIR/AppDir/usr"
RUN make -j4 && make install

## Create Appimage
ADD AppRun $BUILD_DIR/AppDir/AppRun
RUN chmod 755 $BUILD_DIR/AppDir/AppRun
ADD reduce.desktop $BUILD_DIR/AppDir/reduce.desktop
RUN touch "$BUILD_DIR/AppDir/favicon.svg"

WORKDIR $BUILD_DIR
RUN OUTPUT="reduce.appimage" /usr/bin/linuxdeploy --appdir ./AppDir --output appimage \
    --icon-file "$BUILD_DIR/AppDir/favicon.svg" \
    --executable "$BUILD_DIR/AppDir/usr/bin/reduce"
