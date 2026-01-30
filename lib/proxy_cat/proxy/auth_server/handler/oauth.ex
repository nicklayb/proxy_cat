defmodule ProxyCat.Proxy.AuthServer.Handler.Oauth do
  @moduledoc """
  Default handler that just stores things up and ignore
  any messages it receives.
  """
  @behaviour ProxyCat.Proxy.AuthServer.Handler

  alias ProxyCat.Config.AuthSpec.Oauth2
  alias ProxyCat.Proxy.AuthServer.Handler

  require Logger

  @impl Handler
  def init(%Oauth2{} = oauth, key) do
    authorize_url = Oauth2.authorize_url(oauth, key)
    Logger.info("[#{inspect(__MODULE__)}] [authorize_url] #{authorize_url}")
    %{}
  end

  @impl Handler
  def handle_info(_message, state) do
    state
  end

  @impl Handler
  def store(state, key, value), do: Handler.Default.store(state, key, value)

  @impl Handler
  def retrieve(state, key), do: Handler.Default.retrieve(state, key)
end
