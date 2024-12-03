FROM golang AS builder

WORKDIR /app

RUN curl -s https://api.github.com/repos/AlistGo/alist/releases/latest | grep 'tarball_url' | cut -d '"' -f 4 | xargs curl -L -o alist.tar.gz

RUN tar xvaf alist.tar.gz -C . --strip-components=1

RUN rm go.mod && rm go.sum

RUN find . -type f -exec sed -i -e 's|gopkg.in/ldap.v3|github.com/go-ldap/ldap/v3|g' {} +
RUN find . -type f -exec sed -i -e 's|gorm.io/driver/sqlite|github.com/glebarez/sqlite|g' {} +

RUN go mod init github.com/alist-org/alist/v3
RUN go get github.com/meilisearch/meilisearch-go@v0.27.2
RUN go get github.com/xhofe/wopan-sdk-go@v0.1.3

RUN go mod tidy

RUN curl -L https://github.com/alist-org/alist-web/releases/latest/download/dist.tar.gz -o dist.tar.gz
RUN tar -zxvf dist.tar.gz
RUN rm -rf public/dist
RUN mv -f dist public

RUN CGO_ENABLED=0 go build

FROM scratch

COPY --chown=65532 --from=builder /app/alist /app/alist

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

VOLUME /app/data

EXPOSE 5244/tcp

CMD [ "/app/alist" ]
