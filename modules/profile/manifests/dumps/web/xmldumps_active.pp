class profile::dumps::web::xmldumps_active {
    class {'::dumps::web::xmldumps_active':
        do_acme   => hiera('do_acme'),
        datadir   => '/data/xmldatadumps',
        publicdir => '/data/xmldatadumps/public',
        otherdir  => '/data/xmldatadumps/public/other',
    }
    # copy dumps and other datasets to fallback host(s) and to labs
    class {'::dumps::copying::peers':}
    class {'::dumps::copying::labs':}
}
