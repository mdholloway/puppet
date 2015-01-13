# vim:sw=4 ts=4 sts=4 et:
@monitoring::group { 'logstash_eqiad': description => 'eqiad logstash' }

# == Class: role::logstash
#
# Provisions Logstash, Redis, and ElasticSearch.
#
class role::logstash {
    include ::elasticsearch::ganglia
    include ::elasticsearch::nagios::check
    include ::passwords::logstash

    package { 'elasticsearch/plugins':
        provider => 'trebuchet',
    }

    $minimum_master_nodes = $::realm ? {
        'production' => 2,
        'labs'       => 1,
    }
    $expected_nodes = $::realm ? {
        'production' => 2,
        'labs'       => 1,
    }

    class { '::elasticsearch':
        multicast_group      => '224.2.2.5',
        master_eligible      => true,
        minimum_master_nodes => $minimum_master_nodes,
        cluster_name         => "${::realm}-logstash-${::site}",
        heap_memory          => '5G',
        plugins_dir          => '/srv/deployment/elasticsearch/plugins',
        auto_create_index    => true,
        expected_nodes       => $expected_nodes,
        recover_after_nodes  => $minimum_master_nodes,
        recover_after_time   => '1m',
    }

    class { '::redis':
        maxmemory         => '1Gb',
        dir               => '/var/run/redis',
        persist           => undef,
        redis_replication => undef,
        password          => $passwords::logstash::redis,
    }

    # 'redis::ganglia' includes 'redis', and thus must be included below
    # the parametrized class above.
    include ::redis::ganglia

    class { '::logstash':
        heap_memory_mb => 128,
        # TODO: the multiline filter that is used in several places in the
        # current configuration isn't thread safe and can cause crashes or
        # garbled output when used with more than one thread worker.
        filter_workers => 1,
    }

    logstash::input::udp2log { 'mediawiki':
        port => 8324,
    }

    logstash::input::syslog { 'syslog':
        port => 10514,
    }

    logstash::input::redis { 'redis':
        host     => '127.0.0.1',
        key      => 'logstash',
        password => $passwords::logstash::redis,
    }

    logstash::input::gelf { 'gelf':
        port => 12201,
    }

    logstash::conf { 'filter_strip_ansi_color':
        source   => 'puppet:///files/logstash/filter-strip-ansi-color.conf',
        priority => 40,
    }

    logstash::conf { 'filter_syslog':
        source   => 'puppet:///files/logstash/filter-syslog.conf',
        priority => 50,
    }

    logstash::conf { 'filter_mw_via_udp2log':
        source   => 'puppet:///files/logstash/filter-mw-via-udp2log.conf',
        priority => 50,
    }

    logstash::conf { 'filter_mw_via_redis':
        source   => 'puppet:///files/logstash/filter-mw-via-redis.conf',
        priority => 50,
    }

    logstash::conf { 'filter_gelf':
        source   => 'puppet:///files/logstash/filter-gelf.conf',
        priority => 50,
    }

    logstash::conf { 'filter_add_normalized_message':
        source   => 'puppet:///files/logstash/filter-add-normalized-message.conf',
        priority => 60,
    }

    class { '::logstash::output::elasticsearch':
        host            => '127.0.0.1',
        replication     => 'async',
        require_tag     => 'es',
        manage_indices  => true,
        priority        => 90,
    }

}

# == Class: role::logstash::ircbot
#
# Sets up an IRC Bot to log messages from certain IRC channels
class role::logstash::ircbot {
    require ::role::logstash

    $irc_name = $::logstash_irc_name ? {
        undef => "logstash-${::instanceproject}",
        default => $::logstash_irc_name,
    }

    logstash::input::irc { 'freenode':
        user     => $irc_name,
        nick     => $irc_name,
        channels => ['#wikimedia-labs', '#wikimedia-releng'],
    }

    logstash::conf { 'filter_irc_banglog':
        source   => 'puppet:///files/logstash/filter-irc-banglog.conf',
        priority => 50,
    }
}

# == Class: role::logstash::puppetreports
#
# Set up a TCP listener to listen for puppet failure reports.
class role::logstash::puppetreports {
    require ::role::logstash

    if $::realm != 'labs' {
        # Constrain to only labs, security issues in prod have not been worked out yet
        fail('role::logstash::puppetreports may only be deployed to Labs.')
    }

    logstash::input::tcp { 'tcp_json':
        port  => 5229,
        codec => 'json_lines',
    }

    logstash::conf { 'filter_puppet':
        source   => 'puppet:///files/logstash/filter-puppet.conf',
        priority => 50,
    }
}
