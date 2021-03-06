# == Class confluent::kafka::client
#
# Installs the confluent-kafka package and a handy kafka wrapper script.
#
# Most likely you will not use this class directly, and instead
# just use confluent::kafka::broker to install and start a Kafka broker.
# You will only use confluent::kafka::client directly if you need to
# change the version of java, kafka, or scala that is being installed, or if
# you want to install the confluent-kafka package without puppet managing
# a Kafka broker.
#
# == Parameters
#
# [*java_home*]
#   Path to JAVA_HOME.  This class does not manage installation of Java.
#   You must do that elsewhere.  Default: undef (will use system default).
#
# [*kafka_version*]
#   Ensure this version of a confluent-kafka package is installed.
#   Default: undef
#
# [*scala_version*]
#   confluent-kafka-$scala_version will be installed.
#   Default: 2.11.7
#
class confluent::kafka::client(
    $java_home     = undef,
    $kafka_version = undef,
    $scala_version = '2.11.7'
) {
    $package = "confluent-kafka-${scala_version}"

    # If $kafka_version was given,
    # make sure that a specific debian package version was installed.
    if !$kafka_version {
        require_package($package)
    }
    else {
        if !defined(Package[$package]) {
            package { $package:
                ensure => $kafka_version,
            }
        }
    }

    file { '/usr/local/bin/kafka':
        source  => 'puppet:///modules/confluent/kafka/kafka.sh',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => Package[$package],
    }

    # Have puppet manage totally manage this directory.
    # Anything it doesn't know about will be removed.
    file { '/etc/kafka/mirror':
        ensure  => 'directory',
        recurse => true,
        purge   => true,
        force   => true,
        require => Package[$package],
    }
}
