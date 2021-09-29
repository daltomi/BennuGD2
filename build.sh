#!/bin/bash
# Author: github.com/daltomi

BUILD_DIR=build/linux
BUILD_TYPE=Debug
PACKAGE_NAME=bennugd2-gnu-linux.tar.bz2
EXIT_FAILURE=1
EXIT_SUCCESS=0


function show_help() {
    echo "---------------------"
    echo "Usage: ./build.sh [OPTIONS]"
    echo
    echo "Compilation *starts by default* (with the debugging symbols) if none of"
    echo "the following options are specified."
    echo
    echo "Options:"
    echo "  submodules      Initialize git submodule and compile it."
    echo "  clean           Delete the build/ directory, don't touch the submodules."
    echo "  release         Not compiled with debug symbols."
    echo "  package         Create a compressed build/ file named $PACKAGE_NAME"
    echo "  scan            Run 'scan-build make'"
    echo "  help            Show help and exit."
    echo "---------------------"
}

function show_help_and_exit {
    show_help
    exit "$EXIT_SUCCESS"
}


function check_if_exist_sdl_gpu {
    if [ ! -e vendor/sdl-gpu/SDL_gpu/lib/libSDL2_gpu.so ]; then
        echo "Cannot find SDL_gpu."
        echo "You need to run: ./build.sh submodules"
        exit "$EXIT_FAILURE"
    fi
}

function check_if_exist_cmd {
    command -v "$1" 1>/dev/null
    if [ $? -eq "$EXIT_FAILURE" ]; then
        echo "Program '$1' not found."
        return "$EXIT_FAILURE"
    fi
    return "$EXIT_SUCCESS"
}

function exit_if_not_exist_cmd {
    check_if_exist_cmd "$1"
    if [ $? -eq "$EXIT_FAILURE" ]; then
        exit "$EXIT_FAILURE"
    fi
}

function exit_bad_option_argv {
    echo "The option is not recognized: $1"
    show_help
    exit "$EXIT_FAILURE"
}

function prologue_build_tools {
    exit_if_not_exist_cmd "git"
    exit_if_not_exist_cmd "make"
    exit_if_not_exist_cmd "cmake"
    check_if_exist_cmd "gcc"
    if [ $? -eq "$EXIT_FAILURE" ]; then
        exit_if_not_exist_cmd "clang"
    fi
}

function prologue_argv {
    case "$1" in
        "scan") SCAN_BUILD="scan-build"; exit_if_not_exist_cmd "$SCAN_BUILD";;
        "submodules") return "$EXIT_SUCCESS";;
        "clean") return "$EXIT_SUCCESS";;
        "release") BUILD_TYPE=Release;;
        "package") return "$EXIT_SUCCESS";;
        "help") show_help_and_exit;;
        *) exit_bad_option_argv "$1";;
    esac
}

#========== M A I N ==========#


if [ ! -z "$1" ]; then
    prologue_argv "$1"
fi

prologue_build_tools

if [ "$1" == "clean" ]; then
    echo "Cleaning build/ ..."
    rm -rf build
    exit "$EXIT_SUCCESS"
fi

if [ "$1" == "submodules" ]; then
    echo "Cloning... this may take a while..."
    git submodule init
    git submodule update
    cd vendor/sdl-gpu/ || exit "$EXIT_FAILURE"
    cmake -G "Unix Makefiles" -DBUILD_DEMOS=NO -DBUILD_STATIC=NO || exit "$EXIT_FAILURE"
    make || exit "$EXIT_FAILURE"
    cd - || exit "$EXIT_FAILURE"
    exit "$EXIT_SUCCESS"
fi

if [ "$1" == "package" ]; then
    if [ ! -e "$BUILD_DIR" ] || [ ! -e "$BUILD_DIR"/bin ] ; then
        echo "Cannot find directory $BUILD_DIR for packaging."
        echo "You need to run: ./build.sh"
        exit "$EXIT_FAILURE"
    fi

    exit_if_not_exist_cmd "tar"
    exit_if_not_exist_cmd "xz"

    check_if_exist_sdl_gpu

    if [ -e "$PACKAGE_NAME" ]; then
        read -r -p "The package already exists, do you want to remove it? y/n: " YESNO
        if [ "$YESNO" == "y" ] || [ "$YESNO" == "Y" ]; then
            rm -v "$PACKAGE_NAME"
        else
            if [ "$YESNO" != "n" ] && [ "$YESNO" != "N" ]; then
                echo "You did not answer correctly, leaving."
            fi
            echo "Cancel."
            exit "$EXIT_FAILURE"
        fi
    fi

    echo "Packaging... $PACKAGE_NAME"

    DIRTMP=$(mktemp -d packXXXX)
    PACKDIR="$DIRTMP/${PACKAGE_NAME%%.*}"
    PACKBIN="$PACKDIR/BennuGD"

    mkdir -p "$PACKBIN" || exit "$EXIT_FAILURE"
    cp "$BUILD_DIR"/bin/* "$PACKBIN" || exit "$EXIT_FAILURE"
    cp vendor/sdl-gpu/SDL_gpu/lib/*.so "$PACKBIN"
    cp LICENSE WhatsNew.txt "$PACKBIN"
    cp bennugd.sh LICENSE README.md "$PACKDIR"
    sed 's/\$MY_BENNUGD_LIBS/.\/BennuGD:..\/BennuGD/g' -i "$PACKDIR/bennugd.sh"
    sed 's/\$MY_BENNUGD_BINS/.\/BennuGD:..\/BennuGD/g' -i "$PACKDIR/bennugd.sh"
    sed '/^check_exist/I,+2 d' -i "$PACKDIR/bennugd.sh"
    cd "$DIRTMP" || exit "$EXIT_FAILURE"
    tar cJf "$PACKAGE_NAME" "${PACKAGE_NAME%%.*}"
    if [ $? == "$EXIT_FAILURE" ]; then
        echo "Failure."
        exit "$EXIT_FAILURE"
    fi
    cd - || exit "$EXIT_FAILURE"
    mv "$DIRTMP/$PACKAGE_NAME" .
    rm -rf "$DIRTMP"
    echo "Done."
    echo "Size: $(ls -sh $PACKAGE_NAME)"
    exit "$EXIT_SUCCESS"
fi

#========== B U I L D  ==========#

check_if_exist_sdl_gpu

export EXTRA_CFLAGS=-DUSE_SDL2_GPU

mkdir -p "$BUILD_DIR" 2>/dev/null

echo "### Building BennuGD (unofficial, only GNU/Linux) ###"

cd "$BUILD_DIR" || exit "$EXIT_FAILURE"

cmake -DCMAKE_BUILD_TYPE="$BUILD_TYPE" -DUSE_SDL2_GPU=1 ../.. || exit "$EXIT_FAILURE"

if [ ! -z "$SCAN_BUILD" ]; then
    "$SCAN_BUILD" make || exit "$EXIT_FAILURE"
else
    make || exit "$EXIT_FAILURE"
fi

cd - || exit "$EXIT_FAILURE"

echo
echo "### Build done! ###"
echo
echo " - Build type: $BUILD_TYPE"
echo " - Bins and Libs: $(pwd)/$BUILD_DIR/bin"
echo

exit "$EXIT_SUCCESS"
