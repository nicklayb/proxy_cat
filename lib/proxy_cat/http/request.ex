defmodule ProxyCat.Http.Request do
  @moduledoc """
  Generic HTTP Request structure
  """
  alias ProxyCat.Http.Request

  defstruct [:headers, :body, :method, :url]

  @type method :: :get | :post | :patch | :put

  @type t :: %Request{
          headers: [ProxyCat.Http.header()],
          body: any(),
          method: method(),
          url: URI.t()
        }
end
