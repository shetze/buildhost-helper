Name:		nexus
Version:	2.12.0
%define UpstreamRelease 01
Release:	02
Summary:	Nexus manages software “artifacts” required for development, deployment, and provisioning.

Group:		unknown
License:	AGPL
URL:		http://nexus.sonatype.org/
Source0:	http://download.sonatype.com/nexus/oss/%{name}-%{version}-%{UpstreamRelease}-bundle.tar.gz
Source1:	nexus.service
Source2:	nexus.env

Requires:	java

%define	__spec_install_post %{nil}
%define	__os_install_post %{_dbpath}/brp-compress
%define debug_package %{nil}
BuildArch: noarch
AutoReq: no
AutoProv: no

%description
Nexus manages software components required for development, deployment, and provisioning. If you develop software, Nexus can help you share those components with other developers and end users. Nexus greatly simplifies the maintenance of your own internal repositories and access to external repositories. With Nexus you can completely control access to, and deployment of, every component in your organization from a single location.

%prep
%setup -q -n %{name}-%{version}-%{UpstreamRelease}


%build

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/opt/sonatype-work
mkdir -p $RPM_BUILD_ROOT/opt/sonatype-%{name}
mv * $RPM_BUILD_ROOT/opt/sonatype-%{name}
mkdir -p $RPM_BUILD_ROOT/usr/lib/systemd/system
install -m 644 %{SOURCE1} $RPM_BUILD_ROOT/usr/lib/systemd/system/
install -m 644 %{SOURCE2} $RPM_BUILD_ROOT/opt/sonatype-%{name}/conf/

%post
useradd --user-group --system --home-dir /opt/sonatype-%{name} nexus

%files
%defattr(-,nexus,nexus,-)
%doc
/opt/sonatype-%{name}
/opt/sonatype-work
/usr/lib/systemd/system/*


%changelog
* Sat Feb 20 2016 Sebastian Hetze <shetze@redhat.com> - 2.12.0-2
- move nexus.env to /opt/sonatype-nexus/conf
* Sat Feb 20 2016 Sebastian Hetze <shetze@redhat.com> - 2.12.0-1
- new upstream version
* Mon Oct 26 2015 Sebastian Hetze <shetze@redhat.com> - 2.11.4-1
- Create spec file for nexus
