Name:       carton
Version:    1
Release:    1%{?rev}%{?dist}
Summary:    Carton build server

License:    GPLv2+
BuildArch:  noarch
Source:     %{name}-%{version}.tar.gz

Requires:   git
Requires:   rpm-build
Requires:   createrepo
Requires:   thud

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
%{_localstatedir}/lib/%{name}
%{_datadir}/%{name}

%changelog
