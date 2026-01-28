import Config

config(:proxy_cat, ProxyCat.Proxy.Server, port: Box.Config.get("PORT", default: "4000"))
config(:proxy_cat, ProxyCat.Backend.Server, port: Box.Config.get("BACKEND_PORT", default: "4004"))

config(:proxy_cat, ProxyCat.Routing, config_yaml: Box.Config.get("CONFIG_YAML"))

config(:proxy_cat, ProxyCat.Cache, ttl: Box.Config.int("CACHE_TTL", default: "0"))
