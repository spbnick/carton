#
# Carton commit revision management
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

if [ -z "${_CARTON_REV_SH+set}" ]; then
declare _CARTON_REV_SH=

. carton_util.sh
. carton_commit.sh

# Check if a string is a valid revision number.
function carton_rev_num_is_valid()
{
    declare -r str="$1"
    [[ "$str" == "0" ||
       "$str" =~ ^-?[1-9][0-9]*$ ]]
}

# Code unpacking common carton_rev_* function arguments.
declare -r _CARTON_REV_UNPACK='
    declare -r _commit_var="$1";    shift
    carton_assert "carton_var_name_is_valid \"\$_commit_var\""
    declare -r _rev_num="$1";       shift
    carton_assert \"carton_rev_num_is_valid \"\$rel_num\""

    declare -A _commit
    carton_aa_copy _commit "$_commit_var"

    declare -r _rev_dir="${_commit[rel_dir]}/$_rev_num"
'

# Check if a commit revision exists.
# Args: _commit_var _rev_num
function carton_rev_exists()
{
    eval "$_CARTON_REV_UNPACK"
    [ -d "$_rev_dir" ]
}

# Make a commit revision directory.
# Args: _commit_var _rev_num
function carton_rev_make()
{
    eval "$_CARTON_REV_UNPACK"
    mkdir "$_rev_dir/"{,rpm}
}

# Retrieve a commit revision properties into an associative array.
# Args: _rev_var _commit_var _rev_num
function carton_get_rev()
{
    declare -r _rev_var="$1";    shift
    carton_assert 'carton_var_name_is_valid "$_rev_var"'
    eval "$_CARTON_REV_UNPACK"

    declare -A _rev=(
        [_commit_var]="$_commit_var"
        [dir]="$_rev_dir"
        [num]="$_rev_num"
        [rpm_dir]="$_rev_dir/rpm"
        [rpm_log]="$_rev_dir/rpm.log"
        [rpm_stamp]="$_rev_dir/rpm.stamp"
    )

    carton_aa_copy "$_rev_var" _rev
}

# Build RPM packages for a commit revision.
# Args: _dist_dir _rpm_dir _rpm_log _rpm_stamp _rev_num
function _carton_rev_build_rpm()
{
    declare -r _dist_dir="$1";  shift
    declare -r _rpm_dir="$1";   shift
    declare -r _rpm_log="$1";   shift
    declare -r _rpm_stamp="$1"; shift
    declare -r _rev_num="$1";   shift

    declare -a _rpm_opts=("--define=_topdir $_rpm_dir")

    if ((_rev_num > 0)); then
        _rpm_opts+=("--define=rev .1.$((_rev_num))")
    elif ((_rev_num < 0)); then
        _rpm_opts+=("--define=rev .0.$((-_rev_num))")
    fi

    (
        declare _tarball
        declare _spec

        echo -n "Start: "
        date --rfc-2822
        set -x

        mkdir "$_rpm_dir"{,/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}}

        for _tarball in "$_dist_dir/"*.tar.gz; do
            ln -s "$_tarball" "$_rpm_dir/SOURCES/"
        done
        for _spec in "$_dist_dir/"*.spec; do
            ln -s "$_spec" "$_rpm_dir/SPECS/"
            rpmbuild "${_rpm_opts[@]}" \
                     -ba "$_rpm_dir/SPECS/$_spec"
        done

        set +x
        echo -n "End: "
        date --rfc-2822
    ) > "$_rpm_log" 2>&1
    touch "$_rpm_stamp"
}

# Build packages for a commit revision.
# Args: _rev_var
function carton_rev_build()
{
    declare -r _rev_var="$1";   shift
    carton_assert 'carton_var_name_is_valid "$_rev_var"'

    declare -A _rev
    carton_aa_copy _rev "$_rev_var"
    carton_assert '! [ -e "${_rev[rpm_log]}" ]'

    declare -A _commit
    carton_aa_copy _commit "${_rev[_commit_var]}"
    carton_assert '[ -e "${_commit[dist_stamp]}" ]'

    _carton_rev_build_rpm "${_commit[dist_dir]}" \
                          "${_rev[rpm_dir]}" \
                          "${_rev[rpm_log]}" \
                          "${_rev[rpm_stamp]}" \
                          "$_rev_num"
}

fi # _CARTON_REV_SH
