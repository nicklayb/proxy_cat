import Config

config(:proxy_cat, ProxyCat.Proxy.Handler, port: Box.Config.get("PORT", default: "4000"))

port = Box.Config.get("BACKEND_PORT", default: "4004")

config(:proxy_cat, ProxyCat.Backend.Router,
  port: port,
  host: Box.Config.uri("BACKEND_HOST", default: "http://localhost:#{port}")
)

config(:proxy_cat, ProxyCat.Config, config_yaml: Box.Config.get("CONFIG_YAML"))

config(:proxy_cat, ProxyCat.Cache, ttl: Box.Config.int("CACHE_TTL", default: "0"))

config(:proxy_cat, ProxyCat.Config.Reader, adapter: ProxyCat.Config.Reader.Yaml)
