package { vim: ensure => 'installed', }
package { screen: ensure => 'installed', }
package { smartmontools: ensure => 'installed', }
package { iptraf: ensure => 'installed', }
package { bwm-ng: ensure => 'installed', }
package { tcpdump: ensure => 'installed', }
package { wget: ensure => 'installed', }
package { pv: ensure => 'installed', }
package { atop: ensure => 'installed', }
package { iotop: ensure => 'installed', }
package { lshw: ensure => 'installed', }
package { rsyslog: ensure => 'installed', }
package { tmux: ensure => 'installed', }

Exec {
  path => [
    '/usr/local/bin',
    '/usr/local/sbin',
    '/usr/bin',
    '/usr/sbin',
    '/bin',
    '/sbin'
  ],
}

exec {'test': 
  command => 
    "wget -P /tmp https://apt.puppetlabs.com/puppetlabs-release-${lsbdistcodename}.deb ; dpkg -i /tmp/puppetlabs-release-${lsbdistcodename}.deb ; rm -f /tmp/puppetlabs-release-${lsbdistcodename}.deb",
  creates => '/etc/apt/sourceslist.d/puppetlabs-release.list',
}


$backports_file = "/etc/apt/sources.list.d/backports.list"
$backports_contents = "deb http://us.debian.org/debian-backports wheezy-backports main"
exec {'backports':
  command => "echo '$backports_contents' > $backports_file",
  creates => "$backports_file",
  logoutput => on_failure,
}

exec {'git':
  command => "apt-get -t wheezy-backports install git",
  creates => '/usr/bin/git',
  logoutput => on_failure,
}
