#
# Copyright (c) 2012-2013 Red Hat, Inc. All rights reserved.
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

SUBDIRS = lib src tests

CARTON_LIB_DIR = $(pkgdatadir)
CARTON_DATA_DIR = $(localstatedir)/lib/carton

install-data-hook:
	$(MKDIR_P) "$(DESTDIR)$(CARTON_DATA_DIR)"
	mkdir "$(DESTDIR)$(CARTON_DATA_DIR)/project"
	mkdir "$(DESTDIR)$(CARTON_DATA_DIR)/repo"

install-exec-hook:
	$(SED) -e 's#\(CARTON_LIB_DIR=\).*#\1"$(CARTON_LIB_DIR)"#' \
           -e 's#\(CARTON_DATA_DIR=\).*#\1"$${CARTON_DATA_DIR-$(CARTON_DATA_DIR)}"#' \
           -i "$(DESTDIR)$(bindir)/carton-env"
