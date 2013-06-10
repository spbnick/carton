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

TESTS = test-all
TESTS_ENVIRONMENT = PATH="$(srcdir):$(top_srcdir)/src:$$PATH"

dist_noinst_DATA = \
    test_git.sh

dist_noinst_SCRIPTS = \
    test-all            \
    test-branch         \
    test-channel		\
    test-channel-list	\
    test-commit         \
    test-project        \
    test-project-update \
    test-repo           \
    test-repo-list      \
    test-rev

check_DATA = $(dist_noinst_DATA)
check_SCRIPTS = $(dist_noinst_SCRIPTS)
