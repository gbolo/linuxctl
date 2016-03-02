#!/bin/bash
 
VERSION=0.7.0
DATE=`date +%Y-%m-%d.%H-%M-%S`
this_path=$(readlink -f $0)        ## Path of this file including filename
dir_name=`dirname ${this_path}`    ## Dir where this file is
myname=`basename ${this_path}`     ## file name of this script.
logger="${myname}.log"
 
function usage {
  echo "
  usage: $myname [OPTIONS...] <domain-name>
 
  -h <host>       optional  IP or Hostname of web server.
  -e              optional  print output in Excel friendly way.  
  -c <count>      optional  how many times to hit web server.
  -r <report>     optional  generate report on this file.
  -p <url-path>   optional  specify specific path in url to hit.
  -u <useragent>  optional  specify useragent.
  -q              optional  supress output to screen."
 
  exit 1
}
 
# Required program(s)
req_progs=(curl mkdir cat)
for p in ${req_progs[@]}; do
hash "$p" 2>&- || \
{ echo >&2 " Required program \"$p\" not installed."; exit 1; }
done
 
# DEFAULT VARS
DATA_DIR="raw_data"
#HOST_IP=$1
#DOMAIN=$2
COUNT=1
URL_PATH=""
USER_AGENT="test-agent"
LOG_FILE="$DATA_DIR/$DATE.log"
OUTPUT_FILE="$DATA_DIR/$DATE.html"
OUTPUT_PERF_FILE="$DATA_DIR/$DATE.perf"
OUTPUT_SQL_FILE="$DATA_DIR/$DATE.sqlexec"
 
 
function logit {
  if [[ $quiet == "true" ]]
  then
    echo $1 1>> $logger
  else
    echo $1 |tee -a $logger
  fi
}
 
 
## Start coding from here. Some basic flags are already provide. Feel free to override, add, delete
#while getopts :hqfi:o:l: args
while getopts "h:ec:r:p:u:q" args
do
  case $args in
  h) HOST_IP="$OPTARG" ;;
  q) quiet='true' ;; ## Suppress messages, just log them.
  e) excel='true' ;;
  c) COUNT="$OPTARG" ;;
  r) REP_FILE="$OPTARG" ;;
  p) URL_PATH="/$OPTARG" ;;
  u) USER_AGENT="$OPTARG" ;;
  :) logit "The argument -$args requires a parameter" ;;
  *) usage ;;
  esac
done
 
## Do parameter validations here.
 
# Check if COUNT is a number
re='^[0-9]+$'
if ! [[ $COUNT =~ $re ]] ; then
   echo "error: the input for -c '$COUNT' is not a number" >&2; exit 1
fi
 
# Get arguments after switch options
shift $(($OPTIND - 1))
DOMAIN=$1
#second_arg=$2
if [[ -z "$DOMAIN" ]] ; then
  usage
fi
 
 
# If host is not specify, do not include host headers
URL=$DOMAIN$URL_PATH
 
# If Host is specified, rewrite URL
if ! [[ -z "$HOST_IP" ]] ; then
  URL=$HOST_IP$URL_PATH
fi
 
# --- FUNCTIONS ---------------------------------------------------
function SETUP_ENVIR {
 
  ## Make directory
  if [[ ! -e $DATA_DIR ]]; then
    mkdir $DATA_DIR
    
  elif [[ ! -d $DATA_DIR ]]; then
    echo "ERROR: $DATA_DIR already exists but is not a directory" 1>&2
    exit 1;
  fi
 
  ## Init/Clear files
  #echo > $OUTPUT_SQL_FILE
  cat /dev/null > $OUTPUT_SQL_FILE
  
  ## Set curl options
  cat >$DATA_DIR/curl.conf<<__EOF__
output = "$OUTPUT_FILE"
user-agent = "blah"
-w "Connect: %{time_connect} TTFB: %{time_starttransfer} Total-time: %{time_total} \n"
-s
-H "Host: $DOMAIN"
__EOF__
  
}
 
function START_CONNECTIONS {
 
  echo "";
  echo "Starting Benchmark: $HOST_IP - $DOMAIN -> $COUNT hits";
  echo "---------------------------------------------------------------";
  for i in $(seq 1 $COUNT); do
    echo -ne "$i \t";
    curl -K $DATA_DIR/curl.conf $URL >> $OUTPUT_PERF_FILE;
    tail -n1 $OUTPUT_PERF_FILE;
    CALC_PHP_SQL_EXEC_TIME;
  done;
 
}
 
