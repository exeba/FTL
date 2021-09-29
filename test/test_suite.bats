#!./test/libs/bats/bin/bats

@test "Version, Tag, Branch, Hash, Date is reported" {
  run bash -c 'echo ">version >quit" | nc -v 127.0.0.1 4711'
  printf "%s\n" "${lines[@]}"
  [[ ${lines[1]} == "version "* ]]
  [[ ${lines[2]} == "tag "* ]]
  [[ ${lines[3]} == "branch "* ]]
  [[ ${lines[4]} == "hash "* ]]
  [[ ${lines[5]} == "date "* ]]
  [[ ${lines[6]} == "" ]]
}

@test "Running a second instance is detected and prevented" {
  run bash -c 'su pihole -s /bin/sh -c "/home/pihole/pihole-FTL -f"'
  printf "%s\n" "${lines[@]}"
  [[ ${lines[9]} == *"Initialization of shared memory failed." ]]
  [[ ${lines[10]} == *"HINT: pihole-FTL is already running!"* ]]
}

@test "Starting tests without prior history" {
  run bash -c 'grep -c "Total DNS queries: 0" /var/log/pihole-FTL.log'
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "1" ]]
}

@test "Initial blocking status is enabled" {
  run bash -c 'grep -c "Blocking status is enabled" /var/log/pihole-FTL.log'
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "1" ]]
}

@test "Number of compiled regex filters as expected" {
  run bash -c 'grep "Compiled [0-9]* whitelist" /var/log/pihole-FTL.log'
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == *"Compiled 2 whitelist and 1 blacklist regex filters"* ]]
}

@test "Blacklisted domain is blocked" {
  run bash -c "dig blacklist-blocked.test.pi-hole.net @127.0.0.1 +short"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "0.0.0.0" ]]
  [[ ${lines[1]} == "" ]]
}

@test "Gravity domain is blocked" {
  run bash -c "dig gravity-blocked.test.pi-hole.net @127.0.0.1 +short"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "0.0.0.0" ]]
  [[ ${lines[1]} == "" ]]
}

@test "Gravity domain is blocked (TCP)" {
  run bash -c "dig gravity-blocked.test.pi-hole.net @127.0.0.1 +tcp +short"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "0.0.0.0" ]]
  [[ ${lines[1]} == "" ]]
}

@test "Gravity domain + whitelist exact match is not blocked" {
  run bash -c "dig whitelisted.test.pi-hole.net @127.0.0.1 +short"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} != "0.0.0.0" ]]
}

@test "Gravity domain + whitelist regex match is not blocked" {
  run bash -c "dig discourse.pi-hole.net @127.0.0.1 +short"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} != "0.0.0.0" ]]
}

@test "Regex blacklist match is blocked" {
  run bash -c "dig regex5.test.pi-hole.net @127.0.0.1 +short"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "0.0.0.0" ]]
  [[ ${lines[1]} == "" ]]
}

@test "Regex blacklist mismatch is not blocked" {
  run bash -c "dig regexA.test.pi-hole.net @127.0.0.1 +short"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} != "0.0.0.0" ]]
}

@test "Regex blacklist match + whitelist exact match is not blocked" {
  run bash -c "dig regex1.test.pi-hole.net @127.0.0.1 +short"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} != "0.0.0.0" ]]
}

@test "Regex blacklist match + whitelist regex match is not blocked" {
  run bash -c "dig regex2.test.pi-hole.net @127.0.0.1 +short"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} != "0.0.0.0" ]]
}

@test "Client 2: Gravity match matching unassociated whitelist is blocked" {
  run bash -c "dig whitelisted.test.pi-hole.net -b 127.0.0.2 @127.0.0.1 +short"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "0.0.0.0" ]]
}

@test "Client 2: Regex blacklist match matching unassociated whitelist is blocked" {
  run bash -c "dig regex1.test.pi-hole.net -b 127.0.0.2 @127.0.0.1 +short"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "0.0.0.0" ]]
}

@test "Same domain is not blocked for client 1 ..." {
  run bash -c "dig regex1.test.pi-hole.net @127.0.0.1 +short"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} != "0.0.0.0" ]]
}

@test "... or client 3" {
  run bash -c "dig regex1.test.pi-hole.net -b 127.0.0.3  @127.0.0.1 +short"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} != "0.0.0.0" ]]
}

@test "Client 2: Unassociated blacklist match is not blocked" {
  run bash -c "dig blacklist-blocked.test.pi-hole.net -b 127.0.0.2 @127.0.0.1 +short"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} != "0.0.0.0" ]]
}

@test "Client 3: Exact blacklist domain is not blocked" {
  run bash -c "dig blacklist-blocked.test.pi-hole.net -b 127.0.0.3 @127.0.0.1 +short"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} != "0.0.0.0" ]]
}

@test "Client 3: Regex blacklist domain is not blocked" {
  run bash -c "dig regex1.test.pi-hole.net -b 127.0.0.3 @127.0.0.1 +short"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} != "0.0.0.0" ]]
}

@test "Client 3: Gravity domain is not blocked" {
  run bash -c "dig discourse.pi-hole.net -b 127.0.0.3 @127.0.0.1 +short"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} != "0.0.0.0" ]]
}

@test "Client 4: Client is recognized by MAC address" {
  run bash -c "dig TXT CHAOS version.bind -b 127.0.0.4 @127.0.0.1 +short"
  run sleep 0.1
  run bash -c "grep -c \"Found database hardware address 127.0.0.4 -> aa:bb:cc:dd:ee:ff\" /var/log/pihole-FTL.log"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "1" ]]
  run bash -c "grep -c \"Gravity database: Client aa:bb:cc:dd:ee:ff found. Using groups (4)\" /var/log/pihole-FTL.log"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} != "0" ]]
  run bash -c "grep -c 'Regex blacklist: Querying groups for client 127.0.0.4: \"SELECT id from vw_regex_blacklist WHERE group_id IN (4);\"' /var/log/pihole-FTL.log"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "1" ]]
  run bash -c "grep -c 'Regex whitelist: Querying groups for client 127.0.0.4: \"SELECT id from vw_regex_whitelist WHERE group_id IN (4);\"' /var/log/pihole-FTL.log"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "1" ]]
  run bash -c "grep -c 'get_client_querystr: SELECT EXISTS(SELECT domain from vw_whitelist WHERE domain = ? AND group_id IN (4));' /var/log/pihole-FTL.log"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} != "0" ]]
  run bash -c "grep -c 'get_client_querystr: SELECT EXISTS(SELECT domain from vw_blacklist WHERE domain = ? AND group_id IN (4));' /var/log/pihole-FTL.log"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} != "0" ]]
  run bash -c "grep -c 'get_client_querystr: SELECT EXISTS(SELECT domain from vw_gravity WHERE domain = ? AND group_id IN (4));' /var/log/pihole-FTL.log"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} != "0" ]]
  run bash -c "grep -c 'Regex whitelist ([[:digit:]]*, DB ID [[:digit:]]*) .* NOT ENABLED for client 127.0.0.4' /var/log/pihole-FTL.log"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "2" ]]
  run bash -c "grep -c 'Regex blacklist ([[:digit:]]*, DB ID [[:digit:]]*) .* NOT ENABLED for client 127.0.0.4' /var/log/pihole-FTL.log"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "1" ]]
}

@test "Client 5: Client is recognized by MAC address" {
  run bash -c "dig TXT CHAOS version.bind -b 127.0.0.5 @127.0.0.1 +short"
  run sleep 0.1
  run bash -c "grep -c \"Found database hardware address 127.0.0.5 -> aa:bb:cc:dd:ee:ff\" /var/log/pihole-FTL.log"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "1" ]]
  run bash -c "grep -c \"Gravity database: Client aa:bb:cc:dd:ee:ff found. Using groups (4)\" /var/log/pihole-FTL.log"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} != "0" ]]
  run bash -c "grep -c 'Regex blacklist: Querying groups for client 127.0.0.5: \"SELECT id from vw_regex_blacklist WHERE group_id IN (4);\"' /var/log/pihole-FTL.log"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "1" ]]
  run bash -c "grep -c 'Regex whitelist: Querying groups for client 127.0.0.5: \"SELECT id from vw_regex_whitelist WHERE group_id IN (4);\"' /var/log/pihole-FTL.log"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "1" ]]
  run bash -c "grep -c 'get_client_querystr: SELECT EXISTS(SELECT domain from vw_whitelist WHERE domain = ? AND group_id IN (4));' /var/log/pihole-FTL.log"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} != "0" ]]
  run bash -c "grep -c 'get_client_querystr: SELECT EXISTS(SELECT domain from vw_blacklist WHERE domain = ? AND group_id IN (4));' /var/log/pihole-FTL.log"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} != "0" ]]
  run bash -c "grep -c 'get_client_querystr: SELECT EXISTS(SELECT domain from vw_gravity WHERE domain = ? AND group_id IN (4));' /var/log/pihole-FTL.log"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} != "0" ]]
  run bash -c "grep -c 'Regex whitelist ([[:digit:]]*, DB ID [[:digit:]]*) .* NOT ENABLED for client 127.0.0.5' /var/log/pihole-FTL.log"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "2" ]]
  run bash -c "grep -c 'Regex blacklist ([[:digit:]]*, DB ID [[:digit:]]*) .* NOT ENABLED for client 127.0.0.5' /var/log/pihole-FTL.log"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "1" ]]
}

