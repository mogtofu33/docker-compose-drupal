FROM composer:latest

MAINTAINER moimog33@gmail.com

COPY app/ /var/www/html/
RUN chown -R www-data: /var/www/html/

WORKDIR /var/www/html

RUN composer install

EXPOSE 80

VOLUME ["/var/www/html"]

CMD ["php", "-S", "0.0.0.0:80", "-t", "/var/www/html/"]
