FROM golang:1.22-alpine as build

RUN mkdir -p /tools/bin/ \
    && GOBIN=/tools/bin/ CGO_ENABLED=0 go install -ldflags '-s -w' github.com/cloudflare/cfssl/cmd/...@latest \
    && chmod a+x /tools/bin/*

# Final image
FROM alpine:3.18

VOLUME [ "/data" ]
COPY --from=build /tools/bin/cfssl /usr/bin/
COPY --from=build /tools/bin/cfssljson /usr/bin/

WORKDIR /app
COPY entrypoint.sh csr.json ./
CMD [ "/app/entrypoint.sh" ]
