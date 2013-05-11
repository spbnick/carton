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

# Load base commit properties.
# Args: _dir
declare -r _CARTON_COMMIT_LOAD_BASE='
    declare -r _dir="$1";           shift
    carton_assert "[ -d \"\$_dir\" ]"

    declare -A _commit=(
        [dir]="$_dir"
        [dist_dir]="$_dir/dist"
        [dist_log]="$_dir/dist.log"
        [dist_stamp]="$_dir/dist.stamp"
        [rev_dir]="$_dir/rev"
    )
'

# Load commit distribution properties.
declare -r _CARTON_COMMIT_LOAD_DIST='
    if [ -e "${_commit[dist_stamp]}" ]; then
        _commit[is_built]=true
        _commit[dist_ver]=`"${_commit[dist_dir]}/configure" --version |
                                sed "1 {s/.*[[:blank:]]//;q}"`
    else
        _commit[is_built]=false
    fi
'

# Initialize a commit.
# Args: _commit_var _dir
# Input: commit tarball
function carton_commit_init()
{
    declare -r _commit_var="$1";    shift
    carton_assert 'carton_is_valid_var_name "$_commit_var"'
    eval "$_CARTON_COMMIT_LOAD_BASE"

    mkdir "${_commit[dist_dir]}"
    mkdir "${_commit[rev_dir]}"

    # Extract the commit, ignoring stored modification time to prevent
    # future timestamps and subsequent build delays
    tar --extract --touch --directory "${_commit[dist_dir]}"

    # Build the distribution
    (
        cd "${_commit[dist_dir]}"

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
        _status="$?"
        set -o errexit
        if [ "$_status" == 0 ]; then
            touch "${_commit[dist_stamp]}"
        fi
        echo -n "End: "
        date --rfc-2822
    ) > "${_commit[dist_log]}" 2>&1

    eval "$_CARTON_COMMIT_LOAD_DIST"
    carton_arr_copy "$_commit_var" "_commit"
}

# Load a commit.
# Args: _commit_var _dir
function carton_commit_load()
{
    declare -r _commit_var="$1";    shift
    carton_assert 'carton_is_valid_var_name "$_commit_var"'
    eval "$_CARTON_COMMIT_LOAD_BASE
          $_CARTON_COMMIT_LOAD_DIST"
    carton_arr_copy "$_commit_var" "_commit"
}

# Assign commit revision location variables.
# Args: _commit_var _rev_num
declare -r _CARTON_COMMIT_GET_REV_LOC='
    declare -r _commit_var="$1";   shift
    carton_assert "carton_is_valid_var_name \"\$_commit_var\""
    declare -r _rev_num="$1";       shift
    carton_assert "carton_rev_num_is_valid \"\$_rev_num\""

    declare -A _commit
    carton_arr_copy _commit "$_commit_var"

    declare -r _rev_dir="${_commit[rev_dir]}/$_rev_num"
'

# Check if a commit revision exists.
# Args: _commit_var _rev_num
function carton_commit_has_rev()
{
    eval "$_CARTON_COMMIT_GET_REV_LOC"
    [ -d "$_rev_dir" ]
}

# Create a commit revision.
# Args: _rev_var _commit_var _rev_num
function carton_commit_add_rev()
{
    declare -r _rev_var="$1";       shift
    carton_assert 'carton_is_valid_var_name "$_rev_var"'
    eval "$_CARTON_COMMIT_GET_REV_LOC"
    carton_assert '${_commit[is_built]}'
    carton_assert '! carton_commit_has_rev "$_commit_var" "$_rev_num"'
    mkdir "$_rev_dir"
    carton_rev_init "$_rev_var" "$_rev_dir" \
                    "${_commit[dist_ver]}" "$_rev_num" "${_commit[dist_dir]}"
}

# Get a commit revision.
# Args: _rev_var _commit_var _rev_num
function carton_commit_get_rev()
{
    declare -r _rev_var="$1";       shift
    carton_assert 'carton_is_valid_var_name "$_rev_var"'
    eval "$_CARTON_COMMIT_GET_REV_LOC"
    carton_assert '${_commit[is_built]}'
    carton_assert 'carton_commit_has_rev "$_commit_var" "$_rev_num"'
    carton_rev_load "$_rev_var" "$_rev_dir" "${_commit[dist_ver]}" "$_rev_num"
}

# Create or get a commit revision.
# Args: _rev_var _commit_var _rev_num
function carton_commit_add_or_get_rev()
{
    declare -r _rev_var="$1";       shift
    carton_assert 'carton_is_valid_var_name "$_rev_var"'
    declare -r _commit_var="$1";    shift
    carton_assert 'carton_is_valid_var_name "$_commit_var"'
    declare -r _rev_num="$1";       shift
    carton_assert 'carton_rev_num_is_valid "$_rev_num"'

    if carton_commit_rev_exists "$_commit_var" "$_rev_num"; then
        carton_commit_get_rev "$_rev_var" "$_commit_var" "$_rev_num"
    else
        carton_commit_add_rev "$_rev_var" "$_commit_var" "$_rev_num"
    fi
}

# Delete a commit revision.
# Args: _commit_var _rev_num
function carton_commit_del_rev()
{
    eval "$_CARTON_COMMIT_GET_REV_LOC"
    carton_assert '${_commit[is_built]}'
    rm -Rf "$_rev_dir"
}

fi # _CARTON_COMMIT_SH