@test "Client 6: Client is recognized by interface name" {
  run bash -c "dig TXT CHAOS version.bind -b 127.0.0.6 @127.0.0.1 +short"
  run sleep 0.1
  run bash -c "grep -c \"Found database hardware address 127.0.0.6 -> 00:11:22:33:44:55\" /var/log/pihole-FTL.log"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "1" ]]
  run bash -c "grep -c \"There is no record for 00:11:22:33:44:55 in the client table\" /var/log/pihole-FTL.log"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "1" ]]
  run bash -c "grep -c \"Found database interface 127.0.0.6 -> enp0s123\" /var/log/pihole-FTL.log"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "1" ]]
  run bash -c "grep -c \"Gravity database: Client 00:11:22:33:44:55 found (identified by interface enp0s123). Using groups (5)\" /var/log/pihole-FTL.log"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "1" ]]
  run bash -c "grep -c 'Regex blacklist: Querying groups for client 127.0.0.6: \"SELECT id from vw_regex_blacklist WHERE group_id IN (5);\"' /var/log/pihole-FTL.log"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "1" ]]
  run bash -c "grep -c 'Regex whitelist: Querying groups for client 127.0.0.6: \"SELECT id from vw_regex_whitelist WHERE group_id IN (5);\"' /var/log/pihole-FTL.log"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "1" ]]
  run bash -c "grep -c 'get_client_querystr: SELECT EXISTS(SELECT domain from vw_whitelist WHERE domain = ? AND group_id IN (5));' /var/log/pihole-FTL.log"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "1" ]]
  run bash -c "grep -c 'get_client_querystr: SELECT EXISTS(SELECT domain from vw_blacklist WHERE domain = ? AND group_id IN (5));' /var/log/pihole-FTL.log"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "1" ]]
  run bash -c "grep -c 'get_client_querystr: SELECT EXISTS(SELECT domain from vw_gravity WHERE domain = ? AND group_id IN (5));' /var/log/pihole-FTL.log"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "1" ]]
  run bash -c "grep -c 'Regex whitelist ([[:digit:]]*, DB ID [[:digit:]]*) .* NOT ENABLED for client 127.0.0.6' /var/log/pihole-FTL.log"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "2" ]]
  run bash -c "grep -c 'Regex blacklist ([[:digit:]]*, DB ID [[:digit:]]*) .* NOT ENABLED for client 127.0.0.6' /var/log/pihole-FTL.log"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "1" ]]
}

@test "Google.com (A) is not blocked" {
  run bash -c "dig A google.com @127.0.0.1 +short"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} != "0.0.0.0" ]]
}

@test "Google.com (AAAA) is not blocked (TCP query)" {
  run bash -c "dig AAAA google.com @127.0.0.1 +short +tcp"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} != "::" ]]
}

@test "Known host is resolved as expected" {
  run bash -c "dig ftl.pi-hole.net @127.0.0.1 +short"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "139.59.170.52" ]]
  [[ ${lines[1]} == "" ]]
}

@test "DNS reply analysis test (using netmeister.org records)" {
  run bash -c "bash test/dig.sh | tee dig.log"
  printf "%s\n" "${lines[@]}"
}

@test "Statistics as expected" {
  run bash -c 'echo ">stats >quit" | nc -v 127.0.0.1 4711'
  printf "%s\n" "${lines[@]}"
  [[ ${lines[1]} == "domains_being_blocked 3" ]]
  [[ ${lines[2]} == "dns_queries_today 77" ]]
  [[ ${lines[3]} == "ads_blocked_today 6" ]]
  #[[ ${lines[4]} == "ads_percentage_today 7.792208" ]]
  [[ ${lines[5]} == "unique_domains 50" ]]
  [[ ${lines[6]} == "queries_forwarded 61" ]]
  [[ ${lines[7]} == "queries_cached 10" ]]
  # Clients ever seen is commented out as CircleCI may have
  # more devices in its ARP cache so testing against a fixed
  # number of clients may not work in all cases
  #[[ ${lines[8]} == "clients_ever_seen 8" ]]
  #[[ ${lines[9]} == "unique_clients 8" ]]
  [[ ${lines[10]} == "dns_queries_all_types 77" ]]
  [[ ${lines[11]} == "reply_NODATA 9" ]]
  [[ ${lines[12]} == "reply_NXDOMAIN 0" ]]
  [[ ${lines[13]} == "reply_CNAME 1" ]]
  [[ ${lines[14]} == "reply_IP 22" ]]
  [[ ${lines[15]} == "privacy_level 0" ]]
  [[ ${lines[16]} == "status enabled" ]]
  [[ ${lines[17]} == "" ]]
}

# Here and below: It is not meaningful to assume a particular order
# here as the values are sorted before output. It is unpredictable in
# which order they may come out. While this has always been the same
# when compiling for glibc, the new musl build reveals that another
# library may have a different interpretation here.

@test "Top Clients" {
  run bash -c 'echo ">top-clients >quit" | nc -v 127.0.0.1 4711'
  printf "%s\n" "${lines[@]}"
  [[ ${lines[1]} == "0 34 :: "* ]]
  [[ ${lines[2]} == "1 33 127.0.0.1 "* ]]
  [[ ${lines[3]} == "2 4 127.0.0.3 "* ]]
  [[ ${lines[4]} == "3 3 127.0.0.2 "* ]]
  [[ "${lines[@]}" == *"1 aliasclient-0 some-aliasclient"* ]]
  [[ "${lines[@]}" == *"1 127.0.0.4 "* ]]
  [[ "${lines[@]}" == *"1 127.0.0.5 "* ]]
}

@test "Top Domains" {
  run bash -c 'echo ">top-domains (60) >quit" | nc -v 127.0.0.1 4711'
  printf "%s\n" "${lines[@]}"
  [[ "${lines[@]}" == *" 4 version.bind"* ]]
  [[ "${lines[@]}" == *" 4 regex1.test.pi-hole.net"* ]]
  [[ "${lines[@]}" == *" 3 google.com"* ]]
  [[ "${lines[@]}" == *" 3 dnskey.dns.netmeister.org"* ]]
  [[ "${lines[@]}" == *" 2 blacklist-blocked.test.pi-hole.net"* ]]
  [[ "${lines[@]}" == *" 2 net"* ]]
  [[ "${lines[@]}" == *" 2 pi-hole.net"* ]]
  [[ "${lines[@]}" == *" 2 discourse.pi-hole.net"* ]]
  [[ "${lines[@]}" == *" 2 com"* ]]
  [[ "${lines[@]}" == *" 2 arpa"* ]]
  [[ "${lines[@]}" == *" 2 in-addr.arpa"* ]]
  [[ "${lines[@]}" == *" 2 166.in-addr.arpa"* ]]
  [[ "${lines[@]}" == *" 2 ip6.arpa"* ]]
  [[ "${lines[@]}" == *" 2 4.0.1.0.0.2.ip6.arpa"* ]]
  [[ "${lines[@]}" == *" 2 org"* ]]
  [[ "${lines[@]}" == *" 2 netmeister.org"* ]]
  [[ "${lines[@]}" == *" 2 dns.netmeister.org"* ]]
  [[ "${lines[@]}" == *" 1 version.ftl"* ]]
  [[ "${lines[@]}" == *" 1 whitelisted.test.pi-hole.net"* ]]
  [[ "${lines[@]}" == *" 1 a.dns.netmeister.org"* ]]
  [[ "${lines[@]}" == *" 1 any.dns.netmeister.org"* ]]
  [[ "${lines[@]}" == *" 1 ftl.pi-hole.net"* ]]
  [[ "${lines[@]}" == *" 1 srv.dns.netmeister.org"* ]]
  [[ "${lines[@]}" == *" 1 soa.dns.netmeister.org"* ]]
  [[ "${lines[@]}" == *" 1 99.7.84.166.in-addr.arpa"* ]]
  [[ "${lines[@]}" == *" 1 aaaa.dns.netmeister.org"* ]]
  [[ "${lines[@]}" == *" 1 cname.dns.netmeister.org"* ]]
  [[ "${lines[@]}" == *" 1 regex2.test.pi-hole.net"* ]]
  [[ "${lines[@]}" == *" 1 regexa.test.pi-hole.net"* ]]
  [[ "${lines[@]}" == *" 1 "* ]]
  [[ "${lines[@]}" == *" 1 84.166.in-addr.arpa"* ]]
  [[ "${lines[@]}" == *" 1 0.0.9.3.2.7.e.f.f.f.3.6.6.7.2.e.4.8.0.0.0.3.0.0.0.7.4.0.1.0.0.2.ip6.arpa"* ]]
  [[ "${lines[@]}" == *" 1 0.2.ip6.arpa"* ]]
  [[ "${lines[@]}" == *" 1 0.0.2.ip6.arpa"* ]]
  [[ "${lines[@]}" == *" 1 1.0.0.2.ip6.arpa"* ]]
  [[ "${lines[@]}" == *" 1 2.ip6.arpa"* ]]
  [[ "${lines[@]}" == *" 1 0.1.0.0.2.ip6.arpa"* ]]
  [[ "${lines[@]}" == *" 1 7.4.0.1.0.0.2.ip6.arpa"* ]]
  [[ "${lines[@]}" == *" 1 0.7.4.0.1.0.0.2.ip6.arpa"* ]]
  [[ "${lines[@]}" == *" 1 ptr.dns.netmeister.org"* ]]
  [[ "${lines[@]}" == *" 1 txt.dns.netmeister.org"* ]]
  [[ "${lines[@]}" == *" 1 naptr.dns.netmeister.org"* ]]
}

