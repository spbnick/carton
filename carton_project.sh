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

CARTON_ENV=`carton-env`
eval "$CARTON_ENV"

. carton_util.sh

# Project repository directory
declare -r CARTON_PROJECT_DIR="$CARTON_DATA_DIR/project"

# Check if a project exists
# Args: project_name
function carton_project_exists()
{
    declare -r project_name="$1";   shift
    carton_assert 'carton_fs_name_is_valid "$project_name"'
    [ -d "$CARTON_PROJECT_DIR/$project_name" ]
}

# Create a project, cloning a git repo
# Args: project_name git_repo
function carton_project_make()
{
    declare -r project_name="$1";   shift
    carton_assert 'carton_fs_name_is_valid "$project_name"'
    carton_assert '! carton_project_exists "$project_name"'
    declare -r git_repo="$1";       shift
    mkdir "$CARTON_PROJECT_DIR/$project_name"
    git clone --quiet --bare "$git_repo" \
              "$CARTON_PROJECT_DIR/$project_name/git"
    mkdir "$CARTON_PROJECT_DIR/$project_name/commit"
}

# Generate a script assigning project variables with specified prefix.
# Args: project_ project_name
function carton_project_get()
{
    declare -r project_="$1";       shift
    carton_assert 'carton_var_name_is_valid "$project_"'
    declare -r project_name="$1";   shift
    carton_assert 'carton_fs_name_is_valid "$project_name"'
    carton_assert 'carton_project_exists "$project_name"'

    cat <<EOF
        set -o errexit
        declare -r ${project_}dir="\$CARTON_PROJECT_DIR/$project_name"
        declare -r ${project_}git_dir="\$${project_}dir/git"
        declare -r ${project_}commit_dir="\$${project_}dir/commit"
        declare -r ${project_}tag_glob="v*"
        declare -r ${project_}tag_format="v%s"
EOF
}

function carton_project_get()
{
    declare -r _project_var="$1";   shift
    carton_assert 'carton_var_name_is_valid "$_project"'
    declare -r _project_name="$1";   shift
    carton_assert 'carton_fs_name_is_valid "$_project_name"'
    carton_assert 'carton_project_exists "$_project_name"'
    declare -A _project;

    _project[dir]="$CARTON_PROJECT_DIR/$_project_name"
    _project[git_dir]="${_project[dir]}/git"
    _project[commit_dir]="${_project[dir]}/commit"
    _project[tag_glob]="v*"
    _project[tag_format]="v%s"

    carton_aa_copy "$_project_var" _project
}

# Remove a project
# Args: project_name
function carton_project_rm()
{
    declare -r project_name="$1";   shift
    carton_assert 'carton_fs_name_is_valid "$project_name"'
    carton_assert 'carton_project_exists "$project_name"'
    rm -Rf "$CARTON_PROJECT_DIR/$project_name"
}

fi # _CARTON_PROJECT_SH