function CALC_PHP_SQL_EXEC_TIME {
 
  if [ -s $OUTPUT_FILE ]; then
    ## OLD STYLE, WHEN wp-db.php function is modified
    # cat $OUTPUT_FILE | grep -i execution | awk '{sum+=$3} END {print sum}' >> $OUTPUT_SQL_FILE
 
    ## NEW STYLE, WHEN using $wpdb->queries VAR
    cat $OUTPUT_FILE | grep -i Total_sql | awk '{print $2}' >> $OUTPUT_SQL_FILE
  fi
}
 
function GENERATE_REPORT {
 
 
 
  echo "===============================================================";
  echo -ne "CONNECT TIME: \t";
  min=$(cat $OUTPUT_PERF_FILE | awk '{print $2}' | sort -n | head -n1);
  minms=$(echo $min| awk '{printf "%.0f ms", $1*1000}');
  echo -ne "min: $minms \t";
  max=$(cat $OUTPUT_PERF_FILE | awk '{print $2}' | sort -n | tail -n1);
  maxms=$(echo $max| awk '{printf "%.0f ms", $1*1000}');
  echo -ne "max: $maxms \t";
  cat $OUTPUT_PERF_FILE | awk '{sum+=$2} END {printf "avg: %.0f ms\n", sum/NR*1000}';
  
  echo -ne "TTFB TIME: \t";
  min=$(cat $OUTPUT_PERF_FILE | awk '{print $4}' | sort -n | head -n1);
  minms=$(echo $min| awk '{printf "%.0f ms", $1*1000}');
  echo -ne "min: $minms \t";
  max=$(cat $OUTPUT_PERF_FILE | awk '{print $4}' | sort -n | tail -n1);
  maxms=$(echo $max| awk '{printf "%.0f ms", $1*1000}');
  echo -ne "max: $maxms \t";
  cat $OUTPUT_PERF_FILE | awk '{sum+=$4} END {printf "avg: %.0f ms\n", sum/NR*1000}';
 
  echo -ne "TOTAL TIME: \t";
  min=$(cat $OUTPUT_PERF_FILE | awk '{print $6}' | sort -n | head -n1);
  minms=$(echo $min| awk '{printf "%.0f ms", $1*1000}');
  echo -ne "min: $minms \t";
  max=$(cat $OUTPUT_PERF_FILE | awk '{print $6}' | sort -n | tail -n1);
  maxms=$(echo $max| awk '{printf "%.0f ms", $1*1000}');
  echo -ne "max: $maxms \t";
  cat $OUTPUT_PERF_FILE | awk '{sum+=$6} END {printf "avg: %.0f ms\n", sum/NR*1000}';
  
  if [ -s $OUTPUT_SQL_FILE ]; then 
    echo -ne "PHP-SQL TIME: \t";
    min=$(cat $OUTPUT_SQL_FILE | awk '{print $1}' | sort -n | head -n1);
    minms=$(echo $min| awk '{printf "%.0f ms", $1*1000}');
    echo -ne "min: $minms \t";
    max=$(cat $OUTPUT_SQL_FILE | awk '{print $1}' | sort -n | tail -n1);
    maxms=$(echo $max| awk '{printf "%.0f ms", $1*1000}');
    echo -ne "max: $maxms \t";
    cat $OUTPUT_SQL_FILE | awk '{sum+=$1} END {printf "avg: %.0f ms\n", sum/NR*1000}';
  else
    echo "No PHP-SQL Execution Time found, skipping...";
  fi
 
  
  echo "===============================================================";
  echo "Files: ";
 
  echo $OUTPUT_PERF_FILE;
 
  if [ -s $OUTPUT_SQL_FILE ]; then
    echo $OUTPUT_SQL_FILE;
  else
    echo "$OUTPUT_SQL_FILE [empty!]";
  fi
 
  if [ -s $OUTPUT_FILE ]; then
    echo $OUTPUT_FILE;
  else
    echo "$OUTPUT_FILE [empty!]";
  fi
  echo "";
  
 
}
 
## Put your main code here.
function main {
  #echo "made it to main!!"
  #echo $URL
  SETUP_ENVIR;
  START_CONNECTIONS;
  GENERATE_REPORT;
}
 
## Boot strap the script. Nothing much to do here.
main "$@"
