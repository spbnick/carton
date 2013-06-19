#
# Project list
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

if [ -z "${_CARTON_PROJECT_LIST_SH+set}" ]; then
declare _CARTON_PROJECT_LIST_SH=

. carton_util.sh
. carton_project.sh

# Repository directory
declare -r CARTON_PROJECT_LIST_DIR="$CARTON_DATA_DIR/project"

# Check if a string is a valid project name.
# Args: str
function carton_project_list_is_valid_name()
{
    carton_is_valid_fs_name "$1"
}

# Output the list of project names, one per line.
function carton_project_list_list_projects()
{
    carton_assert "[ -d \"\$CARTON_PROJECT_LIST_DIR\" ]"
    ls -1 "$CARTON_PROJECT_LIST_DIR"
}

# Get project location arguments.
# Args: project_name
declare -r _CARTON_PROJECT_LIST_GET_PROJECT_LOC='
    declare -r project_name="$1";   shift
    carton_assert "carton_project_list_is_valid_name \"\$project_name\""
    carton_assert "[ -d \"\$CARTON_PROJECT_LIST_DIR\" ]"
    declare -r project_dir="$CARTON_PROJECT_LIST_DIR/$project_name"
'

# Check if a project exists.
# Args: project_name
function carton_project_list_has_project()
{
    eval "$_CARTON_PROJECT_LIST_GET_PROJECT_LOC"
    [ -e "$project_dir" ]
}

# Add a new project to the list and output its string.
# Args: project_name repo_url [[tag_glob tag_format] update_max_age]
# Output: project string
function carton_project_list_add_project()
{
    eval "$_CARTON_PROJECT_LIST_GET_PROJECT_LOC"
    carton_assert "! carton_project_list_has_project \"\$project_name\""
    mkdir "$project_dir"
    carton_project_init "$project_dir" "$@"
}

# Load and output a project string.
# Args: project_name
function carton_project_list_get_project()
{
    eval "$_CARTON_PROJECT_LIST_GET_PROJECT_LOC"
    carton_assert "carton_project_list_has_project \"\$project_name\""
    carton_project_load "$project_dir"
}

# Delete a project.
# Args: project_name
function carton_project_list_del_project()
{
    eval "$_CARTON_PROJECT_LIST_GET_PROJECT_LOC"
    carton_assert 'carton_project_list_has_project "$project_name"'
    # Override read-only permissions of unfinished builds
    chmod -R u+w -- "$project_dir"
    rm -Rf -- "$project_dir"
}

fi # _CARTON_PROJECT_LIST_SH
