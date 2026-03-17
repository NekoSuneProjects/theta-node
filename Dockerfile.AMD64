# ---- STAGE 1: Build ----
FROM ubuntu:20.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    build-essential gcc make git bzr jq wget curl \
    && rm -rf /var/lib/apt/lists/*

# Install Go 1.14.1
RUN wget https://dl.google.com/go/go1.14.1.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.14.1.linux-amd64.tar.gz && \
    rm go1.14.1.linux-amd64.tar.gz

ENV GOROOT=/usr/local/go
ENV GOPATH=/go
ENV PATH=$PATH:$GOROOT/bin:$GOPATH/bin
ENV GO111MODULE=on

WORKDIR /go/src/github.com/thetatoken

# Default branch (can override at build)
ARG THETA_BRANCH=release

RUN git clone --branch ${THETA_BRANCH} https://github.com/thetatoken/theta-protocol-ledger.git theta

WORKDIR /go/src/github.com/thetatoken/theta
RUN make install


# ---- STAGE 2: Runtime ----
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    jq curl wget ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy binaries from builder
COPY --from=builder /go/bin/theta /usr/local/bin/theta
COPY --from=builder /go/bin/thetacli /usr/local/bin/thetacli

# ENV config
ENV THETA_MODE=mainnet
ENV THETA_PASSWORD=changeme
ENV THETA_HOME=/theta

WORKDIR /theta

# Startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Expose RPC ports
EXPOSE 16888 16889

ENTRYPOINT ["/start.sh"]
