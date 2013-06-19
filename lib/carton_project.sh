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

# Initialize a project and output its string
# Args: dir repo_url [[tag_glob tag_format] update_max_age]
# Output: project string
function carton_project_init()
{
    declare -r arg_num="$#"
    carton_assert '[[ $arg_num == 2 || $arg_num == 4 || $arg_num == 5 ]]'

    eval "$_CARTON_PROJECT_LOAD_BASE"
    declare -r repo_url="$1";               shift
    declare -r tag_glob="${1-v*}";          shift || true
    declare -r tag_format="${1-v%s}";       shift || true
    declare -r update_max_age="${1-@0}";    shift || true

    (
        export GIT_DIR="${project[git_dir]}"
        git init --quiet --bare
        echo "ref: refs/heads/CARTON_INVALID" > "$GIT_DIR/HEAD"
        git config carton.tag-glob "$tag_glob"
        git config carton.tag-format "$tag_format"
        git config carton.update-max-age "$update_max_age"
        git remote add origin "$repo_url"
    )
    mkdir "${project[commit_dir]}"

    carton_arr_print project
}

# Load and output a project string.
# Args: dir
# Output: project string
function carton_project_load()
{
    eval "$_CARTON_PROJECT_LOAD_BASE"
    carton_arr_print project
}

# Output a project configuration option value.
# Args: project_str name
# Output: value
function _carton_project_config_get()
{
    declare -r project_str="$1";    shift
    declare -r name="$1";           shift
    declare -A project
    carton_arr_parse project <<<"$project_str"
    GIT_DIR="${project[git_dir]}" git config --get "carton.$name"
}

# Set a project configuration option value.
# Args: project_str name value
function _carton_project_config_set()
{
    declare -r project_str="$1";    shift
    declare -r name="$1";           shift
    declare -r value="$1";          shift
    declare -A project
    carton_arr_parse project <<<"$project_str"
    GIT_DIR="${project[git_dir]}" git config "carton.$name" "$value"
}

# Get a project's tag glob pattern.
# Args: project_str
# Output: tag glob
function carton_project_get_tag_glob()
{
    _carton_project_config_get "$1" tag-glob
}

# Set a project's release tag glob pattern.
# Args: project_str tag_glob
function carton_project_set_tag_glob()
{
    _carton_project_config_set "$1" tag-glob "$2"
}

# Get project's maximum age of commits eligible for publishing during an
# update, in "date" -d option value format.
# Args: project_str
# Output: maximum age
function carton_project_get_update_max_age()
{
    _carton_project_config_get "$1" update-max-age
}

# Set project's maximum age of commits eligible for publishing during an
# update, in "date" -d option value format.
# Args: project_str value
function carton_project_set_update_max_age()
{
    _carton_project_config_set "$1" update-max-age "$2"
}

