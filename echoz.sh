#!/bin/bash
set -euf
thisdir="$(dirname $0)"
pipename="${XDG_RUNTIME_DIR:-/tmp}/echoz-$$.pipe"
jid="$1"
password="$2"
username="$(echo "$jid" | cut -d'@' -f1)"
domain="$(echo "$jid" | cut -d'@' -f2)"
srv="$( ( dig +short SRV "_xmpp-client._tcp.$domain" || echo "0 0 5222 $domain" ) | sort -n)"
host="$(echo "$srv" | cut -d' ' -f4)"
port="$(echo "$srv" | cut -d' ' -f3)"
authstr="$(echo -ne "\0$username\0$password" | base64)"
rm -f "$pipename"
mkfifo "$pipename"
stdbuf -i0 -o0 \
  openssl s_client \
    -starttls xmpp \
    -xmpphost "$domain" \
    -connect "$host:$port" \
    -quiet \
    < "$pipename" \
  | (echo -ne "$jid $authstr\n"; \
     stdbuf -o0 tr '>\n' '\n\001') \
  | stdbuf -o0 "$thisdir/echoz.sed" \
  | stdbuf -o0 tr -d '\n' \
  | stdbuf -o0 tr '\001' '\n' \
    > "$pipename"
