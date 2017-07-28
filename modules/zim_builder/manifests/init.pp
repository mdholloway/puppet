class zim_builder {
    include zim_builder::install
    include zim_builder::config
    include zim_builder::service

    apt::pin { 'libxapian-dev':
        pin      => 'release a=jessie-backports',
        priority => '1001'
    }
}
