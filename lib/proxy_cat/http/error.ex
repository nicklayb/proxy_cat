defmodule ProxyCat.Http.Error do
  @moduledoc """
  Generic HTTP Error structure
  """
  alias ProxyCat.Http.Error

  defstruct [:error, :detail]

  @type t :: %Error{
          error: any(),
          detail: any()
        }
end
