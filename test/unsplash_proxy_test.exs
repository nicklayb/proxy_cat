defmodule UnsplashProxyTest do
  use ExUnit.Case
  doctest UnsplashProxy

  test "greets the world" do
    assert UnsplashProxy.hello() == :world
  end
end
