import Config

config(:proxy_cat, environment: config_env())

config(:proxy_cat, ProxyCat.Config.Reader, adapter: ProxyCat.Config.Reader.Yaml)