@test "Top Ads" {
  run bash -c 'echo ">top-ads (20) >quit" | nc -v 127.0.0.1 4711'
  printf "%s\n" "${lines[@]}"
  [[ "${lines[@]}" == *" 2 gravity-blocked.test.pi-hole.net"* ]]
  [[ "${lines[@]}" == *" 1 blacklist-blocked.test.pi-hole.net"* ]]
  [[ "${lines[@]}" == *" 1 whitelisted.test.pi-hole.net"* ]]
  [[ "${lines[@]}" == *" 1 regex5.test.pi-hole.net"* ]]
  [[ "${lines[@]}" == *" 1 regex1.test.pi-hole.net"* ]]
  [[ ${lines[6]} == "" ]]
}

@test "Domain auditing, approved domains are not shown" {
  run bash -c 'echo ">top-domains for audit >quit" | nc -v 127.0.0.1 4711'
  printf "%s\n" "${lines[@]}"
  [[ ${lines[@]} != *"google.com"* ]]
}

@test "Upstream Destinations reported correctly" {
  run bash -c 'echo ">forward-dest >quit" | nc -v 127.0.0.1 4711'
  printf "%s\n" "${lines[@]}"
  [[ ${lines[1]} == "-2 7.79 blocklist blocklist" ]]
  [[ ${lines[2]} == "-1 12.99 cache cache" ]]
  [[ ${lines[3]} == "0 61.04 8.8.8.8#53 8.8.8.8#53" ]]
  [[ ${lines[4]} == "1 18.18 84.200.69.80#53 84.200.69.80#53" ]]
}

@test "Query Types reported correctly" {
  run bash -c 'echo ">querytypes >quit" | nc -v 127.0.0.1 4711'
  printf "%s\n" "${lines[@]}"
  [[ ${lines[1]} == "A (IPv4): 25.97" ]]
  [[ ${lines[2]} == "AAAA (IPv6): 2.60" ]]
  [[ ${lines[3]} == "ANY: 1.30" ]]
  [[ ${lines[4]} == "SRV: 1.30" ]]
  [[ ${lines[5]} == "SOA: 1.30" ]]
  [[ ${lines[6]} == "PTR: 3.90" ]]
  [[ ${lines[7]} == "TXT: 7.79" ]]
  [[ ${lines[8]} == "NAPTR: 1.30" ]]
  [[ ${lines[9]} == "MX: 1.30" ]]
  [[ ${lines[10]} == "DS: 28.57" ]]
  [[ ${lines[11]} == "RRSIG: 1.30" ]]
  [[ ${lines[12]} == "DNSKEY: 18.18" ]]
  [[ ${lines[13]} == "NS: 1.30" ]]
  [[ ${lines[14]} == "OTHER: 1.30" ]]
  [[ ${lines[15]} == "SVCB: 1.30" ]]
  [[ ${lines[16]} == "HTTPS: 1.30" ]]
  [[ ${lines[17]} == "" ]]
}

# Here and below: Acknowledge that there might be a host name after
# the IP address of the client (..."*"...)

@test "Get all queries shows expected content" {
  run bash -c 'echo ">getallqueries >quit" | nc -v 127.0.0.1 4711'
  printf "%s\n" "${lines[@]}"
  [[ ${lines[1]} == *"TXT version.ftl 127.0.0.1 3 2 6 "* ]]
  [[ ${lines[2]} == *"TXT version.bind 127.0.0.1 3 2 6 "* ]]
  [[ ${lines[3]} == *"A blacklist-blocked.test.pi-hole.net 127.0.0.1 5 2 4 "* ]]
  [[ ${lines[4]} == *"A gravity-blocked.test.pi-hole.net 127.0.0.1 1 2 4 "* ]]
  [[ ${lines[5]} == *"A gravity-blocked.test.pi-hole.net 127.0.0.1 1 2 4"* ]]
  [[ ${lines[6]} == *"A whitelisted.test.pi-hole.net 127.0.0.1 2 1 4 "* ]]
  [[ ${lines[7]} == *"DS net :: 2 1 11 "* ]]
  [[ ${lines[8]} == *"DNSKEY  :: 2 1 11 "* ]]
  [[ ${lines[9]} == *"DS pi-hole.net :: 2 1 11 "* ]]
  [[ ${lines[10]} == *"DNSKEY net :: 2 1 11 "* ]]
  [[ ${lines[11]} == *"DNSKEY pi-hole.net :: 2 1 11 "* ]]
  [[ ${lines[12]} == *"A discourse.pi-hole.net 127.0.0.1 2 1 4 "* ]]
  [[ ${lines[13]} == *"A regex5.test.pi-hole.net 127.0.0.1 4 2 4 "* ]]
  [[ ${lines[14]} == *"A regexa.test.pi-hole.net 127.0.0.1 2 1 4 "* ]]
  [[ ${lines[15]} == *"A regex1.test.pi-hole.net 127.0.0.1 2 1 4 "* ]]
  [[ ${lines[16]} == *"A regex2.test.pi-hole.net 127.0.0.1 2 1 4 "* ]]
  [[ ${lines[17]} == *"A whitelisted.test.pi-hole.net 127.0.0.2 1 2 4 "* ]]
  [[ ${lines[18]} == *"A regex1.test.pi-hole.net 127.0.0.2 4 2 4 "* ]]
  [[ ${lines[19]} == *"A regex1.test.pi-hole.net 127.0.0.1 3 1 4"* ]]
  [[ ${lines[20]} == *"A regex1.test.pi-hole.net 127.0.0.3 3 1 4 "* ]]
  [[ ${lines[21]} == *"A blacklist-blocked.test.pi-hole.net 127.0.0.2 2 1 4 "* ]]
  [[ ${lines[22]} == *"A blacklist-blocked.test.pi-hole.net 127.0.0.3 3 1 4 "* ]]
  [[ ${lines[23]} == *"A regex1.test.pi-hole.net 127.0.0.3 3 1 4 "* ]]
  [[ ${lines[24]} == *"A discourse.pi-hole.net 127.0.0.3 3 1 4 "* ]]
  [[ ${lines[25]} == *"TXT version.bind 127.0.0.4 3 2 6 "* ]]
  [[ ${lines[26]} == *"TXT version.bind 127.0.0.5 3 2 6 "* ]]
  [[ ${lines[27]} == *"TXT version.bind 127.0.0.6 3 2 6 "* ]]
  [[ ${lines[28]} == *"A google.com 127.0.0.1 2 2 4 "* ]]
  [[ ${lines[29]} == *"DS com :: 2 1 11 "* ]]
  [[ ${lines[30]} == *"DS google.com :: 2 2 1 "* ]]
  [[ ${lines[31]} == *"DNSKEY com :: 2 1 11 "* ]]
  [[ ${lines[32]} == *"AAAA google.com 127.0.0.1 2 2 4 "* ]]
  [[ ${lines[33]} == *"A ftl.pi-hole.net 127.0.0.1 2 1 4 "* ]]
  [[ ${lines[34]} == *"A a.dns.netmeister.org 127.0.0.1 2 2 4 "* ]]
  [[ ${lines[35]} == *"AAAA aaaa.dns.netmeister.org 127.0.0.1 2 2 4 "* ]]
  [[ ${lines[36]} == *"ANY any.dns.netmeister.org 127.0.0.1 2 2 13 "* ]]
  [[ ${lines[37]} == *"TYPE5 cname.dns.netmeister.org 127.0.0.1 2 2 3 "* ]]
  [[ ${lines[38]} == *"SRV srv.dns.netmeister.org 127.0.0.1 2 2 13 "* ]]
  [[ ${lines[39]} == *"SOA soa.dns.netmeister.org 127.0.0.1 2 2 13 "* ]]
  [[ ${lines[40]} == *"PTR 99.7.84.166.in-addr.arpa 127.0.0.1 2 2 5 "* ]]
  [[ ${lines[41]} == *"DS arpa :: 2 1 11 "* ]]
  [[ ${lines[42]} == *"DS in-addr.arpa :: 2 1 11 "* ]]
  [[ ${lines[43]} == *"DNSKEY arpa :: 2 1 11 "* ]]
  [[ ${lines[44]} == *"DS 166.in-addr.arpa :: 2 1 11 "* ]]
  [[ ${lines[45]} == *"DNSKEY in-addr.arpa :: 2 1 11 "* ]]
  [[ ${lines[46]} == *"DS 84.166.in-addr.arpa :: 2 2 1 "* ]]
  [[ ${lines[47]} == *"DNSKEY 166.in-addr.arpa :: 2 1 11 "* ]]
  [[ ${lines[48]} == *"PTR 0.0.9.3.2.7.e.f.f.f.3.6.6.7.2.e.4.8.0.0.0.3.0.0.0.7.4.0.1.0.0.2.ip6.arpa 127.0.0.1 2 2 5 "* ]]
  [[ ${lines[49]} == *"DS ip6.arpa :: 2 1 11 "* ]]
  [[ ${lines[50]} == *"DS 2.ip6.arpa :: 2 2 1 "* ]]
  [[ ${lines[51]} == *"DNSKEY ip6.arpa :: 2 1 11 "* ]]
  [[ ${lines[52]} == *"DS 0.2.ip6.arpa :: 2 2 1 "* ]]
  [[ ${lines[53]} == *"DS 0.0.2.ip6.arpa :: 2 2 1 "* ]]
  [[ ${lines[54]} == *"DS 1.0.0.2.ip6.arpa :: 2 2 1 "* ]]
  [[ ${lines[55]} == *"DS 0.1.0.0.2.ip6.arpa :: 2 2 1 "* ]]
  [[ ${lines[56]} == *"DS 4.0.1.0.0.2.ip6.arpa :: 2 1 11 "* ]]
  [[ ${lines[57]} == *"DS 7.4.0.1.0.0.2.ip6.arpa :: 2 2 1 "* ]]
  [[ ${lines[58]} == *"DNSKEY 4.0.1.0.0.2.ip6.arpa :: 2 1 11 "* ]]
  [[ ${lines[59]} == *"DS 0.7.4.0.1.0.0.2.ip6.arpa :: 2 2 1 "* ]]
  [[ ${lines[60]} == *"PTR ptr.dns.netmeister.org 127.0.0.1 2 2 13 "* ]]
  [[ ${lines[61]} == *"TXT txt.dns.netmeister.org 127.0.0.1 2 2 13 "* ]]
  [[ ${lines[62]} == *"NAPTR naptr.dns.netmeister.org 127.0.0.1 2 2 13 "* ]]
  [[ ${lines[63]} == *"MX mx.dns.netmeister.org 127.0.0.1 2 2 13 "* ]]
  [[ ${lines[64]} == *"DS ds.dns.netmeister.org 127.0.0.1 2 1 13 "* ]]
  [[ ${lines[65]} == *"DS org :: 2 1 11 "* ]]
  [[ ${lines[66]} == *"DS netmeister.org :: 2 1 11 "* ]]
  [[ ${lines[67]} == *"DNSKEY org :: 2 1 11 "* ]]
  [[ ${lines[68]} == *"DS dns.netmeister.org :: 2 1 11 "* ]]
  [[ ${lines[69]} == *"DNSKEY netmeister.org :: 2 1 11 "* ]]
  [[ ${lines[70]} == *"DNSKEY dns.netmeister.org :: 2 1 11 "* ]]
  [[ ${lines[71]} == *"RRSIG rrsig.dns.netmeister.org 127.0.0.1 2 2 13 "* ]]
  [[ ${lines[72]} == *"DNSKEY dnskey.dns.netmeister.org 127.0.0.1 2 1 13 "* ]]
  [[ ${lines[73]} == *"DS dnskey.dns.netmeister.org :: 2 1 11 "* ]]
  [[ ${lines[74]} == *"DNSKEY dnskey.dns.netmeister.org :: 2 1 11 "* ]]
  [[ ${lines[75]} == *"NS ns.dns.netmeister.org 127.0.0.1 2 2 13 "* ]]
  [[ ${lines[76]} == *"SVCB svcb.dns.netmeister.org 127.0.0.1 2 2 13 "* ]]
  [[ ${lines[77]} == *"HTTPS https.dns.netmeister.org 127.0.0.1 2 2 13 "* ]]
  [[ ${lines[78]} == "" ]]
}

