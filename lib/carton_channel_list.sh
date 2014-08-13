#
# Channel list
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

if [ -z "${_CARTON_CHANNEL_LIST_SH+set}" ]; then
declare _CARTON_CHANNEL_LIST_SH=

. carton_util.sh
. carton_channel.sh
. thud_misc.sh

# Check if a channel list string is valid.
# Args: channel_list_str
function carton_channel_list_is_valid()
{
    declare -r channel_list_str="$1";   shift
    declare -a channel_list=()
    declare channel
    read -r -a channel_list <<<"$channel_list_str"
    if [ "${#channel_list[@]}" != 0 ]; then
        for channel in "${channel_list[@]}"; do
            if ! carton_channel_is_valid "$channel"; then
                return 1
            fi
        done
    fi
    return 0
}

# Get channel list and revision variable name from arguments.
# Args: channel_list_str rev_str
declare -r _CARTON_CHANNEL_LIST_GET_WITH_REV_STR='
    declare -r channel_list_str="$1";   shift
    thud_assert "carton_channel_list_is_valid \"\$channel_list_str\""
    declare -r rev_str="$1";   shift
    declare -a channel_list=()
    read -r -a channel_list <<<"$channel_list_str"
'

# Check if a revision is suitable for publishing through a channel list.
# Args: channel_list_str rev_str
function carton_channel_list_is_applicable()
{
    eval "$_CARTON_CHANNEL_LIST_GET_WITH_REV_STR"
    declare channel
    if [ "${#channel_list[@]}" != 0 ]; then
        for channel in "${channel_list[@]}"; do
            if carton_channel_is_applicable "$channel" "$rev_str"; then
                return 0
            fi
        done
    fi
    return 1
}

# Check if a revision is published in a channel list.
# Args: channel_list_str rev_str
function carton_channel_list_is_published()
{
    eval "$_CARTON_CHANNEL_LIST_GET_WITH_REV_STR"
    thud_assert 'carton_channel_list_is_applicable "$channel_list_str" \
                                                     "$rev_str"'
    declare channel
    if [ "${#channel_list[@]}" != 0 ]; then
        for channel in "${channel_list[@]}"; do
            if carton_channel_is_applicable "$channel" "$rev_str" &&
               ! carton_channel_is_published "$channel" "$rev_str"; then
                return 1
            fi
        done
    fi
    return 0
}

# Publish a revision in a channel list.
# Args: channel_list_str rev_str
function carton_channel_list_publish()
{
    eval "$_CARTON_CHANNEL_LIST_GET_WITH_REV_STR"
    thud_assert 'carton_channel_list_is_applicable "$channel_list_str" \
                                                     "$rev_str"'
    thud_assert '! carton_channel_list_is_published "$channel_list_str" \
                                                      "$rev_str"'
    declare channel
    if [ "${#channel_list[@]}" != 0 ]; then
        for channel in "${channel_list[@]}"; do
            if carton_channel_is_applicable "$channel" "$rev_str"; then
               carton_channel_publish "$channel" "$rev_str"
            fi
        done
    fi
}

# Ensure a revision is published in a channel list, i.e. publish, if it isn't.
# Args: channel_list_str rev_str
function carton_channel_list_ensure_published()
{
    eval "$_CARTON_CHANNEL_LIST_GET_WITH_REV_STR"
    thud_assert 'carton_channel_list_is_applicable "$channel_list_str" \
                                                     "$rev_str"'
    declare channel
    if [ "${#channel_list[@]}" != 0 ]; then
        for channel in "${channel_list[@]}"; do
            if carton_channel_is_applicable "$channel" "$rev_str"; then
               carton_channel_ensure_published "$channel" "$rev_str"
            fi
        done
    fi
}

# Withdraw (remove) a revision from a channel list.
# Args: channel_list_str rev_str
function carton_channel_list_withdraw()
{
    eval "$_CARTON_CHANNEL_LIST_GET_WITH_REV_STR"
    thud_assert 'carton_channel_list_is_applicable "$channel_list_str" \
                                                     "$rev_str"'
    thud_assert 'carton_channel_list_is_published "$channel_list_str" \
                                                    "$rev_str"'
    declare channel
    if [ "${#channel_list[@]}" != 0 ]; then
        for channel in "${channel_list[@]}"; do
            if carton_channel_is_applicable "$channel" "$rev_str"; then
               carton_channel_withdraw "$channel" "$rev_str"
            fi
        done
    fi
}

fi # _CARTON_CHANNEL_LIST_SH
