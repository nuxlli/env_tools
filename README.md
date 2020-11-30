# EnvTools

**Attention:** This project is not a configuration tool based on environment
variables for [Elixir][elixir] alone. In general this is not the right approach
for configuring [Elixir][elixir] applications.

This project brings together some useful tools for dealing with environment variables:

- Support for loading and parsing [dotenv][dotenv] files: `EnvTools.load`
- Parsing for [dotenv][dotenv] formats: `EnvTools.decode`
- A types transformer for environment variables: `EnvTools.get`

You can combine this tool with [Mix Config Provider][mix_config_provider], and
get a relatively elegant support for configuration through environment variables.

k8s developer: In my experience deploying [Elixir][elixir] applications for
[k8s](k8s), this collection of tools has proven very useful ;)

## Installation

If [available in Hex](https://hex.pm/packages/env_tools), the package can be
installed by adding `env_tools` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:env_tools, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can be
found at [https://hexdocs.pm/env_tools](https://hexdocs.pm/env_tools).

## Example

```elixir
# config/config.exs
if !Code.ensure_loaded?(EnvTools) do
  # Load before `mix compile`
  env_tools = "deps/env_tools/lib/env_tools.ex"
  if File.exists?(env_tools) do
    Code.eval_file(env_tools)
  else
    # Fallback before `mix deps.get`
    defmodule EnvTools do
      def load(_), do: nil
      def get(opts), do: opts
    end
  end
end

EnvTools.load(["#{__DIR__}/../envs", __DIR__])

use Mix.Config

config :my_app,
  param: EnvTools.get({:interger, "VAR_PARAM", 0})

# other configs
```

## Rules

Formally, [dotenv][dotenv] is not a standardized format. However, many other
projects have used the npm project as a foundation for implementing their parsers.

Like [dotenv][dotenv], this project adheres to the following rules:

- `BASIC=basic` becomes `%{"BASIC" => "basic"}`
- empty lines are skipped
- lines beginning with # are treated as comments
- empty values become empty strings (`EMPTY=` becomes `${"EMPTY" => ""}`)
- single and double quoted values are escaped (`SINGLE_QUOTE='quoted'` becomes `%{"SINGLE_QUOTE" => "quoted"}`)
- new lines are expanded if in double quotes: (`MULTILINE="new\nline"` becomes: `%{"MULTILINE" => "new\nline"}`)
- inner quotes are maintained (think JSON) (`JSON={"foo": "bar"}` becomes `%{"JSON" => "{\"foo\": \"bar\"}"}`)
- whitespace is removed from both ends of the value (see more on trim) (`FOO=" some value "` becomes `%{"FOO" => "some value"}`)

Additional rules:

- export is supported (`export VAR=1` becomes `%{"VAR" => "1"}`
- expand is supported (for `HOME=~/nuxlli`, `USER_HOME=${HOME}` becomes `%{ "USER_HOME" => "~/nuxlli" }`)

[elixir]: https://elixir-lang.org
[dotenv]: https://www.npmjs.com/package/dotenv
[mix_config_provider]: https://hexdocs.pm/distillery/config/runtime.html#mix-config-provider