@test "Get all queries (domain filtered) shows expected content" {
  run bash -c 'echo ">getallqueries-domain regexa.test.pi-hole.net >quit" | nc -v 127.0.0.1 4711'
  printf "%s\n" "${lines[@]}"
  [[ ${lines[1]} == *"A regexa.test.pi-hole.net "?*" 2 1 4"* ]]
  [[ ${lines[2]} == "" ]]
}

@test "Recent blocked shows expected content" {
  run bash -c 'echo ">recentBlocked >quit" | nc -v 127.0.0.1 4711'
  printf "%s\n" "${lines[@]}"
  [[ ${lines[1]} == "regex1.test.pi-hole.net" ]]
  [[ ${lines[2]} == "" ]]
}

@test "pihole-FTL.db schema is as expected" {
  run bash -c 'sqlite3 /etc/pihole/pihole-FTL.db .dump'
  printf "%s\n" "${lines[@]}"
  [[ "${lines[@]}" == *"CREATE TABLE queries (id INTEGER PRIMARY KEY AUTOINCREMENT, timestamp INTEGER NOT NULL, type INTEGER NOT NULL, status INTEGER NOT NULL, domain TEXT NOT NULL, client TEXT NOT NULL, forward TEXT, additional_info TEXT);"* ]]
  [[ "${lines[@]}" == *"CREATE TABLE ftl (id INTEGER PRIMARY KEY NOT NULL, value BLOB NOT NULL);"* ]]
  [[ "${lines[@]}" == *"CREATE TABLE counters (id INTEGER PRIMARY KEY NOT NULL, value INTEGER NOT NULL);"* ]]
  [[ "${lines[@]}" == *"CREATE TABLE IF NOT EXISTS \"network\" (id INTEGER PRIMARY KEY NOT NULL, hwaddr TEXT UNIQUE NOT NULL, interface TEXT NOT NULL, firstSeen INTEGER NOT NULL, lastQuery INTEGER NOT NULL, numQueries INTEGER NOT NULL, macVendor TEXT, aliasclient_id INTEGER);"* ]]
  [[ "${lines[@]}" == *"CREATE TABLE IF NOT EXISTS \"network_addresses\" (network_id INTEGER NOT NULL, ip TEXT UNIQUE NOT NULL, lastSeen INTEGER NOT NULL DEFAULT (cast(strftime('%s', 'now') as int)), name TEXT, nameUpdated INTEGER, FOREIGN KEY(network_id) REFERENCES network(id));"* ]]
  [[ "${lines[@]}" == *"CREATE INDEX idx_queries_timestamps ON queries (timestamp);"* ]]
  [[ "${lines[@]}" == *"CREATE TABLE aliasclient (id INTEGER PRIMARY KEY NOT NULL, name TEXT NOT NULL, comment TEXT);"* ]]
  # Depending on the version of sqlite3, ftl can be enquoted or not...
  [[ "${lines[@]}" == *"INSERT INTO"?*"ftl"?*"VALUES(0,9);"* ]]
}

@test "Ownership, permissions and type of pihole-FTL.db correct" {
  run bash -c 'ls -l /etc/pihole/pihole-FTL.db'
  printf "%s\n" "${lines[@]}"
  # Depending on the shell (x86_64-musl is built on busybox) there can be one or multiple spaces between user and group
  [[ ${lines[0]} == *"pihole"?*"pihole"* ]]
  [[ ${lines[0]} == "-rw-r--r--"* ]]
  run bash -c 'file /etc/pihole/pihole-FTL.db'
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "/etc/pihole/pihole-FTL.db: SQLite 3.x database"* ]]
}

@test "Test fail on invalid CLI argument" {
  run bash -c '/home/pihole/pihole-FTL abc'
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "pihole-FTL: invalid option -- 'abc'" ]]
  [[ ${lines[1]} == "Command: '/home/pihole/pihole-FTL abc'" ]]
  [[ ${lines[2]} == "Try '/home/pihole/pihole-FTL --help' for more information" ]]
}

@test "Help CLI argument return help text" {
  run bash -c '/home/pihole/pihole-FTL help'
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "pihole-FTL - The Pi-hole FTL engine" ]]
  [[ ${lines[3]} == "Available arguments:" ]]
}

@test "No WARNING messages in pihole-FTL.log (besides known capability issues)" {
  run bash -c 'grep "WARNING" /var/log/pihole-FTL.log'
  printf "%s\n" "${lines[@]}"
  run bash -c 'grep "WARNING" /var/log/pihole-FTL.log | grep -c -v -E "CAP_NET_ADMIN|CAP_NET_RAW|CAP_SYS_NICE|CAP_IPC_LOCK|CAP_CHOWN"'
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "0" ]]
}

@test "No \"database not available\" messages in pihole-FTL.log" {
  run bash -c 'grep -c "database not available" /var/log/pihole-FTL.log'
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "0" ]]
}

