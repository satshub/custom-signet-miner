FROM debian:buster-slim as builder

ARG BITCOIN_VERSION=${BITCOIN_VERSION:-26.0}

ARG TARGETPLATFORM=${TARGETPLATFORM:-linux/amd64}

RUN  apt-get update && \
     apt-get install -qq --no-install-recommends ca-certificates dirmngr gosu wget libc6 procps python3.11
WORKDIR /tmp

# Install Bitcoin binaries based on platform
RUN case $TARGETPLATFORM in \
    linux/amd64) export TRIPLET="x86_64-linux-gnu";; \
    linux/arm64) export TRIPLET="aarch64-linux-gnu";; \
    esac && \
    BITCOIN_URL="https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}/bitcoin-${BITCOIN_VERSION}-${TRIPLET}.tar.gz" && \
    BITCOIN_FILE="bitcoin-${BITCOIN_VERSION}-${TRIPLET}.tar.gz" && \
    wget -qO "${BITCOIN_FILE}" "${BITCOIN_URL}" && \
    mkdir -p bin && \
    tar -xzvf "${BITCOIN_FILE}" -C /tmp/bin --strip-components=2 "bitcoin-${BITCOIN_VERSION}/bin/bitcoin-cli" "bitcoin-${BITCOIN_VERSION}/bin/bitcoind" "bitcoin-${BITCOIN_VERSION}/bin/bitcoin-wallet" "bitcoin-${BITCOIN_VERSION}/bin/bitcoin-util"

FROM debian:buster-slim as custom-signet-miner

RUN  apt-get update && \
     apt-get install -qq --no-install-recommends procps python3.11 python3-pip jq && \
     apt-get clean

COPY --from=builder "/tmp/bin/*" /usr/local/bin/

COPY miner /usr/local/bin/miner
RUN chmod +x /usr/local/bin/miner

COPY miner_imports /usr/local/bin/miner_imports
RUN chmod -R +x /usr/local/bin/miner_imports

ENTRYPOINT ["/usr/local/bin/miner"]