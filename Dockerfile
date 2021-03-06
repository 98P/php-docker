FROM alpine:3.12

COPY swoole-4.5.6.tgz /tmp/swoole.tgz
COPY xlswriter-1.3.6.tgz /tmp/xlswriter.tgz
COPY composer /usr/bin/composer

LABEL maintainer="iFree <weizhuang_l@163.com>" version="1.2" license="MIT"

ENV PHPIZE_DEPS="autoconf dpkg-dev dpkg file g++ gcc libc-dev make php7-dev php7-pear pkgconf re2c pcre-dev pcre2-dev zlib-dev libtool automake" \
    TIMEZONE=${timezone:-"Asia/Shanghai"}

RUN set -ex \
    # change apk source repo
    && sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories \
    && apk update \
    && apk add --no-cache \
    libstdc++ \
    openssl \
    ca-certificates \
    curl \
    libxml2 \
    wget \
    tar \
    xz \
    libressl \
    tzdata \
    pcre \
    php7 \
    php7-bcmath \
    php7-curl \
    php7-ctype \
    php7-dom \
    php7-gd \
    php7-iconv \
    php7-json \
    php7-mbstring \
    php7-mysqlnd \
    php7-openssl \
    php7-pdo \
    php7-pdo_mysql \
    php7-pdo_sqlite \
    php7-phar \
    php7-posix \
    php7-redis \
    php7-sockets \
    php7-sodium \
    php7-sysvshm \
    php7-sysvmsg \
    php7-sysvsem \
    php7-soap \
    php7-zip \
    php7-zlib \
    php7-xml \
    php7-xmlreader \
    php7-xmlwriter \
    php7-pcntl \
    php7-tokenizer \
    php7-fileinfo \
    php7-simplexml \
    php7-opcache \
    # install dev packages
    && apk add --no-cache --virtual .build-deps $PHPIZE_DEPS libaio-dev openssl-dev libxml2-dev curl-dev \
    # install swoole
    && cd /tmp \
    && mkdir -p swoole \
    && tar -xf swoole.tgz -C swoole --strip-components=1 \
    && ( \
    cd swoole \
    && phpize \
    && ./configure --enable-mysqlnd --enable-openssl --enable-http2 \
    && make -s -j$(nproc) && make install \
    ) \
    && echo "extension=swoole.so" > /etc/php7/conf.d/swoole.ini \
    && echo "swoole.use_shortname = 'Off'" >> /etc/php7/conf.d/swoole.ini \
    # install xlswriter
    && cd /tmp \
    && mkdir -p xlswriter \
    && tar -xf xlswriter.tgz -C xlswriter --strip-components=1 \
    && ( \
    cd xlswriter \
    && phpize \
    && ./configure --enable-reader=yes \
    && make -s -j$(nproc) && make install \
    ) \
    && echo "extension=xlswriter.so" > /etc/php7/conf.d/xlswriter.ini \
    # add config
    && { \
    echo "upload_max_filesize=100M"; \
    echo "post_max_size=108M"; \
    echo "memory_limit=1024M"; \
    echo "date.timezone=${TIMEZONE}"; \
    } | tee /etc/php7/conf.d/99-overrides.ini \
    && cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime \
    && echo "${TIMEZONE}" > /etc/timezone \
    && chmod +x /usr/bin/composer \
    # clean
    && apk del .build-deps \
    && apk del --purge *-dev \
    && rm -rf /var/cache/apk/* /tmp/* /usr/share/man /usr/share/php7 \
    # show verbose
    && php -v \
    && php -m \
    && php --ri swoole \
    && php --ri xlswriter \
    && echo -e "\033[42;37m Build Completed :).\033[0m\n"
