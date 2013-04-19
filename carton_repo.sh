#
# Carton repo management
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

if [ -z "${_CARTON_REPO_SH+set}" ]; then
declare _CARTON_REPO_SH=

CARTON_ENV=`carton-env`
eval "$CARTON_ENV"

. carton_util.sh
. carton_project.sh

declare -r CARTON_REPO_DIR="$CARTON_DATA_DIR/repo"
declare -r CARTON_REPO_LOCK_TIMEOUT="10 minutes"
declare -r CARTON_REPO_LOCK_INTERVAL="5s"

# Generate a script assigning release variables with specified prefix.
# Args: repo_ repo_name
function carton_repo_get()
{
    declare -r repo_="$1";      shift
    declare -r repo_name="$1";  shift
    carton_assert 'carton_fs_name_is_valid "$repo_name"'

    cat <<EOF
        set -o errexit
        declare -r ${repo_}dir="\$CARTON_REPO_DIR/$repo_name"
        declare -r ${repo_}lock="\$CARTON_REPO_DIR/$repo_name.lock"
        declare -r ${repo_}rpm_link="\$${repo_}dir/yum"
        declare -r ${repo_}rpm_new_link="\$${repo_}dir/yum.new"
        declare -r ${repo_}rpm_dir="\$${repo_}dir/yum.dir"
        declare -r ${repo_}rpm_old_dir="\$${repo_}dir/yum.dir.new"
        declare -r ${repo_}rpm_evr_regex=".*"
EOF
}

fi # _CARTON_REPO_SH
