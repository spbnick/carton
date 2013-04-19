#
# Carton commit management
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

if [ -z "${_CARTON_COMMIT_SH+set}" ]; then
declare _CARTON_COMMIT_SH=

CARTON_ENV=`carton-env`
eval "$CARTON_ENV"

. carton_util.sh
. carton_project.sh

# Convert a commit committish reference to normalized hash.
# Args: project_ committish
# Output: commit hash
function carton_commit_tish_to_hash()
{
    declare -r project_="$1";   shift
    carton_assert 'carton_var_name_is_valid "$project_"'
    declare -r committish="$1"; shift
    declare -r _project_git_dir="${project_}git_dir"

    (
        cd "${!_project_git_dir}"
        git log -n1 --format=format:%h "$committish"
    )
}

# Check if a commit exists.
# Args: project_ committish
function carton_commit_exists()
{
    declare -r project_="$1";   shift
    carton_assert 'carton_var_name_is_valid "$project_"'
    declare -r committish="$1"; shift
    declare hash
    hash=`carton_commit_tish_to_hash "$project_" "$committish"`
    declare -r _project_commit_dir="${project_}commit_dir"

    [ -d "${!_project_commit_dir}/$hash" ]
}

# Create a commit directory.
# Args: project_ committish
function carton_commit_make()
{
    declare -r project_="$1";   shift
    carton_assert 'carton_var_name_is_valid "$project_"'
    declare -r committish="$1"; shift
    declare hash
    hash=`carton_commit_tish_to_hash "$project_" "$committish"`
    declare -r _project_commit_dir="${project_}commit_dir"

    mkdir "${!_project_commit_dir}/$hash/"{,dist,rel}
}

# Remove a commit directory.
# Args: project_ committish
function carton_commit_rm()
{
    declare -r project_="$1";   shift
    carton_assert 'carton_var_name_is_valid "$project_"'
    declare -r committish="$1"; shift
    carton_assert "carton_commit_exists "$project_" "$committish""
    declare hash
    hash=`carton_commit_tish_to_hash "$project_" "$committish"`
    declare -r _project_commit_dir="${project_}commit_dir"

    rm -Rf "${!_project_commit_dir}/$hash"
}

# Generate a script assigning commit variables with specified prefix.
# Args: commit_ project_ committish
function carton_commit_get()
{
    declare -r commit_="$1";    shift
    carton_assert 'carton_var_name_is_valid "$commit_"'
    declare -r project_="$1";   shift
    carton_assert 'carton_var_name_is_valid "$project_"'
    declare -r committish="$1"; shift
    carton_assert 'carton_commit_exists "$project_" "$committish"'

    cat <<EOF
        set -o errexit
        declare -r ${commit_}project_="$project_"
        declare ${commit_}hash
        ${commit_}hash=\`carton_commit_tish_to_hash "$project_" "$committish"\`
        declare -r ${commit_}hash

        declare -r ${commit_}dir="\$${project_}commit_dir/\$${commit_}hash"
        declare -r ${commit_}dist_dir="\$${commit_}dir/dist"
        declare -r ${commit_}dist_log="\$${commit_}dir/dist.log"
        declare -r ${commit_}dist_stamp="\$${commit_}dir/dist.stamp"
        declare -r ${commit_}rel_dir="\$${commit_}dir/rel"

        declare ${commit_}description
        ${commit_}description=\`
            cd "\$${project_}git_dir" &&
                {
                    git describe --long \\
                                 --match="\$${project_}tag_glob" \\
                                 "\$${commit_}hash" | cut -d- -f1-2 ||
                        { [ \$? == 128 ] && echo "-"; } ||
                            false
                }\`
        declare -r ${commit_}description

        declare -r ${commit_}tag_name="\${${commit_}description%-*}"
        declare -r ${commit_}tag_distance="\${${commit_}description#*-}"
EOF
}

fi # _CARTON_COMMIT_SH
