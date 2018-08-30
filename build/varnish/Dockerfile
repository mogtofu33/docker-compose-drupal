FROM mogtofu33/alpine-base:3.8

ENV VARNISH_BACKEND_IP     0.0.0.0
ENV VARNISH_VCL            /etc/varnish/drupal.vcl
ENV VARNISH_MEMORY         100M

RUN apk add --update varnish

# Copy conf
COPY config/drupal.vcl /etc/varnish/drupal.vcl
COPY config/secret /etc/varnish/secret
RUN chown -R varnish: /etc/varnish/

# Copy startup script
ADD scripts/start.sh /scripts/start.sh
RUN chmod +x /scripts/start.sh

EXPOSE 80 6082

VOLUME ["/etc/varnish"]

CMD ["/scripts/start.sh"]
