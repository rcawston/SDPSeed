# SDPSeed - Automated Seedbox
## Overview
The SDPSeed project provides the design for a server that will:
- Scan a remote file share periodically for new or updated "SDP Packages" (essentially, each 2-level-deep path on the share is a package)
- Generate torrent files for packages over a certain size
- Start seeding automatically
- Move the torrent file to a remote server so it can be accessed by SDPFetch or another bittorrent distribution method/client.

## Operating System
* The seedbox was built on RHEL 7.1, but implementing on any modern linux OS with should be possible.

## Base Install
- yum update
- yum install nano cifs-utils screen perl-CPAN
- yum group install "Development Tools"
- groupadd sdpseed
- useradd –m –s /bin/bash –G sdpseed seeder
- mkdir /etc/sdpseed
- mkdir -p /var/sdpseed/{torrents,watch}
- mkdir /mnt/remote-storage
- chown -R seeder:sdpseed /etc/sdpseed
- chown -R seeder:sdpseed /var/sdpseed
- chmod -R 770 /etc/sdpseed/
- chmod -R 770 /var/sdpseed/
- chmod 775 /var/sdpseed/torrents
- nano /etc/yum.repos.d/epel.repo
- > under [epel] set enabled=1; save

## Perl Modules
- cpan
- install Convert::Bencode_XS
- quit

## rtorrent and mktorrent
- yum --enablerepo="epel" install rtorrent
- yum --enablerepo="epel" install mktorrent

## Scripts
- create_db.sh, scan.sh, repath.sh -> copy to /home/seeder

## Configuration Files
- rtorrent.rc -> copy to /home/seeder/.rtorrent.rc
- sdpseed.conf, credentials.txt -> copy to /etc/seeder
- fstab -> add contained line to /etc/fstab

## Edit Configuration
- edit /etc/sdpseed/sdpseed.conf:
 - replace TRACKERURL:PORT with your Tracker URL and port
- edit /etc/sdpseed/credentials.txt:
 - replace COMPLETE_ME! with username, password, and AD domain
- edit /etc/fstab:
 - replace SERVERHOSTNAME/SERVERSHARE with your SDP server's host and share names

## Increase CIFS Max Buffer
- edit /etc/modprobe.d/cifs.conf
- add line: cifs CIFSMaxBufSize=130048

## IPTables Firewall
- iptables-save > iptables.rules
- nano iptables.rules
- Add before reject all:
- > -A INPUT -p tcp --dport 51000:52000 -j ACCEPT
- iptables-restore < iptables.rules
- # verify it worked
- iptables -L

## Finish Install, Scan SDP, Create Torrents
- mount /mnt/remote-storage
- su seeder
- cd ~
- chmod +x *.sh
- ./create_db.sh
- ./scan.sh
- mkdir .rtorrent
- mkdir scanlog

## Launch rtorrent
- screen rtorrent
- *use ctrl-{a,d} to demonize*
- *to restore rtorrent:*
- screen –r

## Setup CRON Job (scan SDP every 2 hours)
- crontab -e
- 0 */2 * * *  /home/seeder/scan.sh > /home/seeder/scanlog/log 2>&1
