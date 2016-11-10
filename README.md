# Container Cloud Service Discovery Example

## Build the Image

```
docker build -t derive-and-hang:latest .
```

## Create the Stack

To demonstrate how to derive host and IP information from containers with service discovery, create a stack in Container Cloud Service using the following YML:

```
version: 2
services:
  A:
    image: "YOUR_DOCKER_HUB_USERNAME/derive-and-hang:latest"
    ports:
      - 11111/tcp
    environment:
      - OCCS_PHASE_ID=0
    command: /hang.sh
  B:
    image: "YOUR_DOCKER_HUB_USERNAME/derive-and-hang:latest"
    ports:
      - 22222/tcp
    environment:
      - OCCS_PHASE_ID=1
      - "SERVICE_DISCOVERY_KEY={{ sd_deployment_containers_path \"A\" 11111 }}"
      - "SELF_KEY={{ sd_deployment_containers_path \"B\" 22222 }}"
      - "PROXY={{proxy \"A:11111\"}}"
      - "http_proxy="
      - "https_proxy="
      - "no_proxy="
    command: /derive-and-hang.sh
```

*NOTE: Set the necessary proxy variables as needed. The derive-and-hang container will need access to the Internet to add packages to Alpine linux for curl and jq.*

## Deploy the Stack

When you deploy the stack, scale up service A to multiple containers. This will demonstrate more effectively how service B can find all the host IP and port combinations for the containers deployed for service A.