# Get project's maximum age of commits eligible for publishing during an
# update, as a an epoch.
# Args: project_str
# Output: maximum age epoch
function carton_project_get_update_max_age_epoch()
{
    declare max_age
    max_age=`carton_project_get_update_max_age "$1"`
    date --date="$max_age" "+%s"
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

declare -r _CARTON_PROJECT_GET_COMMIT_LOC='
    declare -r project_str="$1";   shift
    declare -r committish="$1";    shift

    declare -A project
    carton_arr_parse project <<<"$project_str"

    declare commit_hash
    commit_hash=`GIT_DIR="${project[git_dir]}" \
                    git rev-parse --verify "$committish^{commit}"`
    declare -r commit_dir="${project[commit_dir]}/$commit_hash"
'

# Check if a project commit exists.
# Args: project_str committish
function carton_project_has_commit()
{
    declare -r project_str="$1";   shift
    declare -r committish="$1";    shift

    declare -A project
    carton_arr_parse project <<<"$project_str"

    declare commit_hash
    commit_hash=`GIT_DIR="${project[git_dir]}" \
                    git rev-parse --verify "$committish^{commit}"` ||
        return 1
    declare -r commit_dir="${project[commit_dir]}/$commit_hash"

    [ -d "$commit_dir" ]
}

# Create a project commit and output its string.
# Args: project_str committish
# Output: commit string
function carton_project_add_commit()
{
    eval "$_CARTON_PROJECT_GET_COMMIT_LOC"
    carton_assert "! carton_project_has_commit \"\$project_str\" \
                                               \"\$committish\""
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
                                             \"\$committish\""
    carton_commit_load "$commit_dir"
}

# Create or get a project commit and output its string.
# Args: project_str committish
# Output: commit string
function carton_project_add_or_get_commit()
{
    declare -r project_str="$1";   shift
    declare -r commitish="$1";     shift

    if carton_project_has_commit "$project_str" "$committish"; then
        carton_project_get_commit "$project_str" "$committish"
    else
        carton_project_add_commit "$project_str" "$committish"
    fi
}

# Get a built commit's revision number according to the git repository state.
# Args: project_str committish
# Output: commit revision number
function carton_project_get_commit_rev_num()
{
    declare -r project_str="$1";   shift
    declare -r committish="$1";    shift
    declare -A project
    declare commit_str
    declare -A commit
    declare tag_glob
    declare tag_format
    declare ver_tag_name
    declare desc
    declare tag_name
    declare tag_distance
    declare rev_num

    carton_arr_parse project <<<"$project_str"

    carton_assert 'carton_project_has_commit "$project_str" "$committish"'
    commit_str=`carton_project_get_commit "$project_str" "$committish"`
    carton_arr_parse commit <<<"$commit_str"
    carton_assert '"${commit[is_built]}"'

    tag_glob=`GIT_DIR="${project[git_dir]}" \
                git config --get "carton.tag-glob"`
    tag_format=`GIT_DIR="${project[git_dir]}" \
                    git config --get "carton.tag-format"`

    ver_tag_name=`printf "$tag_format" "${commit[dist_ver]}"`

    desc=`GIT_DIR="${project[git_dir]}" \
            git describe --always --long --match="$tag_glob" "$committish"`
    if [[ "$desc" == *-* ]]; then
        # Cut hash off
        desc="${desc%-*}"
        # Cut distance off
        tag_name="${desc%-*}"
        # Cut tag off
        tag_distance="${desc##*-}"
    else
        tag_name=""
        tag_distance=$((`GIT_DIR="${project[git_dir]}" \
                            git rev-list "$committish" | wc -l` - 1))
    fi

    if [ "$ver_tag_name" == "$tag_name" ]; then
        rev_num="$tag_distance"
    else
        rev_num="-$tag_distance"
    fi

    echo "$rev_num"
}

# Delete a project commit.
# Args: project_str committish
function carton_project_del_commit()
{
    eval "$_CARTON_PROJECT_GET_COMMIT_LOC"
    # Override read-only permissions of unfinished builds
    chmod -R u+w "$commit_dir"
    rm -Rf "$commit_dir"
}

declare -r _CARTON_PROJECT_GET_BRANCH_LOC='
    declare -r project_str="$1";   shift
    declare -r branch_name="$1";   shift
    declare -A project
    carton_arr_parse project <<<"$project_str"
    carton_assert "carton_branch_name_is_valid \"${project[git_dir]}\" \
                                               \"\$branch_name\""
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
    GIT_DIR="${project[git_dir]}" \
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

# Remove a project branch.
# Args: project_str branch_name
function carton_project_del_branch()
{
    eval "$_CARTON_PROJECT_GET_BRANCH_LOC"
    carton_assert 'carton_project_has_branch "$project_str" \
                                             "$branch_name"'
    GIT_DIR="${project[git_dir]}" git branch -D "$branch_name" >/dev/null
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

# Publish new revisions for a project commit.
# Args: project_str channel_list committish
function _carton_project_update_commit()
{
    declare -r project_str="$1";    shift
    declare -r channel_list="$1";   shift
    declare -r committish="$1";     shift

    declare commit_str
    declare -A commit
    declare rev_num
    declare rev_str
    declare -A rev

    commit_str=`carton_project_add_or_get_commit "$project_str" "$committish"`
    carton_arr_parse commit <<<"$commit_str"

    if ! "${commit[is_built]}"; then
        return 0
    fi

    rev_num=`carton_project_get_commit_rev_num "$project_str" "$committish"`

    rev_str=`carton_commit_add_or_get_rev "$commit_str" "$rev_num"`
    carton_arr_parse rev <<<"$rev_str"

    if ! "${rev[is_built]}"; then
        return 0
    fi

    if carton_channel_list_is_applicable "$channel_list" "$rev_str"; then
        carton_channel_list_ensure_published "$channel_list" "$rev_str"
    fi
}

# Publish new revisions for project commits (specified via "git rev-list"
# arguments) to a channel list, excluding those beyond update_max_age.
# Args: project_str channel_list_str git_rev_list_arg...
function carton_project_update_commit_list()
{
    declare -r arg_num="$#"
    carton_assert '(( $arg_num >= 3 ))'
    declare -r project_str="$1";        shift
    declare -r channel_list_str="$1";   shift
    declare -A project
    declare max_age_epoch
    declare commit_hash

    carton_arr_parse project <<<"$project_str"
    max_age_epoch=`carton_project_get_update_max_age_epoch "$project_str"`

    # For each specified commit not older than max_age_epoch
    while read -r commit_hash; do
        _carton_project_update_commit "$project_str" \
                                      "$channel_list_str" \
                                      "$commit_hash"
    done < <(
        GIT_DIR="${project[git_dir]}" \
            git rev-list --max-age="$max_age_epoch" "$@"
    )
}

# Publish revisions of commits new to a project branch.
# Args: project_str branch_name
function carton_project_update_branch_new()
{
    declare -r project_str="$1";    shift
    declare -r branch_name="$1";    shift
    carton_assert 'carton_project_has_branch "$project_str" "$branch_name"'

    declare -A project
    declare branch_str
    declare channel_list

    carton_arr_parse project <<<"$project_str"
    branch_str=`carton_project_get_branch "$project_str" \
                                          "$branch_name"`
    channel_list=`carton_branch_get_channel_list "$branch_str"`

    # Publish new commits
    carton_project_update_commit_list "$project_str" "$channel_list" \
                                      "^refs/heads/$branch_name" \
                                      "$branch_name@{upstream}"
    # Update branch reference
    GIT_DIR="${project[git_dir]}" \
        git update-ref "refs/heads/$branch_name" "$branch_name@{upstream}"
}

# Publish revisions of commits affected by addition of tags to a project
# branch.
# Args: project_str branch_name
function carton_project_update_branch_tags()
{
    declare -r project_str="$1";    shift
    declare -r branch_name="$1";    shift
    carton_assert 'carton_project_has_branch "$project_str" "$branch_name"'

    declare -A project
    declare tag_glob
    declare branch_str
    declare channel_list
    declare tag_list_str
    declare -a tag_list
    declare -A tag_map
    declare tag
    declare new_tag_list_str
    declare desc

    carton_arr_parse project <<<"$project_str"
    tag_glob=`carton_project_get_tag_glob "$project_str"`
    branch_str=`carton_project_get_branch "$project_str" \
                                          "$branch_name"`
    channel_list=`carton_branch_get_channel_list "$branch_str"`

    # Build original tag map
    tag_list_str=`carton_branch_get_tag_list "$branch_str"`
    read -r -a tag_list <<<"$tag_list_str"
    tag_map=()
    unset tag
    if [ "${#tag_list[@]}" != 0 ]; then
        for tag in "${tag_list[@]}"; do
            tag_map[$tag]=""
        done
    fi

    # Update commits, starting from the latest, which appear right before a
    # known tag and down to a new tag
    new_tag_list_str=""
    ref="refs/heads/$branch_name"
    while true; do
        desc=`GIT_DIR="${project[git_dir]}" \
                git describe --always --long --match="$tag_glob" "$ref"`
        if [[ "$desc" != *-* ]]; then
            break
        fi
        # Cut hash off
        desc="${desc%-*}"
        # Cut distance off
        tag="${desc%-*}"

        # If it's a new tag
        if [[ -z "${tag_map[$tag]+set}" ]]; then
            carton_project_update_commit_list "$project_str" "$channel_list" \
                                              "^refs/tags/$tag^" "$ref"
        fi

        new_tag_list_str="${new_tag_list_str:+$new_tag_list_str }$tag"
        ref="refs/tags/$tag^"
    done

    # Update tag list
    carton_branch_set_tag_list "$branch_str" "$new_tag_list_str"
}

# Publish a project's branch new commit revisions.
# Args: project_str branch_name
function carton_project_update_branch()
{
    declare -r project_str="$1";    shift
    declare -r branch_name="$1";    shift
    carton_assert 'carton_project_has_branch "$project_str" "$branch_name"'
    carton_project_update_branch_new "$project_str" "$branch_name"
    carton_project_update_branch_tags "$project_str" "$branch_name"
}

# Publish project's new commit revisions.
# Args: project_str
function carton_project_update()
{
    declare -r project_str="$1";   shift

    # For each branch
    for branch_name in `carton_project_list_branches "$project_str"`; do
        carton_project_update_branch "$project_str" "$branch_name"
    done
}

# Skip project's new commits, without publishing.
# Args: project_str
function carton_project_skip()
{
    declare -r project_str="$1";   shift
    declare -A project
    declare branch_name
    declare branch_str
    declare tag_glob
    declare new_tag_list_str
    declare ref
    declare desc

    carton_arr_parse project <<<"$project_str"
    tag_glob=`carton_project_get_tag_glob "$project_str"`

    for branch_name in `carton_project_list_branches "$project_str"`; do
        branch_str=`carton_project_get_branch "$project_str" "$branch_name"`

        # Update branch reference
        GIT_DIR="${project[git_dir]}" \
            git update-ref "refs/heads/$branch_name" \
                           "$branch_name@{upstream}"

        # Update tag list
        new_tag_list_str=""
        ref="refs/heads/$branch_name"
        while true; do
            desc=`GIT_DIR="${project[git_dir]}" \
                    git describe --always --long --match="$tag_glob" "$ref"`
            if [[ "$desc" != *-* ]]; then
                break
            fi
            # Cut hash off
            desc="${desc%-*}"
            # Cut distance off
            tag="${desc%-*}"
            new_tag_list_str="${new_tag_list_str:+$new_tag_list_str }$tag"
            ref="refs/tags/$tag^"
        done
        carton_branch_set_tag_list "$branch_str" "$new_tag_list_str"
    done
}

fi # _CARTON_PROJECT_SH