@test "No ERROR messages in pihole-FTL.log" {
  run bash -c 'grep "ERROR" /var/log/pihole-FTL.log'
  printf "%s\n" "${lines[@]}"
  run bash -c 'grep -c "ERROR" /var/log/pihole-FTL.log'
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "0" ]]
}

@test "No FATAL messages in pihole-FTL.log (besides error due to starting FTL more than once)" {
  run bash -c 'grep "FATAL" /var/log/pihole-FTL.log'
  printf "%s\n" "${lines[@]}"
  run bash -c 'grep "FATAL:" /var/log/pihole-FTL.log | grep -c -v "FATAL: create_shm(): Failed to create shared memory object \"FTL-lock\": File exists"'
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "0" ]]
}

# Regex tests
@test "Compiled blacklist regex as expected" {
  run bash -c 'grep -c "Compiling blacklist regex 0 (DB ID 6): regex\[0-9\].test.pi-hole.net" /var/log/pihole-FTL.log'
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "1" ]]
}

@test "Compiled whitelist regex as expected" {
  run bash -c 'grep -c "Compiling whitelist regex 0 (DB ID 3): regex2" /var/log/pihole-FTL.log'
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "1" ]]
  run bash -c 'grep -c "Compiling whitelist regex 1 (DB ID 4): discourse" /var/log/pihole-FTL.log'
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "1" ]]
}

@test "Regex Test 1: \"regex7.test.pi-hole.net\" vs. [database regex]: MATCH" {
  run bash -c './pihole-FTL regex-test "regex7.test.pi-hole.net"'
  printf "%s\n" "${lines[@]}"
  [[ $status == 0 ]]
}

@test "Regex Test 2: \"a\" vs. \"a\": MATCH" {
  run bash -c './pihole-FTL regex-test "a" "a"'
  printf "%s\n" "${lines[@]}"
  [[ $status == 0 ]]
}

@test "Regex Test 3: \"aa\" vs. \"^[a-z]{1,3}$\": MATCH" {
  run bash -c './pihole-FTL regex-test "aa" "^[a-z]{1,3}$"'
  printf "%s\n" "${lines[@]}"
  [[ $status == 0 ]]
}

@test "Regex Test 4: \"aaaa\" vs. \"^[a-z]{1,3}$\": NO MATCH" {
  run bash -c './pihole-FTL regex-test "aaaa" "^[a-z]{1,3}$"'
  printf "%s\n" "${lines[@]}"
  [[ $status == 2 ]]
}

@test "Regex Test 5: \"aa\" vs. \"^a(?#some comment)a$\": MATCH (comments)" {
  run bash -c './pihole-FTL regex-test "aa" "^a(?#some comment)a$"'
  printf "%s\n" "${lines[@]}"
  [[ $status == 0 ]]
}

@test "Regex Test 6: \"abc.abc\" vs. \"([a-z]*)\.\1\": MATCH" {
  run bash -c './pihole-FTL regex-test "abc.abc" "([a-z]*)\.\1"'
  printf "%s\n" "${lines[@]}"
  [[ $status == 0 ]]
}

@test "Regex Test 7: Complex character set: MATCH" {
  run bash -c './pihole-FTL regex-test "__abc#LMN012$x%yz789*" "[[:digit:]a-z#$%]+"'
  printf "%s\n" "${lines[@]}"
  [[ $status == 0 ]]
}

@test "Regex Test 8: Range expression: MATCH" {
  run bash -c './pihole-FTL regex-test "!ABC-./XYZ~" "[--Z]+"'
  printf "%s\n" "${lines[@]}"
  [[ $status == 0 ]]
}

@test "Regex Test 9: Back reference: \"aabc\" vs. \"(a)\1{1,2}\": MATCH" {
  run bash -c './pihole-FTL regex-test "aabc" "(a)\1{1,2}"'
  printf "%s\n" "${lines[@]}"
  [[ $status == 0 ]]
}

@test "Regex Test 10: Back reference: \"foo\" vs. \"(.)\1$\": MATCH" {
  run bash -c './pihole-FTL regex-test "foo" "(.)\1$"'
  printf "%s\n" "${lines[@]}"
  [[ $status == 0 ]]
}

@test "Regex Test 11: Back reference: \"foox\" vs. \"(.)\1$\": NO MATCH" {
  run bash -c './pihole-FTL regex-test "foox" "(.)\1$"'
  printf "%s\n" "${lines[@]}"
  [[ $status == 2 ]]
}

@test "Regex Test 12: Back reference: \"1234512345\" vs. \"([0-9]{5})\1\": MATCH" {
  run bash -c './pihole-FTL regex-test "1234512345" "([0-9]{5})\1"'
  printf "%s\n" "${lines[@]}"
  [[ $status == 0 ]]
}

@test "Regex Test 13: Back reference: \"12345\" vs. \"([0-9]{5})\1\": NO MATCH" {
  run bash -c './pihole-FTL regex-test "12345" "([0-9]{5})\1"'
  printf "%s\n" "${lines[@]}"
  [[ $status == 2 ]]
}

@test "Regex Test 14: Complex back reference: MATCH" {
  run bash -c './pihole-FTL regex-test "cat.foo.dog---cat%dog!foo" "(cat)\.(foo)\.(dog)---\1%\3!\2"'
  printf "%s\n" "${lines[@]}"
  [[ $status == 0 ]]
}

@test "Regex Test 15: Approximate matching, 0 errors: MATCH" {
  run bash -c './pihole-FTL regex-test "foobarzap" "foo(bar){~1}zap"'
  printf "%s\n" "${lines[@]}"
  [[ $status == 0 ]]
}

@test "Regex Test 16: Approximate matching, 1 error (inside fault-tolerant area): MATCH" {
  run bash -c './pihole-FTL regex-test "foobrzap" "foo(bar){~1}zap"'
  printf "%s\n" "${lines[@]}"
  [[ $status == 0 ]]
}

@test "Regex Test 17: Approximate matching, 1 error (outside fault-tolert area): NO MATCH" {
  run bash -c './pihole-FTL regex-test "foxbrazap" "foo(bar){~1}zap"'
  printf "%s\n" "${lines[@]}"
  [[ $status == 2 ]]
}

@test "Regex Test 18: Approximate matching, 0 global errors: MATCH" {
  run bash -c './pihole-FTL regex-test "foobar" "^(foobar){~1}$"'
  printf "%s\n" "${lines[@]}"
  [[ $status == 0 ]]
}

@test "Regex Test 19: Approximate matching, 1 global error: MATCH" {
  run bash -c './pihole-FTL regex-test "cfoobar" "^(foobar){~1}$"'
  printf "%s\n" "${lines[@]}"
  [[ $status == 0 ]]
}

@test "Regex Test 20: Approximate matching, 2 global errors: NO MATCH" {
  run bash -c './pihole-FTL regex-test "ccfoobar" "^(foobar){~1}$"'
  printf "%s\n" "${lines[@]}"
  [[ $status == 2 ]]
}

@test "Regex Test 21: Approximate matching, insert + substitute: MATCH" {
  run bash -c './pihole-FTL regex-test "oobargoobaploowap" "(foobar){+2#2~2}"'
  printf "%s\n" "${lines[@]}"
  [[ $status == 0 ]]
}

@test "Regex Test 22: Approximate matching, insert + delete: MATCH" {
  run bash -c './pihole-FTL regex-test "3oifaowefbaoraofuiebofasebfaobfaorfeoaro" "(foobar){+1 -2}"'
  printf "%s\n" "${lines[@]}"
  [[ $status == 0 ]]
}

@test "Regex Test 23: Approximate matching, insert + delete (insufficient): NO MATCH" {
  run bash -c './pihole-FTL regex-test "3oifaowefbaoraofuiebofasebfaobfaorfeoaro" "(foobar){+1 -1}"'
  printf "%s\n" "${lines[@]}"
  [[ $status == 2 ]]
}

@test "Regex Test 24: Useful hint for invalid regular expression \"f{x}\": Invalid contents of {}" {
  run bash -c './pihole-FTL regex-test "fbcdn.net" "f{x}"'
  printf "%s\n" "${lines[@]}"
  [[ ${lines[1]} == "REGEX WARNING: Invalid regex CLI filter \"f{x}\": Invalid contents of {}" ]]
  [[ $status == 1 ]]
}

@test "Regex Test 25: Useful hint for invalid regular expression \"a**\": Invalid use of repetition operators" {
  run bash -c './pihole-FTL regex-test "fbcdn.net" "a**"'
  printf "%s\n" "${lines[@]}"
  [[ ${lines[1]} == "REGEX WARNING: Invalid regex CLI filter \"a**\": Invalid use of repetition operators" ]]
  [[ $status == 1 ]]
}

@test "Regex Test 26: Useful hint for invalid regular expression \"x\\\": Trailing backslash" {
  run bash -c './pihole-FTL regex-test "fbcdn.net" "x\\"'
  printf "%s\n" "${lines[@]}"
  [[ ${lines[1]} == "REGEX WARNING: Invalid regex CLI filter \"x\\\": Trailing backslash" ]]
  [[ $status == 1 ]]
}

