defmodule ProxyCat.BaseCase do
  @moduledoc """
  Base test case template
  """
  use ExUnit.CaseTemplate

  using do
    quote do
      import ProxyCat.BaseCase
      import Mox, only: [verify_on_exit!: 1]
      import ProxyCat.Support.Date
      import ProxyCat.Support.Fixtures
      import ProxyCat.Support.Jwt
      require Assertions
    end
  end
end
