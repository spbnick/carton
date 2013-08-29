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

. thud_misc.sh

# Check if a string is suitable for use in a data sub-directory path.
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

# Output an (associative) array.
# Args: _var
# Output: the array with keys and values on separate lines with newlines
#         and backslashes escaped, terminated by a "*"
function carton_arr_print()
{
    declare -r _var="$1"
    thud_assert 'carton_is_valid_var_name "$_var"'
    declare -r _bs='\'
    declare _k
    declare _v
    eval "
        for _k in \"\${!$_var[@]}\"; do
            _v=\"\${$_var[\$_k]}\"
            _k=\"\${_k//\\\\/\$_bs\$_bs}\"
            _v=\"\${_v//\\\\/\$_bs\$_bs}\"
            echo \"\${_k//\$'\\n'/\\\\n}\"
            echo \"\${_v//\$'\\n'/\\\\n}\"
        done
        echo \"*\"
    "
}

# Parse an (associative) array from a format output by carton_arr_print.
# Args: _var
# Input: the array in carton_arr_print output format: keys and values on
#        separate lines with newlines and backslashes escaped, terminated by a
#        "*".
function carton_arr_parse()
{
    declare -r _var="$1"
    thud_assert 'carton_is_valid_var_name "$_var"'
    declare _k
    declare _v
    eval "
        $_var=()
        while IFS='' read -r _k && [ \"\$_k\" != \"*\" ]; do
            IFS='' read -r _v || break
            printf -v _k '%b' \"\$_k\"
            printf -v _v '%b' \"\$_v\"
            $_var[\$_k]=\"\$_v\"
        done
    "
}

fi # _CARTON_UTIL_SH
