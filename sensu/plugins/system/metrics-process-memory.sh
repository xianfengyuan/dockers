#!/bin/bash

# #RED
SCHEME=`hostname`

usage()
{
  cat <<EOF
usage: $0 options

This plugin produces Memory usage

OPTIONS:
   -h      Show this message
   -p      Process name
   -s      Metric naming scheme, text to prepend to cpu.usage (default: $SCHEME)
EOF
}

while getopts "hp:s:" OPTION
  do
    case $OPTION in
      h)
        usage
        exit 1
        ;;
      p)
        PROCESS="$OPTARG"
        ;;
      s)
        SCHEME="$OPTARG"
        ;;
      ?)
        usage
        exit 1
        ;;
    esac
done

if [ ${PROCESS} ]; then
  scriptname=`basename $0`
  SCHEME="${SCHEME}.${PROCESS}"
  ret=`ps aux | grep "${PROCESS}" | grep -v grep | grep -v $scriptname | awk '{print $6}'`
  if [ ! "${ret}" ]; then
    echo "$SCHEME.memory 0 `date +%s`"
    exit 0
  fi
  echo "$SCHEME.memory ${ret} `date +%s`"
  exit 0
fi
