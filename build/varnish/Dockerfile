FROM mogtofu33/alpine-base:latest

MAINTAINER moimog33@gmail.com

ENV VARNISH_BACKEND_IP     0.0.0.0
ENV VARNISH_VCL            /etc/varnish/default.vcl
ENV VARNISH_MEMORY         100M

RUN apk add --update varnish

# Copy conf
COPY config/default.vcl /etc/varnish/default.vcl
COPY config/secret /etc/varnish/secret
RUN chown -R varnish: /etc/varnish/

# Copy startup script
ADD scripts/start.sh /scripts/start.sh
RUN chmod +x /scripts/start.sh

EXPOSE 80 6082

VOLUME ["/etc/varnish"]

CMD ["/scripts/start.sh"]
