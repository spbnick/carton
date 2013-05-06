#
# Revision object
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

# Check if a string is a valid revision number.
# Args: str
function carton_rev_num_is_valid()
{
    declare -r str="$1"
    [[ "$str" == "0" ||
       "$str" =~ ^-?[1-9][0-9]*$ ]]
}

# Load base revision properties.
# Args: _dir _num _dist_dir
declare -r _CARTON_REV_LOAD_BASE='
    declare -r _dir="$1";   shift
    carton_assert "[ -d \"\$_dir\" ]"
    declare -r _ver="$1";   shift
    declare -r _num="$1";   shift
    carton_assert \"carton_rev_num_is_valid \"\$_num\""

    declare -A _rev=(
        [dir]="$_dir"
        [ver]="$_ver"
        [num]="$_num"
        [rpm_dir]="$_dir/rpm"
        [rpm_stamp]="$_dir/rpm.stamp"
        [rpm_log]="$_dir/rpm.log"
    )
'

# Load revision packages' properties.
declare -r _CARTON_REV_LOAD_PKGS='
    if [ -e "${_rev[rpm_stamp]}" ]; then
        _rev[is_built]=true
    else
        _rev[is_built]=false
    fi
'

# Build RPM packages for a revision.
# Args: _dist_dir _rpm_dir _rpm_log _rpm_stamp _num
function _carton_rev_build_rpm()
{
    declare -r _dist_dir="$1";  shift
    declare -r _rpm_dir="$1";   shift
    declare -r _rpm_log="$1";   shift
    declare -r _rpm_stamp="$1"; shift
    declare -r _num="$1";       shift

    declare -a _rpm_opts=("--define=_topdir $_rpm_dir")

    if ((_num > 0)); then
        _rpm_opts+=("--define=rev .1.$((_num))")
    elif ((_num < 0)); then
        _rpm_opts+=("--define=rev .0.$((-_num))")
    fi

    (
        set -e
        echo -n "Start: "
        date --rfc-2822
        (
            set -x

            declare _tarball
            declare _spec

            mkdir "$_rpm_dir"{,/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}}

            for _tarball in "$_dist_dir/"*.tar.gz; do
                ln -s "$_tarball" "$_rpm_dir/SOURCES/"
            done
            for _spec in "$_dist_dir/"*.spec; do
                ln -s "$_spec" "$_rpm_dir/SPECS/"
            done
            for _spec in "$_rpm_dir/SPECS/"*.spec; do
                rpmbuild "${_rpm_opts[@]}" -ba "$_spec"
            done
        )
        echo -n "End: "
        date --rfc-2822
    ) > "$_rpm_log" 2>&1 &&
        touch "$_rpm_stamp"
}

# Initialize a revision.
# Args: _rev_var _dir _ver _num _dist_dir
function carton_rev_init()
{
    declare -r _rev_var="$1";    shift
    carton_assert 'carton_is_valid_var_name "$_rev_var"'
    eval "$_CARTON_REV_LOAD_BASE"
    declare -r _dist_dir="$1";   shift
    carton_assert "[ -d \"\$_dist_dir\" ]"
    mkdir "${_rev[rpm_dir]}"
    _carton_rev_build_rpm "$_dist_dir" \
                          "${_rev[rpm_dir]}" \
                          "${_rev[rpm_log]}" \
                          "${_rev[rpm_stamp]}" \
                          "${_rev[num]}"
    eval "$_CARTON_REV_LOAD_PKGS"
    carton_arr_copy "$_rev_var" _rev
}

# Load a revision.
# Args: _rev_var _dir _ver _num
function carton_rev_load()
{
    declare -r _rev_var="$1";    shift
    carton_assert 'carton_is_valid_var_name "$_rev_var"'
    eval "$_CARTON_REV_LOAD_BASE
          $_CARTON_REV_LOAD_PKGS"
    carton_arr_copy "$_rev_var" _rev
}

fi # _CARTON_REV_SH
