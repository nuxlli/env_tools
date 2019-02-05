defmodule EnvToolsTest do
  use ExUnit.Case
  doctest EnvTools

  test "greets the world" do
    assert EnvTools.hello() == :world
  end
end
