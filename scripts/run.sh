#!/usr/bin/bash

set -e

args=("")
display=":2.0"
size="1800x1000"
debug="1"
awesome_config=""
awesome_bin=""
awesome_libs=()

function error() {
    echo "Error: $1" >&2
    exit "${2:-1}"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
    -c | --config)
        awesome_config="$2"
        shift
        shift
        ;;
    -b | --bin)
        awesome_bin="$2"
        shift
        shift
        ;;
    -l | --lib)
        awesome_libs+=("$2")
        shift
        shift
        ;;
    -d | --display)
        display="$2"
        shift
        shift
        ;;
    -s | --size)
        size="$2"
        shift
        shift
        ;;
    -n | --no-debug)
        debug=""
        shift
        ;;
    -*)
        error "Unknown option $1" 2
        ;;
    *)
        args+=("$1")
        shift
        ;;
    esac
done

if [[ -z "$awesome_config" ]]; then
    error "Missing rc.lua path"
fi
if [[ -z "$awesome_bin" ]]; then
    error "Missing bin path"
fi
if [[ ${#awesome_libs[@]} -eq 0 ]]; then
    error "Missing lib path"
fi

echo "Starting Xephyr (display=$display, size=$size)"
Xephyr "$display" -ac -br -noreset -screen "$size" &
xephyr_pid=$!
while ! DISPLAY="$display" xset q &>/dev/null; do sleep 0.1; done
echo "Xephyr pid: $xephyr_pid"

echo "Awesome bin: $awesome_bin"
echo "Awesome libs: ${awesome_libs[*]}"
echo "Awesome config: $awesome_config"
echo "Starting awesome"
echo "================================================================"
DEBUG="$debug" DISPLAY="$display" "$awesome_bin" -c "$awesome_config" -s "${awesome_libs[@]}"
echo "================================================================"
echo "Stopping Xephyr"
kill $xephyr_pid &>/dev/null