@test "Regex Test 27: Useful hint for invalid regular expression \"[\": Missing ']'" {
  run bash -c './pihole-FTL regex-test "fbcdn.net" "["'
  printf "%s\n" "${lines[@]}"
  [[ ${lines[1]} == "REGEX WARNING: Invalid regex CLI filter \"[\": Missing ']'" ]]
  [[ $status == 1 ]]
}

@test "Regex Test 28: Useful hint for invalid regular expression \"(\": Missing ')'" {
  run bash -c './pihole-FTL regex-test "fbcdn.net" "("'
  printf "%s\n" "${lines[@]}"
  [[ ${lines[1]} == "REGEX WARNING: Invalid regex CLI filter \"(\": Missing ')'" ]]
  [[ $status == 1 ]]
}

@test "Regex Test 29: Useful hint for invalid regular expression \"{1\": Missing '}'" {
  run bash -c './pihole-FTL regex-test "fbcdn.net" "{1"'
  printf "%s\n" "${lines[@]}"
  [[ ${lines[1]} == "REGEX WARNING: Invalid regex CLI filter \"{1\": Missing '}'" ]]
  [[ $status == 1 ]]
}

@test "Regex Test 30: Useful hint for invalid regular expression \"[[.foo.]]\": Unknown collating element" {
  run bash -c './pihole-FTL regex-test "fbcdn.net" "[[.foo.]]"'
  printf "%s\n" "${lines[@]}"
  [[ ${lines[1]} == "REGEX WARNING: Invalid regex CLI filter \"[[.foo.]]\": Unknown collating element" ]]
  [[ $status == 1 ]]
}

@test "Regex Test 31: Useful hint for invalid regular expression \"[[:foobar:]]\": Unknown character class name" {
  run bash -c './pihole-FTL regex-test "fbcdn.net" "[[:foobar:]]"'
  printf "%s\n" "${lines[@]}"
  [[ ${lines[1]} == "REGEX WARNING: Invalid regex CLI filter \"[[:foobar:]]\": Unknown character class name" ]]
  [[ $status == 1 ]]
}

@test "Regex Test 32: Useful hint for invalid regular expression \"(a)\\2\": Invalid back reference" {
  run bash -c './pihole-FTL regex-test "fbcdn.net" "(a)\\2"'
  printf "%s\n" "${lines[@]}"
  [[ ${lines[1]} == "REGEX WARNING: Invalid regex CLI filter \"(a)\\2\": Invalid back reference" ]]
  [[ $status == 1 ]]
}

@test "Regex Test 33: Useful hint for invalid regular expression \"[g-1]\": Invalid character range" {
  run bash -c './pihole-FTL regex-test "fbcdn.net" "[g-1]"'
  printf "%s\n" "${lines[@]}"
  [[ ${lines[1]} == "REGEX WARNING: Invalid regex CLI filter \"[g-1]\": Invalid character range" ]]
  [[ $status == 1 ]]
}

@test "Regex Test 34: Quiet mode: Match = Return code 0, nothing else" {
  run bash -c './pihole-FTL -q regex-test "fbcdn.net" "f"'
  printf "%s\n" "${lines[@]}"
  [[ $status == 0 ]]
}

@test "Regex Test 35: Quiet mode: Invalid regex = Return code 1, with error message" {
  run bash -c './pihole-FTL -q regex-test "fbcdn.net" "g{x}"'
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "REGEX WARNING: Invalid regex CLI filter \"g{x}\": Invalid contents of {}" ]]
  [[ $status == 1 ]]
}

@test "Regex Test 36: Quiet mode: No Match = Return code 2, nothing else" {
  run bash -c './pihole-FTL -q regex-test "fbcdn.net" "g"'
  printf "%s\n" "${lines[@]}"
  [[ $status == 2 ]]
}

@test "Regex Test 37: Option \"^localhost$;querytype=A\" working as expected (ONLY matching A queries)" {
  run bash -c 'sqlite3 /etc/pihole/gravity.db "INSERT INTO domainlist (type,domain) VALUES (3,\"^localhost$;querytype=A\");"'
  printf "sqlite3 INSERT: %s\n" "${lines[@]}"
  [[ $status == 0 ]]
  run bash -c 'kill -RTMIN $(cat /var/run/pihole-FTL.pid); sleep 1'
  printf "reload: %s\n" "${lines[@]}"
  [[ $status == 0 ]]
  run sleep 2
  run bash -c 'dig A localhost @127.0.0.1 +short'
  printf "dig A: %s\n" "${lines[@]}"
  [[ ${lines[0]} == "0.0.0.0" ]]
  run bash -c 'dig AAAA localhost @127.0.0.1 +short'
  printf "dig AAAA: %s\n" "${lines[@]}"
  [[ ${lines[0]} != "::" ]]
  run bash -c 'sqlite3 /etc/pihole/gravity.db "DELETE FROM domainlist WHERE domain = \"^localhost$;querytype=A\";"'
  printf "sqlite3 DELETE: %s\n" "${lines[@]}"
  [[ $status == 0 ]]
  run bash -c 'kill -RTMIN $(cat /var/run/pihole-FTL.pid)'
  printf "reload: %s\n" "${lines[@]}"
  [[ $status == 0 ]]
  run sleep 2
}

@test "Regex Test 38: Option \"^localhost$;querytype=!A\" working as expected (NOT matching A queries)" {
  run bash -c 'sqlite3 /etc/pihole/gravity.db "INSERT INTO domainlist (type,domain) VALUES (3,\"^localhost$;querytype=!A\");"'
  printf "sqlite3 INSERT: %s\n" "${lines[@]}"
  [[ $status == 0 ]]
  run bash -c 'kill -RTMIN $(cat /var/run/pihole-FTL.pid); sleep 1'
  printf "reload: %s\n" "${lines[@]}"
  [[ $status == 0 ]]
  run sleep 2
  run bash -c 'dig A localhost @127.0.0.1 +short'
  printf "dig A: %s\n" "${lines[@]}"
  [[ ${lines[0]} != "0.0.0.0" ]]
  run bash -c 'dig AAAA localhost @127.0.0.1 +short'
  printf "dig AAAA: %s\n" "${lines[@]}"
  [[ ${lines[0]} == "::" ]]
  run bash -c 'sqlite3 /etc/pihole/gravity.db "DELETE FROM domainlist WHERE domain = \"^localhost$;querytype=!A\";"'
  printf "sqlite3 DELETE: %s\n" "${lines[@]}"
  [[ $status == 0 ]]
  run bash -c 'kill -RTMIN $(cat /var/run/pihole-FTL.pid)'
  printf "reload: %s\n" "${lines[@]}"
  [[ $status == 0 ]]
  run sleep 2
}

@test "Regex Test 39: Option \";invert\" working as expected (match is inverted)" {
  run bash -c './pihole-FTL -q regex-test "f" "g;invert"'
  printf "%s\n" "${lines[@]}"
  [[ $status == 0 ]]
  run bash -c './pihole-FTL -q regex-test "g" "g;invert"'
  printf "%s\n" "${lines[@]}"
  [[ $status == 2 ]]
}

@test "Regex Test 40: Option \";querytype\" sanity checks" {
  run bash -c './pihole-FTL regex-test "f" g\;querytype=!A\;querytype=A'
  printf "%s\n" "${lines[@]}"
  [[ $status == 2 ]]
  [[ ${lines[1]} == *"Overwriting previous querytype setting" ]]
}

@test "Regex Test 41: Option \"^localhost$;reply=NXDOMAIN\" working as expected" {
  run bash -c 'sqlite3 /etc/pihole/gravity.db "INSERT INTO domainlist (type,domain) VALUES (3,\"^localhost$;reply=NXDOMAIN\");"'
  printf "sqlite3 INSERT: %s\n" "${lines[@]}"
  [[ $status == 0 ]]
  run bash -c 'kill -RTMIN $(cat /var/run/pihole-FTL.pid); sleep 1'
  printf "reload: %s\n" "${lines[@]}"
  [[ $status == 0 ]]
  run sleep 2
  run bash -c 'dig A localhost @127.0.0.1'
  printf "dig: %s\n" "${lines[@]}"
  [[ ${lines[3]} == *"status: NXDOMAIN"* ]]
  run bash -c 'sqlite3 /etc/pihole/gravity.db "DELETE FROM domainlist WHERE domain = \"^localhost$;reply=NXDOMAIN\";"'
  printf "sqlite3 DELETE: %s\n" "${lines[@]}"
  [[ $status == 0 ]]
  run bash -c 'kill -RTMIN $(cat /var/run/pihole-FTL.pid)'
  printf "reload: %s\n" "${lines[@]}"
  [[ $status == 0 ]]
  run sleep 2
}

