#!/bin/bash -e
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0
fqdn="$(hostname -f)"
address="$(/sbin/ip addr show dev eth1 | awk -F'( +|/)' '/inet / {print $3}')"
if [[ "${address}" == "$(dig +short "${fqdn}")" && "${fqdn}." == "$(dig +short -x "${address}")" ]]
then
  exit 0
fi
TTL=21600 # 6 hours
export KRB5CCNAME="FILE:/tmp/krb5cc_0"
domain="$(hostname -d)"
# WARNING: It is possible for the Kerberos realm name to be other than the upper-cased DNS domain name
# The correct realm name can be discovered with `realm discover --client-software=<winbind|sssd>`
# or may be configured as the default_realm in /etc/krb5.conf
realm="${domain^^}"
master="$(dig +short NS "$domain" | head -n 1)"
host="$(hostname)"
kinit -t /etc/krb5.keytab -k "${host^^}\$@${domain^^}"
nsupdate -g <<EOF
server ${master}
realm ${realm}
update delete ${fqdn}. A
update delete ${fqdn}. AAAA
update add ${fqdn}. ${TTL} in A ${address}
send
EOF
reverse=$(awk -F. '{print $4"."$3"."$2"."$1".in-addr.arpa"}' <<<"${address}")
nsupdate -g <<EOF
server ${master}
realm ${realm}
update delete ${reverse}. PTR
update add ${reverse}. ${TTL} in PTR ${fqdn}.
send
EOF