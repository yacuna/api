%define rname Finance-Bitcoin-Yacuna
Name: perl-%{rname}
Version: 0.1
Release: 1%{?dist}
Summary: yacuna.com API connector module
License: LGPL
Group: Development/Libraries
URL: http://search.cpan.org/dist/%{rname}/
Source0: http://search.cpan.org/CPAN/authors/id/P/PH/MARTCHOUK/%{rname}-%{version}.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch: noarch
Requires: perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))
Requires: perl(HTTP::Request)
Requires: perl(WWW::Mechanize)
Requires: perl(MIME::Base64)
Requires: perl(Digest::SHA)
BuildRequires: perl(ExtUtils::MakeMaker) perl(Module::Build) perl(Test::Simple)


%description
This module allows to connect to the api of the bitcoin market Kraken.

Please see http://docs.yacuna.com/api for a catalog of api methods.


%prep
%setup -q -n %{rname}-%{version}


%build
%{__perl} Makefile.PL INSTALLDIRS=vendor
make %{?_smp_mflags}


%install
[ '%{buildroot}' != '/' ] && rm -rf %{buildroot}
make pure_install PERL_INSTALL_ROOT=%{buildroot}

find %{buildroot} -type f -name .packlist -delete
find %{buildroot} -depth -type d -empty -delete

%{_fixperms} %{buildroot}/*


%clean
[ '%{buildroot}' != '/' ] && rm -rf %{buildroot}


%files
%defattr(-,root,root,-)
%doc README
%{perl_vendorlib}/Finance/Bitcoin/Yacuna.pm
%{_mandir}/man3/Finance::Bitcoin::Yacuna.3pm*