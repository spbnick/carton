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
# Args: _git_dir _name
declare -r _CARTON_BRANCH_LOAD_BASE='
    declare -r _git_dir="$1";    shift
    carton_assert "[ -d \"\$_git_dir\" ]"
    declare -r _name="$1";   shift
    carton_assert "carton_branch_name_is_valid \"\$_name\""

    declare -A _branch=(
        [git_dir]="$_git_dir"
        [name]="$_name"
    )
'

# Initialize a branch.
# Args: _branch_var _git_dir _name
function carton_branch_init()
{
    declare -r _branch_var="$1";    shift
    carton_assert 'carton_is_valid_var_name "$_branch_var"'
    eval "$_CARTON_BRANCH_LOAD_BASE"
    GIT_DIR="${_branch[git_dir]}" \
        git config "branch.${_branch[name]}.carton-channel-list" ""
    carton_arr_copy "$_branch_var" "_branch"
}

# Load a branch.
# Args: _branch_var _git_dir _name
function carton_branch_load()
{
    declare -r _branch_var="$1";    shift
    carton_assert 'carton_is_valid_var_name "$_branch_var"'
    eval "$_CARTON_BRANCH_LOAD_BASE"
    carton_arr_copy "$_branch_var" "_branch"
}

# Get a branch channel list.
# Args: _channel_list_var _branch_var
function carton_branch_get_channel_list()
{
    declare -r _branch_var="$1";    shift
    carton_assert 'carton_is_valid_var_name "$_branch_var"'
    declare -r _channel_list_var="$1";    shift
    carton_assert 'carton_is_valid_var_name "$_channel_list_var"'
    declare -A _branch
    carton_arr_copy _branch "$_branch_var"
    carton_channel_list_init "$_channel_list_var" < <(
        GIT_DIR="${_branch[git_dir]}"
            git config --get \
                "branch.${_branch[name]}.carton-channel-list"
    )
}

# Set a branch channel list.
# Args: _branch_var _channel_list_var
function carton_branch_set_channel_list()
{
    declare -r _branch_var="$1";    shift
    carton_assert 'carton_is_valid_var_name "$_branch_var"'
    declare -r _channel_list_var="$1";    shift
    carton_assert 'carton_is_valid_var_name "$_channel_list_var"'
    declare -A _branch
    carton_arr_copy _branch "$_branch_var"

    GIT_DIR="${_branch[git_dir]}" \
        git config "branch.${_branch[name]}.carton-channel-list" \
                   "`carton_channel_list_print \"\$_channel_list_var\"`"
}

fi # _CARTON_BRANCH_SH
