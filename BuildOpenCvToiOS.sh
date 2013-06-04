#!/bin/bash
################################################################################
# Este script irá criar os binários universais para os devices iOS. 
# Como saída você vai obter as bibliotecas estáticas incluindo os headers
# do OpenCV.
################################################################################

if [ $# -ne 2 ]
then
    echo "Error in $0 - Invalid Argument Count"
    echo "Syntax: $0 [OpenCV source directory] [Build destination directory]"
    echo "If the destination directory already exists, it will be overwritten!"
    exit
fi

# Path para o diretório do código fonte
D=`dirname "$1"`
B=`basename "$1"`
SRC="`cd \"$D\" 2>/dev/null && pwd || echo \"$D\"`/$B"

# Path para o diretório de compilação
D=`dirname "$2"`
B=`basename "$2"`
BUILD="`cd \"$D\" 2>/dev/null && pwd || echo \"$D\"`/$B"

INTERMEDIATE=$BUILD/tmp
IOS_DEV_BUILD_DIR=$INTERMEDIATE/ios-dev-build
IOS_SIM_BUILD_DIR=$INTERMEDIATE/ios-sim-build

################################################################################
# Limpa a compilação antiga e recompila a nova.
echo $SRC
echo $BUILD
echo "WARNING: The bulid directory will be removed and re-created again."
echo "WARNING: It's your last chance to check is it correct and you do not have anything valuable in it."
read -p "Press any key to continue..."

#rm -rf $BUILD

################################################################################
# Configurações para compilação de release/debug para dispositivos iOS
mkdir -p $IOS_DEV_BUILD_DIR
pushd $IOS_DEV_BUILD_DIR
cmake -GXcode -DCMAKE_TOOLCHAIN_FILE=$SRC/ios/cmake/Toolchains/Toolchain-iPhoneOS_Xcode.cmake \
-DCMAKE_INSTALL_PREFIX=$INTERMEDIATE/install \
-DOPENCV_BUILD_3RDPARTY_LIBS=YES \
-DBUILD_EXAMPLES=NO \
-DBUILD_TESTS=NO \
-DBUILD_NEW_PYTHON_SUPPORT=NO \
-DBUILD_PERF_TESTS=NO \
-DBUILD_PERF_TESTS=NO \
-DCMAKE_C_FLAGS_RELEASE="-O3 -ffast-math" \
-DCMAKE_CXX_FLAGS_RELEASE="-O3 -ffast-math" \
-DCMAKE_XCODE_ATTRIBUTE_GCC_VERSION="com.apple.compilers.llvmgcc42" $SRC

xcodebuild -sdk iphoneos -configuration Release -target ALL_BUILD
xcodebuild -sdk iphoneos -configuration Release -target install install
xcodebuild -sdk iphoneos -configuration Debug -target ALL_BUILD
popd

################################################################################
# Configurações para compilação de release/debug para simulador iOS
mkdir -p $IOS_SIM_BUILD_DIR
pushd $IOS_SIM_BUILD_DIR
cmake -GXcode -DCMAKE_TOOLCHAIN_FILE=$SRC/ios/cmake/Toolchains/Toolchain-iPhoneSimulator_Xcode.cmake \
-DCMAKE_INSTALL_PREFIX=$INTERMEDIATE/install \
-DOPENCV_BUILD_3RDPARTY_LIBS=YES \
-DBUILD_EXAMPLES=NO \
-DBUILD_TESTS=NO \
-DBUILD_NEW_PYTHON_SUPPORT=NO \
-DBUILD_PERF_TESTS=NO \
-DCMAKE_XCODE_ATTRIBUTE_GCC_VERSION="com.apple.compilers.llvmgcc42" $SRC
xcodebuild -sdk iphonesimulator -configuration Release -target ALL_BUILD
xcodebuild -sdk iphonesimulator -configuration Debug -target ALL_BUILD
popd

################################################################################
# Copia terceira parte das libs para o diretório de libs do opencv
cp -f $IOS_DEV_BUILD_DIR/3rdparty/lib/Debug/*.a   $IOS_DEV_BUILD_DIR/lib/Debug/
cp -f $IOS_DEV_BUILD_DIR/3rdparty/lib/Release/*.a $IOS_DEV_BUILD_DIR/lib/Release/

cp -f $IOS_SIM_BUILD_DIR/3rdparty/lib/Debug/*.a   $IOS_SIM_BUILD_DIR/lib/Debug/
cp -f $IOS_SIM_BUILD_DIR/3rdparty/lib/Release/*.a $IOS_SIM_BUILD_DIR/lib/Release/

################################################################################
# Monta os binários universais para as configurações de release:
mkdir -p $BUILD/lib/Release/

for FILE in `ls $IOS_DEV_BUILD_DIR/lib/Release`
do
  lipo $IOS_DEV_BUILD_DIR/lib/Release/$FILE \
       $IOS_SIM_BUILD_DIR/lib/Release/$FILE \
       -create -output $BUILD/lib/Release/$FILE
done

################################################################################
# Monta os binários universais para as configurações de debug:
mkdir -p $BUILD/lib/Debug/

for FILE in `ls $IOS_DEV_BUILD_DIR/lib/Debug`
do
lipo $IOS_DEV_BUILD_DIR/lib/Debug/$FILE \
$IOS_SIM_BUILD_DIR/lib/Debug/$FILE \
-create -output $BUILD/lib/Debug/$FILE
done

################################################################################
# Copia os headers:
rm -rf $BUILD/include
mv $INTERMEDIATE/install/include $BUILD/include

################################################################################
# Limpeza final
#rm -rf $INTERMEDIATE
echo "All is done"
