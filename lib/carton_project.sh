#
# Project
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

if [ -z "${_CARTON_PROJECT_SH+set}" ]; then
declare _CARTON_PROJECT_SH=

. carton_util.sh
. carton_branch.sh
. carton_commit.sh

# Load base project properties from arguments.
# Args: dir
declare -r _CARTON_PROJECT_LOAD_BASE='
    declare -r dir="$1";   shift
    carton_assert "[ -d \"\$dir\" ]"
    declare -A project=(
        [dir]="$dir"
        [git_dir]="$dir/git"
        [commit_dir]="$dir/commit"
    )
'

# Load additional project properties.
declare -r _CARTON_PROJECT_LOAD_PROPS='
    project+=(
        [tag_glob]=`GIT_DIR="${project[git_dir]}" \
                        git config --get "carton.tag-glob"`
        [tag_format]=`GIT_DIR="${project[git_dir]}" \
                        git config --get "carton.tag-format"`
    )
'

# Initialize a project and output its string
# Args: dir repo_url [[tag_glob tag_format] update_max_age]
# Output: project string
function carton_project_init()
{
    declare -r arg_num="$#"
    carton_assert '[ $arg_num == 2 || $arg_num == 4 || $arg_num == 5 ]'

    eval "$_CARTON_PROJECT_LOAD_BASE"
    declare -r repo_url="$1";               shift
    declare -r tag_glob="${1-v*}";          shift
    declare -r tag_format="${1-v%s}";       shift
    declare -r update_max_age="${1-@0}";    shift

    (
        export GIT_DIR="${project[git_dir]}"
        git init --quiet --bare
        git config carton.tag-glob "$tag_glob"
        git config carton.tag-format "$tag_format"
        git config carton.update-max-age "$update_max_age"
        git config carton.tag-list ""
        git remote add origin "$repo_url"
        git fetch --quiet
    )
    mkdir "${project[commit_dir]}"

    eval "$_CARTON_PROJECT_LOAD_PROPS"

    carton_arr_print project
}

# Load and output a project string.
# Args: dir
# Output: project string
function carton_project_load()
{
    eval "$_CARTON_PROJECT_LOAD_BASE
          $_CARTON_PROJECT_LOAD_PROPS"
    carton_arr_print project
}

declare -r _CARTON_PROJECT_GET_COMMIT_LOC='
    declare -r project_str="$1";   shift
    declare -r committish="$1";    shift

    declare -A project
    carton_arr_parse project <<<"$project_str"

    declare commit_hash
    commit_hash=`GIT_DIR="${project[git_dir]}" \
                    git rev-parse --verify "$committish"`
    declare -r commit_dir="${project[commit_dir]}/$commit_hash"
'

# Check if a project commit exists.
# Args: project_str committish
function carton_project_has_commit()
{
    eval "$_CARTON_PROJECT_GET_COMMIT_LOC"
    [ -d "$commit_dir" ]
}

# Create a project commit and output its string.
# Args: project_str committish
# Output: commit string
function carton_project_add_commit()
{
    eval "$_CARTON_PROJECT_GET_COMMIT_LOC"
    carton_assert "! carton_project_has_commit \"\$project_str\" \
                                               \"\$commit_hash\""
    mkdir "$commit_dir"
    carton_commit_init "$commit_dir" < <(
        GIT_DIR="${project[git_dir]}" \
            git archive --format=tar "$commit_hash"
    )
}

# Output a project commit string.
# Args: project_str committish
# Output: commit string
function carton_project_get_commit()
{
    eval "$_CARTON_PROJECT_GET_COMMIT_LOC"
    carton_assert "carton_project_has_commit \"\$project_str\" \
                                             \"\$commit_hash\""
    carton_commit_load "$commit_dir"
}

# Create or get a project commit and output its string.
# Args: project_str committish
# Output: commit string
function carton_project_add_or_get_commit()
{
    declare -r project_str="$1";   shift
    carton_assert 'carton_is_valid_str_name "$project_str"'
    declare -r commitish="$1";     shift

    if carton_project_commit_exists "$project_str" "$committish"; then
        carton_project_get_commit "$project_str" "$committish"
    else
        carton_project_add_commit "$project_str" "$committish"
    fi
}

# Delete a project commit.
# Args: project_str committish
function carton_project_del_commit()
{
    eval "$_CARTON_PROJECT_GET_COMMIT_LOC"
    rm -Rf "$commit_dir"
}

# Determine revision number based on version tag format/commit distribution
# version and the closest version tag.
# Args: tag_format ver tag_name tag_distance
# Output: revision number
function carton_project_make_rev_num()
{
    declare -r tag_format="$1";     shift
    declare -r ver="$1";            shift
    declare -r tag_name="$1";       shift
    declare -r tag_distance="$1";   shift
    declare ver_tag_name

    ver_tag_name=`printf "$tag_format" "$ver"`
    if [ "$ver_tag_name" == "$tag_name" ]; then
        echo "$tag_distance"
    else
        echo "-$tag_distance"
    fi
}

declare -r _CARTON_PROJECT_GET_BRANCH_LOC='
    declare -r project_str="$1";   shift
    declare -r branch_name="$1";   shift
    carton_assert "carton_branch_name_is_valid \"\$branch_name\""
    declare -A project
    carton_arr_parse project <<<"$project_str"
'

# Output project branch names, one per line.
# Args: project_str
function carton_project_list_branches()
{
    declare -r project_str="$1";   shift
    declare -A project
    carton_arr_parse project <<<"$project_str"
    declare ref

    for ref in `GIT_DIR="${project[git_dir]}" \
                    git for-each-ref --format='%(refname)' refs/heads/`; do
        echo "${ref#refs/heads/}"
    done
}

