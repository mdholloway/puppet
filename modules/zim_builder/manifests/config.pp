class zim_builder::config inherits zim_builder {

    exec { 'configure libzim':
        command => '/bin/sh configure && make && make install',
        cwd     => '/opt/openzim/zimlib'
    }

    exec { 'configure zimwriterfs':
        command => '/bin/sh configure CXXFLAGS="-I../zimlib/include -I/usr/local/include" LDFLAGS=-L../zimlib/src/.libs && make && make install',
        cwd     => '/opt/openzim/zimwriterfs'
    }
}