@test "Regex Test 42: Option \"^localhost$;reply=NODATA\" working as expected" {
  run bash -c 'sqlite3 /etc/pihole/gravity.db "INSERT INTO domainlist (type,domain) VALUES (3,\"^localhost$;reply=NODATA\");"'
  printf "sqlite3 INSERT: %s\n" "${lines[@]}"
  [[ $status == 0 ]]
  run bash -c 'kill -RTMIN $(cat /var/run/pihole-FTL.pid); sleep 1'
  printf "reload: %s\n" "${lines[@]}"
  [[ $status == 0 ]]
  run sleep 2
  run bash -c 'dig A localhost @127.0.0.1 +short'
  printf "dig (short): %s\n" "${lines[@]}"
  [[ ${lines[0]} == "" ]]
  run bash -c 'dig A localhost @127.0.0.1'
  printf "dig (full): %s\n" "${lines[@]}"
  [[ ${lines[3]} == *"status: NOERROR"* ]]
  run bash -c 'sqlite3 /etc/pihole/gravity.db "DELETE FROM domainlist WHERE domain = \"^localhost$;reply=NODATA\";"'
  printf "sqlite3 DELETE: %s\n" "${lines[@]}"
  [[ $status == 0 ]]
  run bash -c 'kill -RTMIN $(cat /var/run/pihole-FTL.pid)'
  printf "reload: %s\n" "${lines[@]}"
  [[ $status == 0 ]]
  run sleep 2
}

@test "Regex Test 43: Option \"^localhost$;reply=REFUSED\" working as expected" {
  run bash -c 'sqlite3 /etc/pihole/gravity.db "INSERT INTO domainlist (type,domain) VALUES (3,\"^localhost$;reply=REFUSED\");"'
  printf "sqlite3 INSERT: %s\n" "${lines[@]}"
  [[ $status == 0 ]]
  run bash -c 'kill -RTMIN $(cat /var/run/pihole-FTL.pid); sleep 1'
  printf "reload: %s\n" "${lines[@]}"
  [[ $status == 0 ]]
  run sleep 2
  run bash -c 'dig A localhost @127.0.0.1 +short'
  printf "dig (short): %s\n" "${lines[@]}"
  [[ ${lines[0]} == "" ]]
  run bash -c 'dig A localhost @127.0.0.1'
  printf "dig (full): %s\n" "${lines[@]}"
  [[ ${lines[3]} == *"status: REFUSED"* ]]
  run bash -c 'sqlite3 /etc/pihole/gravity.db "DELETE FROM domainlist WHERE domain = \"^localhost$;reply=REFUSED\";"'
  printf "sqlite3 DELETE: %s\n" "${lines[@]}"
  [[ $status == 0 ]]
  run bash -c 'kill -RTMIN $(cat /var/run/pihole-FTL.pid)'
  printf "reload: %s\n" "${lines[@]}"
  [[ $status == 0 ]]
  run sleep 2
}

@test "Regex Test 44: Option \"^localhost$;reply=1.2.3.4\" working as expected" {
  run bash -c 'sqlite3 /etc/pihole/gravity.db "INSERT INTO domainlist (type,domain) VALUES (3,\"^localhost$;reply=1.2.3.4\");"'
  printf "sqlite3 INSERT: %s\n" "${lines[@]}"
  [[ $status == 0 ]]
  run bash -c 'kill -RTMIN $(cat /var/run/pihole-FTL.pid); sleep 1'
  printf "reload: %s\n" "${lines[@]}"
  [[ $status == 0 ]]
  run sleep 2
  run bash -c 'dig A localhost @127.0.0.1 +short'
  printf "dig A: %s\n" "${lines[@]}"
  [[ ${lines[0]} == "1.2.3.4" ]]
  run bash -c 'dig AAAA localhost @127.0.0.1 +short'
  printf "dig AAAA: %s\n" "${lines[@]}"
  [[ ${lines[0]} == "::" ]]
  run bash -c 'sqlite3 /etc/pihole/gravity.db "DELETE FROM domainlist WHERE domain = \"^localhost$;reply=1.2.3.4\";"'
  printf "sqlite3 DELETE: %s\n" "${lines[@]}"
  [[ $status == 0 ]]
  run bash -c 'kill -RTMIN $(cat /var/run/pihole-FTL.pid)'
  printf "reload: %s\n" "${lines[@]}"
  [[ $status == 0 ]]
  run sleep 2
}

@test "Regex Test 45: Option \"^localhost$;reply=fe80::1234\" working as expected" {
  run bash -c 'sqlite3 /etc/pihole/gravity.db "INSERT INTO domainlist (type,domain) VALUES (3,\"^localhost$;reply=fe80::1234\");"'
  printf "sqlite3 INSERT: %s\n" "${lines[@]}"
  [[ $status == 0 ]]
  run bash -c 'kill -RTMIN $(cat /var/run/pihole-FTL.pid); sleep 1'
  printf "reload: %s\n" "${lines[@]}"
  [[ $status == 0 ]]
  run sleep 2
  run bash -c 'dig A localhost @127.0.0.1 +short'
  printf "dig A: %s\n" "${lines[@]}"
  [[ ${lines[0]} == "0.0.0.0" ]]
  run bash -c 'dig AAAA localhost @127.0.0.1 +short'
  printf "dig AAAA: %s\n" "${lines[@]}"
  [[ ${lines[0]} == "fe80::1234" ]]
  run bash -c 'sqlite3 /etc/pihole/gravity.db "DELETE FROM domainlist WHERE domain = \"^localhost$;reply=fe80::1234\";"'
  printf "sqlite3 DELETE: %s\n" "${lines[@]}"
  [[ $status == 0 ]]
  run bash -c 'kill -RTMIN $(cat /var/run/pihole-FTL.pid)'
  printf "reload: %s\n" "${lines[@]}"
  [[ $status == 0 ]]
  run sleep 2
}

@test "Regex Test 46: Option \"^localhost$;reply=1.2.3.4;reply=fe80::1234\" working as expected" {
  run bash -c 'sqlite3 /etc/pihole/gravity.db "INSERT INTO domainlist (type,domain) VALUES (3,\"^localhost$;reply=1.2.3.4;reply=fe80::1234\");"'
  printf "sqlite3 INSERT: %s\n" "${lines[@]}"
  [[ $status == 0 ]]
  run bash -c 'kill -RTMIN $(cat /var/run/pihole-FTL.pid); sleep 1'
  printf "reload: %s\n" "${lines[@]}"
  [[ $status == 0 ]]
  run sleep 2
  run bash -c 'dig A localhost @127.0.0.1 +short'
  printf "dig A: %s\n" "${lines[@]}"
  [[ ${lines[0]} == "1.2.3.4" ]]
  run bash -c 'dig AAAA localhost @127.0.0.1 +short'
  printf "dig AAAA: %s\n" "${lines[@]}"
  [[ ${lines[0]} == "fe80::1234" ]]
  run bash -c 'sqlite3 /etc/pihole/gravity.db "DELETE FROM domainlist WHERE domain = \"^localhost$;reply=1.2.3.4;reply=fe80::1234\";"'
  printf "sqlite3 DELETE: %s\n" "${lines[@]}"
  [[ $status == 0 ]]
  run bash -c 'kill -RTMIN $(cat /var/run/pihole-FTL.pid)'
  printf "reload: %s\n" "${lines[@]}"
  [[ $status == 0 ]]
  run sleep 2
}

# x86_64-musl is built on busybox which has a slightly different
# variant of ls displaying three, instead of one, spaces between the
# user and group names.

@test "Ownership and permissions of pihole-FTL.db correct" {
  run bash -c 'ls -l /etc/pihole/pihole-FTL.db'
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == *"pihole pihole"* || ${lines[0]} == *"pihole   pihole"* ]]
  [[ ${lines[0]} == "-rw-r--r--"* ]]
}

# "ldd" prints library dependencies and the used interpreter for a given program
#
# Dependencies on shared libraries are displayed like
#    libm.so.6 => /lib/x86_64-linux-gnu/libm.so.6 (0x00007fa7d28be000)
#
# In this test, we use ldd and check for the dependency arrow "=>" to check if
# our generated binary depends on shared libraries in the way we expect it to

@test "Dependence on shared libraries" {
  run bash -c 'ldd ./pihole-FTL'
  printf "%s\n" "${lines[@]}"
  [[ "${STATIC}" != "true" && "${lines[@]}" == *"=>"* ]] || \
  [[ "${STATIC}" == "true" && "${lines[@]}" != *"=>"* ]]
}

# "file" determines the file type of our generated binary
#
# We use its ability to test whether a specific interpreter is
# required by the given executable. What the interpreter is, is not
# really well documented in "man elf(5)", however, one can say that
# the interpreter is a program that finds and loads the shared
# libraries needed by a program, prepares the program to run, and then
# runs it.
#
# In this test, we use "file" to confirm the absence of the dependence
# on an interpreter for the static binary.

@test "Dependence on specific interpreter" {
  run bash -c 'file ./pihole-FTL'
  printf "%s\n" "${lines[@]}"
  [[ "${STATIC}" != "true" && "${lines[@]}" == *"interpreter"* ]] || \
  [[ "${STATIC}" == "true" && "${lines[@]}" != *"interpreter"* ]]
}

