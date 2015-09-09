#!/bin/bash
# Scan SDP fileshare (mounted to $SDPPATH - as set in sdpseed.conf) for new/updated sub-folders
# Creates .torrent for each sub-folder (package) that is >$MINSIZE
source /etc/sdpseed/sdpseed.conf

# Creates a torrent for specified package
createtorrent()
{
  torrentcreated=0
  if [ -z "$1" ]; then
    echo createtorrent required package name!
  else
    PACAKGE=$1
    TORRENTNAME=`echo $PACKAGE | tr '/' '#'`
    CHECK=`du -sb $SDPPATH/$PACKAGE`
    regex="([0-9]+)"
    echo $CHECK
    if [[ $CHECK =~ $regex ]]; then
      SIZE=${BASH_REMATCH[1]}
      echo "size is $SIZE bytes"
      if [[ $SIZE -gt $MINSIZE ]]; then
        echo "Creating torrent $TORRENTNAME for $PACKAGE..."
        $MKTORRENT -p -l 22 -a "$TRACKERURL" -o $TORRENTSTORE/$TORRENTNAME.torrent -n "$TORRENTNAME" "$PACKAGE"
        echo "Moving to $SDPPATH/$PACKAGE"
		pushd $SDPPATH/$PACKAGE
        /home/seeder/nh.pl $TORRENTSTORE/$TORRENTNAME.torrent $TORRENTSTORE/../watch/$TORRENTNAME.torrent
        echo "Uploading torrent to Share"
        cp $TORRENTSTORE/$TORRENTNAME.torrent $TORRENTUPLOAD/$TORRENTNAME.torrent
        popd
        torrentcreated=1
      else
        echo "Size under threshhold... skipping torrent creation."
      fi
    else
      echo "ERROR: unable to detect the package size!"
    fi
  fi
}

# Deleted the existing torrent for a package and re-creates
recreatetorrent()
{
  if [ -z "$1" ]; then
    echo recreatetorrent required package name!
  else
    PACKAGE=$1
    TORRENTNAME=`echo $PACKAGE | tr '/' '#'`
    echo Removing old torrent $TORRENTNAME...
    rm -rf $TORRENTSTORE/$TORRENTNAME.torrent 2>/dev/null
    rf -rf $TORRENTSTORE/../watch/$TORRENTNAME.torrent 2>/dev/null
    rm -rf $TORRENTUPLOAD/$TORRENTNAME.torrent 2>/dev/null
    echo Sleeping for 10 seconds to allow rtorrent to remove torrent
    sleep 10
    createtorrent $PACKAGE
  fi
}

# Load the last scanned timestamps from the db
q="SELECT * FROM packages"
LIST=`sqlite3 $DBFILE "$q"`

pushd $SDPPATH
find . -mindepth 2 -maxdepth 2 -type d -print0 | while IFS= read -r -d $'\0' LINE; do
  # Skip if the path contains a space
  if [[ "$LINE" != "${LINE%[[:space:]]*}" ]]; then
    continue
  fi

  PACKAGE=${LINE:2}
  LASTUPDATED=`date -r "$PACKAGE" +'%s'`
  FOUND="false"

  for ROW in $LIST; do
    DB_ID=`echo $ROW | awk '{split($0,a,"|"); print a[1]}'`
    DB_FOLDER=`echo $ROW | awk '{split($0,a,"|"); print a[2]}'`
    DB_LASTUPDATED=`echo $ROW | awk '{split($0,a,"|"); print a[3]}'`

    if [ "$PACKAGE" = "$DB_FOLDER" ]; then
      echo "=========================="
      echo -e "$DB_FOLDER -> Prev: $DB_LASTUPDATED -> Curr: $LASTUPDATED";
      FOUND="true"
      if [[ $DB_LASTUPDATED != $LASTUPDATED ]]; then
        echo "$PACKAGE has changed!"
        # TODO: Update Torrent
        recreatetorrent $PACKAGE
        q="UPDATE packages SET lastupdated=$LASTUPDATED, torrentcreated=$torrentcreated WHERE folder='$PACKAGE'"
        sqlite3 $DBFILE "$q"
      fi
      echo "=========================="
    fi
  done

  if [ $FOUND = "false" ]; then
    echo "$PACKAGE is new!"
    # TODO: Update Torrent
    createtorrent $PACKAGE
    q="INSERT INTO packages (lastupdated, folder, torrentcreated) VALUES ('$LASTUPDATED', '$PACKAGE', $torrentcreated)"
    sqlite3 $DBFILE "$q"
  fi
done
