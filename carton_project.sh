#
# Carton project management
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

if [ -z "${_CARTON_PROJECT_SH+set}" ]; then
declare _CARTON_PROJECT_SH=

. carton_util.sh

# Project repository directory
declare -r CARTON_PROJECT_DIR="$CARTON_DATA_DIR/project"

# Check if a project name is valid.
# Args: project_name
function carton_project_name_is_valid()
{
    carton_fs_name_is_valid "$1"
}

declare -r _CARTON_PROJECT_GET_LOC='
    declare -r _project_name="$1";   shift
    carton_assert \"carton_project_name_is_valid \"\$_project_name\""
    declare -A _project=(
        [dir]="$CARTON_PROJECT_DIR/$_project_name"
    )
'

declare -r _CARTON_PROJECT_GET_STRUCT='
    carton_assert "[ -d \"\${_project[dir]}\" ]"
    _project+=(
        [git_dir]="${_project[dir]}/git"
        [commit_dir]="${_project[dir]}/commit"
        [channel_dir]="${_project[dir]}/channel"
    )
'

declare -r _CARTON_PROJECT_GET_PROPS='
    _project+=(
        [tag_glob]=`cd "${_project[git_dir]}" &&
                        git config --get "carton.tag-glob"`
        [tag_format]=`cd "${_project[git_dir]}" &&
                        git config --get "carton.tag-format"`
    )
'

# Check if a project exists.
# Args: _project_name
function carton_project_exists()
{
    eval "$_CARTON_PROJECT_GET_LOC"
    [ -d "${_project[dir]}" ]
}

# Create a project.
# Args: _project_var _project_name _git_repo [_tag_glob _tag_format]
function carton_project_make()
{
    declare -r arg_num="$#"
    carton_assert '[ $arg_num == 3 || $arg_num == 5 ]'
    declare -r _project_var="$1";   shift
    carton_assert 'carton_var_name_is_valid "$_project_var"'
    eval "$_CARTON_PROJECT_GET_LOC"
    carton_assert '! carton_project_exists "$_project_name"'
    declare -r _git_repo="$1";          shift
    declare -r _tag_glob="${1-v*}";     shift
    declare -r _tag_format="${1-v%s}";  shift

    mkdir "${_project[dir]}"

    eval "$_CARTON_PROJECT_GET_STRUCT"
    git clone --quiet --bare "$_git_repo" "${_project[git_dir]}"
    (
        cd "${_project[git_dir]}"
        git config carton.tag-glob "$_tag_glob"
        git config carton.tag-format "$_tag_format"
    )
    mkdir "${_project[commit_dir]}"
    mkdir "${_project[channels_dir]}"

    eval "$_CARTON_PROJECT_GET_PROPS"

    carton_aa_copy "$_project_var" _project
}

# Remove a project.
# Args: _project_name
function carton_project_rm()
{
    eval "$_CARTON_PROJECT_GET_LOC"
    carton_assert 'carton_project_exists "$_project_name"'
    rm -Rf "${_project[dir]}"
}

# Retrieve a project.
# Args: _project_var _project_name
function carton_project_get()
{
    declare -r _project_var="$1";   shift
    carton_assert 'carton_var_name_is_valid "$_project_var"'
    eval "$_CARTON_PROJECT_GET_LOC
          $_CARTON_PROJECT_GET_STRUCT
          $_CARTON_PROJECT_GET_PROPS"
    carton_aa_copy "$_project_var" _project
}

fi # _CARTON_PROJECT_SH
