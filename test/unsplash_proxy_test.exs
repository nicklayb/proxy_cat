defmodule ProxyCatTest do
  use ExUnit.Case
  doctest ProxyCat

  test "greets the world" do
    assert ProxyCat.hello() == :world
  end
end
