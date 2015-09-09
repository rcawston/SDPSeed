#!/bin/bash
PACKAGE=$1
PACKAGE=${1%.torrent}
echo -n /mnt/remote-storage/sdp/$PACKAGE | tr '#' '/'
