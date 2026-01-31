import Config

config(:proxy_cat, ProxyCat.Config.Reader,
  adapter: ProxyCat.Config.Reader.Mock,
  variable_provider: ProxyCat.VariableInjector.Provider.Mock
)

config(:proxy_cat, ProxyCat.Http, adapter: ProxyCat.Http.Adapter.Mock)

config(:proxy_cat, ProxyCat.DataStore, adapter: ProxyCat.DataStore.Adapter.Mock)

config(:joken, default_signer: "secret")
