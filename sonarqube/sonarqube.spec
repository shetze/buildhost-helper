Name:		sonarqube
Version:	4.5.6
Release:	01
Summary:	An open source platform for continuous inspection of code quality.

Group:		Development/Tools
License:	LGPLv3
URL:		http:/sonarsource.org/
Source0:	https://sonarsource.bintray.com/Distribution/sonarqube/sonarqube-%{version}.zip
Source1:	sonar.service

Requires:	java

%define __spec_install_post %{nil}
%define __os_install_post %{_dbpath}/brp-compress
%define debug_package %{nil}
BuildArch: noarch
AutoReq: no
AutoProv: no

%description
SonarQube (previously known as Sonar) is an open source platform for Continuous Inspection of code quality. It is written in java and supported for 25+ languages such as Java, C/C++, C#, PHP, Flex, Groovy, JavaScript, Python, PL/SQL, COBOL, etc, it is also used for Android Development

%prep
%setup -q -n %{name}-%{version}


%build

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/opt/sonarqube
rm -rv bin/windows*
rm -rv bin/solaris*
rm -rv bin/macosx*
mv * $RPM_BUILD_ROOT/opt/sonarqube
mkdir -p $RPM_BUILD_ROOT/usr/lib/systemd/system
install -m 644 %{SOURCE1} $RPM_BUILD_ROOT/usr/lib/systemd/system/

%post
useradd --user-group --system --home-dir /opt/sonarqube sonar

%files
%defattr(-,sonar,sonar,-)
%doc
/opt/sonarqube
/usr/lib/systemd/system/*


%changelog
* Sat Feb 20 2016 Sebastian Hetze <shetze@redhat.com> - 4.5.6-1
- Create spec file for sonarqube
