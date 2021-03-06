# == Define: eventlogging::service::consumer
#
# Consumers are data sinks; they act as an interface between
# EventLogging and various data storage, monitoring, and visualization
# systems. Multiple consumers may subscribe to a single event stream.
# One consumer may write the data to Hadoop, another to statsd, another
# to MongoDB, etc. Both the input stream and the output medium are
# specified by URI. A plug-in architecture provides a mechanism for a
# plug-in to register itself as the handler of a particular output URI
# scheme (for example, the MongoDB consumer handles "mongo://" URIs).
#
# === Parameters
#
# [*input*]
#   This parameter specifies the URI of the event stream the consumer
#   should consume. Example: 'tcp://eventlog1001.eqiad.wmnet:8600'.
#
# [*output*]
#   Bind the multiplexing publisher to this URI.
#   Example: 'tcp://*:8600'.
#
# [*sid*]
#   Specifies the Socket ID consumer should use to identify itself when
#   subscribing to the input stream. Defaults to the resource title.
#   Should contain only URL-safe characters.
#
# [*schemas_path*]
#   If given, this path will be passed to eventlogging-consumer --schemas-path,
#   which causes schemas to be loaded and cached from a local file path before
#   consumption begins.  This does not restrict the consumer from finding
#   schemas on meta.wikimedia.org if they don't exist in schemas_path.
#
# [*ensure*]
#   Specifies whether the consumer should be provisioned or destroyed.
#   Value may be 'present' (provisions the resource; the default) or
#   'absent' (destroys the resource).
#
# [*owner*]
#   Owner of config file.  Default: root
#
# [*group*]
#   Group owner of config file.  Default: root
#
# [*mode*]
#   File permission mode of config file.  Default: 0644
#
# [*reload_on]
#   Reload eventlogging-consumer if any of the provided Puppet
#   resources have changed.  This should be an array of alreday
#   declared puppet resources.  E.g.
#   [File['/path/to/topicconfig.yaml'], Class['::something::else']]
#
# === Examples
#
#  eventlogging::service::consumer { 'all events':
#    input  => 'tcp://eventlog1001.eqiad.wmnet:8600',
#    output => 'mongodb://eventlog1001.eqiad.wmnet:27017/?w=1',
#  }
#
define eventlogging::service::consumer(
    $input,
    $output,
    $sid          = $title,
    $schemas_path = undef,
    $ensure       = present,
    $owner        = 'root',
    $group        = 'root',
    $mode         = '0644',
    $reload_on    = undef,
) {
    # eventlogging-consumer puppetization currently only works on Ubuntu with upstart
    if $::operatingsystem != 'Ubuntu' {
        fail('eventlogging::service::consumer currently only works on Ubuntu with upstart.')
    }

    Class['eventlogging::server'] -> Eventlogging::Service::Consumer[$title]

    $basename = regsubst($title, '\W', '-', 'G')
    $config_file = "/etc/eventlogging.d/consumers/${basename}"
    file { $config_file:
        ensure  => $ensure,
        content => template('eventlogging/consumer.erb'),
        owner   => $owner,
        group   => $group,
        mode    => $mode,
    }

    # Upstart specific reload command for this eventlogging consumer task.
    $reload_cmd = "/sbin/reload eventlogging/consumer NAME=${basename} CONFIG=${config_file}"
    # eventlogging-consumer can be SIGHUPed via reload.
    # Note that this does not restart the service, so no
    # events in flight should be lost.
    # This will only happen if $reload_on is provided.
    exec { "reload eventlogging-consumer-${basename}":
        command     => $reload_cmd,
        refreshonly => true,
        subscribe   => $reload_on,
    }
}
