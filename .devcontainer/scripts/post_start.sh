#!/bin/sh

# Start Docker service if not already running.
sudo service docker start

# Start Tailscale daemon if it's installed and not already running
if command -v tailscaled >/dev/null 2>&1; then
	if ! pgrep -x tailscaled > /dev/null; then
		echo "🔗 Starting Tailscale daemon..."
		sudo mkdir -p /var/lib/tailscale /var/run/tailscale
		sudo tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock &
		echo "✅ Tailscale daemon started."
	else
		echo "✅ Tailscale daemon is already running."
	fi
fi
