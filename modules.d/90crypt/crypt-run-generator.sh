#!/bin/sh

. /lib/dracut-lib.sh
type crypttab_contains >/dev/null 2>&1 || . /lib/dracut-crypt-lib.sh

dev=$1
luks=$2

crypttab_contains "$luks" "$dev" && exit 0

allowdiscards="-"

# command -v cryptsetup >/dev/null || dwarn "Cannot locate 'cryptsetup', YMMV"

# parse for allow-discards
if getargbool 0 rd.luks.allow-discards; then
    # The parameter is present in cmdline at least once.
    # Let's see if specific uuids are specified
    discarduuids=$(getargs "rd.luks.allow-discards")
    if [ ! -z "$discarduuids" ]; then
        discarduuids=$(str_replace "$discarduuids" 'luks-' '')
        if strstr " $discarduuids " " ${luks##luks-}"; then
            # This uuid matches
            allowdiscards="discard"
        fi
    else
        # Only the boolean parameter was specified
        allowdiscards="discard"
    fi
fi

echo "$luks $dev - timeout=0,$allowdiscards" >> /etc/crypttab

if command -v systemctl >/dev/null; then
    systemctl daemon-reload
    systemctl start cryptsetup.target
fi
exit 0
