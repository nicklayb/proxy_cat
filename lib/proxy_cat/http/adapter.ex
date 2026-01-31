defmodule ProxyCat.Http.Adapter do
  @moduledoc """
  Behaviour for implementing HTTP adapters
  """
  @type request :: ProxyCat.Http.Request.t()
  @type response :: ProxyCat.Http.Response.t()
  @type error :: ProxyCat.Http.Error.t()

  @type result :: {:ok, response()} | {:error, error()}

  @callback request(request(), Keyword.t()) :: result()
end
