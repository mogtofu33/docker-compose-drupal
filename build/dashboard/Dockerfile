FROM composer:latest

MAINTAINER moimog33@gmail.com

# RUN apk --update add curl lynx

# COPY src/ /var/www/html/
# RUN chown -R www-data: /var/www/html/

RUN mkdir -p /www
RUN chown -R www-data: /www

WORKDIR /var/www/html

# RUN composer install

EXPOSE 8181

VOLUME ["/var/www/html"]

CMD ["php", "-S", "0.0.0.0:8181", "index.php"]
