#
# Commit
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
. carton_rev.sh
. thud_misc.sh
. thud_arr.sh

# Load base commit properties.
# Args: dir
declare -r _CARTON_COMMIT_LOAD_BASE='
    declare -r hash="$1";          shift
    declare -r dir="$1";           shift
    thud_assert "[ -d \"\$dir\" ]"

    declare -A commit=(
        [hash]="$hash"
        [dir]="$dir"
        [dist_dir]="$dir/dist"
        [dist_log]="$dir/dist.log"
        [dist_stamp]="$dir/dist.stamp"
        [rev_dir]="$dir/rev"
    )
'

# Load commit distribution properties.
declare -r _CARTON_COMMIT_LOAD_DIST='
    if [ -e "${commit[dist_stamp]}" ]; then
        commit[is_built]=true
        commit[dist_ver]=`"${commit[dist_dir]}/configure" --version |
                                sed "1 {s/.*[[:blank:]]//;q}"`
    else
        commit[is_built]=false
    fi
'

# Initialize and output a commit.
# Args: hash dir
# Input: commit tarball
# Output: commit
function carton_commit_init()
{
    eval "$_CARTON_COMMIT_LOAD_BASE"
    mkdir "${commit[dist_dir]}"
    mkdir "${commit[rev_dir]}"

    # Extract the commit, ignoring stored modification time to prevent
    # future timestamps and subsequent build delays
    tar --extract --touch --directory "${commit[dist_dir]}"

    # Build the distribution
    (
        cd "${commit[dist_dir]}"

        echo -n "Start: "
        date --rfc-2822
        set +o errexit
        (
            set -o errexit -o xtrace

            # Check that there are no tarballs in the source
            ! test -e *.tar.gz

            # Build source tarball
            ./bootstrap
            ./configure
            make distcheck
        )
        status="$?"
        set -o errexit
        if [ "$status" == 0 ]; then
            touch "${commit[dist_stamp]}"
        fi
        echo -n "End: "
        date --rfc-2822
    ) > "${commit[dist_log]}" 2>&1

    eval "$_CARTON_COMMIT_LOAD_DIST"
    thud_arr_print commit
}

# Load and output a commit.
# Args: hash dir
# Output: commit
function carton_commit_load()
{
    eval "$_CARTON_COMMIT_LOAD_BASE
          $_CARTON_COMMIT_LOAD_DIST"
    thud_arr_print commit
}

# Assign commit revision location variables.
# Args: commit_str rev_num
declare -r _CARTON_COMMIT_GET_REV_LOC='
    declare -r commit_str="$1"; shift
    declare -r rev_num="$1";    shift
    thud_assert "carton_rev_num_is_valid \"\$rev_num\""

    declare -A commit=()
    thud_arr_parse commit <<<"$commit_str"

    declare -r rev_dir="${commit[rev_dir]}/$rev_num"
'

# Check if a commit revision exists.
# Args: commit_str rev_num
function carton_commit_has_rev()
{
    eval "$_CARTON_COMMIT_GET_REV_LOC"
    [ -d "$rev_dir" ]
}

# Create a commit revision and output its string.
# Args: commit_str rev_num
# Output: revision string
function carton_commit_add_rev()
{
    eval "$_CARTON_COMMIT_GET_REV_LOC"
    thud_assert '${commit[is_built]}'
    thud_assert '! carton_commit_has_rev "$commit_str" "$rev_num"'
    mkdir "$rev_dir"
    carton_rev_init "$rev_dir" \
                    "${commit[dist_ver]}" "$rev_num" "${commit[hash]}" \
                    "${commit[dist_dir]}"
}

# Load a commit revision and output its string.
# Args: commit_str rev_num
# Output: revision string
function carton_commit_get_rev()
{
    eval "$_CARTON_COMMIT_GET_REV_LOC"
    thud_assert '${commit[is_built]}'
    thud_assert 'carton_commit_has_rev "$commit_str" "$rev_num"'
    carton_rev_load "$rev_dir" \
                    "${commit[dist_ver]}" "$rev_num" "${commit[hash]}"
}

# Create or load a commit revision and output its string.
# Args: commit_str rev_num
# Output: revision string
function carton_commit_add_or_get_rev()
{
    declare -r commit_str="$1";    shift
    declare -r rev_num="$1";       shift
    thud_assert 'carton_rev_num_is_valid "$rev_num"'

    if carton_commit_has_rev "$commit_str" "$rev_num"; then
        carton_commit_get_rev "$commit_str" "$rev_num"
    else
        carton_commit_add_rev "$commit_str" "$rev_num"
    fi
}

# Delete a commit revision.
# Args: commit_str rev_num
function carton_commit_del_rev()
{
    eval "$_CARTON_COMMIT_GET_REV_LOC"
    thud_assert '${commit[is_built]}'
    rm -Rf "$rev_dir"
}

fi # _CARTON_COMMIT_SH
