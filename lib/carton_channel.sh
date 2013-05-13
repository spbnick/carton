#
# Channel object
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

if [ -z "${_CARTON_CHANNEL_SH+set}" ]; then
declare _CARTON_CHANNEL_SH=

. carton_util.sh
. carton_repo_list.sh

# Check if a string is a valid channel.
# Args: str
function carton_channel_is_valid()
{
    declare -r str="$1";    shift
    [[ "$str" != *' '* ]] &&
        carton_repo_list_is_valid_name "${str%%/*}"
}

# Get channel and revision variable name from arguments.
# Args: __channel __rev_var
declare -r _CARTON_CHANNEL_GET_WITH_REV_VAR='
    declare -r __channel="$1";   shift
    carton_assert "carton_channel_is_valid \"\$__channel\""
    declare -r __rev_var="$1";   shift
    carton_assert "carton_is_valid_var_name \"\$__rev_var\""
    declare -r __channel_repo_name="${__channel%%/*}"
    declare -r __channel_ver_regex="${__channel:${#__channel_repo_name}+1}"
'

# Check if a revision is suitable for publishing through a channel.
# Args: __channel __rev_var
function carton_channel_is_applicable()
{
    eval "$_CARTON_CHANNEL_GET_WITH_REV_VAR"
    declare -A __rev
    carton_arr_copy __rev "$__rev_var"
    [[ "$__channel_ver_regex" == "" ||
       "${__rev[num]}" == 0 && "${__rev[ver]}" =~ $__channel_ver_regex ]]
}

# Check if a revision is published in a channel.
# Args: __channel __rev_var
function carton_channel_is_published()
{
    eval "$_CARTON_CHANNEL_GET_WITH_REV_VAR"
    carton_assert 'carton_channel_is_applicable "$__channel" "$__rev_var"'
    declare -A __repo
    carton_repo_list_get_repo __repo "$__channel_repo_name"
    carton_repo_is_published __repo "$__rev_var"
}

# Publish a revision in a channel.
# Args: __channel __rev_var
function carton_channel_publish()
{
    eval "$_CARTON_CHANNEL_GET_WITH_REV_VAR"
    carton_assert 'carton_channel_is_applicable "$__channel" "$__rev_var"'
    carton_assert '! carton_channel_is_published "$__channel" "$__rev_var"'
    declare -A __repo
    carton_repo_list_get_repo __repo "$__channel_repo_name"
    carton_repo_publish __repo "$__rev_var"
}

# Withdraw (remove) a revision from a channel.
# Args: __channel __rev_var
function carton_channel_withdraw()
{
    eval "$_CARTON_CHANNEL_GET_WITH_REV_VAR"
    carton_assert 'carton_channel_is_applicable "$__channel" "$__rev_var"'
    carton_assert 'carton_channel_is_published "$__channel" "$__rev_var"'
    declare -A __repo
    carton_repo_list_get_repo __repo "$__channel_repo_name"
    carton_repo_withdraw __repo "$__rev_var"
}

fi # _CARTON_CHANNEL_SH
