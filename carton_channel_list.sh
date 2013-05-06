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

# Initialize a channel list.
# Args: _channel_list_var
# Input: channels, separated by space
function carton_channel_list_init()
{
    declare -r _channel_list_var="$1";  shift
    carton_assert 'carton_is_valid_var_name "$_channel_list_var"'
    read -r -a "$_channel_list_var"
}

# Print a channel list.
# Args: _channel_list_var
# Output: channels, separated by space
function carton_channel_list_print()
{
    declare -r _channel_list_var="$1";  shift
    carton_assert 'carton_is_valid_var_name "$_channel_list_var"'
    declare -a _channel_list
    carton_arr_copy _channel_list "$_channel_list_var"
    echo -n "${_channel_list[*]}"
}

# Get channel list and revision variable name from arguments.
# Args: _channel_list_var _rev_var
declare -r _CARTON_CHANNEL_LIST_GET_WITH_REV_VAR='
    declare -r _channel_list_var="$1";   shift
    carton_assert "carton_var_name_is_valid \"\$_channel_list_var\""
    declare -r _rev_var="$1";   shift
    carton_assert "carton_is_valid_var_name \"\$_rev_var\""
    declare -a _channel_list
    carton_arr_copy channel_list "$_channel_list_var"
'

# Check if a revision is suitable for publishing through a channel list.
# Args: _channel_list_var _rev_var
function carton_channel_list_is_applicable()
{
    eval "$_CARTON_CHANNEL_LIST_GET_WITH_REV_VAR"
    declare _channel
    for _channel in "${_channel_list[@]}"; do
        if carton_channel_is_applicable _channel "$_rev_var"; then
            return 0
        fi
    done
    return 1
}

# Check if a revision is published in a channel list.
# Args: _channel_list_var _rev_var
function carton_channel_list_is_published()
{
    eval "$_CARTON_CHANNEL_LIST_GET_WITH_REV_VAR"
    carton_assert 'carton_channel_list_is_applicable "$_channel_list_var" \
                                                     "$_rev_var"'
    declare _channel
    for _channel in "${_channel_list[@]}"; do
        if carton_channel_is_applicable "$_channel" "$_rev_var" &&
           ! carton_channel_is_published "$_channel" "$_rev_var"; then
            return 1
        fi
    done
    return 0
}

# Publish a revision in a channel list.
# Args: _channel_list_var _rev_var
function carton_channel_list_publish()
{
    eval "$_CARTON_CHANNEL_LIST_GET_WITH_REV_VAR"
    carton_assert 'carton_channel_list_is_applicable "$_channel_list_var" \
                                                     "$_rev_var"'
    carton_assert '! carton_channel_list_is_published "$_channel_list_var" \
                                                      "$_rev_var"'
    declare _channel
    for _channel in "${_channel_list[@]}"; do
        if carton_channel_is_applicable "$_channel" "$_rev_var"; then
           carton_channel_publish "$_channel" "$_rev_var"
        fi
    done
}

# Withdraw (remove) a revision from a channel list.
# Args: _channel_list_var _rev_var
function carton_channel_list_withdraw()
{
    eval "$_CARTON_CHANNEL_LIST_GET_WITH_REV_VAR"
    carton_assert 'carton_channel_list_is_applicable "$_channel_list_var" \
                                                     "$_rev_var"'
    carton_assert 'carton_channel_list_is_published "$_channel_list_var" \
                                                    "$_rev_var"'
    declare _channel
    for _channel in "${_channel_list[@]}"; do
        if carton_channel_is_applicable "$_channel" "$_rev_var"; then
           carton_channel_withdraw "$_channel" "$_rev_var"
        fi
    done
}

fi # _CARTON_CHANNEL_LIST_SH
