import Config

config(:logger, level: Box.Config.atom("LOG_LEVEL", default: "info"))

config(:proxy_cat, ProxyCat.Proxy.Handler, port: Box.Config.get("PORT", default: "4000"))

port = Box.Config.get("BACKEND_PORT", default: "4004")

config(:proxy_cat, ProxyCat.Backend.Router,
  port: port,
  host: Box.Config.uri("BACKEND_HOST", default: "http://localhost:#{port}")
)

config(:proxy_cat, ProxyCat.Config, config_yaml: Box.Config.get("CONFIG_YAML"))

default_dets =
  :proxy_cat
  |> :code.priv_dir()
  |> Path.join("datastore.dat")

config(:proxy_cat, ProxyCat.DataStore,
  adapter:
    {ProxyCat.DataStore.Adapter.Dets,
     [table_name: :proxy_cat_data_store, file: Box.Config.get("DETS_FILE", default: default_dets)]}
)
