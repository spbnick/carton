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
. carton_commit.sh

# Load base project properties from arguments.
# Args: _dir
declare -r _CARTON_PROJECT_LOAD_BASE='
    declare -r _dir="$1";   shift
    carton_assert "[ -d \"\$_dir\" ]"
    declare -A _project=(
        [dir]="$_dir"
        [git_dir]="$_dir/git"
        [commit_dir]="$_dir/commit"
    )
'

# Load additional project properties.
declare -r _CARTON_PROJECT_LOAD_PROPS='
    _project+=(
        [tag_glob]=`GIT_DIR="${_project[git_dir]}" \
                        git config --get "carton.tag-glob"`
        [tag_format]=`GIT_DIR="${_project[git_dir]}" \
                        git config --get "carton.tag-format"`
    )
'

# Initialize a project.
# Args: _project_var _dir _repo_url [[_tag_glob _tag_format] _update_max_age]
function carton_project_init()
{
    declare -r arg_num="$#"
    carton_assert '[ $arg_num == 3 || $arg_num == 5 || $arg_num == 6 ]'

    declare -r _project_var="$1";       shift
    carton_assert 'carton_is_valid_var_name "$_project_var"'
    eval "$_CARTON_PROJECT_LOAD_BASE"
    declare -r _repo_url="$1";          shift
    declare -r _tag_glob="${1-v*}";     shift
    declare -r _tag_format="${1-v%s}";  shift
    declare -r _update_max_age="${1-@0}";  shift

    (
        export GIT_DIR="${_project[git_dir]}"
        git init --quiet --bare
        git config carton.tag-glob "$_tag_glob"
        git config carton.tag-format "$_tag_format"
        git config carton.update-max-age "$_update_max_age"
        git config carton.tag-list ""
        git remote add origin "$_repo_url"
        git fetch --quiet
    )
    mkdir "${_project[commit_dir]}"

    eval "$_CARTON_PROJECT_LOAD_PROPS"

    carton_arr_copy "$_project_var" _project
}

# Load a project.
# Args: _project_var _dir
function carton_project_load()
{
    declare -r _project_var="$1";   shift
    carton_assert 'carton_is_valid_var_name "$_project_var"'
    eval "$_CARTON_PROJECT_LOAD_BASE
          $_CARTON_PROJECT_LOAD_PROPS"
    carton_arr_copy "$_project_var" _project
}

declare -r _CARTON_PROJECT_GET_COMMIT_LOC='
    declare -r _project_var="$1";   shift
    carton_assert "carton_is_valid_var_name \"\$_project_var\""
    declare -r _committish="$1";    shift

    declare -A _project
    carton_arr_copy _project "$_project_var"

    declare _commit_hash
    _commit_hash=`GIT_DIR="${_project[git_dir]}" \
                    git rev-parse --verify "$_committish"`
    declare -r _commit_dir="${_project[commit_dir]}/$_commit_hash"
'

declare -r _CARTON_PROJECT_GET_COMMIT_PROPS='
    declare _commit_desc
    _commit_desc=`git describe --long \
                               --match="${_project[tag_glob]}" \
                               "$_commit_hash" | cut -d- -f1-2 ||
                    { [ $? == 128 ] && echo "-"; } ||
                        false`

    declare _commit_tag_name
    _commit_tag_name="${_commit_desc%-*}"

    declare _commit_tag_distance
    _commit_tag_distance="${_commit_desc#*-}"
'

# Check if a project commit exists.
# Args: _project_var _committish
function carton_project_has_commit()
{
    eval "$_CARTON_PROJECT_GET_COMMIT_LOC"
    [ -d "$_commit_dir" ]
}

# Create a project commit.
# Args: _commit_var _project_var _committish
function carton_project_add_commit()
{
    declare -r _commit_var="$1";    shift
    carton_assert 'carton_is_valid_var_name "$_commit_var"'
    eval "$_CARTON_PROJECT_GET_COMMIT_LOC"
    carton_assert "! carton_project_has_commit \"\$_project_var\" \
                                               \"\$_commit_hash\""
    mkdir "$_commit_dir"
    carton_commit_init "$_commit_var" "$_commit_dir" < <(
        GIT_DIR="${_project[git_dir]}" \
            git archive --format=tar "$_commit_hash"
    )
}

