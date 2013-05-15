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
# Args: channel rev_str
declare -r _CARTON_CHANNEL_GET_WITH_REV_STR='
    declare -r channel="$1";   shift
    carton_assert "carton_channel_is_valid \"\$channel\""
    declare -r rev_str="$1";   shift
    declare -r channel_repo_name="${channel%%/*}"
    declare -r channel_ver_regex="${channel:${#channel_repo_name}+1}"
'

# Check if a revision is suitable for publishing through a channel.
# Args: channel rev_str
function carton_channel_is_applicable()
{
    eval "$_CARTON_CHANNEL_GET_WITH_REV_STR"
    declare -A rev
    carton_arr_parse rev <<<"$rev_str"
    [[ "$channel_ver_regex" == "" ||
       "${rev[num]}" == 0 && "${rev[ver]}" =~ $channel_ver_regex ]]
}

# Check if a revision is published in a channel.
# Args: channel rev_str
function carton_channel_is_published()
{
    eval "$_CARTON_CHANNEL_GET_WITH_REV_STR"
    carton_assert 'carton_channel_is_applicable "$channel" "$rev_str"'
    declare repo_str
    repo_str=`carton_repo_list_get_repo "$channel_repo_name"`
    carton_repo_is_published "$repo_str" "$rev_str"
}

# Publish a revision in a channel.
# Args: channel rev_str
function carton_channel_publish()
{
    eval "$_CARTON_CHANNEL_GET_WITH_REV_STR"
    carton_assert 'carton_channel_is_applicable "$channel" "$rev_str"'
    carton_assert '! carton_channel_is_published "$channel" "$rev_str"'
    declare repo_str
    repo_str=`carton_repo_list_get_repo "$channel_repo_name"`
    carton_repo_publish "$repo_str" "$rev_str"
}

# Withdraw (remove) a revision from a channel.
# Args: channel rev_str
function carton_channel_withdraw()
{
    eval "$_CARTON_CHANNEL_GET_WITH_REV_STR"
    carton_assert 'carton_channel_is_applicable "$channel" "$rev_str"'
    carton_assert 'carton_channel_is_published "$channel" "$rev_str"'
    declare repo_str
    repo_str=`carton_repo_list_get_repo "$channel_repo_name"`
    carton_repo_withdraw "$repo_str" "$rev_str"
}

fi # _CARTON_CHANNEL_SH
