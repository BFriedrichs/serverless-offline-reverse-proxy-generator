# SLS Offline Reverse Proxe

Run multiple serverless services combined on a port

```
./run_services [PATH] [NGINX_PORT] [START_PORT]
```

## Parameters
Parameters are optional. Specifying any parameter requires specifying the ones preceeding it.

### PATH (default = Current folder)
The path to your services folder.
Expected structure:
* [PATH]
  * serviceA
    * serverless.yml
  * serviceB
    * serverless.yml
  * ...

### NGINX_PORT (default = 9000)
The nginx reverse proxy (your API) will run on this port

### START_PORT (default = 9555)
Make sure that START_PORT + [Number of services] are not occupied by another process since this script is brutal and will nuke anything that is occupying said ports.