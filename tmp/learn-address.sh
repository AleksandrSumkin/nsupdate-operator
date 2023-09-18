#!/bin/bash

dnsserver=192.168.2.200
fwdzone=domain.local
revzone=7.168.192.in-addr.arpa
ttl=300
op=$1
addr=$2
revaddr=`echo $addr | sed -re 's:([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+):\4.\3.\2.\1.in-addr.arpa:'`
cn=$3
fqdn=$cn.$fwdzone
dir=/etc/openvpn/dns
addfile=$dir/add_$addr
delfile=$dir/del_$addr
keytab_file=/etc/openvpn/krb5.keytab
user=ddns

addRecord() {
        kinit -k -t $keytab_file $user
        cat > $addfile << EOF
gsstsig
server $dnsserver
zone $fwdzone
update delete $fqdn a
update add $fqdn $ttl a $addr
send
zone $revzone
update delete $revaddr ptr
update add $revaddr $ttl ptr $fqdn
send
EOF

        cat > $delfile << EOF
gsstsig
server $dnsserver
zone $fwdzone
update delete $fqdn a
send
zone $revzone
update delete $revaddr ptr
send
EOF

        nsupdate -v $addfile
        rm -f $addfile
}

delRecord() {
        kinit -k -t $keytab_file $user
        nsupdate -v $delfile
        rm -f $delfile
}

case $op in
        add|update)
                addRecord
                ;;
        delete)
                delRecord
                ;;
        *)
                echo "Unable to handle operation $op.  Exiting" exit 1
esac