import Config

config(:proxy_cat, environment: config_env())

config(:proxy_cat, ProxyCat.Config.Reader,
  adapter: ProxyCat.Config.Reader.Yaml,
  variable_provider: ProxyCat.VariableInjector.Provider.SystemEnvironment
)

config(:proxy_cat, ProxyCat.Http, adapter: ProxyCat.Http.Adapter.Req)

config(:proxy_cat, ProxyCat.DataStore, adapter: ProxyCat.DataStore.Adapter.Dets)

if config_env() == :test, do: import_config("test.exs")
