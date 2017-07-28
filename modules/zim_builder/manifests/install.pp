class zim_builder::install inherits zim_builder {

    package { [
        'gcc',
        'g++',
        'pkg-config',
        'imagemagick',
        'icu-devtools',
        'libicu-dev',
        'libxapian-dev',
        'libtool',
        'autoconf',
        'automake',
        'nodejs-legacy',
        'npm',
        'jpegoptim',
        'advancecomp',
        'gifsicle',
        'pngquant',
        'liblzma-dev',
        'libmagic-dev',
        'zlib1g-dev',
        'redis-server',
        'libxml-simple-perl',
        'libwww-perl',
        'libgetargs-long-perl',
      ]: ensure => present
    }

    git::clone { 'openzim':
        ensure    => 'latest',
        directory => '/opt/openzim'
    }

    exec { 'autogen zimwriterfs':
        command => '/bin/sh autogen.sh',
        cwd     => '/opt/openzim/zimwriterfs'
    }

    exec { 'autogen zimlib':
        command => '/bin/sh autogen.sh',
        cwd     => '/opt/openzim/zimlib'
    }
}
