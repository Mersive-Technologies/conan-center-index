#!/bin/bash

set -x
set -e

export CONAN_COMPILER=clang
export CC=${TOOLCHAIN}/bin/aarch64-linux-android23-clang
export CXX=${TOOLCHAIN}/bin/aarch64-linux-android23-clang
export CMAKE_C_COMPILER=${TOOLCHAIN}/bin/aarch64-linux-android23-clang
export CMAKE_CXX_COMPILER=${TOOLCHAIN}/bin/aarch64-linux-android23-clang
export CMAKE_LINKER=${TOOLCHAIN}/bin/aarch64-linux-android23-clang
export CMAKE_AR=${TOOLCHAIN}/bin/aarch64-linux-android-ar

export MAKE_ANDROID_NDK="$ANDROID_NDK_HOME"
export CONAN_CMAKE_ANDROID_NDK="$ANDROID_NDK_HOME"

export CMAKE_MAKE_PROGRAM="$ANDROID_NDK_HOME/prebuilt/linux-x86_64/bin/make"
export CONAN_MAKE_PROGRAM="$CMAKE_MAKE_PROGRAM"
printenv

apt-get update -y -qq
apt-get install -y -qq python3 python3-pip git

pip3 install conan
conan --version

# cross compile profile
mkdir -p ~/.conan/profiles
echo "[settings]" >> ~/.conan/profiles/android
echo "compiler=clang" >> ~/.conan/profiles/android
echo "compiler.version=9" >> ~/.conan/profiles/android
echo "compiler.libcxx=libstdc++11" >> ~/.conan/profiles/android
echo "arch=armv8" >> ~/.conan/profiles/android
echo "os=Android" >> ~/.conan/profiles/android
echo "os.api_level=$TARGET_API" >> ~/.conan/profiles/android
echo "" >> ~/.conan/profiles/android
echo "[env]" >> ~/.conan/profiles/android
echo "CC=$CC" >> ~/.conan/profiles/android
echo "CXX=$CXX" >> ~/.conan/profiles/android
echo "CMAKE_C_COMPILER=CMAKE_C_COMPILER" >> ~/.conan/profiles/android
echo "CMAKE_CXX_COMPILER=CMAKE_CXX_COMPILER" >> ~/.conan/profiles/android
echo "CONAN_CMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake" >> ~/.conan/profiles/android

echo "Adding Mersive's Conan Remote Repository"
conan remote add mersive https://artifactory.mersive.xyz/artifactory/api/conan/conan-mersive
conan user ci-rustusbip -r mersive -p "$ARTIFACTORY_PASSWORD"

function basic_build {
  libraryName="$1"
  libraryVersion="$2"
  relativePath="$3"
  echo "Performing a build of [$libraryName] with version [$libraryVersion]:"
  cd "recipes/$libraryName/$relativePath"

  COORDINATE="$libraryName/$libraryVersion@"
  echo "Installing [$COORDINATE]"
  conan install . "$COORDINATE" --profile android

  echo "Getting sources of [$COORDINATE]"
  conan source .

  echo "Building [$COORDINATE]"
  conan build .

  echo "Exporting [$COORDINATE]"
  conan export-pkg . "$COORDINATE"

  echo "Uploading [$COORDINATE]"
  conan upload "$COORDINATE" --all -c -r mersive

  echo "Done building [$COORDINATE]!"
  cd -
}

basic_build "zlib" "$ZLIB_VERSION" "$ZLIB_VERSION"
basic_build "mbedtls" "$MBEDTLS_VERSION" "all"
