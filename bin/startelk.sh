#!/bin/sh

if [ $# -lt 1 ]; then
    echo $0 pattern
    exit 1
fi

docker ps -a | grep "$1 ago" | awk '{print $1}' | xargs --no-run-if-empty docker rm -f

docker run -d -p 20022:22 -p 5601:5601 -p 9200:9200 -p 5000:5000 -p 5005:5005 --name elk xyuan/elk
docker run -d --restart=always -p 8080:80 -p 2003:2003 -p 8125:8125/udp -p 8126:8126 --name gs xyuan/gs
sleep 10

docker run -d -p 10022:22 -p 3009:3000 -p 4567:4567 -p 5671:5671 -p 15672:15672 --link elk:elk --link gs:gs --name sensu xyuan/sensu

