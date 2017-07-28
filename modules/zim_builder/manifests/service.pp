class zim_builder::service inherits zim_builder {

    service { 'redis-server':
        ensure  => running,
        enable  => true,
        require => Package['redis-server']
    }

}

