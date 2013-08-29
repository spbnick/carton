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

fi # _CARTON_UTIL_SH
