defmodule ProxyCat.Http.Response do
  @moduledoc """
  Generic HTTP Response structure
  """
  alias ProxyCat.Http.Response

  defstruct [:status, :body, :headers]

  @type t :: %Response{
          headers: [ProxyCat.Http.header()],
          body: any(),
          status: non_neg_integer()
        }
end
