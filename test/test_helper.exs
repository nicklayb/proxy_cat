ExUnit.start()

Mox.defmock(ProxyCat.Http.Adapter.Mock, for: ProxyCat.Http.Adapter)
Mox.defmock(ProxyCat.DataStore.Adapter.Mock, for: ProxyCat.DataStore.Adapter)
Mox.defmock(ProxyCat.Config.Reader.Mock, for: ProxyCat.Config.Reader)
Mox.defmock(ProxyCat.VariableInjector.Provider.Mock, for: ProxyCat.VariableInjector.Provider)
