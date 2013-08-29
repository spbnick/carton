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
. thud_misc.sh

declare -r CARTON_LOCK_FILE="$CARTON_DATA_DIR/lock.pid"
declare -r CARTON_LOCK_INTERVAL="5s"

# Lock the data directory on behalf of the current shell.
# Args: [timeout]
function carton_lock()
{
    thud_assert '[ -d "$CARTON_DATA_DIR" ]'
    thud_assert '[ -w "$CARTON_DATA_DIR" ]'

    declare deadline
    if [ -n "${1+set}" ]; then
        deadline=`date --date="$1" +%s`
    fi

    # Spin-lock
    while ! ( set -o noclobber && echo $$ >"$CARTON_LOCK_FILE" ) 2>/dev/null; do
        if [ -n "$deadline" ] && ((`date +%s` > deadline)); then
            return 1
        fi
        sleep "$CARTON_LOCK_INTERVAL"
    done
}

# Check if the data directory is locked.
function carton_locked()
{
    [ -f "$CARTON_LOCK_FILE" ]
}

# Check if the data directory is locked by the current shell.
function carton_owned()
{
    declare lock_pid
    lock_pid=`< "$CARTON_LOCK_FILE"` 2>/dev/null &&
        [ "$$" == "$lock_pid" ]
}

# Unlock the data directory locked by the current shell.
function carton_unlock()
{
    thud_assert 'carton_owned'
    rm "$CARTON_LOCK_FILE"
}

# Unlock the data directory locked by any shell.
function carton_breakin()
{
    thud_assert 'carton_locked'
    rm "$CARTON_LOCK_FILE"
}

# Initialize data directory.
function carton_init()
{
    thud_assert "[ -d \"\$CARTON_DATA_DIR\" ]"
    mkdir "$CARTON_PROJECT_LIST_DIR"
    mkdir "$CARTON_REPO_LIST_DIR"
}

# Cleanup data directory.
function carton_cleanup()
{
    thud_assert "[ -d \"\$CARTON_DATA_DIR\" ]"
    rm -Rf "$CARTON_REPO_LIST_DIR"
    rm -Rf "$CARTON_PROJECT_LIST_DIR"
}

fi # _CARTON_SH
