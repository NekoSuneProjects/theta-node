#!/bin/bash
set -e

echo "Running Theta in mode: $THETA_MODE"

# Ensure dirs exist
mkdir -p /theta
mkdir -p ~/.thetacli

# Create password file (required for non-interactive Docker)
PASSWORD_FILE="/theta/password.txt"
echo "$THETA_PASSWORD" > $PASSWORD_FILE
chmod 600 $PASSWORD_FILE

start_cli() {
  echo "Starting ThetaCli daemon on port 16889..."
  thetacli daemon start --port=16889 &
}

# Create wallet if it doesn't exist
init_wallet() {
  if [ ! -d "/root/.thetacli/keys" ] || [ -z "$(ls -A /root/.thetacli/keys 2>/dev/null)" ]; then
    echo "No wallet found. Creating new wallet..."
    echo "$THETA_PASSWORD" | thetacli key new || true
  else
    echo "Wallet already exists. Skipping creation."
  fi
}

case "$THETA_MODE" in

  privatenet)
    echo "PrivateNet setup..."

    mkdir -p /theta/privatenet
    cp -r /theta/theta/integration/privatenet /theta/ || true

    mkdir -p ~/.thetacli
    cp -r /theta/theta/integration/privatenet/thetacli/* ~/.thetacli/ || true
    chmod 700 ~/.thetacli/keys/encrypted || true

    init_wallet
    start_cli

    exec theta start \
      --config=/theta/privatenet/node \
      --password-file=$PASSWORD_FILE
    ;;

  testnet)
    echo "TestNet setup..."

    mkdir -p /theta/testnet
    cp -r /theta/theta/integration/testnet/walletnode /theta/testnet || true

    wget -O /theta/testnet/walletnode/snapshot \
      $(curl -k https://theta-testnet-backup.s3.amazonaws.com/snapshot/snapshot)

    init_wallet
    start_cli

    exec theta start \
      --config=/theta/testnet/walletnode \
      --password-file=$PASSWORD_FILE
    ;;

  mainnet)
    echo "MainNet setup..."

    mkdir -p /theta/mainnet/walletnode

    curl -k --output /theta/mainnet/walletnode/config.yaml \
      $(curl -k 'https://mainnet-data.thetatoken.org/config?is_guardian=true')

    wget -O /theta/mainnet/walletnode/snapshot \
      $(curl -k https://mainnet-data.thetatoken.org/snapshot)

    init_wallet
    start_cli

    exec theta start \
      --config=/theta/mainnet/walletnode \
      --password-file=$PASSWORD_FILE
    ;;

  *)
    echo "Unknown mode: $THETA_MODE"
    exit 1
    ;;
esac
