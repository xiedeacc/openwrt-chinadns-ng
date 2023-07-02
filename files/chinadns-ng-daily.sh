#!/bin/sh -e

[ -d /etc/chinadns-ng ] || mkdir /etc/chinadns-ng

set -o errexit
set -o pipefail

url='https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf'
data="$(curl -4fsSkL "$url" | grep -v -e '^[[:space:]]*$' -e '^[[:space:]]*#')"
echo "$data" | awk -F/ '{print $2}' | sort | uniq > /etc/chinadns-ng/chnlist.txt


# update chnroute-nft
data="$(curl -4fsSkL https://ftp.apnic.net/stats/apnic/delegated-apnic-latest | grep CN | grep ipv4)"
echo "add table inet global" > /etc/chinadns-ng/chnroute.nftset
echo "add set inet global chnroute { type ipv4_addr; flags interval; }" >> /etc/chinadns-ng/chnroute.nftset
awk -F'|' '{printf("add element inet global chnroute { %s/%d }\n", $4, 32-log($5)/log(2))}' <<<"$data" >> /etc/chinadns-ng/chnroute.nftset


# update chnroute6-nft
data="$(curl -4fsSkL https://ftp.apnic.net/stats/apnic/delegated-apnic-latest | grep CN | grep ipv6)"
echo "add table inet global" > /etc/chinadns-ng/chnroute6.nftset
echo "add set inet global chnroute6 { type ipv6_addr; flags interval; }" >> /etc/chinadns-ng/chnroute6.nftset
awk -F'|' '{printf("add element inet global chnroute6 { %s/%d }\n", $4, $5)}' <<<"$data" >> /etc/chinadns-ng/chnroute6.nftset


# update gfwlist
url='https://raw.githubusercontent.com/pexcn/daily/gh-pages/gfwlist/gfwlist.txt'
data="$(curl -4fsSkL "$url" | grep -v -e '^[[:space:]]*$' -e '^[[:space:]]*#')"
get_data() {
    echo "$data"
    # echo "google.cn"
    echo "googleapis.cn"
}
get_data | sort | uniq >gfwlist.txt



/etc/init.d/chinadns-ng restart
