#!/bin/bash

set -ex
PROJECT_DIR=`dirname $0 | while read a; do cd $a && pwd && break; done`
SYSTEM_NAME=$(uname -s)

if [ -z "$BUILD_TYPE" ]; then
  BUILD_TYPE=Release
fi

BUILD_DIR=BUILD-$SYSTEM_NAME-$BUILD_TYPE

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

cmake -DTYPESENSE_VERSION=$TYPESENSE_VERSION -DCMAKE_BUILD_TYPE=$BUILD_TYPE -H$PROJECT_DIR -B$PROJECT_DIR/$BUILD_DIR
make typesense-server typesense-test -C $PROJECT_DIR/$BUILD_DIR

if [[ "$@" == *"--package-binary"* ]]; then
    OS_FAMILY=$(echo `uname` | awk '{print tolower($0)}')
    RELEASE_NAME=typesense-server-$TYPESENSE_VERSION-$OS_FAMILY-amd64
    printf `md5sum $PROJECT_DIR/$BUILD_DIR/typesense-server | cut -b-32` > $PROJECT_DIR/$BUILD_DIR/typesense-server.md5.txt
    tar -cvzf $PROJECT_DIR/$BUILD_DIR/$RELEASE_NAME.tar.gz -C $PROJECT_DIR/$BUILD_DIR typesense-server typesense-server.md5.txt
    echo "Built binary successfully: $PROJECT_DIR/$BUILD_DIR/$RELEASE_NAME.tar.gz"
fi

if [[ "$@" == *"--package-libs"* ]]; then
    OS_FAMILY=$(echo `uname` | awk '{print tolower($0)}')
    RELEASE_NAME=typesense-server-libs-$TYPESENSE_VERSION-$OS_FAMILY-amd64
    LIBS=`cat $PROJECT_DIR/external-$SYSTEM_NAME/libs.txt`
    TAR_PATHS=""
    for lib in $LIBS; do
        TAR_PATHS="$TAR_PATHS -C $lib `ls $lib/*.a | xargs basename`"
    done

    TAR_PATHS="$TAR_PATHS -C $PROJECT_DIR/$BUILD_DIR `ls $PROJECT_DIR/$BUILD_DIR/*.a | xargs basename`"
    tar -cvzf $PROJECT_DIR/$BUILD_DIR/$RELEASE_NAME.tar.gz $TAR_PATHS
fi
