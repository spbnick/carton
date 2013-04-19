#
# Carton build server functions
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

CARTON_ENV=`carton-env`
eval "$CARTON_ENV"

. carton_util.sh
. carton_rel.sh
. carton_repo.sh

# Build a release RPM package from distribution tarball
# Args: project_name committish rel_num
function carton_make_rpm()
{
    declare -r project_name="$1";   shift
    carton_assert 'carton_fs_name_is_valid "$project_name"'
    declare -r committish="$1";     shift
    declare -r rel_num="$1";        shift

    carton_get_project project_ "$project_name" |
    (
        eval "`cat`"
        carton_get_commit commit_ project_ "$committish" |
        (
            eval "`cat`"
            (
                carton_get_dist dist_ commit_
                carton_get_rel rel_ commit_ "$rel_num"
            ) |
            (
                eval "`cat`"

                carton_assert 'test -e "$commit_dist_stamp"'
                carton_assert 'test -d "$rel_dir"'

                mkdir "$rel_rpm_dir"{,/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}}
                (
                    declare tarball
                    declare spec

                    echo -n "Start: "
                    date --rfc-2822
                    set -x

                    for tarball in "$commit_dist_dir/"*.tar.gz; do
                        ln -s "$tarball" "$rel_rpm_dir/SOURCES/"
                    done
                    for spec in "$commit_dist_dir/"*.spec; do
                        ln -s "$spec" "$rel_rpm_dir/SPECS/"
                        rpmbuild "${rel_rpm_opts[@]}" \
                                 -ba "$rel_rpm_dir/SPECS/$spec"
                    done

                    set +x
                    echo -n "End: "
                    date --rfc-2822
                ) >> "$commit_rpm_log" 2>&1
                touch "$commit_rpm_stamp"
            )
        )
    )
}

# Publish a release RPM package to a repository
# Args: project_name committish rel_num repo_name
function carton_publish_rpm()
{
    declare -r project_name="$1";   shift
    carton_assert 'carton_fs_name_is_valid "$project_name"'
    declare -r committish="$1";     shift
    declare -r rel_num="$1";        shift
    declare -r repo_name="$1";      shift
    carton_assert 'carton_fs_name_is_valid "$repo_name"'

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

fi # _CARTON_SH
