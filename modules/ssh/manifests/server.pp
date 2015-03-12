class ssh::server (
    $listen_port = '22',
    $listen_address = undef,
    $permit_root = true,
) {
    package { 'openssh-server':
        ensure => latest;
    }

    service { 'ssh':
        ensure    => running,
        subscribe => File['/etc/ssh/sshd_config'],
    }

    if ($::realm == 'labs') {
        $ssh_authorized_keys_file ='/etc/ssh/userkeys/%u /public/keys/%u/.ssh/authorized_keys'
    } else {
        # Lucid doesn't seem to like this at all, ssh refuses to start
        if os_version('ubuntu > lucid') {
            $ssh_authorized_keys_file ='/etc/ssh/userkeys/%u .ssh/authorized_keys .ssh/authorized_keys2'
        }
    }

    file { '/etc/ssh/userkeys':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        recurse => true,
        purge   => true,
    }

    file { '/etc/ssh/sshd_config':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('ssh/sshd_config.erb'),
    }

    # publish this hosts's host key; prefer ECDSA -> RSA (no DSA)
    #
    # There's two issues that stop us from using ed25519 keys:
    #
    # 1) We need to still be able to collect on precise hosts and precise's
    # OpenSSH version does not support ed25519. While you'd think we could
    # export both and use a puppet collector filter to exclude type !=
    # 'ed25519', puppet's sshkey type is stupid and uses namevar for the
    # hostname and namevar is unique, so you can't define two different keys of
    # a different type for the same host. This is waiting until <= precise is
    # gone.
    #
    # 2) Puppet sshkey is also stupid in that it hardcodes acceptable types in
    # its code, and ed25519 is not a valid type in trusty's version (3.4.3). It
    # is in jessie's version (3.7.3), though. So this is waiting until <=
    # trusty is gone, or until we backport a newer version of puppet to trusty.

    if $::sshecdsakey {
        # facter bug: one key regardless of ECDSA keytype;
        # no type exported as a separate variable
        $key  = $::sshecdsakey
        $type = 'ecdsa-sha2-nistp256'
    } elsif $::sshrsakey {
        $key  = $::sshrsakey
        $type = 'ssh-rsa'
    } else {
        err("No valid SSH host key found for ${::fqdn}")
    }

    debug("Storing ${type} SSH hostkey for ${::fqdn}")
    @@sshkey { $::fqdn:
        ensure       => present,
        type         => $type,
        key          => $key,
        host_aliases => [ $::hostname, $::ipaddress, $::ipaddress6 ],
    }
}
