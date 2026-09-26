FROM --platform=$BUILDPLATFORM golang:1.27.1 AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
ARG TARGETOS
ARG TARGETARCH
ARG VERSION=dev
RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -trimpath -ldflags="-s -w" -o /operator ./cmd/operator
RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -trimpath -ldflags="-s -w -X main.version=$VERSION" -o /replicove ./cmd/replicove

FROM postgres:18-bookworm@sha256:3725f4e2499eef5134592b3b4ab79a543ed7f8e533b05b5b637af926630f6650
LABEL org.opencontainers.image.source="https://github.com/nimeshbuilds/replicove" \
      org.opencontainers.image.title="Replicove" \
      org.opencontainers.image.description="Disposable Kubernetes integration environments powered by vCluster" \
      org.opencontainers.image.licenses="Apache-2.0"
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=build /operator /operator
COPY --from=build /replicove /replicove
USER 65532:65532
ENTRYPOINT ["/operator"]
