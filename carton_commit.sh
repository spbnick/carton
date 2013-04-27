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

. carton_util.sh
. carton_project.sh

declare -r _CARTON_COMMIT_GET_LOC='
    declare -r _project_var="$1";   shift
    carton_assert "carton_var_name_is_valid \"\$_project_var\""
    declare -r _committish="$1";    shift

    declare -A _project
    carton_aa_copy _project "$_project_var"

    declare -A _commit=()

    _commit[hash]=`
        cd "${_project[git_dir]}" &&
        git log -n1 --format=format:%h "$_committish"`
    _commit[dir]="${_project[commit_dir]}/${_commit[hash]}"
'

declare -r _CARTON_COMMIT_GET_STRUCT='
    carton_assert "[ -d \"\${_commit[dir]}\" ]"
    _commit+=(
        [dist_dir]="${_commit[dir]}/dist"
        [dist_stamp]="${_commit[dir]}/dist.stamp"
        [dist_log]="${_commit[dir]}/dist.log"
        [rev_dir]="${_commit[dir]}/rev"
    )
'

declare -r _CARTON_COMMIT_GET_PROPS='
    carton_assert "[ -d \"\${_commit[dir]}\" ]"

    _commit[desc]=`git describe --long \
                                --match="${_project[tag_glob]}" \
                                "${_commit[hash]}" | cut -d- -f1-2 ||
                    { [ $? == 128 ] && echo "-"; } ||
                        false`
    _commit[tag_name]="${_commit[description]%-*}"
    _commit[tag_distance]="${_commit[description]#*-}"

    if [ -e "${_commit[dist_stamp]}" ]; then
        _commit[is_built]="true"

        _commit[dist_ver]=`"${_commit[dist_dir]}/configure" --version |
                            sed "1 {s/.*[[:blank:]]//;q}"`
        _commit[dist_tag_name]=`printf "${_project[tag_format]}" \
                                    "${_commit[dist_ver]}"`
        if [ "${_commit[dist_tag_name]}" == "${_commit[tag_name]}" ]; then
            _commit[rev_num]="${_commit[tag_distance]}"
        else
            _commit[rev_num]="-${_commit[tag_distance]}"
        fi
    else
        _commit[is_built]="false"
    fi
'

# Check if a commit exists.
# Args: _project_var _committish
function carton_commit_exists()
{
    eval "$_CARTON_COMMIT_GET_LOC"
    [ -d "${_commit[dir]}" ]
}

# Create a commit.
# Args: _commit_var _project_var _committish
function carton_commit_make()
{
    declare -r _commit_var="$1";    shift
    carton_assert 'carton_var_name_is_valid "$_commit_var"'
    eval "$_CARTON_COMMIT_GET_LOC"
    carton_assert '! carton_commit_exists "$_project_var" "$_committish"'

    mkdir "${_commit[dir]}"

    eval "$_CARTON_COMMIT_GET_STRUCT"
    mkdir "${_commit[dist_dir]}"
    mkdir "${_commit[rev_dir]}"

    # Extract the commit, ignoring stored modification time to prevent
    # future timestamps and subsequent build delays
    (
        cd "${_project[git_dir]}"
        git archive --format=tar "${_commit[hash]}"
    ) | tar --extract --touch --verbose --directory "${_commit[dist_dir]}"

    # Build the distribution
    (
        set -e
        cd "${_commit[dist_dir]}"

        echo -n "Start: "
        date --rfc-2822
        (
            set -x

            # Check that there are no tarballs in the source
            ! test -e *.tar.gz

            # Build source tarball
            ./bootstrap
            ./configure
            make distcheck
        )
        echo -n "End: "
        date --rfc-2822
    ) > "${_commit[dist_log]}" 2>&1 &&
        touch "${_commit[dist_stamp]}"

    eval "$_CARTON_COMMIT_GET_PROPS"

    carton_aa_copy "$_commit_var" _commit
}

# Remove a commit directory.
# Args: _project_var _committish
function carton_commit_rm()
{
    eval "$_CARTON_COMMIT_GET_LOC"
    carton_assert 'carton_commit_exists "$_project_var" "$_committish"'
    rm -Rf "${_commit[dir]}"
}

# Retrieve a commit.
# Args: _commit_var _project_var _committish
function carton_commit_get()
{
    declare -r _commit_var="$1";    shift
    carton_assert 'carton_var_name_is_valid "$_commit_var"'
    eval "$_CARTON_COMMIT_GET_LOC
          $_CARTON_COMMIT_GET_STRUCT
          $_CARTON_COMMIT_GET_PROPS"
    carton_aa_copy "$_commit_var" _commit
}

fi # _CARTON_COMMIT_SH
