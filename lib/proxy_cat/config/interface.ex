defprotocol ProxyCat.Config.Interface do
  @moduledoc """
  Protocol to work with various configuration versions.
  The individual configurations **must not** leak outside
  there own namespacing. Any calls that has to invoke a configuration
  part, has to go through these functions.

  The interface should also not be invoked directly, calls
  should go through `ProxyCat.Config` to streamline the interface
  """

  alias ProxyCat.Config
  alias ProxyCat.Config.AuthSpec

  @type header :: {String.t(), String.t()}

  @spec proxy_exists?(Config.t(), atom()) :: boolean()
  def proxy_exists?(config, key)

  @spec host(Config.t(), atom()) :: {:ok, URI.t()} | {:error, any()}
  def host(config, key)

  @spec update_headers(Config.t(), atom(), :request | :response, [header()]) :: [header()]
  def update_headers(config, key, request_or_response, headers)

  @spec stateful_proxies(Config.t()) :: [{AuthSpec.t(), atom()}]
  def stateful_proxies(config)

  @spec auth(Config.t(), atom()) :: AuthSpec.t() | nil
  def auth(config, key)
end
