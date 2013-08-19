#!/bin/bash
# Build all frameworks in Release configuration
#
# Syntax:
#   build-frameworks.sh

CURRENT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIGURATION=Release
PROJECT=${CURRENT_PATH}/../postgresql-kit.xcodeproj

# Build iOS Frameworks
xcodebuild -project ${PROJECT} -target "openssl_ios" -configuration ${CONFIGURATION} || exit -1
xcodebuild -project ${PROJECT} -target "libpq_ios" -configuration ${CONFIGURATION} || exit -1
xcodebuild -project ${PROJECT} -target "PGClientKit_ios" -configuration ${CONFIGURATION} || exit -1

# Build iOS iApps
# xcodebuild -project ${PROJECT} -target "PGClient_ios" -configuration ${CONFIGURATION} || exit -1

# Build Mac Frameworks
xcodebuild -project ${PROJECT} -target "openssl_mac" -configuration ${CONFIGURATION} || exit -1
xcodebuild -project ${PROJECT} -target "postgresql_mac" -configuration ${CONFIGURATION} || exit -1
xcodebuild -project ${PROJECT} -target "PGClientKit_mac" -configuration ${CONFIGURATION} || exit -1
xcodebuild -project ${PROJECT} -target "PGServerKit_mac" -configuration ${CONFIGURATION} || exit -1

# Build Mac Apps
xcodebuild -project ${PROJECT} -target "PGServer" -configuration ${CONFIGURATION} || exit -1


