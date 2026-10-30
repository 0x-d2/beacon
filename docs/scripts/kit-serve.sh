#!/bin/zsh
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Vorssaint

# BeaconKit™'s site on the Mac that renders it (docs/beaconkit-mac-mini.md › 5): Beacon's own Caddy serves
# ~/BeaconKit/site/current on a local port, and Tailscale Serve brings it to the tailnet on an HTTPS port. Each run
# keeps the two ports it chose last time while they are still Beacon's, and moves to the next free one when something
# else took one (another server on the Mac, another Serve entry); it never touches what isn't Beacon's. It prints the
# address and, on a runner, writes `url`, `local_port` and `tailnet_port` to the step's outputs, which the catalog
# workflow posts to GitHub.
#
#   docs/scripts/kit-serve.sh            set up or repair, then print the address
#   docs/scripts/kit-serve.sh --dry-run  only say which ports it would use
#
#   State: ~/BeaconKit/serve.env (the ports it chose). Caddy: ~/BeaconKit/Caddyfile, LaunchAgent
#   co.ikili.beaconkit.caddy, log ~/BeaconKit/caddy.log; its admin API is off, so it shares not even :2019 with another
#   Caddy. Needs caddy (brew install caddy), jq, and the Tailscale CLI signed in.
set -euo pipefail

dry=0
[[ ${1:-} == --dry-run ]] && dry=1

home=$HOME/BeaconKit
state=$home/serve.env
label=co.ikili.beaconkit.caddy
plist=$HOME/Library/LaunchAgents/$label.plist
domain=gui/$(id -u)
local_range=(8789 8888) tailnet_range=(8445 8544)

tailscale=${TAILSCALE:-$(command -v tailscale || print /Applications/Tailscale.app/Contents/MacOS/Tailscale)}
[[ -x $tailscale ]] || { print -u2 "Tailscale CLI bulunamadı."; exit 1 }
command -v jq > /dev/null || { print -u2 "jq bulunamadı."; exit 1 }

# The ports chosen last time. Only those can be Beacon's: without them, any listener or Serve entry is someone else's.
known_local="" known_tailnet=""
if [[ -f $state ]]; then
  while IFS='=' read -r key value; do
    [[ $value == <-> ]] || continue
    case $key in
      local_port) known_local=$value ;;
      tailnet_port) known_tailnet=$value ;;
    esac
  done < $state
fi
local_port=${known_local:-$local_range[1]} tailnet_port=${known_tailnet:-$tailnet_range[1]}

caddy_pid() { launchctl print $domain/$label 2>/dev/null | awk '$1 == "pid" { print $3; exit }' }
listener() { lsof -nP -t -iTCP:$1 -sTCP:LISTEN 2>/dev/null | head -n 1 }
serve_json=$($tailscale serve status --json 2>/dev/null || print '{}')
[[ -n $serve_json ]] || serve_json='{}'

