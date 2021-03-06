# filtertags: labs-project-tools
class role::toollabs::k8s::webproxy {

    $master_host = hiera('k8s_master')
    $etcd_url = join(prefix(suffix(hiera('flannel::etcd_hosts'), ':2379'), 'https://'), ',')

    ferm::service { 'flannel-vxlan':
        proto => udp,
        port  => 8472,
    }

    class { '::k8s::flannel':
        etcd_endpoints => $etcd_url,
    }

    class { '::toollabs::kube2proxy':
        master_host => $master_host,
    }

    class { '::k8s::infrastructure_config':
        master_host => $master_host,
    }

    class { '::k8s::proxy':
        master_host => $master_host,
    }

    # The kubelet service is installed automatically as part of the kubernetes-node
    # deb, we don't want it to be running on tools-proxy - so we are explicitly ensuring
    # it's stopped
    service { 'kubelet':
        ensure => stopped,
    }
}
