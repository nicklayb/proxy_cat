# Unsplash Proxy

Hosts a proxy that forwards request to Unsplash inferring your API key. 

## Why?

So you can query Unsplash without an API key, simple as that. My use case example is that I wanted all my NixOS computer to be able to pull wallpapers but without having to provider my Unsplash API Key on all of them. So I just poll my proxy. Obviously it works only at home (or on vpn) and I don't recommend hosting this publicly or Unsplash will probably block you.


## Installation

I expose a docker image for the proxy at `nboisvert/unsplash-proxy`. The only necessary environment variable is `UNSPLASH_API_KEY` which is your Access Key.

Optionally, you can also pass `PORT` if you which to change the port it listens to (defaults to `4000`)

```
docker run -e UNSPLASH_API_KEY=yourkey docker.io/nboisvert/unsplash-proxy
```
