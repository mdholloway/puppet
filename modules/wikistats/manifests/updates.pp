# the update scripts fetching data (input) for wikistats
# and writing it to local mariadb
#FIXME - this was used in labs in the past but is gone unfortunately
#require misc::mariadb::server
class wikistats::updates (
    $db_pass,
) {

    # update scripts are PHP-cli
    if os_version('debian >= stretch') {
        require_package('php7.0-cli')
    } else {
        require_package('php5-cli')
    }

    # log dir for wikistats
    file { '/var/log/wikistats':
        ensure => directory,
        mode   => '0664',
        owner  => 'wikistatsuser',
        group  => 'wikistatsuser',
    }

    # update table data: usage: <project prefix>@<hour>
    wikistats::cronjob::update { [
                'wp@0',  # Wikipedias
                'lx@1',  # LXDE
                'si@1',  # Wikisite
                'wt@2',  # Wiktionaries
                'ws@3',  # Wikisources
                'wn@4',  # Wikinews
                'wb@5',  # Wikibooks
                'wq@6',  # Wikiquotes
                'os@7',  # OpenSUSE
                'gt@8',  # Gentoo
                'sf@8',  # Sourceforge
                'an@9',  # Anarchopedias
                'et@9',  # EdiThis
                'wf@10', # Wikifur
                'wy@10', # Wikivoyage
                'wv@11', # Wikiversities
                'wi@11', # Wikia
                'sc@12', # Scoutwikis
                'ne@13', # Neoseeker
                'wr@14', # Wikitravel
                'et@15', # EditThis
                'mt@16', # Metapedias
                'un@17', # Uncylomedias
                'wx@18', # Wikimedia Special
                'mh@18', # Miraheze
                'mw@19', # Mediawikis
                'sw@20', # Shoutwikis
                'ro@21', # Rodovid
                'wk@21', # Wikkii
                're@22', # Referata
                'ga@22', # Gamepedias
                'w3@23', # W3C
                ]: }

    # dump xml data: usage: <project prefix>@<hour>
    wikistats::cronjob::xmldump {
        'wp' : db_pass => $db_pass, table => 'wikipedias',   minute => '3';
        'wt' : db_pass => $db_pass, table => 'wiktionaries', minute => '5';
    }

    # imports (fetching lists of wikis itself) usage: <project name>@<weekday>
    wikistats::cronjob::import { [
        'miraheze@5', # https://phabricator.wikimedia.org/T153930
    ]: }

}
