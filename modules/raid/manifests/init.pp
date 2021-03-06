# == Class: raid
#
# Class to set up monitoring for software and hardware RAID
#
# === Parameters
# * write_cache_policy: if set, it will check that the write cache
#                       policy of all logical drives matches the one
#                       given, normally 'WriteBack' or 'WriteThrough'.
#                       Currently only works for Megacli systems, it is
#                       ignored in all other cases.
# === Examples
#
#  include raid

class raid (
    $write_cache_policy = undef,
){

    if empty($write_cache_policy) {
        $check_raid = '/usr/bin/sudo /usr/local/lib/nagios/plugins/check_raid'
    } else {
        $check_raid = "/usr/bin/sudo /usr/local/lib/nagios/plugins/check_raid --policy ${write_cache_policy}"
    }

    # for 'forking' checks (i.e. all but mdadm, which essentially just reads
    # kernel memory from /proc/mdstat) check every $check_interval
    # minutes instead of default of one minute. If the check is non-OK, retry
    # every $retry_interval.
    $check_interval = 10
    $retry_interval = 5

    if 'megaraid' in $facts['raid'] {
        require_package('megacli')
        $get_raid_status_megacli = '/usr/local/lib/nagios/plugins/get-raid-status-megacli'

        file { $get_raid_status_megacli:
            ensure => present,
            owner  => 'root',
            group  => 'root',
            mode   => '0555',
            source => 'puppet:///modules/raid/get-raid-status-megacli.py';
        }

        sudo::user { 'nagios_megaraid':
            user       => 'nagios',
            privileges => ["ALL = NOPASSWD: ${get_raid_status_megacli}"],
        }

        nrpe::check { 'get_raid_status_megacli':
            command => "/usr/bin/sudo ${get_raid_status_megacli} -c",
        }

        nrpe::monitor_service { 'raid_megaraid':
            description    => 'MegaRAID',
            nrpe_command   => "${check_raid} megacli",
            check_interval => $check_interval,
            retry_interval => $retry_interval,
            event_handler  => "raid_handler!megacli!${::site}",
        }
    }

    if 'hpsa' in $facts['raid'] {
        require_package('hpssacli')

        file { '/usr/local/lib/nagios/plugins/check_hpssacli':
            ensure => present,
            owner  => 'root',
            group  => 'root',
            mode   => '0555',
            source => 'puppet:///modules/raid/dsa-check-hpssacli',
        }

        sudo::user { 'nagios_hpssacli':
            user       => 'nagios',
            privileges => [
                'ALL = NOPASSWD: /usr/sbin/hpssacli controller all show',
                'ALL = NOPASSWD: /usr/sbin/hpssacli controller slot=[0-9] ld all show',
                'ALL = NOPASSWD: /usr/sbin/hpssacli controller slot=[0-9] ld all show detail',
                'ALL = NOPASSWD: /usr/sbin/hpssacli controller slot=[0-9] ld * show',
                'ALL = NOPASSWD: /usr/sbin/hpssacli controller slot=[0-9] pd all show',
                'ALL = NOPASSWD: /usr/sbin/hpssacli controller slot=[0-9] pd [0-9]\:[0-9] show',
                'ALL = NOPASSWD: /usr/sbin/hpssacli controller slot=[0-9] pd [0-9][EIC]\:[0-9]\:[0-9] show',
                'ALL = NOPASSWD: /usr/sbin/hpssacli controller slot=[0-9] pd [0-9][EIC]\:[0-9]\:[0-9][0-9] show',
                'ALL = NOPASSWD: /usr/sbin/hpssacli controller slot=[0-9] show status',
                'ALL = NOPASSWD: /usr/sbin/hpssacli controller slot=[0-9] show detail',
                'ALL = NOPASSWD: /usr/sbin/hpacucli controller all show',
                'ALL = NOPASSWD: /usr/sbin/hpacucli controller slot=[0-9] ld all show',
                'ALL = NOPASSWD: /usr/sbin/hpacucli controller slot=[0-9] ld * show',
                'ALL = NOPASSWD: /usr/sbin/hpacucli controller slot=[0-9] pd all show',
                'ALL = NOPASSWD: /usr/sbin/hpacucli controller slot=[0-9] pd [0-9]\:[0-9] show',
                'ALL = NOPASSWD: /usr/sbin/hpacucli controller slot=[0-9] pd [0-9][EIC]\:[0-9]\:[0-9] show',
                'ALL = NOPASSWD: /usr/sbin/hpacucli controller slot=[0-9] pd [0-9][EIC]\:[0-9]\:[0-9][0-9] show',
                'ALL = NOPASSWD: /usr/sbin/hpacucli controller slot=[0-9] show status',
                'ALL = NOPASSWD: /usr/sbin/hpacucli controller slot=[0-9] show detail',
            ],
        }

        nrpe::monitor_service { 'raid_hpssacli':
            description    => 'HP RAID',
            nrpe_command   => '/usr/local/lib/nagios/plugins/check_hpssacli',
            timeout        => 90, # can take > 10s on servers with lots of disks
            check_interval => $check_interval,
            retry_interval => $retry_interval,
            event_handler  => "raid_handler!hpssacli!${::site}",
        }

        $get_raid_status_hpssacli = '/usr/local/lib/nagios/plugins/get-raid-status-hpssacli'

        file { $get_raid_status_hpssacli:
            ensure => present,
            owner  => 'root',
            group  => 'root',
            mode   => '0555',
            source => 'puppet:///modules/raid/get-raid-status-hpssacli.sh';
        }

        nrpe::check { 'get_raid_status_hpssacli':
            command => "${get_raid_status_hpssacli} -c",
        }
    }

    if 'mpt' in $facts['raid'] {
        package { 'mpt-status':
            ensure => present,
        }

        file { '/etc/default/mpt-statusd':
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0555',
            content => "RUN_DAEMON=no\n",
            before  => Package['mpt-status'],
        }

        nrpe::monitor_service { 'raid_mpt':
            description    => 'MPT RAID',
            nrpe_command   => "${check_raid} mpt",
            check_interval => $check_interval,
            retry_interval => $retry_interval,
            event_handler  => "raid_handler!mpt!${::site}",
        }

        nrpe::check { 'get_raid_status_mpt':
            command => "${check_raid} mpt",
        }
    }

    if 'md' in $facts['raid'] {
        # if there is an "md" RAID configured, mdadm is already installed

        nrpe::monitor_service { 'raid_md':
            description   => 'MD RAID',
            nrpe_command  => "${check_raid} md",
            event_handler => "raid_handler!md!${::site}",
        }

        nrpe::check { 'get_raid_status_md':
            command => 'cat /proc/mdstat',
        }
    }

    file { '/usr/local/lib/nagios/plugins/check_raid':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/raid/check-raid.py';
    }

    sudo::user { 'nagios_raid':
        user       => 'nagios',
        privileges => ['ALL = NOPASSWD: /usr/local/lib/nagios/plugins/check_raid'],
    }
}
