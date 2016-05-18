export host=\$host;
export proxy_add_x_forwarded_for=\$proxy_add_x_forwarded_for;

export time_local=\$time_local;
export remote_addr=\$remote_addr;
export request_method=\$request_method;
export request=\$request;
export request_length=\$request_length;
export status=\$status;
export bytes_sent=\$bytes_sent;
export body_bytes_sent=\$body_bytes_sent;
export http_referer=\$http_referer;
export http_user_agent=\$http_user_agent;
export upstream_addr=\$upstream_addr;
export upstream_status=\$upstream_status;
export request_time=\$request_time;
export upstream_response_time=\$upstream_response_time;
export upstream_connect_time=\$upstream_connect_time;
export upstream_header_time=\$upstream_header_time;
export http_x_forwarded_for=\$http_x_forwarded_for;
export remote_user=\$remote_user;

export request_uri=\$request_uri;
export http_x_forwarded_proto=\$http_x_forwarded_proto;

echo "
user  nginx;

worker_rlimit_nofile 65536;
worker_processes 4;

error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;

events {
    worker_connections 16384;
    use epoll;
    multi_accept on;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    server_tokens off;

    log_format apm '\"$time_local\" client=$remote_addr '
               'method=$request_method request=\"$request\" remote_user=\"$remote_user\" '
               'request_length=$request_length '
               'status=$status bytes_sent=$bytes_sent '
               'body_bytes_sent=$body_bytes_sent '
               'http_x_forwarded_for=$http_x_forwarded_for '
               'referer=$http_referer '
               'user_agent=\"$http_user_agent\" '
               'upstream_addr=$upstream_addr '
               'upstream_status=$upstream_status '
               'request_time=$request_time '
               'upstream_response_time=$upstream_response_time '
               'upstream_connect_time=$upstream_connect_time '
               'upstream_header_time=$upstream_header_time';

    access_log  /var/log/nginx/access.log  apm;

    sendfile        on;
    tcp_nopush      on;
    tcp_nodelay     on;

    keepalive_timeout  15;

    gzip  on;

    server {

      listen       80;

      error_page 401 403 404 /404.html;

      location /greeting {
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Server $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

        resolver 8.8.8.8;
        proxy_pass http://greeter/greeting;
        proxy_redirect default;
        proxy_cookie_path /greeting /greeting;
        proxy_http_version 1.1;
        proxy_set_header Connection \"\";
      }
    }

    upstream greeter {
        server ${GREETER_PORT_9000_TCP_ADDR}:${GREETER_PORT_9000_TCP_PORT};
        keepalive 100;
    }
}
" | envsubst > /etc/nginx/nginx.conf && nginx -g 'daemon off;'