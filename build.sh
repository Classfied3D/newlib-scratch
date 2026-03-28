#!/bin/sh

if [ ! -d "build" ]; then
  mkdir build
  mkdir build/scratch
fi

if [ ! -d "newlib-cygwin" ]; then
  echo "Newlib not found. Please run build-newlib.sh first."
  exit 1
fi

clang --target=arm-none-eabi \
      -m32 -ffreestanding -Os \
      -D_LDBL_EQ_DBL \
      -fno-vectorize -fno-slp-vectorize \
      -fno-stack-protector \
      -emit-llvm -c \
      -I newlib-cygwin/include \
      -I newlib-cygwin/newlib/libc/include/ \
      demo.c \
      -o build/demo_unlnk.bc

linked_optlevel="0" # -Os optimizes away stdlib calls

llvm-nm-mp-19 build/demo_unlnk.bc | grep ' T ' | awk '{print $3}' > build/symbols.txt
llvm-link-mp-19 build/demo_unlnk.bc build/newlib.bc --only-needed -o build/demo_unopt.bc
opt-mp-19 build/demo_unopt.bc \
  --internalize-public-api-file=build/symbols.txt \
  -passes="default<O$linked_optlevel>,internalize,globaldce" \
  -vectorize-loops=false \
  -vectorize-slp=false \
  -S -o build/demo.ll
llvm2scratch build/demo.ll --output build/scratch/demo.sprite3

rm build/demo_unlnk.bc
rm build/demo_unopt.bc
