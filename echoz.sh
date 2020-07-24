#!/bin/sh
set -euf
thisdir="$(dirname "$0")"
pipename="${XDG_RUNTIME_DIR:-/tmp}/echoz-$$.pipe"
jid="$1"
password="$2"
username="$(echo "$jid" | sed 's/@.*//')"
domain="$(echo "$jid" | sed 's/.*@//')"
srv="$( ( dig +short SRV "_xmpp-client._tcp.$domain" | grep . || echo "0 0 5222 $domain" ) | sort -n | sed -n '1s/[[:digit:]]\+[[:space:]][[:digit:]]\+[[:space:]]//p')"
host="$(echo "$srv" | sed 's/[[:digit:]]\+[[:space:]]//' | sed 's/\.$//')"
port="$(echo "$srv" | sed 's/[[:space:]].*//')"
authstr="$(printf '\0%s\0%s' "$username" "$password" | base64)"
rm -f "$pipename"
mkfifo "$pipename"
DEBUG_PATH=${DEBUG_PATH:-}
if [ "x$DEBUG_PATH" != "x" ]; then
  debug_recv="${DEBUG_PATH}recv.xml"
  debug_sent="${DEBUG_PATH}sent.xml"
  rm -f "$debug_sent" "$debug_recv"
else
  debug_recv=/dev/null
  debug_sent=/dev/null
fi
stdbuf -i0 -o0 \
  openssl s_client \
    -starttls xmpp \
    -xmpphost "$domain" \
    -connect "$host:$port" \
    -quiet \
    < "$pipename" \
  | (printf '%s %s\n' "$jid" "$authstr"; \
     stdbuf -o0 tr '>\n' '\n\001') \
  | stdbuf -o0 tee "$debug_recv" \
  | stdbuf -o0 "$thisdir/echoz.sed" \
  | stdbuf -o0 tee "$debug_sent" \
  | stdbuf -o0 tr -d '\n' \
  | stdbuf -o0 tr '\001' '\n' \
    > "$pipename"
