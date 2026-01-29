# Proxy Cat

Multi service proxy, in one YAML.

**Note**: This service **is not** intended to be public facing. Do not expose this service as you could be leaking secrets and/or busting api rate limiting for an uncontrolled usage.

I am not responsible for any problems you might have with the proxied services.

## Installation

### Using docker

```yaml
services:
  proxy_cat:
    image: nboisvert/proxy_cat:latest
    environment:
      - CONFIG_YAML=/config.yml
    volumes:
      - ./config.yml:/config.yml
```

Make sure to have a `config.yml` file that resembles the example in this repo, updated to your needs (See [Configuration](#configuration))

## Configuration

The yaml configuration allows defining multiple proxies. 

**Note**: I haven't tested a lot of authenticated services yet, so it's highly possible that you end up finding issues, I don't how well services respects OAuth (or even if this services actually respects OAuth).

```yml
version: 1 # Is required, expected to be one defined in the `ProxyCat.Config` module
proxies:
  unsplash: # This key is not only the name of the proxy but the "Target" like you'll see below
    host: "https://api.unsplash.com" # Host to call
    cache: # Optional, useful to limit the amount of requests that actually go through
      ttl: 5m

    request_headers:
      add: # Will add the following headers to every requests
       -  key: Authorization
          value: "Client-ID %UNSPLASH_API_KEY%" # This variable will be provided by the environment at the time of loading the config

        - key: "Accept-Version"
          value: "v1"
```

## Makings requests

In order to make requests, make sure to provide a `X-ProxyCat-Target` header with the targetted proxy (the key of the proxy in the config file)

```sh
curl -H "X-ProxyCat-Target: unsplash" http://localhost:4000/photos/random
```

This will make a request to the server's configured `unsplash` proxy adding both the `Authorization` and `Accept-Version` headers defined in the `request_headers` section.
