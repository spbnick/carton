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

# Initialize data directory.
function carton_init()
{
    carton_assert "[ -d \"\$CARTON_DATA_DIR\" ]"
    mkdir "$CARTON_PROJECT_LIST_DIR"
    mkdir "$CARTON_REPO_LIST_DIR"
}

# Cleanup data directory.
function carton_cleanup()
{
    carton_assert "[ -d \"\$CARTON_DATA_DIR\" ]"
    rm -Rf "$CARTON_REPO_LIST_DIR"
    rm -Rf "$CARTON_PROJECT_LIST_DIR"
}

fi # _CARTON_SH
