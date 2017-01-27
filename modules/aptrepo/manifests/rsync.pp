# sets up rsync of APT repos between 2 servers
# activates rsync for push from the primary to secondary
class aptrepo::rsync {

    $primary_server = hiera('install_server', 'install1001.wikimedia.org')

    # only activate rsync/firewall hole on the server that is NOT active
    if $::fqdn != $primary_server {

        $ensure = 'present'
        include rsync::server

        # just APT data (/srv/wikimedia/)
        rsync::server::module { 'aptrepo':
            ensure      => $aptrepo::rsync::ensure,
            path        => $aptrepo::basedir,
            read_only   => 'no',
            hosts_allow => $primary_server,
        }
        # also other data like junos, megacli, (all of /srv/)
        rsync::server::module { 'install-srv':
            ensure      => $aptrepo::rsync::ensure,
            path        => '/srv',
            read_only   => 'no',
            hosts_allow => $primary_server,
        }

    } else {
        $ensure = 'absent'
    }

    ferm::service { 'aptrepo-rsync':
        ensure => $aptrepo::rsync::ensure,
        proto  => 'tcp',
        port   => '873',
        srange => "@resolve(${primary_server})",
    }
}
