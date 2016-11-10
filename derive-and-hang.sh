#!/bin/sh

# Add curl to the base alpine linux so that we can send requests
# to the unauthenticated key/value endpoint.
apk upgrade && apk add -U curl jq

# Wait for a few seconds to make sure the dependent services are up.
# This is technically unnecessary if the stack uses a phased run by
# setting the OCCS_PHASE_ID variables for each service.
i=0
seconds=5
trap 'echo Exiting application; exit' SIGHUP SIGINT SIGTERM
while [ $i -lt $seconds ]; do
  echo Waiting $(expr $i + 1)/$seconds before resolving variables
  i=$(expr $i + 1)
  sleep 1
done

# Each worker has an unauthenticated endpoint for getting consul-like
# keys/values from service discovery. The endpoint is accessible via
# the Docker bridge on port 9109
export SERVICE_DISCO_URL=172.17.0.1:9109/api/kv

# Use a service discovery key path to derive all the host:port combinations
# for the service mapped to that discovery key path. SERVICE_DISCOVERY_KEY is
# defined by {{sd_deployment_containers_path "svc" port}}, where svc is the
# name of the depended on service in the stack YML and port is the port number
# of the depended on service in the stack YML.
echo "# --------------------------------------------------------"
echo "# Determining hosts and ports from service discovery using"
echo "# the SERVICE_DISCOVERY_KEY variable..."
echo "# --------------------------------------------------------"
export HOSTS_AND_PORTS=$(curl -s ${SERVICE_DISCO_URL}/${SERVICE_DISCOVERY_KEY}?keys=true | jq -r ".[]" | xargs -iKEY sh -c "curl -s ${SERVICE_DISCO_URL}/KEY?raw=true;echo")
echo SERVICE_DISCOVERY_KEY=${SERVICE_DISCOVERY_KEY}
echo HOSTS_AND_PORTS=${HOSTS_AND_PORTS}

# Split the host and port from the PROXY variable. The PROXY variable
# is set in the stack YML using a {{proxy "svc:port"}} template.
echo "# --------------------------------------------------------"
echo "# Determining host and port from PROXY variable..."
echo "# --------------------------------------------------------"
export PROXY_HOST=$(echo ${PROXY} | sed -r -e 's/^(.+):.+$/\1/')
export PROXY_PORT=$(echo ${PROXY} | sed -r -e 's/^.+:(.+)$/\1/')
echo PROXY=${PROXY}
echo PROXY_HOST=${PROXY_HOST}
echo PROXY_PORT=${PROXY_PORT}

# Use service discovery to derive the host:port of "self". This is achieved
# by first determining the container ID of the running container within itself.
# SELF_KEY is defined by {{sd_deployment_containers_path "svc" port}}, where svc
# is the name of the same service in the stack YML and port is the port number
# of the same service in the stack YML.
echo "# --------------------------------------------------------"
echo "# Determining host and port of myself..."
echo "# --------------------------------------------------------"
export CONTAINER_ID=$(cat /proc/self/cgroup | grep 'cpu:/' | sed -r 's/[0-9]+:cpu:.docker.//g')
export SELF=$(curl -s ${SERVICE_DISCO_URL}/${SELF_KEY}/${CONTAINER_ID}?raw=true)
export SELF_HOST=$(echo ${SELF} | sed -r -e 's/^(.+):.+$/\1/')
export SELF_PORT=$(echo ${SELF} | sed -r -e 's/^.+:(.+)$/\1/')
echo SELF=${SELF}
echo SELF_HOST=${SELF_HOST}
echo SELF_PORT=${SELF_PORT}

# This loop hangs for 10 minutes to allow time to inspect logs before the container exits.
i=0;
while [ $i -lt 600 ]; do
  echo Hello world from service ${OCCS_SERVICE_ID}!
  i=$(expr $i + 1)
  sleep 1
done
