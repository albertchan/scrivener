defmodule Scrivener.Config do
  @moduledoc """
  A `Scrivener.Config` can be created with a `caller`, a `page_number`, a `page_size` and a `module`. It can optionally be provided a `Keyword` of `options`.

      %Scrivener.Config{
        caller: self(),
        page_number: 2,
        page_size: 5,
        module: MyApp.Repo,
        options: [
          foo: "bar"
        ]
      }
  """

  defstruct [:caller, :module, :options, :page_number, :page_size, :limit, :skip]

  @type t :: %__MODULE__{}

  @doc false
  def new(module, defaults, nil) do
    new(module, defaults, %{})
  end

  @doc false
  def new(module, defaults, options) do
    options = normalize_options(options)

    get_config(module, defaults, options)
  end

  @doc false
  def new(options) do
    options = normalize_options(options)

    new(options["module"], [], options)
  end

  defp get_config(module, defaults, options) do
    case get_env(:scrivener, :offset_format) do
      f when f in [:offest, :skip] ->
        %Scrivener.Config{
          caller: Map.get(options, "caller", self()),
          module: module,
          options: merged_options(defaults, options),
          skip: options["skip"] |> to_int(1),
          limit: limit_size(defaults, options)
        }
      _ ->
        %Scrivener.Config{
          caller: Map.get(options, "caller", self()),
          module: module,
          options: merged_options(defaults, options),
          page_number: options["page"] |> to_int(1),
          page_size: page_size(defaults, options)
        }
    end
  end

  defp get_env(config, key) when is_atom(config) do
    config
    |> Application.get_env(key)
    |> get_value()
  end

  defp get_value({:system, var, default}), do: System.get_env(var) || default
  defp get_value({:system, var}), do: System.get_env(var)
  defp get_value(value), do: value

  defp default_page_size(defaults) do
    defaults[:page_size] || 10
  end

  defp normalize_options(options) do
    Enum.reduce(options, %{}, fn {k, v}, map ->
      Map.put(map, to_string(k), v)
    end)
  end

  defp merged_options(defaults, options) do
    default_opts = Keyword.get(defaults, :options, [])

    opts =
      options
      |> Map.get("options", [])
      |> Keyword.new()

    Keyword.merge(default_opts, opts)
  end

  def page_size(defaults, opts) do
    default_page_size = default_page_size(defaults)
    requested_page_size = opts["page_size"] |> to_int(default_page_size)

    min(requested_page_size, defaults[:max_page_size])
  end

  def limit_size(defaults, opts) do
    default_page_size = default_page_size(defaults)
    requested_page_size = opts["limit"] |> to_int(default_page_size)

    min(requested_page_size, defaults[:max_page_size])
  end

  defp to_int(:error, default), do: default
  defp to_int(nil, default), do: default
  defp to_int(b, default) when is_binary(b), do: b |> Integer.parse() |> to_int(default)
  defp to_int(i, default) when is_integer(i), do: to_int({i, nil}, default)
  defp to_int({i, _}, default) when is_integer(i) and i < 1, do: default
  defp to_int({i, _}, _) when is_integer(i), do: i
  defp to_int(_, default), do: default
end
