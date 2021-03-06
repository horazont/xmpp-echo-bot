XMPP Echo Bot
=============

Do you know that situation, you really really need an XMPP echo bot, but you don’t have access to high-level tools like `Python <https://github.com/horazont/aioxmpp>`_ to write one? All you have is `openssl`, `bash`, `dig`, `stdbuf` and `sed`? Then this tool is for you.

This is an XMPP echo bot written in (mostly) sed. Bash is used to do the pre-authentication setup (look up DNS records, establish TLS via ``openssl s_client``). sed processes the XML stream and handles all interaction with the server on the XMPP level. Yes, this kinda parses XML in sed.

Tested to work against Prosody 0.9.

Usage
-----

::

    ./echoz.sh user@domain password

Supported Features
------------------

* Off-the-Record messaging
* `XEP-0092 (Software Version) <https://xmpp.org/extensions/xep-0092.html>`_
* `XEP-0199 (XMPP Ping) <https://xmpp.org/extensions/xep-0199.html>`_

Testimonials
------------

* *This is crazy, I haven't crashed it yet!* — `Matthew Wild <https://github.com/mwild1>`_
* *I'm frightened. It's only two steps away from gaining consciousness.* — `Georg Lukas <https://op-co.de/>`_
* *I am simultaneously appalled and in awe. wow* — `Lance <https://github.com/legastero>`_
* *With Echoz.sed, we were able to reduce our XMPP Echo server costs by 90% compared to our previous TeX-based solution.* — Leon
* *While simple and limited, sed is sufficiently powerful for a large number of purposes.* — `Wikipedia <https://en.wikipedia.org/wiki/Sed>`_
* *oh my god this actually works* — `Test <xmpp:test@hub.sotecware.net>`_

Implementation Details
----------------------

* We use ``tr`` to convert ``>`` to ``\n`` -- since sed is line (or NUL) based, there’s not really another way to parse XMPP XML (which generally never contains newlines) with sed.
* TLS is handled outside of sed for similar reasons. And to keep my sanity (some people might question whether I still have any bit of sanity left).
* Likewise, SRV lookup and composition of the authentication data is entirely handled in bash. This also means that only PLAIN SASL authentication is supported -- SCRAM requires a level of interactivity which would be extremely hard to achieve in sed (not impossible though; we would "just" have to implement base64 and sha1-hmac in sed).
* Since XMPP is a protocol where the client speaks first, we need to hand sed some initial input to allow it to generate a "line" of output (the stream header). We do that with bash, and use that opportunity to pass some configuration to the sed program (namely JID and authentication string).

**Design Considerations**

* We considered using ``xml2`` to convert the XML stream into events; however, it turns out that ``2xm[`` doesn’t like stream resets. Also, using the ``tr`` approach also allows us to detect the end of elements, which is useful for various purposes.
