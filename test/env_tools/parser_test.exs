defmodule EnvTools.ParserTest do
  use ExUnit.Case, async: true

  alias EnvTools, as: Parser

  test "basic parse and trim lines" do
    envs =
      Parser.decode!("""
        FOO=bar
        NAME = david
      """)

    assert %{"FOO" => "bar"} = envs
    assert %{"NAME" => "david"} = envs
  end

  test "support export" do
    envs =
      Parser.decode!("""
        export    NAME=david
        export SITE=http://example.com
      """)

    assert %{"NAME" => "david"} = envs
    assert %{"SITE" => "http://example.com"} = envs
  end

  test "optional value" do
    envs = Parser.decode!("NAME=")
    assert %{"NAME" => nil} = envs
  end

  test "support simple or double quoted value" do
    envs =
      Parser.decode!("""
        NAME="david luiz"
        export SITE='http://example.com'
      """)

    assert %{"NAME" => "david luiz"} = envs
    assert %{"SITE" => "http://example.com"} = envs
  end

  test "support comments" do
    envs =
      Parser.decode!("""
        # User name
        NAME="david luiz"
        export SITE='http://example.com' # Andress url
      """)

    assert %{"NAME" => "david luiz"} = envs
    assert %{"SITE" => "http://example.com"} = envs
  end

  test "expand values, looking in on itself" do
    envs =
      Parser.decode!("""
        USER_NAME="joe"
        USER_PASSWORD="${USER_NAME}_pass"
        export SITE='http://${USER_NAME}:$USER_PASSWORD@example.com' # Andress url
      """)

    assert %{"USER_NAME" => "joe"} = envs
    assert %{"USER_PASSWORD" => "joe_pass"} = envs
    assert %{"SITE" => "http://joe:joe_pass@example.com"} = envs
  end

  test "expand values, using as an alternative the map informed" do
    envs =
      Parser.decode!(
        """
          USER_PASSWORD="${USER_NAME}_\\$PASS"
          export SITE='http://${USER_NAME}:$USER_PASSWORD@$HOSTNAME' # Andress url
        """,
        system: %{
          "USER_NAME" => "david",
          "HOSTNAME" => "example.io"
        }
      )

    assert %{"USER_PASSWORD" => "david_\\$PASS"} = envs
    assert %{"SITE" => "http://david:david_\\$PASS@example.io"} = envs
  end
end
