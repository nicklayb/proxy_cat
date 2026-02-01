import Config

config(:logger, level: Box.Config.atom("LOG_LEVEL", default: "info"))

config(:proxy_cat, ProxyCat.Proxy.Handler, port: Box.Config.get("PORT", default: "4000"))

port = Box.Config.get("BACKEND_PORT", default: "4004")

config(:proxy_cat, ProxyCat.Backend.Router,
  port: port,
  host: Box.Config.uri("BACKEND_HOST", default: "http://localhost:#{port}")
)

config(:proxy_cat, ProxyCat.Config,
  file: Path.expand(Box.Config.get("CONFIG_FILE", test: "./example.yml"))
)

priv_dir = :code.priv_dir(:proxy_cat)

config(:proxy_cat, ProxyCat.DataStore,
  adapter_options: [directory: Box.Config.get("DETS_DIRECTORY", default: to_string(priv_dir))]
)

{success_level, error_level} =
  with [success_level, error_level] <-
         Box.Config.list("HTTP_LOG_LEVELS", default: "info|error", separator: "|") do
    {String.to_existing_atom(success_level), String.to_existing_atom(error_level)}
  end

config(:proxy_cat, ProxyCat.Http, log_levels: [success: success_level, error: error_level])

config(:proxy_cat, ProxyCat.Config.Server,
  hot_reload_enabled?: Box.Config.bool("CONFIG_HOT_RELOAD", default: "true", test: false)
)
