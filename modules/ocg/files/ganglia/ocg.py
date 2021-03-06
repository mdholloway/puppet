#!/usr/bin/python
#
# Copyright (c) 2014 Jeff Green <jgreen@wikimedia.org>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the 'Software'), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
import argparse
import logging
import logging.handlers
import os
import re
import requests
import time

_url = 'http://localhost:8000/?command=health'
_timeout = 15
_time_max = 60
_tmp_fs = '/mnt/tmpfs'
_data_fs = '/srv'
_descriptions = {}
_logger = None
_report_cache = {}
_last_ocg_health_time = 0


def setup_logging():
    '''set up _logger as syslog handler'''
    global _logger
    _logger = logging.getLogger('GlobalLogger')
    _logger.setLevel(logging.INFO)
    syslog_handler = logging.handlers.SysLogHandler(address='/dev/log')
    syslog_handler.setLevel(logging.INFO)
    syslog_handler.setFormatter(
        logging.Formatter('ganglia-ocg[%(process)d]: %(message)s'))
    _logger.addHandler(syslog_handler)


def set_cache(data=None):
    global _report_cache
    if data is None:
        _logger.debug('clearing cache')
        _report_cache = {
            'ocg_job_status_queue': 0,
            'ocg_job_queue': 0,
            'ocg_health_check_response_time': _timeout,
        }
    else:
        _logger.debug('populating cache')
        _report_cache = {
            'ocg_job_status_queue': data[u'StatusObjects'][u'length'],
            'ocg_job_queue': data[u'JobQueue'][u'length'],
            'ocg_health_check_response_time': data[u'requestTime'],
        }


def poll_ocg_server():
    '''make an http request to OCG server and parse JSON response data
    :returns: dict containing the parsed JSON data
    '''
    # cache OCG health report in a global, to avoid rapid-fire GETs
    global _last_ocg_health_time, _report_cache
    if time.time() - _last_ocg_health_time > 45:
        _last_ocg_health_time = time.time()
        set_cache()
        try:
            _logger.info(_url)
            r = requests.get(_url, timeout=_timeout)
        except requests.exceptions.RequestException as e:
            _logger.error(e)
        else:
            if r.status_code != 200:
                _logger.error(r.status_code)
            else:
                try:
                    data = r.json()
                except Exception as e:
                    _logger.error(e)
                else:
                    set_cache(data)
    else:
        _logger.debug('using cache')
    return _report_cache


def check_utilization(path):
    '''check filesystem utilization
    :param path: filesystem path
    :returns: filesystem utilization as a percentage
    '''
    if os.path.ismount(path):
        stat = os.statvfs(path)
        blocks_allocated = float(stat.f_blocks - stat.f_bfree)
        percent_allocated = blocks_allocated / stat.f_blocks * 100
        utilization = int(round(percent_allocated))
    else:
        informative_message = 'not a mounted filesystem %s' % path
        _logger.error(informative_message)
        utilization = 0
    return utilization


def fetch_value(name):
    '''look up reported values and return in appropriate units
    :param name: metric name
    :returns: the reported value
    '''
    value = None
    if re.match('ocg_(job_status_queue|job_queue|health_check_response_time)$',
                name):
        data = poll_ocg_server()
        value = data[name]
    elif name == 'ocg_tmp_filesystem_utilization':
        value = check_utilization(_tmp_fs)
    elif name == 'ocg_data_filesystem_utilization':
        value = check_utilization(_data_fs)
    informative_message = '%s %s' % (name, value)
    _logger.info(informative_message)
    return value


def metric_init(params):
    '''initialize metrics, run ocg health check fetcher
    :param params: dict of params from ganglia config or CLI arguments
    :returns: descriptors, also sets globals _url, _timeout, _tmp_fs,
    :         _data_fs, _descriptions
    '''
    global _url, _timeout, _tmp_fs, _data_fs, _descriptions, descriptors
    setup_logging()
    _logger.debug('metric_init')
    if 'url' in params:
        _url = params['url']
    if 'tmp_filesystem' in params:
        _tmp_fs = params['tmp_filesystem']
    if 'data_filesystem' in params:
        _data_fs = params['data_filesystem']
    if 'timeout' in params:
        _timeout = params['timeout']
    METRIC_DEFAULTS = {
        'time_max': _time_max,
        'units': 'messages',
        'groups': 'OCG',
        'slope': 'both',
        'value_type': 'uint',
        'format': '%d',
        'description': '',
        'call_back': fetch_value,
    }
    _descriptions = dict(
        ocg_job_status_queue={
            'description': 'OCG job status queue'},
        ocg_job_queue={
            'description': 'OCG job queue'},
        ocg_tmp_filesystem_utilization={
            'description': 'OCG tmp filesystem utilization',
            'units': '%'},
        ocg_data_filesystem_utilization={
            'description': 'OCG data filesystem utilization',
            'units': '%'},
        ocg_health_check_response_time={
            'description': 'OCG health check response time',
            'units': 'ms'},
    )
    # populate _descriptions with metric defaults
    for metric in _descriptions:
        _descriptions[metric]['name'] = str(metric)
        for key in METRIC_DEFAULTS:
            _descriptions[metric].setdefault(key, METRIC_DEFAULTS[key])
    # jam _descriptions into awkward list of dicts for ganglia
    descriptors = []
    for name, desc in _descriptions.iteritems():
        informative_message = '%s - %s' % (str(name), str(desc))
        _logger.debug(informative_message)
        descriptors.append(desc.copy())
    return descriptors


def metric_cleanup():
    '''clean up the metric module (required + unused)'''
    _logger.debug('metric_cleanup')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='Ganglia OCG server health collector')
    parser.add_argument(
        '-u', '--url', dest='url', default=_url,
        help='OCG health URI (%(default)s)')
    parser.add_argument(
        '--timeout', type=int, default=_timeout,
        help='OCG health URI timeout (%(default)s)')
    parser.add_argument(
        '--tmp', dest='tmp_filesystem', default=_tmp_fs,
        help='OCG tmp filesystem (%(default)s)')
    parser.add_argument(
        '--data', dest='data_filesystem', default=_data_fs,
        help='OCG data filesystem (%(default)s)')
    parsed_params = vars(parser.parse_args())
    descriptors = metric_init(parsed_params)
    for d in descriptors:
        v = d['call_back'](d['name'])
        print '%s is %s %s' % (d['name'], v, d['units'])
