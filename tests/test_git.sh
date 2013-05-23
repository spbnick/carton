#
# Test git repository management
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

if [ -z "${_TEST_GIT_SH+set}" ]; then
declare _TEST_GIT_SH=

. carton_util.sh

# Initialize repo
# Args: [dir]
function test_git_init()
{
    git init --quiet "${1-.}"
}

# Commit pre-build-support history
# Args: [dir]
function test_git_commit_pre_build()
(
    cd "${1-.}"
    for f in a b c; do
        echo "$f" > "$f"
        git add *
        git commit --quiet --message "Add $f"
        git tag "add_$f"
    done
)

# Commit v1 build support
# Args: [dir]
function test_git_commit_v1()
(
    cd "${1-.}"
    carton_unindent <<<'
        set -o errexit
        aclocal
        automake --add-missing --copy
        autoconf
    ' > bootstrap
    chmod a+x bootstrap
    carton_unindent <<<'
        AC_PREREQ(2.60)
        AC_INIT([carton-test], [1])
        AM_INIT_AUTOMAKE([1.10 -Wall foreign])
        AC_CONFIG_FILES([Makefile])
        AC_OUTPUT
    ' > configure.ac
    carton_unindent <<<'
        dist_pkgdata_DATA =
        dist_pkgdata_DATA += a
        dist_pkgdata_DATA += b
        dist_pkgdata_DATA += c
    ' > Makefile.am
    git add *
    git commit --quiet --message 'Add build support'
    git tag "add_build"
    git tag "v1_update"
)

# Commit spec file
# Args: [dir]
function test_git_commit_spec()
(
    cd "${1-.}"
    carton_unindent <<<'
        Name:       carton-test
        Version:    1
        Release:    1%{?rev}%{?dist}
        Summary:    Carton test

        License:    GPLv2+
        BuildArch:  noarch
        Source:     %{name}-%{version}.tar.gz

        %description

        %prep
        %setup -q

        %build
        %configure
        make %{?_smp_mflags}

        %install
        make install DESTDIR=%{buildroot}

        %files
        %doc
        %{_datadir}/%{name}

        %changelog
    ' > carton-test.spec
    git add *
    git commit --quiet --message 'Add spec file'
    git tag "add_spec"
)

# Commit pre-v1 history
# Args: [dir]
function test_git_commit_pre_v1()
(
    cd "${1-.}"
    for f in d e f; do
        echo "$f" > "$f"
        echo "dist_pkgdata_DATA += $f" >> Makefile.am
        git add *
        git commit --quiet --message "Add $f"
        git tag "add_$f"
    done
)

# Tag v1
# Args: [dir]
function test_git_tag_v1()
(
    cd "${1-.}"
    git tag --annotate --message "Release v1" v1
)

# Commit post-v1 history
# Args: [dir]
function test_git_commit_post_v1()
(
    cd "${1-.}"
    for f in g h i; do
        echo "$f" > "$f"
        echo "dist_pkgdata_DATA += $f" >> Makefile.am
        git add *
        git commit --quiet --message "Add $f"
        git tag "add_$f"
    done
)

# Commit v2 update
# Args: [dir]
function test_git_commit_v2()
(
    cd "${1-.}"
    sed -e '/\[carton-test\]/ s/\[1\]/[2]/' -i configure.ac
    sed -e "/Version:/ s/1/2/" -i carton-test.spec
    git commit --quiet --all --message 'Increase version'
    git tag "v2_update"
)

# Commit pre-v2 history
# Args: [dir]
function test_git_commit_pre_v2()
(
    cd "${1-.}"
    for f in j k l; do
        echo "$f" > "$f"
        echo "dist_pkgdata_DATA += $f" >> Makefile.am
        git add *
        git commit --quiet --message "Add $f"
        git tag "add_$f"
    done
)

# Tag v2
# Args: [dir]
function test_git_tag_v2()
(
    cd "${1-.}"
    git tag --annotate --message "Release v2" v2
)

# Make complete test git repo
# Args: [dir]
function test_git_make()
{
    declare -r dir="${1-.}"

    for f in init \
             commit_pre_build \
             commit_v1 \
             commit_spec \
             commit_pre_v1 \
             tag_v1 \
             commit_post_v1 \
             commit_v2 \
             commit_pre_v2 \
             tag_v2; do
        "test_git_$f" "$dir"
    done
}

fi # _TEST_GIT_SH
