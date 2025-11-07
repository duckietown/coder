#!/bin/sh

# Start Docker service if not already running.
sudo service docker start

# Start Tailscale daemon if it's installed and not already running
if command -v tailscaled >/dev/null 2>&1; then
	if ! pgrep -x tailscaled > /dev/null; then
		echo "🔗 Starting Tailscale daemon..."
		sudo mkdir -p /var/lib/tailscale /var/run/tailscale
		# Start tailscaled in userspace-networking mode (for containers without TUN device)
		sudo nohup tailscaled --tun=userspace-networking --state=/var/lib/tailscale/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock > /tmp/tailscaled.log 2>&1 &
		# Wait a moment for the daemon to start
		sleep 2
		# Check if it's running
		if pgrep -x tailscaled > /dev/null; then
			echo "✅ Tailscale daemon started in userspace-networking mode."
			echo "   Run 'sudo tailscale up' to connect to your network"
		else
			echo "❌ Failed to start Tailscale daemon. Check /tmp/tailscaled.log"
			cat /tmp/tailscaled.log
		fi
	else
		echo "✅ Tailscale daemon is already running."
	fi
fi

# Start code-server (if installed) and ensure it's reachable by the Coder proxy.
# Bind to 0.0.0.0 so the container network/proxy can reach it (otherwise proxy -> connection refused / 502).
if command -v code-server >/dev/null 2>&1; then
	# prefer env var port if set, fallback to 13337
	PORT=${FEATURE_CODE_SERVER_OPTION_PORT:-13337}
	# If code-server already running, do nothing
	if pgrep -f "code-server" > /dev/null; then
		echo "✅ code-server already running."
	else
		echo "⚙️ Starting code-server on 0.0.0.0:${PORT}..."
		# Start as the current user (postStart runs as container user) and daemonize with nohup
		nohup code-server --bind-addr 0.0.0.0:${PORT} --auth none --disable-telemetry > /tmp/code-server.log 2>&1 &
		sleep 1
		if pgrep -f "code-server" > /dev/null; then
			echo "✅ code-server started and listening on 0.0.0.0:${PORT}"
			echo "   Logs: /tmp/code-server.log"
		else
			echo "❌ Failed to start code-server. Check /tmp/code-server.log"
			cat /tmp/code-server.log || true
		fi
	fi
fi
