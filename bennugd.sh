#!/bin/bash
#
#  Helper of bgdc, bgdi and moddesc
#
#  The most useful way to use this script is: "bennugd file.prg",
#  compile and run at the same time.
#
#  Tips:
#   a) bennugd.sh -h
#
#   b) ln -s $(pwd)/bennugd.sh  ~/.local/bin/bennugd
#
#   c) alias bennugd=/home/a/b/bennugd.sh
#
#  Author: github.com/daltomi

#======================================
# Replace $MY_BENNUGD_xxxx with the *absolute* path.

YOU_BENNUGD_LIBS="$MY_BENNUGD_LIBS"

YOU_BENNUGD_BINS="$MY_BENNUGD_BINS"

#======================================

# < Warning: do not edit from hare >

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$YOU_BENNUGD_LIBS

export PATH=$PATH:$YOU_BENNUGD_BINS

function help() {
    echo "====================="
    echo "Usage: bennugd [OPTIONS] [FILE.PRG]"
    echo "Options:"
    echo "  -i   interpreter"
    echo "  -c   compiler"
    echo "  -s   moddesc"
    echo "  -g   run gdb"
    echo "  -h   show help"
    echo
    echo " Examples:"
    echo " bennugd file.prg               (compile and run)"
    echo " bennugd -c file.prg            (compile only)"
    echo " bennugd -c file.prg -o mygame  (compile with options)"
    echo " bennugd -i mygame.dcb          (interpreter)"
    echo " bennugd -g -c file.prg         (run gdb with bgdc)"
    echo " bennugd -g -i mygame.dcb       (run gdb with bgdi)"
    echo "====================="
    exit 1
}

function check_exist {
    if [ ! -e "$1" ]; then
        echo "$2" "$1"
        exit 1;
    fi
}

function get_bennugd_ver {
    local VER="$(bgdc | head -n 1 | cut -c6)"
    return "${VER%%.*}"
}

function compile_and_run {
    get_bennugd_ver

    if [ "$?" == "1" ]; then
        # Old BennuGD - 1.x
        bgdc "$1" && exit
        bgdi "${1%.*}.dcb"
    else
        bgdc "$1" && bgdi "${1%.*}.dcb"
    fi
    exit $?
}


function is_valid_option {
    case "$1" in
        "-c") BIN_SELECT="bgdc";;
        "-i") BIN_SELECT="bgdi";;
        "-s") BIN_SELECT="moddesc";;
        "-g") return 1;;
        "-h") help;;
        *) return 0
    esac
    return 1
}

#========== M A I N ==========#

check_exist "$YOU_BENNUGD_LIBS" "Directory not found: "
check_exist "$YOU_BENNUGD_BINS" "Directory not found: "


function check_gdb {
    command -v gdb 1>/dev/null
    if [ $? -eq 1 ]; then
        echo "Command gdb not found."
        exit 1
    fi

    is_valid_option "$1"

    if [ $? -eq 0 ]; then
        echo "The -g option requires a valid parameter."
        exit 1
    fi
}


if [ "$#" -eq 0 ]; then
    help 
fi


if [ "$#" -eq 1 ]; then

    if [ "$1" == "-g" ]; then
        check_gdb "$2"
    fi

    is_valid_option "$1"
    if [ $? -eq 1 ]; then
        "$BIN_SELECT"
    else
        if [ "${1##*.}" == "prg" ]; then
            compile_and_run "$1"
        fi
        help
    fi
else
    is_valid_option "$1"
    if [ $? -eq 1 ]; then
        if [ "$1" == "-g" ]; then
            check_gdb "$2"
            shift 2
            gdb --args "$BIN_SELECT" "$@"
            exit 0
        fi
        shift
        "$BIN_SELECT" "$@"
    else
        help
    fi
fi

exit 0
