class dumps::copying::labs {
    file { '/usr/local/bin/wmfdumpsmirror.py':
        ensure => 'present',
        mode   => '0755',
        source => 'puppet:///modules/dumps/copying/wmfdumpsmirror.py',
    }

    file{ '/usr/local/sbin/labs-rsync-cron.sh':
        ensure => 'present',
        mode   => '0755',
        source => 'puppet:///modules/dumps/copying/labs-rsync-cron.sh',
    }

    cron { 'dumps_labs_rsync':
        ensure      => 'present',
        user        => 'root',
        minute      => '50',
        hour        => '3',
        command     => '/usr/local/sbin/labs-rsync-cron.sh',
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        require     => File['/usr/local/bin/wmfdumpsmirror.py',
                            '/usr/local/sbin/labs-rsync-cron.sh'],
    }
}

