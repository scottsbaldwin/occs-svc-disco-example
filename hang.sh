#!/bin/sh
i=0
trap 'echo Exiting application; exit' SIGHUP SIGINT SIGTERM
while [ $i -lt 600 ]; do
  echo Hello world from service ${OCCS_SERVICE_ID}!
  i=$(expr $i + 1)
  sleep 1;
done
