#!/bin/sed -unrf
# read config into hold buffer
h;
# use domain as to
s#^\S+@(\S+)\s.+$#<stream:stream xmlns="jabber:client" xmlns:stream="http://etherx.jabber.org/streams" version="1.0" to="\1">#;
p;n;

:wait-for-plain;
/^PLAIN<\/mechanism$/bauth-with-plain;
n;
bwait-for-plain;

:auth-with-plain;
# load config
g;
s#^\S+\s+(\S+)$#<auth xmlns='urn:ietf:params:xml:ns:xmpp-sasl' mechanism='PLAIN'>\1</auth>#;
p;n;
bwait-for-sasl-result;

:wait-for-sasl-result;
/^<success\s+xmlns=['"]urn:ietf:params:xml:ns:xmpp-sasl['"]/bsasl-success;
/^<failure\s+xmlns=['"]urn:ietf:params:xml:ns:xmpp-sasl['"]/bsasl-failure;
n;
bwait-for-sasl-result;

:sasl-success;
# restart stream: load config and send stream header
g;
s#^\S+@(\S+)\s.+$#<stream:stream xmlns="jabber:client" xmlns:stream="http://etherx.jabber.org/streams" version="1.0" to="\1">#;
p;n;
bwait-for-bind;

:sasl-failure;
s#^.+$#</stream:stream>#;
q1;

:wait-for-bind;
/^<bind xmlns='urn:ietf:params:xml:ns:xmpp-bind'/bbind;
n;
bwait-for-bind;

:bind;
s#^(.+)$#<iq type='set' id='sed-bind'><bind xmlns='urn:ietf:params:xml:ns:xmpp-bind'/></iq>#;p;n;
bwait-for-bind-result;

:wait-for-bind-result;
/<iq.+id=['"]sed-bind['"]/bprocess-bind-result;
n;
bwait-for-bind-result;

:process-bind-result;
/type=["']error["']/bexit-with-error;
bsend-presence;

:exit-with-error;
s#^.+$#</stream:stream>#;p;q1;

:send-presence;
s#^.+$#<presence/>#;p;n;
bmain-loop;

:main-loop;
/<message/bhandle-message;
/<iq/bhandle-iq;
# no handler, convert to single space, emit and continue
s#^.+$# #;p;
n;
bmain-loop;

:handle-message;
/type='chat'/bhandle-chat-message;
bmain-loop;

:handle-chat-message;
# prepare header; store it in hold space first
h;
# extract new to address
s#^.*from=(['"][^'"]+?['"]).*$#to=\1\n#;
# add copy of header and extrat new from address
G;
s#^(.+)\n.+to=(['"][^'"]+?['"]).*$#\1 from=\2#;
# write header
s#^(.+)$#<message type="chat" \1>#;
# store result in hold space
h;
bmessage-search-body-loop;

:message-search-body-loop;
# drop message if end-of-message before body
\#</message#bmain-loop;
\#<body#bmessage-collect-body;
n;
bmessage-search-body-loop;

:message-collect-body;
# next line must contain body
n;
s#^(.+)</body#<body>\1</body>#;
# append result to hold space
H;
# load full hold space and append </message> and send
g;
s#^(.+)$#\1</message>#;
p;n;
bmain-loop;

:handle-iq;
# prepare header; store it in hold space first
h;
# extract new to address
s#^.*from=(['"][^'"]+?['"]).*$#to=\1\n#;
# add copy of header and extract new from address
G;
s#^(.+)\n.+to=(['"][^'"]+?['"]).*$#\1 from=\2#;
# add copy of header and extract id
G;
s#^(.+)\n.+id=(['"][^'"]+?['"]).*$#\1 id=\2#;
# compose header
s#^(.+)$#<iq \1>#;
# store result in hold space and fetch original header for further processing
x;

/type='get'/bsend-error;
/type='set'/bsend-error;
bmain-loop;

:send-error;
# load composed header from hold space
g;
s#^<iq (.+)>$#<iq type='error' \1><error><service-unavailable xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/><text xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'>Feature not implemented by sedbot.</text></error></iq>#;
p;n;
bskip-iq;

:skip-iq;
# skip remainder of IQ payload until done
/<\/iq/bmain-loop;
n;
bskip-iq;
