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
. thud_misc.sh

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
    declare -r dir="$1";    shift
    thud_assert "[ -d \"\$dir\" ]"
    declare -r ver="$1";    shift
    declare -r num="$1";    shift
    declare -r hash="$1";   shift
    thud_assert "carton_rev_num_is_valid \"\$num\""

    declare -A rev=(
        [dir]="$dir"
        [ver]="$ver"
        [num]="$num"
        [hash]="$hash"
        [rpm_dir]="$dir/rpm"
        [rpm_stamp]="$dir/rpm.stamp"
        [rpm_log]="$dir/rpm.log"
    )
'

# Load revision packages' properties.
declare -r _CARTON_REV_LOAD_PKGS='
    if [ -e "${rev[rpm_stamp]}" ]; then
        rev[is_built]=true
    else
        rev[is_built]=false
    fi
'

# Build RPM packages for a revision.
# Args: dist_dir rpm_dir rpm_log rpm_stamp num hash
function _carton_rev_build_rpm()
{
    declare -r dist_dir="$1";  shift
    declare -r rpm_dir="$1";   shift
    declare -r rpm_log="$1";   shift
    declare -r rpm_stamp="$1"; shift
    declare -r num="$1";       shift
    declare -r hash="$1";      shift

    declare -a rpm_opts=("--define=_topdir $rpm_dir")

    if ((num < 0)); then
        rpm_opts+=("--define=rev .0.$((-num)).$hash")
    elif ((num == 0)); then
        rpm_opts+=("--define=rev .1")
    else
        rpm_opts+=("--define=rev .1.$((num)).$hash")
    fi

    (
        declare status

        echo -n "Start: "
        date --rfc-2822
        set +o errexit
        (
            set -o errexit -o xtrace

            declare tarball
            declare spec

            mkdir "$rpm_dir"{,/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}}

            for tarball in "$dist_dir/"*.tar.gz; do
                ln -s "$tarball" "$rpm_dir/SOURCES/"
            done
            for spec in "$dist_dir/"*.spec; do
                ln -s "$spec" "$rpm_dir/SPECS/"
            done
            for spec in "$rpm_dir/SPECS/"*.spec; do
                rpmbuild "${rpm_opts[@]}" -ba "$spec"
            done
        )
        status="$?"
        set -o errexit
        if [ "$status" == 0 ]; then
            touch "$rpm_stamp"
        fi
        echo -n "End: "
        date --rfc-2822
    ) > "$rpm_log" 2>&1
}

# Initialize a revision and output its string.
# Args: dir ver num hash dist_dir
# Output: revision string
function carton_rev_init()
{
    eval "$_CARTON_REV_LOAD_BASE"
    declare -r dist_dir="$1";   shift
    thud_assert "[ -d \"\$dist_dir\" ]"
    _carton_rev_build_rpm "$dist_dir" \
                          "${rev[rpm_dir]}" \
                          "${rev[rpm_log]}" \
                          "${rev[rpm_stamp]}" \
                          "${rev[num]}" \
                          "${rev[hash]}"
    eval "$_CARTON_REV_LOAD_PKGS"
    carton_arr_print rev
}

# Load and output a revision string.
# Args: dir ver num hash
# Output: revision string
function carton_rev_load()
{
    eval "$_CARTON_REV_LOAD_BASE
          $_CARTON_REV_LOAD_PKGS"
    carton_arr_print rev
}

fi # _CARTON_REV_SH
