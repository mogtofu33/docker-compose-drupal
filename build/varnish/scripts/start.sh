#!/bin/sh

mkdir -p /var/lib/varnish/`hostname` && chown nobody /var/lib/varnish/`hostname`
#varnishd -s malloc,${VARNISH_MEMORY} -a :80 -f ${VARNISH_VCL}
varnishd -s malloc,${VARNISH_MEMORY} -a :80 -T 0.0.0.0:6082 -S /etc/varnish/secret -f ${VARNISH_VCL}
sleep 1
varnishlog > /var/log/varnish/varnish-access.log
