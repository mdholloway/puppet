class dumps::web::dirs(
    $datadir = '/data/xmldatadumps',
    $publicdir = '/data/xmldatadumps/public',
    $otherdir = '/data/xmldatadumps/public/other',
) {
    # Please note that this is incomplete, but new directories
    # should be defined in puppet (here).
    $analyticsdir             = "${otherdir}/analytics"
    $othermiscdir             = "${otherdir}/misc"
    $othertestfilesdir        = "${otherdir}/testfiles"
    $otherdir_wikidata_legacy = "${otherdir}/wikidata"
    $otherdir_wikibase        = "${otherdir}/wikibase/"
    $relative_wikidatawiki    = 'other/wikibase/wikidatawiki'
    $xlationdir               = "${otherdir}/contenttranslation"
    $centralauthdir           = '/data/xmldatadumps/private/centralauth'
    $cirrussearchdir          = "${otherdir}/cirrussearch"
    $medialistsdir            = "${otherdir}/imageinfo"
    $pagetitlesdir            = "${otherdir}/pagetitles"
    $mediatitlesdir           = "${otherdir}/mediatitles"
    $categoriesrdf            = "${otherdir}/categoriesrdf"

    file { $datadir:
        ensure => 'directory',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    file { $publicdir:
        ensure => 'directory',
        mode   => '0775',
        owner  => 'datasets',
        group  => 'datasets',
    }

    file { $otherdir:
        ensure => 'directory',
        mode   => '0755',
        owner  => 'datasets',
        group  => 'datasets',
    }

    file { $analyticsdir:
        ensure => 'directory',
        mode   => '0755',
        owner  => 'datasets',
        group  => 'datasets',
    }

    file { $othermiscdir:
        ensure => 'directory',
        mode   => '0755',
        owner  => 'datasets',
        group  => 'datasets',
    }

    file { $othertestfilesdir:
        ensure => 'directory',
        mode   => '0755',
        owner  => 'datasets',
        group  => 'datasets',
    }

    file { $otherdir_wikibase:
        ensure => 'directory',
        mode   => '0755',
        owner  => 'datasets',
        group  => 'datasets',
    }

    file { "${publicdir}/${relative_wikidatawiki}":
        ensure => 'directory',
        mode   => '0755',
        owner  => 'datasets',
        group  => 'datasets',
    }

    # T72385
    # needs to be relative because it is mounted via NFS at differing names
    file { "${publicdir}/wikidatawiki/entities":
        ensure => 'link',
        target => "../${relative_wikidatawiki}",
    }

    # Legacy
    file { $otherdir_wikidata_legacy:
        ensure => 'directory',
        mode   => '0755',
        owner  => 'datasets',
        group  => 'datasets',
    }

    file { $xlationdir:
        ensure => 'directory',
        mode   => '0755',
        owner  => 'datasets',
        group  => 'datasets',
    }

    file { $centralauthdir:
        ensure => 'directory',
        mode   => '0755',
        owner  => 'datasets',
        group  => 'datasets',
    }

    file { $cirrussearchdir:
        ensure => 'directory',
        mode   => '0755',
        owner  => 'datasets',
        group  => 'datasets',
    }

    file { $medialistsdir:
        ensure => 'directory',
        mode   => '0755',
        owner  => 'datasets',
        group  => 'datasets',
    }

    file { $mediatitlesdir:
        ensure => 'directory',
        mode   => '0755',
        owner  => 'datasets',
        group  => 'datasets',
    }

    file { $pagetitlesdir:
        ensure => 'directory',
        mode   => '0755',
        owner  => 'datasets',
        group  => 'datasets',
    }

    file { $categoriesrdf:
        ensure => 'directory',
        mode   => '0755',
        owner  => 'datasets',
        group  => 'datasets',
    }
}
