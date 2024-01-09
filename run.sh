#!/bin/bash

# Get the path to the script.
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Concatenate path to the binary.
prog_path="$script_dir/bin/prog"

# Run the binary with NVIDIA Graphics.
prime-run "$prog_path"
