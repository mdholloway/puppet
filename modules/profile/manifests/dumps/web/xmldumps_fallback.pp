class profile::dumps::web::xmldumps_fallback {
    class {'::dumps::web::xmldumps':
        do_acme   => hiera('do_acme'),
        datadir   => '/data/xmldatadumps',
        publicdir => '/data/xmldatadumps/public',
        otherdir  => '/data/xmldatadumps/public/other',
    }
}
