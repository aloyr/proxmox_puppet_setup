package { atop: ensure => 'installed', }
package { bwm-ng: ensure => 'installed', }
package { curl: ensure => 'installed', }
package { cron-apt: ensure => 'installed', }
package { htop: ensure => 'installed', }
package { iotop: ensure => 'installed', }
package { iptraf: ensure => 'installed', }
package { lshw: ensure => 'installed', }
package { pv: ensure => 'installed', }
package { rsyslog: ensure => 'installed', }
package { screen: ensure => 'installed', }
package { smartmontools: ensure => 'installed', }
package { tcpdump: ensure => 'installed', }
package { tmux: ensure => 'installed', }
#package { vim: ensure => 'installed', }
package { wget: ensure => 'installed', }

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

exec {'no_enterprise':
  command => "sed -i ’s/^\([^#]\)/#\1/g’ /etc/apt/sources.list.d/pve-enterprise.list",
  unless => "grep ^# /etc/apt/sources.list.d/pve-enterprise.list",
}

exec {'test': 
  command => 
    "wget -P /tmp https://apt.puppetlabs.com/puppetlabs-release-pc1-${lsbdistcodename}.deb ; dpkg -i /tmp/puppetlabs-release-${lsbdistcodename}.deb ; rm -f /tmp/puppetlabs-release-pc1-${lsbdistcodename}.deb",
  creates => '/etc/apt/sourceslist.d/puppetlabs-pc1.list',
}


package { git: ensure => 'installed', }
#$backports_file = "/etc/apt/sources.list.d/backports.list"
##$backports_contents = "deb http://us.debian.org/debian-backports wheezy-backports main"
#$backports_contents = "deb http://ftp.de.debian.org/debian wheezy-backports main"
#exec {'backports':
#  command => "echo '$backports_contents' > $backports_file",
#  creates => "$backports_file",
#  logoutput => on_failure,
#}
#
#exec {'git':
#  command => "apt-get update ; apt-get -t wheezy-backports install git",
#  creates => '/usr/bin/git',
#  logoutput => on_failure,
#  require => Exec ['no_enterprise'],
#}

exec {'set_prompt.sh':
  command => "wget -O /etc/profile.d/set_prompt.sh https://raw.githubusercontent.com/aloyr/proxmox_puppet_setup/master/set_prompt.sh",
  creates => '/etc/profile.d/set_prompt.sh',
}

exec {'toprc':
  command => "wget -O /root/.toprc https://raw.githubusercontent.com/aloyr/proxmox_puppet_setup/master/toprc",
  creates => '/root/.toprc',
}

package {'vim':
  ensure => 'installed',
  require => Exec ['no_enterprise'],
}

package {'mdadm':
  ensure => 'installed',
  require => Exec ['no_enterprise'],
}

class timezone {
  package { "tzdata":
    ensure => installed
  }
}

class timezone::central inherits timezone {
  file { "/etc/localtime":
    require => Package["tzdata"],
    ensure => file,
    content => file("/usr/share/zoneinfo/US/Central"),
  }
}

class timezone::eastern inherits timezone {
  file { "/etc/localtime":
    require => Package["tzdata"],
    ensure => file,
    content => file("/usr/share/zoneinfo/US/Eastern"),
  }
}

class timezone::pacific inherits timezone {
  file { "/etc/localtime":
    require => Package["tzdata"],
    ensure => file,
    content => file("/usr/share/zoneinfo/US/Pacific"),
  }
}

class timezone::mountain inherits timezone {
  file { "/etc/localtime":
    require => Package["tzdata"],
    ensure => file,
    content => file("/usr/share/zoneinfo/US/Mountain"),
  }
}

include timezone
include timezone::central