# Get a project commit.
# Args: _commit_var _project_var _committish
function carton_project_get_commit()
{
    declare -r _commit_var="$1";    shift
    carton_assert 'carton_is_valid_var_name "$_commit_var"'
    eval "$_CARTON_PROJECT_GET_COMMIT_LOC"
    carton_assert "carton_project_has_commit \"\$_project_var\" \
                                             \"\$_commit_hash\""
    carton_commit_load "$_commit_var" "$_commit_dir"
}

# Create or get a project commit.
# Args: _commit_var _project_var _committish
function carton_project_add_or_get_commit()
{
    declare -r _commit_var="$1";    shift
    carton_assert 'carton_is_valid_var_name "$_commit_var"'
    declare -r _project_var="$1";   shift
    carton_assert 'carton_is_valid_var_name "$_project_var"'
    declare -r _commitish="$1";     shift

    if carton_project_commit_exists "$_project_var" "$_committish"; then
        carton_project_get_commit "$_commit_var" \
                                  "$_project_var" "$_committish"
    else
        carton_project_add_commit "$_commit_var" \
                                  "$_project_var" "$_committish"
    fi
}

# Delete a project commit.
# Args: _project_var _committish
function carton_project_del_commit()
{
    eval "$_CARTON_PROJECT_GET_COMMIT_LOC"
    rm -Rf "$_commit_dir"
}

# Determine revision number based on version tag format/commit distribution
# version and the closest version tag.
# Args: tag_format ver tag_name tag_distance
# Output: revision number
function _carton_project_make_rev_num()
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
    declare -r _project_var="$1";   shift
    carton_assert "carton_is_valid_var_name \"\$_project_var\""
    declare -r _branch_name="$1";   shift
    carton_assert "carton_branch_name_is_valid \"\$_branch_name\""
    declare -A _project
    carton_arr_copy _project "$_project_var"
'

# Output project branch names, one per line.
# Args: _project_var
function carton_project_list_branches()
{
    declare -r _project_var="$1";   shift
    carton_assert 'carton_is_valid_var_name "$_project_var"'
    declare -A _project
    carton_arr_copy _project "$_project_var"
    declare ref

    for ref in `GIT_DIR="${_project[git_dir]}" \
                    git for-each-ref --format='%(refname)' refs/heads/`; do
        echo "${ref#refs/heads/}"
    done
}

# Check if a project branch exists.
# Args: _project_var _branch_name
function carton_project_has_branch()
{
    eval "$_CARTON_PROJECT_GET_BRANCH_LOC"
    GIT_DIR="${_branch[git_dir]}" \
        git show-ref --quiet --verify "refs/heads/$_branch_name"
}

# Create a project branch.
# Args: _project_var _branch_name [_channel_list]
function carton_project_add_branch()
{
    declare -r _branch_var="$1";    shift
    carton_assert 'carton_is_valid_var_name "$_branch_var"'
    eval "$_CARTON_PROJECT_GET_BRANCH_LOC"
    carton_assert '! carton_project_has_branch "$_project_var" \
                                               "$_branch_name"'
    GIT_DIR="${_project[git_dir]}" \
        git branch --track "$_branch_name" \
               "remotes/origin/$_branch_name" >/dev/null
    carton_branch_init _branch_var "${_project[git_dir]}" "$_branch_name" "$@"
}

# Get a project branch.
# Args: _project_var _branch_name
function carton_project_get_branch()
{
    declare -r _branch_var="$1";    shift
    carton_assert 'carton_is_valid_var_name "$_branch_var"'
    eval "$_CARTON_PROJECT_GET_BRANCH_LOC"
    carton_assert 'carton_project_has_branch "$_project_var" \
                                             "$_branch_name"'
    carton_branch_load _branch_var "${_project[git_dir]}" "$_branch_name"
}

# Fetch from remote.
# Args: _project_var
function carton_project_fetch()
{
    declare -r _project_var="$1";   shift
    carton_assert 'carton_is_valid_var_name "$_project_var"'
    declare -A _project
    carton_arr_copy __project "$_project_var"

    GIT_DIR="${_project[git_dir]}" git fetch --quiet
}

