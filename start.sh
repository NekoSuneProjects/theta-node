#!/bin/bash
set -e

echo "Running Theta in mode: $THETA_MODE"

start_cli() {
  echo "Starting ThetaCli daemon on port 16889..."
  thetacli daemon start --port=16889 &
}

case "$THETA_MODE" in

  privatenet)
    echo "⚡ PrivateNet setup..."

    mkdir -p /theta/privatenet
    cp -r /theta/theta/integration/privatenet /theta/ || true

    mkdir -p ~/.thetacli
    cp -r /theta/theta/integration/privatenet/thetacli/* ~/.thetacli/ || true
    chmod 700 ~/.thetacli/keys/encrypted || true

    start_cli

    exec theta start --config=/theta/privatenet/node --password=$THETA_PASSWORD
    ;;

  testnet)
    echo "🌐 TestNet setup..."

    mkdir -p /theta/testnet
    cp -r /theta/theta/integration/testnet/walletnode /theta/testnet || true

    wget -O /theta/testnet/walletnode/snapshot \
      $(curl -k https://theta-testnet-backup.s3.amazonaws.com/snapshot/snapshot)

    start_cli

    exec theta start --config=/theta/testnet/walletnode
    ;;

  mainnet)
    echo "🚀 MainNet setup..."

    mkdir -p /theta/mainnet/walletnode

    curl -k --output /theta/mainnet/walletnode/config.yaml \
      $(curl -k 'https://mainnet-data.thetatoken.org/config?is_guardian=true')

    wget -O /theta/mainnet/walletnode/snapshot \
      $(curl -k https://mainnet-data.thetatoken.org/snapshot)

    start_cli

    exec theta start --config=/theta/mainnet/walletnode
    ;;

  *)
    echo "❌ Unknown mode: $THETA_MODE"
    exit 1
    ;;
esac
