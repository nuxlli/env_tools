defmodule EnvTools do
  @quotes_pattern ~r/^(['"])(.*)\1$/
  @pattern ~r/
    \A
    (?:export\s+)?    # optional export
    ([\w\.]+)         # key
    (?:\s*=\s*|:\s+?) # separator
    (                 # optional value begin
      '(?:\'|[^'])*?' #   single quoted value
      |               #   or
      "(?:\"|[^"])*?" #   double quoted value
      |               #   or
      [^#\n]+?        #   unquoted value
    )?                # value end
    (?:\s*\#.*)?      # optional comment
    \z
    /x

  # https://regex101.com/r/XrvCwE/1
  @env_expand_pattern ~r/
    (?:^|[^\\])                           # prevent to expand \$
    (                                     # get variable key pattern
      \$                                  #
      (?:                                 #
        ([A-Z0-9_]*[A-Z_]+[A-Z0-9_]*)     # get variable key
        |                                 #
        (?:                               #
          {([A-Z0-9_]*[A-Z_]+[A-Z0-9_]*)} # get variable key between {}
        )                                 #
      )                                   #
    )                                     #
    /x

  def decode!(input, opts \\ []) do
    system = Keyword.get(opts, :system, %{})

    input
    |> String.trim()
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.flat_map(&Regex.scan(@pattern, &1))
    |> trim_quotes_from_values
    |> Enum.reduce([], &expand_env(&1, &2, system))
    |> Enum.reduce(Map.new(), &collect_into_map/2)
  end

  defp collect_into_map([_whole, key, value], env) do
    Map.put(env, key, value)
  end

  # without value
  defp expand_env([whole, key], acc, _system), do: acc ++ [[whole, key, nil]]

  defp expand_env([whole, key, value], acc, system) do
    new_value =
      @env_expand_pattern
      |> Regex.scan(value)
      |> replace_matchs(value, acc, system)

    acc ++ [[whole, key, new_value]]
  end

  defp replace_matchs([], value, _previous, _system), do: value

  defp replace_matchs(matchs, value, previous, system) do
    matchs
    |> Enum.reduce(value, fn
      [_whole, pattern | keys], v ->
        v |> replace_env(pattern, keys, previous, system)
    end)
  end

  defp replace_env(value, pattern, ["" | keys], env, system) do
    replace_env(value, pattern, keys, env, system)
  end

  defp replace_env(value, pattern, [key | _], env, system) do
    replace_env(value, pattern, key, env, system)
  end

  defp replace_env(value, pattern, key, previous, system) do
    new_value =
      Enum.find(previous, fn
        [_whole, ^key, _] -> true
        _ -> false
      end)
      |> case do
        [_, _, value] -> value
        _ -> Map.get(system, key, "")
      end

    String.replace(value, pattern, new_value)
  end

  defp trim_quotes_from_values(values) do
    values
    |> Enum.map(fn values ->
      Enum.map(values, &trim_quotes/1)
    end)
  end

  defp trim_quotes(value) do
    String.replace(value, @quotes_pattern, "\\2")
  end
end
