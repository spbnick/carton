#
# Carton commit distribution release management
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

if [ -z "${_CARTON_REL_SH+set}" ]; then
declare _CARTON_REL_SH=

CARTON_ENV=`carton-env`
eval "$CARTON_ENV"

. carton_util.sh
. carton_dist.sh

# Make a commit distribution release directory.
# Args: project_name committish rel_num
function carton_make_rel()
{
    declare -r project_name="$1"
    carton_assert 'carton_fs_name_is_valid "$project_name"'
    declare -r committish="$2"

    carton_get_project project_ "$project_name" |
    (
        eval "`cat`"
        carton_get_commit commit_ project_ "$committish" |
        (
            eval "`cat`"
            mkdir "$commit_rel_dir/$rel_num"
        )
    )
}

# Generate a script assigning release variables with specified prefix.
# Args: rel_ commit_ rel_num
function carton_get_rel()
{
    declare -r dist_="$1";      shift
    declare -r commit_="$1";    shift
    declare -r rel_num="$1";    shift

    declare -r _project_="${commit_}project_"
    declare -r project_="${!_project_}"

    cat <<EOF
        set -o errexit
        declare -r ${rel_}dir="\$${commit_}rel_dir/$rel_num"
        declare -r ${rel_}rpm_dir="\$${rel_}dir/rpm"
        declare -r ${rel_}rpm_log="\$${rel_}dir/rpm.log"
        declare -r ${rel_}rpm_stamp="\$${rel_}dir/rpm.stamp"

        declare -a ${rel_}rpm_opts=("--define=_topdir \$${rel_}rpm_dir")
        elif ((rel_num > 0)); then
            ${rel_}rpm_opts[1]="--define=build .1.$rel_num"
        elif ((rel_num < 0)); then
            ${rel_}rpm_opts[1]="--define=build .0.$rel_num"
        fi
        declare -r ${rel_}rpm_opts
EOF
}

fi # _CARTON_REL_SH
