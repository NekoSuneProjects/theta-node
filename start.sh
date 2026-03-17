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

    if [ ! -d "/theta/privatenet/node" ]; then
      echo "Copying privatenet config..."
      cp -r /theta/theta/integration/privatenet /theta/ || true
    else
      echo "Privatenet config already exists. Skipping copy."
    fi

    mkdir -p ~/.thetacli

    if [ ! -d "/root/.thetacli/keys" ]; then
      echo "Copying CLI wallet data..."
      cp -r /theta/theta/integration/privatenet/thetacli/* ~/.thetacli/ || true
      chmod 700 ~/.thetacli/keys/encrypted || true
    else
      echo "Wallet already exists. Skipping copy."
    fi

    init_wallet
    start_cli

    exec theta start \
      --config=/theta/privatenet/node \
      --password="$THETA_PASSWORD"
    ;;

  testnet)
    echo "TestNet setup..."

    mkdir -p /theta/testnet

    if [ ! -d "/theta/testnet/walletnode" ]; then
      echo "Copying testnet config..."
      cp -r /theta/theta/integration/testnet/walletnode /theta/testnet || true
    else
      echo "Testnet config already exists. Skipping copy."
    fi

    # Snapshot check
    if [ ! -f "/theta/testnet/walletnode/snapshot" ]; then
      echo "Downloading snapshot..."
      wget -O /theta/testnet/walletnode/snapshot \
        $(curl -k https://theta-testnet-backup.s3.amazonaws.com/snapshot/snapshot)
    else
      echo "Snapshot already exists. Skipping download."
    fi

    init_wallet
    start_cli

    exec theta start \
      --config=/theta/testnet/walletnode \
      --password="$THETA_PASSWORD"
    ;;

  mainnet)
    echo "MainNet setup..."

    mkdir -p /theta/mainnet/walletnode

    # Config check
    if [ ! -f "/theta/mainnet/walletnode/config.yaml" ]; then
      echo "Downloading config.yaml..."
      curl -k --output /theta/mainnet/walletnode/config.yaml \
        $(curl -k 'https://mainnet-data.thetatoken.org/config?is_guardian=true')
    else
      echo "config.yaml already exists. Skipping download."
    fi

    # Snapshot check
    if [ ! -f "/theta/mainnet/walletnode/snapshot" ]; then
      echo "Downloading snapshot..."
      wget -O /theta/mainnet/walletnode/snapshot \
        $(curl -k https://mainnet-data.thetatoken.org/snapshot)
    else
      echo "Snapshot already exists. Skipping download."
    fi

    init_wallet
    start_cli

    exec theta start \
      --config=/theta/mainnet/walletnode \
      --password="$THETA_PASSWORD"
    ;;

  *)
    echo "Unknown mode: $THETA_MODE"
    exit 1
    ;;
esac
