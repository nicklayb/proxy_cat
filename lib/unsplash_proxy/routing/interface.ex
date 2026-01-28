defprotocol ProxyCat.Routing.Interface do
  def proxy_exists?(config, key)
  def host(config, key)
  def update_headers(config, key, headers)
  def stateful_proxies(config)
  def auth(config, key)
end
