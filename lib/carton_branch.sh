#
# Branch object
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

if [ -z "${_CARTON_BRANCH_SH+set}" ]; then
declare _CARTON_BRANCH_SH=

. carton_util.sh
. carton_channel_list.sh

# Check if a branch name is valid.
# Args: git_dir name
function carton_branch_name_is_valid()
{
    declare -r git_dir="$1";    shift
    carton_assert '[ -d "$git_dir" ]'
    declare -r name="$1";       shift
    GIT_DIR="$git_dir" git check-ref-format "refs/heads/$name" >/dev/null
}

# Load base branch properties.
# Args: git_dir name
declare -r _CARTON_BRANCH_LOAD_BASE='
    declare -r git_dir="$1";    shift
    carton_assert "[ -d \"\$git_dir\" ]"
    declare -r name="$1";   shift
    carton_assert "carton_branch_name_is_valid \"\$git_dir\" \"\$name\""

    declare -A branch=(
        [git_dir]="$git_dir"
        [name]="$name"
    )
'

# Initialize a branch and output its string.
# Args: git_dir name [channel_list]
# Output: branch string
function carton_branch_init()
{
    eval "$_CARTON_BRANCH_LOAD_BASE"
    declare channel_list_str
    if [ $# != 0 ]; then
        channel_list_str="$1"
        shift
    else
        channel_list_str=""
    fi
    carton_assert 'carton_channel_list_is_valid "$channel_list_str"'
    GIT_DIR="${branch[git_dir]}" \
        git config "branch.${branch[name]}.carton-channel-list" \
                   "$channel_list_str"
    GIT_DIR="${branch[git_dir]}" \
        git config "branch.${branch[name]}.carton-tag-list" ""
    carton_arr_print branch
}

# Load a branch.
# Args: branch_str git_dir name
function carton_branch_load()
{
    eval "$_CARTON_BRANCH_LOAD_BASE"
    carton_arr_print branch
}

# Output a branch configuration option value.
# Args: branch_str name
# Output: value
function _carton_branch_config_get()
{
    declare -r branch_str="$1";    shift
    declare -r name="$1";           shift
    declare -A branch
    carton_arr_parse branch <<<"$branch_str"
    GIT_DIR="${branch[git_dir]}" \
        git config --get "branch.${branch[name]}.carton-$name"
}

# Set a branch configuration option value.
# Args: branch_str name value
function _carton_branch_config_set()
{
    declare -r branch_str="$1";    shift
    declare -r name="$1";           shift
    declare -r value="$1";          shift
    declare -A branch
    carton_arr_parse branch <<<"$branch_str"
    GIT_DIR="${branch[git_dir]}" \
        git config "branch.${branch[name]}.carton-$name" "$value"
}

# Get a branch channel list.
# Args: branch_str
# Output: channel list string
function carton_branch_get_channel_list()
{
    declare channel_list_str
    channel_list_str=`_carton_branch_config_get "$1" "channel-list"`
    carton_assert 'carton_channel_list_is_valid "$channel_list_str"'
    echo -n "$channel_list_str"
}

# Set a branch channel list.
# Args: branch_str channel_list_str
function carton_branch_set_channel_list()
{
    declare -r branch_str="$1";         shift
    declare -r channel_list_str="$1";   shift
    carton_assert 'carton_channel_list_is_valid "$channel_list_str"'
    _carton_branch_config_set "$branch_str" "channel-list" "$channel_list_str"
}

# Get a branch tag list.
# Args: branch_str
# Output: tag list string
function carton_branch_get_tag_list()
{
    _carton_branch_config_get "$1" "tag-list"
}

# Set a branch tag list.
# Args: branch_str tag_list_str
function carton_branch_set_tag_list()
{
    _carton_branch_config_set "$1" "tag-list" "$2"
}

fi # _CARTON_BRANCH_SH
