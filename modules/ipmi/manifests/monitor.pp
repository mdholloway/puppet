class ipmi::monitor {
    require_package('freeipmi-tools')

    # ipmi_devintf needs to be loaded for the checks to work properly (T167121)
    file { '/usr/local/lib/nagios/plugins/check_ipmi_sensor':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/base/monitoring/check_ipmi_sensor',
    }

    kmod::module { 'ipmi_devintf':
        ensure => present,
    }

    ::sudo::user { 'nagios_ipmi_temp':
        user       => 'nagios',
        privileges => ['ALL = NOPASSWD: /usr/sbin/ipmi-sel, /usr/sbin/ipmi-sensors'],
    }

    nrpe::monitor_service { 'check_ipmi_temp':
        description    => 'IPMI Temperature',
        nrpe_command   => '/usr/local/lib/nagios/plugins/check_ipmi_sensor --noentityabsent -T Temperature -ST Temperature --nosel',
        check_interval => 30,
        retry_interval => 10,
        timeout        => 60,
    }
}
