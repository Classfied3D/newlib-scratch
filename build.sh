#!/bin/sh

: "${LLVM_PREFIX:=}"
: "${LLVM_SUFFIX:=}"
: "${CC:=${LLVM_PREFIX}clang${LLVM_SUFFIX}}"
: "${LD:=${LLVM_PREFIX}ld.lld${LLVM_SUFFIX}}"
: "${AR:=${LLVM_PREFIX}llvm-ar${LLVM_SUFFIX}}"
: "${RANLIB:=${LLVM_PREFIX}llvm-ranlib${LLVM_SUFFIX}}"
: "${LLVM_LINK:=${LLVM_PREFIX}llvm-link${LLVM_SUFFIX}}"
: "${OPT:=${LLVM_PREFIX}opt${LLVM_SUFFIX}}"
: "${SCRATCHCFLAGS:=}"
: "${LINKED_OPTLEVEL:=0}"

if [ -z "$SCRATCHCFLAGS" ]; then
  SCRATCHCFLAGS="${CFLAGS} --target=arm-none-eabi \
                -m32 -ffreestanding -Os \
                -fno-vectorize -fno-slp-vectorize \
                -fno-stack-protector \
                -emit-llvm -c \
                -nostdlib"
fi

mkdir -p build
mkdir -p build/newlib

if [ ! -d "build/newlib/scratch" ]; then
  # Build newlib
  cd newlib-cygwin/newlib/
  mkdir -p build
  cd build

  CC=$CC LD=$LD AR=$AR RANLIB=$RANLIB CFLAGS="$SCRATCHCFLAGS -Wno-unknown-pragmas -I ../../include/ -I ../libc/include/" \
    ../configure --host=scratch --enable-newlib-elix-level=1 \
    --prefix="$(pwd)/../../../build/newlib"
  make install

  cd ../../..
fi

# Build demo
$CC $SCRATCHCFLAGS \
  -I build/newlib/scratch/include \
  -I sb3api.h \
  demo.c \
  -o build/demo_unlnk.bc

$LLVM_LINK build/demo_unlnk.bc build/newlib/scratch/lib/*.a \
  --only-needed -o build/demo_unopt.bc

$OPT build/demo_unopt.bc \
  -passes="default<O$LINKED_OPTLEVEL>,globaldce" \
  -vectorize-loops=false \
  -vectorize-slp=false \
  -S -o build/demo.ll

llvm2scratch build/demo.ll -o build/demo.sprite3

rm build/demo_unlnk.bc build/demo_unopt.bc