# Check if a project branch exists.
# Args: project_str branch_name
function carton_project_has_branch()
{
    eval "$_CARTON_PROJECT_GET_BRANCH_LOC"
    GIT_DIR="${branch[git_dir]}" \
        git show-ref --quiet --verify "refs/heads/$branch_name"
}

# Create a project branch and output its string.
# Args: project_str branch_name [channel_list]
# Output: branch string
function carton_project_add_branch()
{
    eval "$_CARTON_PROJECT_GET_BRANCH_LOC"
    carton_assert '! carton_project_has_branch "$project_str" \
                                               "$branch_name"'
    GIT_DIR="${project[git_dir]}" \
        git branch --track "$branch_name" \
               "remotes/origin/$branch_name" >/dev/null
    carton_branch_init "${project[git_dir]}" "$branch_name" "$@"
}

# Output a project branch string.
# Args: project_str branch_name
function carton_project_get_branch()
{
    eval "$_CARTON_PROJECT_GET_BRANCH_LOC"
    carton_assert 'carton_project_has_branch "$project_str" \
                                             "$branch_name"'
    carton_branch_load "${project[git_dir]}" "$branch_name"
}

# Fetch from remote.
# Args: project_str
function carton_project_fetch()
{
    declare -r project_str="$1";   shift
    declare -A project
    carton_arr_parse project <<<"$project_str"
    GIT_DIR="${project[git_dir]}" git fetch --quiet
}

# Publish new commit revisions.
# Args: project_str
function carton_project_update()
{
    declare -r project_str="$1";   shift
    carton_assert 'carton_is_valid_str_name "$project_str"'
    declare -A project
    carton_arr_parse project <<<"$project_str"

    (
        declare max_age
        declare max_age_stamp
        declare tag
        declare -a old_tag_list=()
        declare -A old_tag_map=()
        declare -A tag_rev_map=()
        declare commit_hash
        declare commit_stamp
        declare commit_rev_num
        declare branch_name
        declare branch_hash
        declare -A branch
        declare last_tag_name=""
        declare last_tag_dist=1
        declare channel_list

        cd "${project[git_dir]}"

        max_age=`git config --get "carton.update-max-age"`
        max_age_stamp=`date --date="$max_age" "+%s"`

        # Read old tag list into a tag->hash map
        read -r -a old_tag_list < <(git config --get "carton.tag-list")
        if [ "${#old_tag_list[@]}" != 0 ]; then
            for tag in "${old_tag_list[@]}" do
                commit_hash=`git rev-list -n1 "$tag"`
                old_tag_map[$tag]="$commit_hash"
            done
        fi

        # Map commit hashes to tags
        while read -r commit_hash tag; do
            tag_rev_map[$commit_hash]="${tag#refs/tags/}"
        done < <(
            git for-each-ref --sort=taggerdate \
                             --format='%(objectname) %(refname)' \
                             "refs/tags/${project[tag_glob]}"
        )

        # For each branch
        for branch_name in `carton_project_list_branches "$branch_str"`; do
            branch_str=`carton_project_get_branch "$project_str" \
                                                  "$branch_name"`
            channel_list=`carton_branch_get_channel_list "$branch_str"`
            branch_hash=`git rev-list -n1 refs/heads/$branch_name`

            # For each commit in remote branch
            while read -r commit_stamp commit_hash; do
                # If the commit has a tag
                if [ -n "${tag_rev_map[$commit_hash]+set}" ]; then
                    last_tag_name="${tag_rev_map[$commit_hash]}"
                    last_tag_distance=0
                fi

                # If the commit is within update-max-age
                if ((commit_stamp >= max_age_stamp)) &&
                   # and if the commit is new to our branch
                   [[ -z "$branch_hash" ||
                      # or the commit's last seen tag is new
                      -z "${old_tag_map[$last_tag]+set}" ]]; then
                    # Publish commit revision
                    declare commit_str
                    commit_str=`carton_project_add_or_get_commit \
                                    "$project_str" "$commit_hash"`
                    declare -A commit
                    carton_arr_parse commit <<<"$commit_str"
                    if "${commit[is_built]}"; then
                        commit_rev_num=`carton_project_make_rev_num \
                                            "${project[tag_format]}" \
                                            "${commit[dist_ver]}"
                                            "$last_tag_name" \
                                            "$last_tag_distance"`
                        if ! carton_commit_has_rev "$commit_str"
                                                   "$commit_rev_num"; then
                            declare rev_str
                            rev_str=`carton_commit_add_rev \
                                        "$commit_str" "$commit_rev_num"`
                            declare -A rev
                            carton_arr_parse rev <<<"$rev_str"
                            if "${rev[is_built]}"; then
                                if carton_channel_list_is_applicable \
                                    "$channel_list" "$rev_str"; then
                                    carton_channel_list_publish \
                                        "$channel_list" "$rev_str"
                                fi
                            fi
                        fi
                    fi
                fi

                # If this is the last commit seen by our branch
                if [ "$commit_hash" == "$branch_hash" ]; then
                    # Consider all following commits as new
                    branch_hash=
                # else, if this commit is new to our branch
                elif [ -z "$branch_hash" ]; then
                    # Advance branch
                    git update-ref "refs/heads/$branch_name" \
                                   "$commit_hash"
                fi

                last_tag_distance=$((last_tag_distance + 1))
            done < <(
                git rev-list --reverse --timestamp \
                             "refs/heads/$branch_name@{upstream}"
            )
        done

        # Remember new tag list
        git config carton.tag-list "${!tag_rev_map[@]}"
    )
}

fi # _CARTON_PROJECT_SH
