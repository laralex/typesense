#!/bin/bash

set -ex
PROJECT_DIR=`dirname $0 | while read a; do cd $a && pwd && break; done`
SYSTEM_NAME=Windows
BUILD_DIR=build-$SYSTEM_NAME

if [ -z "$TYPESENSE_VERSION" ]; then
  TYPESENSE_VERSION="nightly"
fi

if [[ "$@" == *"--clean"* ]]; then
  echo "Cleaning..."
  rm -rf $PROJECT_DIR/$BUILD_DIR
  mkdir $PROJECT_DIR/$BUILD_DIR
fi

if [[ "$@" == *"--depclean"* ]]; then
  echo "Cleaning dependencies..."
  rm -rf $PROJECT_DIR/external-$SYSTEM_NAME
  mkdir $PROJECT_DIR/external-$SYSTEM_NAME
fi

#echo "Creating development image..."
#docker build --file $PROJECT_DIR/docker/development.Dockerfile --tag typesense/typesense-development:23-JUNE-2020-1 $PROJECT_DIR/docker

echo "Building Typesense $TYPESENSE_VERSION..."
docker run -it -v $PROJECT_DIR:/typesense typesense/typesense-development:23-JUNE-2020-1 cmake -DTYPESENSE_VERSION=$TYPESENSE_VERSION \
-DCMAKE_BUILD_TYPE=Release -H/typesense -B/typesense/$BUILD_DIR

docker run -it -v $PROJECT_DIR:/typesense typesense/typesense-development:23-JUNE-2020-1 make typesense-server -C/typesense/$BUILD_DIR

if [[ "$@" == *"--build-deploy-image"* ]]; then
    echo "Creating deployment image for Typesense $TYPESENSE_VERSION server ..."

    cp $PROJECT_DIR/docker/deployment.Dockerfile $PROJECT_DIR/$BUILD_DIR
    docker build --file $PROJECT_DIR/$BUILD_DIR/deployment.Dockerfile --tag typesense/typesense:$TYPESENSE_VERSION \
                        $PROJECT_DIR/$BUILD_DIR
fi

if [[ "$@" == *"--package-binary"* ]]; then
    OS_FAMILY=linux
    RELEASE_NAME=typesense-server-$TYPESENSE_VERSION-$OS_FAMILY-amd64
    printf `md5sum $PROJECT_DIR/$BUILD_DIR/typesense-server | cut -b-32` > $PROJECT_DIR/$BUILD_DIR/typesense-server.md5.txt
    tar -cvzf $PROJECT_DIR/$BUILD_DIR/$RELEASE_NAME.tar.gz -C $PROJECT_DIR/$BUILD_DIR typesense-server typesense-server.md5.txt
    echo "Built binary successfully: $PROJECT_DIR/$BUILD_DIR/$RELEASE_NAME.tar.gz"
fi

if [[ "$@" == *"--package-libs"* ]]; then
    OS_FAMILY=linux
    RELEASE_NAME=typesense-server-libs-$TYPESENSE_VERSION-$OS_FAMILY-amd64
    LIBS=`cat $PROJECT_DIR/external-$SYSTEM_NAME/libs.txt`
    TAR_PATHS=""
    for lib in $LIBS; do
        TAR_PATHS="$TAR_PATHS -C $PROJECT_DIR/../$lib `ls $PROJECT_DIR/../$lib/*.a | xargs basename`"
    done

    TAR_PATHS="$TAR_PATHS -C $PROJECT_DIR/$BUILD_DIR `ls $PROJECT_DIR/$BUILD_DIR/*.a | xargs basename`"
    tar -cvzf $PROJECT_DIR/$BUILD_DIR/$RELEASE_NAME.tar.gz $TAR_PATHS
fi
#
#if [[ "$@" == *"--create-deb-upload"* ]]; then
#    docker run -it -v $PROJECT_DIR:/typesense typesense/typesense-development:23-JUNE-2020-1 cmake -DTYPESENSE_VERSION=$TYPESENSE_VERSION \
#    -DCMAKE_BUILD_TYPE=Debug -H/typesense -B/typesense/$BUILD_DIR
#fi

echo "Done... quitting."
