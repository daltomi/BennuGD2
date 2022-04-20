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

EXIT_FAILURE=1
EXIT_SUCCESS=0

function help() {
    echo "====================="
    echo "Usage: bennugd [OPTIONS] [FILE.PRG]"
    echo "Options:"
    echo "  -i   interpreter"
    echo "  -c   compiler"
    echo "  -s   moddesc"
    echo "  -g   run gdb"
    echo "  -v   run valgrind"
    echo "  -h   show help"
    echo; echo " Examples:"
    echo; echo " bennugd file.prg                 (compile and run)"
    echo; echo " bennugd -c file.prg              (compile only)"
    echo; echo " bennugd -c file.prg [OPTIONS]    (compile: with options)"
    echo; echo " bennugd -i mygame.dcb            (interpreter only)"
    echo; echo " bennugd -i mygame.dcb [OPTIONS]  (interpreter: with options)"
    echo; echo " bennugd -g -c file.prg           (run gdb with bgdc)"
    echo; echo " bennugd -g -i mygame.dcb         (run gdb with bgdi)"
    echo; echo " bennugd -v -c file.prg           (run valgrind with bgdc)"
    echo; echo " bennugd -v -i mygame.dcb         (run valgrind with bgdi)"
    echo; echo "====================="
    exit "$EXIT_FAILURE"
}

function check_exist {
    if [ ! -e "$1" ]; then
        echo "$2" "$1"
        exit "$EXIT_FAILURE";
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
        "-g") return "$EXIT_SUCCESS";;
        "-v") return "$EXIT_SUCCESS";;
        "-h") help;;
        *) return "$EXIT_FAILURE";;
    esac
    return "$EXIT_SUCCESS"
}

#========== M A I N ==========#

check_exist "$YOU_BENNUGD_LIBS" "Directory not found: "
check_exist "$YOU_BENNUGD_BINS" "Directory not found: "


function check_gdb {
    exit_if_not_exist_cmd "gdb"

    is_valid_option "$1"

    if [ $? -eq "$EXIT_FAILURE" ]; then
        echo "The -g option requires a valid parameter."
        exit "$EXIT_FAILURE"
    fi
}

function check_valgrind {
    exit_if_not_exist_cmd "valgrind"

    is_valid_option "$1"

    if [ $? -eq "$EXIT_FAILURE" ]; then
        echo "The -v option requires a valid parameter."
        exit "$EXIT_FAILURE"
    fi
}

if [ "$#" -eq 0 ]; then
    help 
fi


if [ "$#" -eq 1 ]; then

    if [ "$1" == "-g" ]; then
        check_gdb "$2"
    fi
    if [ "$1" == "-v" ]; then
        check_valgrind "$2"
    fi

    is_valid_option "$1"
    if [ $? -eq "$EXIT_SUCCESS" ]; then
        "$BIN_SELECT"
    else
        if [ "${1##*.}" == "prg" ]; then
            compile_and_run "$1"
        fi
        help
    fi
else
    is_valid_option "$1"
    if [ $? -eq "$EXIT_SUCCESS" ]; then
        if [ "$1" == "-g" ]; then
            check_gdb "$2"
            shift 2
            gdb --args "$BIN_SELECT" "$@"
            exit $?
        fi
        if [ "$1" == "-v" ]; then
            check_valgrind "$2"
            shift 2
            valgrind "$BIN_SELECT" "$@"
            exit $?
        fi
        shift
        "$BIN_SELECT" "$@"
    else
        help
    fi
fi

exit "$EXIT_SUCCESS"
