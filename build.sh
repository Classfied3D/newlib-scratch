#!/bin/sh

: "${LLVM_PREFIX:=}"
: "${LLVM_SUFFIX:=}"
: "${CC:=${LLVM_PREFIX}clang${LLVM_SUFFIX}}"
: "${LD:=${LLVM_PREFIX}ld.lld${LLVM_SUFFIX}}"
: "${AR:=${LLVM_PREFIX}llvm-ar${LLVM_SUFFIX}}"
: "${RANLIB:=${LLVM_PREFIX}llvm-ranlib${LLVM_SUFFIX}}"
: "${LLVM_LINK:=${LLVM_PREFIX}llvm-link${LLVM_SUFFIX}}"
: "${OPT:=${LLVM_PREFIX}opt${LLVM_SUFFIX}}"
: "${L2SFLAGS:=}"
: "${CFLAGS:=}"
: "${SCRATCHCFLAGS:=}"

INPUT=()
OPTLEVEL="z"

while getopts "O:" opt; do
  case $opt in
    O) OPTLEVEL="$OPTARG" ;;
  esac
done

shift $((OPTIND - 1))
INPUTS+=("$@")

if [ ${#INPUTS[@]} -eq 0 ]; then
  INPUTS=("demo.c")
fi

if [ -z "$SCRATCHCFLAGS" ]; then
  SCRATCHCFLAGS="${CFLAGS} --target=arm-none-eabi \
                -m32 -ffreestanding -O${OPTLEVEL} \
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

BC_FILES=()
for src in "${INPUTS[@]}"; do
  bc_name="build/$(basename "${src%.*}").bc"
  $CC $SCRATCHCFLAGS \
    -I build/newlib/scratch/include \
    -I sb3api.h \
    "$src" \
    -o "$bc_name"
  BC_FILES+=("$bc_name")
done

$LLVM_LINK "${BC_FILES[@]}" build/newlib/scratch/lib/*.a \
  --only-needed -o build/output_unopt.bc

# TODO: allow passing in a public api list, or allow compiling a library and make
# a public api list from it's functions
echo "main" > build/public.txt

$OPT build/output_unopt.bc \
  -passes="default<O$OPTLEVEL>,internalize,globaldce" \
  -vectorize-loops=false \
  -vectorize-slp=false \
  -internalize-public-api-file=build/public.txt \
  -S -o build/output.ll

llvm2scratch build/output.ll -o build/output.sb3 \
  --debug-scratch-text=build/output.txt \
  --debug-scratchblocks=build/blocks.txt $L2SFLAGS \

rm "${BC_FILES[@]}" build/output_unopt.bc