# Where Serve sends a port's root: empty when Serve doesn't answer on it, "other" when it isn't a plain proxy.
serve_target() {
  jq -r --arg p $1 '
    if (.TCP // {} | has($p)) then
      ([(.Web // {}) | to_entries[] | select(.key | endswith(":" + $p)) | .value.Handlers["/"].Proxy // "other"] | first) // "other"
    else "" end' <<< $serve_json
}

# Beacon may use a local port if nothing listens on it, or its own Caddy does.
local_free() {
  local pid=$(listener $1)
  [[ -z $pid || $pid == $(caddy_pid) ]]
}

# Beacon may use a tailnet port if nothing on the Mac listens on it and Serve doesn't answer on it — or it is the port
# Beacon chose last time and Serve still sends it to Beacon's Caddy.
ours_target() { [[ -n $known_tailnet && ( $1 == http://127.0.0.1:$known_local || $1 == http://127.0.0.1:$local_port ) ]] }
tailnet_free() {
  [[ -z $(listener $1) ]] || return 1
  local target=$(serve_target $1)
  [[ -z $target ]] || { [[ $1 == $known_tailnet ]] && ours_target $target }
}

pick() {  # pick <free-function> <current> <first> <last>
  local test=$1 current=$2 port
  $test $current && { print $current; return }
  for (( port = $3; port <= $4; port++ )); do
    $test $port && { print $port; return }
  done
  return 1
}

local_port=$(pick local_free $local_port $local_range) \
  || { print -u2 "$local_range[1]–$local_range[2] arasında boş yerel port yok."; exit 1 }
tailnet_port=$(pick tailnet_free $tailnet_port $tailnet_range) \
  || { print -u2 "$tailnet_range[1]–$tailnet_range[2] arasında boş tailnet portu yok."; exit 1 }
[[ -n $known_local && $local_port != $known_local ]] && print "Yerel port $known_local başkasında; Beacon'ın yeni yerel portu $local_port."
[[ -n $known_tailnet && $tailnet_port != $known_tailnet ]] && print "Tailnet portu $known_tailnet başkasında; Beacon'ın yeni tailnet portu $tailnet_port."

if (( dry )); then
  print "Yerel port $local_port (Caddy), tailnet portu $tailnet_port (Tailscale Serve)."
  exit 0
fi

caddy=${CADDY:-$(command -v caddy || true)}
[[ -n $caddy ]] || { print -u2 "caddy bulunamadı: brew install caddy"; exit 1 }
mkdir -p $home $HOME/Library/LaunchAgents

# Writes a file only when its content changes; says whether it did.
write() {
  [[ -f $1 && "$(< $1)" == "$2" ]] && return 1
  print -r -- $2 > $1
}

caddyfile="{
	admin off
}

http://127.0.0.1:$local_port {
	root * $home/site/current
	encode gzip
	header Cache-Control no-cache
	try_files {path} /index.html
	file_server
}"
agent="<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
<dict>
	<key>Label</key><string>$label</string>
	<key>ProgramArguments</key>
	<array>
		<string>$caddy</string>
		<string>run</string>
		<string>--config</string><string>$home/Caddyfile</string>
		<string>--adapter</string><string>caddyfile</string>
	</array>
	<key>RunAtLoad</key><true/>
	<key>KeepAlive</key><true/>
	<key>StandardErrorPath</key><string>$home/caddy.log</string>
</dict>
</plist>"

config_changed=0 agent_changed=0
write $home/Caddyfile $caddyfile && config_changed=1
write $plist $agent && agent_changed=1
$caddy validate --config $home/Caddyfile --adapter caddyfile > /dev/null 2>&1 \
  || { print -u2 "Caddyfile geçersiz: $caddy validate --config $home/Caddyfile --adapter caddyfile"; exit 1 }

if ! launchctl print $domain/$label > /dev/null 2>&1; then
  launchctl bootstrap $domain $plist
elif (( agent_changed )); then
  launchctl bootout $domain/$label
  for i in {1..50}; do launchctl print $domain/$label > /dev/null 2>&1 || break; sleep 0.2; done
  launchctl bootstrap $domain $plist
elif (( config_changed )); then
  launchctl kickstart -k $domain/$label
fi

for i in {1..50}; do
  pid=$(caddy_pid)
  [[ -n $pid && $(listener $local_port) == $pid ]] && break
  sleep 0.2
done
[[ -n ${pid:-} && $(listener $local_port) == $pid ]] \
  || { print -u2 "Caddy $local_port portunu dinlemiyor; ~/BeaconKit/caddy.log:"; tail -n 5 $home/caddy.log >&2 || true; exit 1 }

# Beacon's previous Serve entry goes if it moved; one that isn't Beacon's is never touched.
if [[ -n $known_tailnet && $known_tailnet != $tailnet_port ]] && ours_target "$(serve_target $known_tailnet)"; then
  $tailscale serve --https=$known_tailnet off > /dev/null
fi
target=$(serve_target $tailnet_port)
if [[ $target != http://127.0.0.1:$local_port ]]; then
  [[ -n $target ]] && $tailscale serve --https=$tailnet_port off > /dev/null
  $tailscale serve --bg --https=$tailnet_port http://127.0.0.1:$local_port > /dev/null
fi

print -l "local_port=$local_port" "tailnet_port=$tailnet_port" > $state
host=$($tailscale status --json | jq -r '.Self.DNSName | rtrimstr(".")')
url=https://$host:$tailnet_port
print "BeaconKit: $url (yerel port $local_port, tailnet portu $tailnet_port)"
if [[ -n ${GITHUB_OUTPUT:-} ]]; then
  print -l "url=$url" "local_port=$local_port" "tailnet_port=$tailnet_port" >> $GITHUB_OUTPUT
fi
