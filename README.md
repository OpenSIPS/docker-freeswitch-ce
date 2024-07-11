# FreeSWITCH Docker Image

Docker recipe for building a very light **FreeSWITCH** image that is meant to be used in the OpenSIPS Community Edition projects.

## Warning
To be used only in local setups. This image configures FreeSWITCH in a completely open service and does not enforce any security measures (such as authentication), thus should not be directly accessible.

## Building image
You can build the docker image by running:
```
docker build --tag freeswitch .
```
## Configuration
#### SIP Profiles
Currently both registration and calls authentication is bypassed, allowing everything that is coming to the server. All calls are being placed in the `public` context.

#### Dialplans
There is currently no dialplan available in order to provide any services, you must mount your own dialplans.

#### Directory
The current setup dinamically creates an user along with its properties (such as voicemail) through the [XML handler LUA](xml_handler.lua) script.


## Usage
Any **.sh** script that you have in a volume mounted at `/docker-entrypoint.d/` will be executed in container at start.

## Packages on DockerHub

Released docker packages are visible on DockerHub
https://hub.docker.com/r/opensips/freeswitch-ce
