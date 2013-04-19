#
# Carton commit distribution management
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

if [ -z "${_CARTON_DIST_SH+set}" ]; then
declare _CARTON_DIST_SH=

CARTON_ENV=`carton-env`
eval "$CARTON_ENV"

. carton_util.sh
. carton_commit.sh

# Build a commit source distribution tarball
# Args: project_name committish
function carton_dist_make()
{
    declare -r project_name="$1";   shift
    carton_assert 'carton_fs_name_is_valid "$project_name"'
    declare -r committish="$1";     shift

    carton_get_project project_ "$project_name" |
    (
        eval "`cat`"
        carton_assert 'carton_commit_exists project_ "$committish"'
        carton_get_commit commit_ project_ "$committish" |
        (
            eval "`cat`"

            if [ -e "$commit_dist_dir" ]; then
                return 0
            fi

            mkdir -p "$commit_dist_dir"

            (
                cd "$project_git_dir"
                git archive --format=tar "$commit_hash"
            ) |
            (
                cd "$commit_dist_dir"

                echo -n "Start: "
                date --rfc-2822
                set -x

                # Extract the commit, ignoring stored modification time to prevent
                # future timestamps and subsequent build delays
                tar --extract --touch --verbose

                # Check that there are no tarballs in the source
                ! test -e *.tar.gz

                # Build source tarball
                ./bootstrap
                ./configure
                make distcheck

                set +x
                echo -n "End: "
                date --rfc-2822
            ) > "$commit_dist_log" 2>&1
            touch "$commit_dist_stamp"
        )
    )
}

# Generate a script assigning distribution variables with specified prefix.
# Args: dist_ commit_
function carton_dist_get()
{
    declare -r dist_="$1";      shift
    declare -r commit_="$1";    shift

    declare -r _project_="${commit_}project_"
    declare -r project_="${!_project_}"

    cat <<EOF
        set -o errexit
        declare ${dist_}ver
        ${dist_}ver=\`"\$${commit_}dist_dir/configure" --version |
                            sed '1 {s/.*[[:blank:]]//;q}'\`
        declare -r ${dist_}ver

        declare -r ${dist_}tag_name=\`printf "\$${project_}tag_format" \
                                             "\$${dist_}ver"\`

        if [ "\$${commit_}tag_name" == "\$${dist_}tag_name" ]; then
            declare -r ${dist_}rel_num="\$${commit_}tag_distance"
        else
            declare -r ${dist_}rel_num="-\$${commit_}tag_distance"
        fi
EOF
}

fi # _CARTON_DIST_SH
