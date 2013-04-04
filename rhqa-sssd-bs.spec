Name:       rhqa-sssd-bs
Version:    1
Release:    1%{?build}%{?dist}
Summary:    Red Hat QA SSSD team build server

License:    GPLv2+
BuildArch:  noarch
Source:     %{name}-%{version}.tar.gz

Requires:   git
Requires:   autoconf
Requires:   automake
Requires:   libtool
Requires:   rpm-build
Requires:   createrepo

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
%{_bindir}/%{name}*

%changelog
