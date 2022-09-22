FROM golang:alpine as builder
MAINTAINER justcy
ENV GOPROXY https://goproxy.cn/
ENV LDFLAGS="-s -w -X github.com/TruthHun/BookStack/utils.GitHash=${GITHASH} -X github.com/TruthHun/BookStack/utils.BuildAt=${BUILDAT} -X github.com/TruthHun/BookStack/utils.Version=${VERSION}"
WORKDIR /go/release
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories
RUN apk update && apk add tzdata
COPY go.mod ./go.mod
RUN go mod tidy
COPY . .
RUN pwd && ls
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -v -o bookstack -ldflags "${LDFLAGS}"
FROM ubuntu:22.04
# 安装依赖
RUN apt update -y \
    && apt install -y locales \
    && rm -rf /var/lib/apt/lists/* \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 \
    && apt update -y \
    && apt install -y fonts-wqy-zenhei fonts-wqy-microhei \
    && apt install -y xdg-utils wget xz-utils python chromium-browser \
    && wget -nv -O- https://download.calibre-ebook.com/linux-installer.sh | sh /dev/stdin
ENV LANG en_US.utf8
COPY --from=builder /go/release/bookstack /
COPY --from=builder /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
EXPOSE 8181
CMD ["./bookstack"]