@test "Architecture is correctly reported on startup" {
  run bash -c 'grep "Compiled for" /var/log/pihole-FTL.log'
  printf "Output: %s\n\$CIRCLE_JOB: %s\nuname -m: %s\n" "${lines[@]:-not set}" "${CIRCLE_JOB:-not set}" "$(uname -m)"
  [[ ${lines[0]} == *"Compiled for ${CIRCLE_JOB:-$(uname -m)}"* ]]
}

@test "Building machine (CI) is reported on startup" {
  [[ ${CIRCLE_JOB} != "" ]] && compiled_str="on CI" || compiled_str="locally" && export compiled_str
  run bash -c 'grep "Compiled for" /var/log/pihole-FTL.log'
  printf "Output: %s\n\$CIRCLE_JOB: %s\n" "${lines[@]:-not set}" "${CIRCLE_JOB:-not set}"
  [[ ${lines[0]} == *"(compiled ${compiled_str})"* ]]
}

@test "Compiler version is correctly reported on startup" {
  compiler_version="$(${CC} --version | head -n1)" && export compiler_version
  run bash -c 'grep "Compiled for" /var/log/pihole-FTL.log'
  printf "Output: %s\n\$CC: %s\nVersion: %s\n" "${lines[@]:-not set}" "${CC:-not set}" "${compiler_version:-not set}"
  [[ ${lines[0]} == *"using ${compiler_version}"* ]]
}

@test "No errors on setting busy handlers for the databases" {
  run bash -c 'grep -c "Cannot set busy handler" /var/log/pihole-FTL.log'
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "0" ]]
}

@test "Blocking status is correctly logged in pihole.log" {
  run bash -c 'grep -c "gravity blocked gravity-blocked.test.pi-hole.net is 0.0.0.0" /var/log/pihole.log'
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "2" ]]
}

@test "Port file exists and contains expected API port" {
  run bash -c 'cat /run/pihole-FTL.port'
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "4711" ]]
}

@test "LUA: Interpreter returns FTL version" {
  run bash -c './pihole-FTL lua -e "print(pihole.ftl_version())"'
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "v"* ]]
}

@test "LUA: Interpreter loads and enabled bundled library \"inspect\"" {
  run bash -c './pihole-FTL lua -e "print(inspect(inspect))"'
  printf "%s\n" "${lines[@]}"
  [[ ${lines[@]} == *'_DESCRIPTION = "human-readable representations of tables"'* ]]
  [[ ${lines[@]} == *'_VERSION = "inspect.lua 3.1.0"'* ]]
}

@test "EDNS(0) analysis working as expected" {
  # Get number of lines in the log before the test
  before="$(grep -c ^ /var/log/pihole-FTL.log)"

  # Run test command
  #                                  CLIENT SUBNET          COOKIE                       MAC HEX                     MAC TEXT                                          CPE-ID
  run bash -c 'dig localhost +short +subnet=192.168.1.1/32 +ednsopt=10:1122334455667788 +ednsopt=65001:000102030405 +ednsopt=65073:41413A42423A43433A44443A45453A4646 +ednsopt=65074:414243444546 @127.0.0.1'
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "127.0.0.1" ]]
  [[ $status == 0 ]]

  # Get number of lines in the log after the test
  after="$(grep -c ^ /var/log/pihole-FTL.log)"

  # Extract relevant log lines
  log="$(sed -n "${before},${after}p" /var/log/pihole-FTL.log)"
  printf "%s\n" "${log}"

  # Start actual test
  run bash -c "grep -c \"EDNS(0) CLIENT SUBNET: 192.168.1.1/32\"" <<< "${log}"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "1" ]]
  run bash -c "grep -c \"EDNS(0) COOKIE (client-only): 1122334455667788\"" <<< "${log}"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "1" ]]
  run bash -c "grep -c \"EDNS(0) MAC address (BYTE format): 00:01:02:03:04:05\"" <<< "${log}"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "1" ]]
  run bash -c "grep -c \"EDNS(0) MAC address (TEXT format): AA:BB:CC:DD:EE:FF\"" <<< "${log}"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "1" ]]
  run bash -c "grep -c \"EDNS(0) CPE-ID (payload size 6): \\\"ABCDEF\\\" (0x41 0x42 0x43 0x44 0x45 0x46)\"" <<< "${log}"
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "1" ]]
}

@test "EDNS(0) ECS can overwrite client address (IPv4)" {
  # Get number of lines in the log before the test
  before="$(grep -c ^ /var/log/pihole-FTL.log)"

  # Run test command
  run bash -c 'dig localhost +short +subnet=192.168.47.97/32 @127.0.0.1'
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "127.0.0.1" ]]
  [[ $status == 0 ]]

  # Get number of lines in the log after the test
  after="$(grep -c ^ /var/log/pihole-FTL.log)"

  # Extract relevant log lines
  run bash -c "sed -n \"${before},${after}p\" /var/log/pihole-FTL.log"
  printf "%s\n" "${lines[@]}"
  [[ "${lines[@]}" == *"**** new UDP IPv4 query[A] query \"localhost\" from lo:192.168.47.97#53 "* ]]
}

@test "EDNS(0) ECS can overwrite client address (IPv6)" {
  # Get number of lines in the log before the test
  before="$(grep -c ^ /var/log/pihole-FTL.log)"

  # Run test command
  run bash -c 'dig localhost +short +subnet=fe80::b167:af1e:968b:dead/128 @127.0.0.1'
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "127.0.0.1" ]]
  [[ $status == 0 ]]

  # Get number of lines in the log after the test
  after="$(grep -c ^ /var/log/pihole-FTL.log)"

  # Extract relevant log lines
  run bash -c "sed -n \"${before},${after}p\" /var/log/pihole-FTL.log"
  printf "%s\n" "${lines[@]}"
  [[ "${lines[@]}" == *"**** new UDP IPv4 query[A] query \"localhost\" from lo:fe80::b167:af1e:968b:dead#53 "* ]]
}

@test "alias-client is imported and used for configured client" {
  run bash -c 'grep -c "Added alias-client \"some-aliasclient\" (aliasclient-0) with FTL ID 0" /var/log/pihole-FTL.log'
  printf "Added: %s\n" "${lines[@]}"
  [[ ${lines[0]} == "1" ]]
  run bash -c 'grep -c "Aliasclient ID 127.0.0.6 -> 0" /var/log/pihole-FTL.log'
  printf "Found ID: %s\n" "${lines[@]}"
  [[ ${lines[0]} == "1" ]]
  run bash -c 'grep -c "Client .* (127.0.0.6) IS  managed by this alias-client, adding counts" /var/log/pihole-FTL.log'
  printf "Adding counts: %s\n" "${lines[@]}"
  [[ ${lines[0]} == "1" ]]
}

@test "EDNS(0) ECS skipped for loopback address (IPv4)" {
  # Get number of lines in the log before the test
  before="$(grep -c ^ /var/log/pihole-FTL.log)"

  # Run test command
  run bash -c 'dig localhost +short +subnet=127.0.0.1/32 @127.0.0.1'
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "127.0.0.1" ]]
  [[ $status == 0 ]]

  # Get number of lines in the log after the test
  after="$(grep -c ^ /var/log/pihole-FTL.log)"

  # Extract relevant log lines
  run bash -c "sed -n \"${before},${after}p\" /var/log/pihole-FTL.log"
  printf "%s\n" "${lines[@]}"
  [[ "${lines[@]}" == *"EDNS(0) CLIENT SUBNET: Skipped 127.0.0.1/32 (IPv4 loopback address)"* ]]
}

@test "EDNS(0) ECS skipped for loopback address (IPv6)" {
  # Get number of lines in the log before the test
  before="$(grep -c ^ /var/log/pihole-FTL.log)"

  # Run test command
  run bash -c 'dig localhost +short +subnet=::1/128 @127.0.0.1'
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "127.0.0.1" ]]
  [[ $status == 0 ]]

  # Get number of lines in the log after the test
  after="$(grep -c ^ /var/log/pihole-FTL.log)"

  # Extract relevant log lines
  run bash -c "sed -n \"${before},${after}p\" /var/log/pihole-FTL.log"
  printf "%s\n" "${lines[@]}"
  [[ "${lines[@]}" == *"EDNS(0) CLIENT SUBNET: Skipped ::1/128 (IPv6 loopback address)"* ]]
}

@test "Embedded SQLite3 shell available and functional" {
  run bash -c './pihole-FTL sqlite3 -help'
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "Usage: sqlite3 [OPTIONS] FILENAME [SQL]" ]]
}

@test "Embedded SQLite3 shell is called for .db file" {
  run bash -c './pihole-FTL abc.db ".version"'
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "SQLite 3."* ]]
}

@test "Embedded LUA engine is called for .lua file" {
  echo 'print("Hello from LUA")' > abc.lua
  run bash -c './pihole-FTL abc.lua'
  printf "%s\n" "${lines[@]}"
  [[ ${lines[0]} == "Hello from LUA" ]]
  rm abc.lua
}
