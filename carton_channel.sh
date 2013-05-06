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
. carton_rev.sh

# Check if a string is a valid channel.
# Args: str
function carton_channel_is_valid()
{
    declare -r str="$1";    shift
    [[ "$str" != *' '* ]] &&
        carton_repo_list_is_valid_name "${str%%/*}"
}

# Get channel and revision variable name from arguments.
# Args: _channel _rev_var
declare -r _CARTON_CHANNEL_GET_WITH_REV_VAR='
    declare -r _channel="$1";   shift
    carton_assert "carton_channel_is_valid \"\$_channel\""
    declare -r _rev_var="$1";   shift
    carton_assert "carton_is_valid_var_name \"\$_rev_var\""
    declare -r _channel_repo_name="${channel%%/*}"
    declare -r _channel_ver_regex="${channel#*/}"
'

# Check if a revision is suitable for publishing through a channel.
# Args: _channel _rev_var
function carton_channel_is_applicable()
{
    eval "$_CARTON_CHANNEL_GET_WITH_REV_VAR"
    declare -A _rev
    carton_arr_copy _rev "$_rev_var"
    [[ "$_channel_ver_regex" == "" ||
       "${_rev[num]}" == 0 && "${_rev[ver]}" =~ $_channel_ver_regex ]]
}

# Check if a revision is published in a channel.
# Args: _channel _rev_var
function carton_channel_is_published()
{
    eval "$_CARTON_CHANNEL_GET_WITH_REV_VAR"
    carton_assert 'carton_channel_is_applicable "$_channel" "$_rev_var"'
    declare -A _repo
    carton_repo_list_get_repo _repo "$_channel_repo_name"
    carton_repo_is_published _repo "$_rev_var"
}

# Publish a revision in a channel.
# Args: _channel _rev_var
function carton_channel_publish()
{
    eval "$_CARTON_CHANNEL_GET_WITH_REV_VAR"
    carton_assert 'carton_channel_is_applicable "$_channel" "$_rev_var"'
    carton_assert '! carton_channel_is_published "$_channel" "$_rev_var"'
    declare -A _repo
    carton_repo_list_get_repo _repo "$_channel_repo_name"
    carton_repo_publish _repo "$_rev_var"
}

# Withdraw (remove) a revision from a channel.
# Args: _channel _rev_var
function carton_channel_withdraw()
{
    eval "$_CARTON_CHANNEL_GET_WITH_REV_VAR"
    carton_assert 'carton_channel_is_applicable "$_channel" "$_rev_var"'
    carton_assert 'carton_channel_is_published "$_channel" "$_rev_var"'
    declare -A _repo
    carton_repo_list_get_repo _repo "$_channel_repo_name"
    carton_repo_withdraw _repo "$_rev_var"
}

fi # _CARTON_CHANNEL_SH
