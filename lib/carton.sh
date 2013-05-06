#
# Carton build server
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

if [ -z "${_CARTON_SH+set}" ]; then
declare _CARTON_SH=

. carton_util.sh
. carton_project_list.sh
. carton_repo_list.sh

declare -r CARTON_REPO_LOCK_TIMEOUT="10 minutes"
declare -r CARTON_REPO_LOCK_INTERVAL="5s"

# Initialize data directory.
function carton_init()
{
    carton_assert "[ -d \"\$CARTON_DATA_DIR\" ]"
    mkdir "$CARTON_REPO_LIST_DIR"
    mkdir "$CARTON_PROJECT_LIST_DIR"
}

<<"DISABLED"
# Publish a release RPM package to a repository
# Args: project_name committish rel_num repo_name
function carton_publish_rpm()
{
    declare -r project_name="$1";   shift
    carton_assert 'carton_is_valid_fs_name "$project_name"'
    declare -r committish="$1";     shift
    declare -r rel_num="$1";        shift
    declare -r repo_name="$1";      shift
    carton_assert 'carton_is_valid_fs_name "$repo_name"'

    (
        carton_get_project project_ "$project_name"
        carton_get_repo repo_ "$repo_name"
    ) |
    (
        eval "`cat`"
        carton_get_commit commit_ project_ "$committish" |
        (
            eval "`cat`"
            carton_get_rel rel_ commit_ "$rel_num" |
            (
                eval "`cat`"

                declare lock_deadline
                declare status
                lock_deadline=`date --date="$CARTON_REPO_LOCK_TIMEOUT" +%s`

                # Spin-lock the repo
                while ! ( set -o noclobber && echo $$ >"$repo_lock" ) 2>/dev/null; do
                    if ((`date +%s` > lock_deadline)); then
                        echo "Timeout getting repo lock $repo_lock" \
                             "held by PID `cat $repo_lock`" >&2
                        exit 1
                    fi
                    sleep "$CARTON_REPO_LOCK_INTERVAL"
                done

                set +e
                (
                    set -e
                    # Cleanup after a possible terminated publish
                    rm -R "$repo_rpm_old_dir"
                    rm "$repo_rpm_new_link"

                    # Attempt to move to a copy of current repo atomically
                    cp -a "$repo_rpm_dir" "$repo_rpm_old_dir"
                    ln -s "$repo_rpm_old_dir" "$repo_rpm_new_link"
                    mv -T "$repo_rpm_new_link" "$repo_rpm_link"

                    # Add packages
                    find "$rel_rpm_dir"/{RPMS,SRPMS} -name "*.rpm" -print0 |
                        xargs -0 ln -sft "$repo_rpm_dir"

                    # Update metadata
                    createrepo --update "$repo_rpm_dir"

                    # Attempt to move to the new repo atomically
                    ln -s "$repo_rpm_dir" "$repo_rpm_new_link"
                    mv -T "$repo_rpm_new_link" "$repo_rpm_link"

                    # Remove old repo
                    rm -R "$repo_rpm_old_dir"
                )
                status="$?"
                set -e

                # Unlock the repo
                rm "$repo_lock"

                exit "$status"
            )
        )
    )
}
DISABLED

fi # _CARTON_SH
