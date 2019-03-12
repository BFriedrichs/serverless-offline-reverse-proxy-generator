#!/bin/bash

CURR_PATH="./"
NGINX_PORT=9000

if [ "$1" != "" ]; then
  CURR_PATH=$1
  if [[ $CURR_PATH != */ ]] ;
  then
    CURR_PATH="$CURR_PATH/"
  fi
fi
SERVERLESS_FILES=`ls -1 $CURR_PATH**/serverless.yml`;

if [ "$2" != "" ]; then
  NGINX_PORT=$2
fi

CURR_PORT=9555
if [ "$3" != "" ]; then
  CURR_PORT=$3
fi
NETCAT_PORT=$CURR_PORT
CURR_PORT=`expr $CURR_PORT + 1`

cat > nginx_config << EOL
events { }
http {
    server {
      listen $NGINX_PORT;
EOL

TEST=()
CURR_PWD=`pwd`

echo "" > $CURR_PWD/log
echo ""
echo "##########################################################################"
echo ""

for YML in $SERVERLESS_FILES:
do
  cd `dirname $YML`
  DIR_NAME=`dirname $YML`
  BASE_NAME=`basename $DIR_NAME`

  # Kill server that is possibly still running and spawn new one
  lsof -i tcp:$CURR_PORT | grep LISTEN | awk '{print $2}' | xargs kill
  # echo `serverless offline --port $CURR_PORT &` | nc localhost $NETCAT_PORT
  serverless offline --port $CURR_PORT >>$CURR_PWD/log 2>&1 &
  echo "Started lambda for $BASE_NAME on port $CURR_PORT .."

  ENDPOINTS=`cat ./serverless.yml | grep path | sed 's/path: //g' | sed 's/ //g'`;
  BASE=`cat ./serverless.yml | grep basePath | sed 's/ //g' | sed -nE 's/[^:]+:"([^"]+)".*/\1/p'`
  for ENDPOINT in $ENDPOINTS
  do

    # badly fix slashes
    if [[ $ENDPOINT != /* ]] ;
    then
      ENDPOINT="/$ENDPOINT"
    fi
    if [[ $ENDPOINT != */ ]] ;
    then
      ENDPOINT="$ENDPOINT/"
    fi

    FINAL="/$BASE$ENDPOINT"

    if [[ " ${TEST[@]} " =~ " ${FINAL} " ]]; then
      continue
    fi
    TEST+=($FINAL)

    LOC=`echo $FINAL | sed 's/{[^}]*}/[0-9a-z]+/g'`
    REL_LOC=`echo $ENDPOINT | sed 's/{[^}]*}/[0-9a-z]+/g'`

# the nginx location has the prefixed basepath
# the serverless one only needs the relative one
# EOL only works when not indented?? Magic, dont fix!
cat >> $CURR_PWD/nginx_config << EOL
      location $LOC {
          proxy_pass http://localhost:$CURR_PORT$REL_LOC;
      }
EOL

  done

  cd $CURR_PWD
  CURR_PORT=`expr $CURR_PORT + 1`
done

cat >> nginx_config << EOL
    }
}
EOL

# Create nginx server
lsof -i tcp:$NGINX_PORT | grep LISTEN | awk '{print $2}' | xargs kill
nginx -c `pwd`/nginx_config

echo ""
echo "##########################################################################"
echo ""
echo "API running at localhost:$NGINX_PORT"
echo "Netcat output running on port $NETCAT_PORT. (nc -kl $NETCAT_PORT)"
echo "Alternatively logs are located in the 'log' file".
echo ""
echo "##########################################################################"
echo ""

tail -f $CURR_PWD/log | nc localhost $NETCAT_PORT