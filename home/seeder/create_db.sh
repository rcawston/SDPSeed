#!/bin/bash
# include the global config
source /etc/sdpseed/sdpseed.conf

# Table structure
STRUCTURE="CREATE TABLE packages (id INTEGER PRIMARY KEY, folder TEXT UNIQUE, lastupdated INTEGER, torrentcreated INTEGER);"

DB=$DBFILE

# Create an Empty db file and fill it with the structure
cat /dev/null > $DB
echo $STRUCTURE > /tmp/tmpstructure
sqlite3 $DB < /tmp/tmpstructure;
rm -f /tmp/tmpstructure;
rm -rf $TORRENTSTORE/*