# Publish new commit revisions.
# Args: __project_var
function carton_project_update()
{
    declare -r __project_var="$1";   shift
    carton_assert 'carton_is_valid_var_name "$__project_var"'
    declare -A __project
    carton_arr_copy __project "$__project_var"

    (
        declare __max_age
        declare __max_age_stamp
        declare __tag
        declare -a __old_tag_list=()
        declare -A __old_tag_map=()
        declare -A __tag_rev_map=()
        declare __commit_hash
        declare __commit_stamp
        declare __commit_rev_num
        declare __branch_name
        declare __branch_hash
        declare -A __branch
        declare __last_tag_name=""
        declare __last_tag_dist=1
        declare -A __commit
        declare -A __rev
        declare __channel_list

        cd "${__project[git_dir]}"

        __max_age=`git config --get "carton.update-max-age"`
        __max_age_stamp=`date --date="$__max_age" "+%s"`

        # Read old tag list into a tag->hash map
        read -r -a __old_tag_list < <(git config --get "carton.tag-list")
        if [ "${#__old_tag_list[@]}" != 0 ]; then
            for __tag in "${__old_tag_list[@]}" do
                __commit_hash=`git rev-list -n1 "$__tag"`
                __old_tag_map[$__tag]="$__commit_hash"
            done
        fi

        # Map commit hashes to tags
        while read -r __commit_hash __tag; do
            __tag_rev_map[$__commit_hash]="${__tag#refs/tags/}"
        done < <(
            git for-each-ref --sort=taggerdate \
                             --format='%(objectname) %(refname)' \
                             "refs/tags/${__project[tag_glob]}"
        )

        # For each branch
        for __branch_name in `carton_project_list_branches __project`; do
            carton_project_get_branch __branch __project "$__branch_name"
            carton_branch_get_channel_list __channel_list __branch
            __branch_hash=`git rev-list -n1 refs/heads/$__branch_name`

            # For each commit in remote branch
            while read -r __commit_stamp __commit_hash; do
                # If the commit has a tag
                if [ -n "${__tag_rev_map[$__commit_hash]+set}" ]; then
                    __last_tag_name="${__tag_rev_map[$__commit_hash]}"
                    __last_tag_distance=0
                fi

                # If the commit is within update-max-age
                if ((__commit_stamp >= __max_age_stamp)) &&
                   # and if the commit is new to our branch
                   [[ -z "$__branch_hash" ||
                      # or the commit's last seen tag is new
                      -z "${__old_tag_map[$__last_tag]+set}" ]]; then
                    # Publish commit revision
                    carton_project_add_or_get_commit __commit __project \
                                                     "$__commit_hash"
                    if "${__commit[is_built]}"; then
                        __commit_rev_num=`_carton_project_make_rev_num \
                                            "${__project[tag_format]}" \
                                            "${__commit[dist_ver]}"
                                            "$__last_tag_name" \
                                            "$__last_tag_distance"`
                        if ! carton_commit_has_rev __commit
                                                   "$__commit_rev_num"; then
                            carton_commit_add_rev __rev __commit \
                                                  "$__commit_rev_num"
                            if "${__rev[is_built]}"; then
                                if carton_channel_list_is_applicable \
                                        __channel_list __rev; then
                                    carton_channel_list_publish \
                                        __channel_list __rev
                                fi
                            fi
                        fi
                    fi
                fi

                # If this is the last commit seen by our branch
                if [ "$__commit_hash" == "$__branch_hash" ]; then
                    # Consider all following commits as new
                    __branch_hash=
                # else, if this commit is new to our branch
                elif [ -z "$__branch_hash" ]; then
                    # Advance branch
                    git update-ref "refs/heads/$__branch_name" \
                                   "$__commit_hash"
                fi

                __last_tag_distance=$((__last_tag_distance + 1))
            done < <(
                git rev-list --reverse --timestamp \
                             "refs/heads/$__branch_name@{upstream}"
            )
        done

        # Remember new tag list
        git config carton.tag-list "${!__tag_rev_map[@]}"
    )
}

fi # _CARTON_PROJECT_SH
