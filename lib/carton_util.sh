#
# Carton miscellaneous functions and variables
#
# Copyright (c) 2013 Red Hat, Inc. All rights reserved.
#
# This copyrighted material is made available to anyone wishing
# to use, modify, copy, or redistribute it subject to the terms
# and conditions of the GNU General Public License version 2.
#
# This program is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
# PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public
# License along with this program; if not, write to the Free
# Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
# Boston, MA 02110-1301, USA.

if [ -z "${_CARTON_UTIL_SH+set}" ]; then
declare _CARTON_UTIL_SH=

CARTON_ENV=`carton-env`
eval "$CARTON_ENV"

# Unindent text by removing at most the number of spaces present in the first
# non-empty line from the beginning of every line.
# Input: indented text
# Output: unindented text
function carton_unindent()
{
    awk --re-interval '
        BEGIN {
            p = ""
        }
        {
            l = $0
            if (l != "") {
                if (p == "")
                    p = "^ {0," (match(l, /[^ ]/) - 1) "}"
                sub(p, "", l)
            }
            print l
        }
    '
}

# Abort shell, optionally outputting a message to stderr.
# Args: [echo_arg]...
function carton_abort()
{
    if [ $# != 0 ]; then
        echo "$@" >&2
    fi
    exit 1
}

# Evaluate and execute a command string, abort shell if unsuccessfull.
# Args: [eval_arg]...
function carton_assert()
{
    eval "$@" || carton_abort "Assertion failed: $@"
}

# Check if a string is a valid filesystem name.
# Args: str
function carton_is_valid_fs_name()
{
    declare -r str="$1"
    [[ "$str" =~ ^[A-Za-z0-9_-]+$ ]]
}

# Check if a string is a valid variable name.
# Args: name
function carton_is_valid_var_name()
{
    declare -r str="$1"
    [[ "$1" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]
}

# Copy (associative) array contents.
# Args: _dst _src
function carton_arr_copy()
{
    declare _dst="$1";  shift
    declare _src="$1";  shift
    declare _k

    eval "
        $_dst=()
        for _k in \"\${!$_src[@]}\"; do
            $_dst[\$_k]=\"\${$_src[\$_k]}\"
        done
    "
}

# Output an (associative) array.
# Args: _var
# Output: the array with keys and values on separate lines with newlines
#         and backslashes escaped
function carton_arr_print()
{
    declare -r _var="$1"
    carton_assert 'carton_is_valid_var_name "$_var"'
    declare -r _bs='\'
    declare _k
    declare _v
    eval "
        for _k in \"\${!$_var[@]}\"; do
            _k=\"\${_k//\$_bs/\$_bs\$_bs}\"
            _v=\"\${$_var[\$_k]//\$_bs/\$_bs\$_bs}\"
            echo \"\${_k//\$'\\n'/\\\\n}\"
            echo \"\${_v//\$'\\n'/\\\\n}\"
        done
    "
}

# Parse an (associative) array from a format output by carton_arr_print.
# Args: _var
# Input: the array in carton_arr_print output format: keys and values on
#        separate lines with newlines and backslashes escaped
function carton_arr_parse()
{
    declare -r _var="$1"
    carton_assert 'carton_is_valid_var_name "$_var"'
    declare -r _bs='\'
    declare _k
    declare _v
    eval "
        while IFS='' read -r _k; do
            IFS='' read -r _v || break
            _k=\"\${_k//\\\\n/\$'\\n'}\"
            _v=\"\${_v//\\\\n/\$'\\n'}\"
            _k=\"\${_k//\$_bs\$_bs/\$_bs}\"
            _v=\"\${_v//\$_bs\$_bs/\$_bs}\"
            $_var[\$_k]=\"\$_v\"
        done
    "
}

fi # _CARTON_UTIL_SH
