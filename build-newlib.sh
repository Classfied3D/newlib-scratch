#!/bin/sh

version="newlib-4.6.0"

if [ ! -d "build" ]; then
  mkdir build
  mkdir build/scratch
fi

if [ ! -d "newlib-cygwin" ]; then
  echo "------ Cloning Newlib"
  rm -rf include

  git clone https://sourceware.org/git/newlib-cygwin.git
  if [ ! -d "newlib-cygwin" ]; then
    exit 1
  fi

  cd newlib-cygwin
  git checkout "${version}"
  cd ..
fi

rm -rf build/newlib

echo "------ Building Newlib"
# */ssp/* to disable stack protector
(cd newlib-cygwin && find newlib/libc \
  -name '*.c' \
  ! -path '*/posix/*' \
  ! -path '*/ssp/*' \
  ! -path '*/unix/*' \
  ! -path '*/stdio64/*' \
  ! -path '*/sys/*' \
  ! -path '*/machine/*' \
  ! -path '*/stdio/nano-*' \
  -print0 | while IFS= read -r -d '' file; do
  out="../build/${file%.c}.bc"
  mkdir -p "$(dirname "$out")"
  echo "Compiling $file -> $out"
  clang --target=arm-none-eabi \
        -m32 -ffreestanding -Os \
        -D_LDBL_EQ_DBL \
        -fno-vectorize -fno-slp-vectorize \
        -fno-stack-protector \
        -emit-llvm -c \
        -I include/ \
        -I newlib/libc/include/ \
        "$file" -o "$out"
done
)

llvm-link-mp-19 build/newlib/libc/**/*.bc -o build/newlib_unopt.bc
opt-mp-19 build/newlib_unopt.bc \
  -passes="default<Os>" \
  -vectorize-loops=false \
  -vectorize-slp=false \
  -o build/newlib.bc
rm build/newlib_unopt.bc
