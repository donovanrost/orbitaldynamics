defmodule OrbitalDynamics.Environment.FixedSunProvider do
  @moduledoc """
  Internal fixed-Sun environment provider.

  This adapter exists to make the current fixed inertial solar-direction
  assumption explicit through the provider contract. It is not an ephemeris
  provider.
  """

  @behaviour OrbitalDynamics.Environment.Provider

  @default_direction {1.0, 0.0, 0.0}
  @safe_number_limit 1.0e15
  @max_opts_length 64
  @max_container_depth 8
  @max_container_entries 2_048
  @max_list_length 1_024
  @max_map_size 128
  @allowed_options [:sun_direction]

  @impl OrbitalDynamics.Environment.Provider
  def capabilities do
    %{
      "id" => "environment.provider.solar.fixed_inertial_direction",
      "schema_contract" => "environment_provider_capability.v1",
      "category" => "solar_direction",
      "model" => "fixed_inertial_solar_direction",
      "source" => "internal_fixed_sun_assumption",
      "validation_level" => "assumption_declared",
      "coverage" => %{
        "starts_at_s" => nil,
        "ends_at_s" => nil,
        "time_scale" => "seconds_since_j2000",
        "coverage_policy" => "all_times"
      },
      "interpolation" => "constant",
      "supported_bodies" => ["earth"],
      "network_access" => false,
      "outputs" => ["sun_direction"],
      "known_limits" => [
        "not an ephemeris provider",
        "no Sun range or light-time correction",
        "no time-varying apparent solar direction"
      ]
    }
  end

  def fetch(kind, opts \\ [])

  @impl OrbitalDynamics.Environment.Provider
  def fetch(:sun_direction, opts) do
    with :ok <- validate_opts(opts),
         {:ok, direction} <-
           normalized_direction(Keyword.get(opts, :sun_direction, @default_direction)) do
      {:ok,
       %{
         "provider_id" => capabilities()["id"],
         "sun_direction" => encode_direction(direction),
         "frame" => "eci_j2000_inertial",
         "model" => "fixed_inertial_solar_direction"
       }}
    end
  end

  def fetch(kind, _opts), do: {:error, {:unsupported_environment_product, kind}}

  defp encode_direction({x, y, z}), do: [x, y, z]

  defp normalized_direction({x, y, z} = direction) do
    if finite_number?(x) and finite_number?(y) and finite_number?(z) and
         vector_norm(direction) > 0.0 do
      {:ok, direction}
    else
      {:error, {:invalid_option, :sun_direction}}
    end
  end

  defp normalized_direction([x, y, z]) do
    normalized_direction({x, y, z})
  end

  defp normalized_direction(_direction), do: {:error, {:invalid_option, :sun_direction}}

  defp vector_norm({x, y, z}), do: :math.sqrt(x * x + y * y + z * z)

  defp validate_opts(opts) do
    with {:ok, items} <- bounded_list_items(opts, :opts, @max_opts_length),
         true <- Enum.all?(items, &keyword_entry?/1),
         true <- unique_keyword_keys?(items),
         :ok <- preflight_option_values(items),
         :ok <- reject_unsupported_options(items) do
      :ok
    else
      false -> {:error, {:invalid_option, :opts}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp keyword_entry?({key, _value}) when is_atom(key), do: true
  defp keyword_entry?(_entry), do: false

  defp unique_keyword_keys?(items) do
    keys = Enum.map(items, fn {key, _value} -> key end)
    length(keys) == length(Enum.uniq(keys))
  end

  defp preflight_option_values(items) do
    Enum.reduce_while(items, :ok, fn {key, value}, :ok ->
      case preflight_option_value(key, value) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp preflight_option_value(:sun_direction, {x, y, z}),
    do: preflight_vector_components([x, y, z], :sun_direction)

  defp preflight_option_value(:sun_direction, [x, y, z]),
    do: preflight_vector_components([x, y, z], :sun_direction)

  defp preflight_option_value(_key, value), do: preflight_container(value, :opts)

  defp preflight_vector_components(components, field) do
    if Enum.all?(components, &finite_number?/1) do
      :ok
    else
      {:error, {:invalid_option, field}}
    end
  end

  defp reject_unsupported_options(items) do
    Enum.reduce_while(items, :ok, fn {key, _value}, :ok ->
      if key in @allowed_options do
        {:cont, :ok}
      else
        {:halt, {:error, {:unsupported_option, key}}}
      end
    end)
  end

  defp preflight_container(term, field) do
    preflight_container([{term, 0}], 0, field)
  end

  defp preflight_container([], _visited, _field), do: :ok

  defp preflight_container(_stack, visited, field) when visited > @max_container_entries,
    do: {:error, {:container_limit_exceeded, field}}

  defp preflight_container([{_term, depth} | _rest], _visited, field)
       when depth > @max_container_depth do
    {:error, {:container_depth_exceeded, field}}
  end

  defp preflight_container([{tuple, _depth} | _rest], _visited, field) when is_tuple(tuple),
    do: {:error, {:invalid_container, field}}

  defp preflight_container([{%{} = map, depth} | rest], visited, field) do
    cond do
      map_size(map) > @max_map_size ->
        {:error, {:container_limit_exceeded, field}}

      invalid_map_key?(map) ->
        {:error, {:invalid_container, field}}

      true ->
        with :ok <- reject_generic_alias_collisions(map) do
          children = Enum.map(Map.values(map), &{&1, depth + 1})
          preflight_container(children ++ rest, visited + map_size(map), field)
        end
    end
  end

  defp preflight_container([{list, depth} | rest], visited, field) when is_list(list) do
    case bounded_list_items(list, field, @max_list_length) do
      {:ok, items} ->
        children = Enum.map(items, &{&1, depth + 1})
        preflight_container(children ++ rest, visited + length(items), field)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp preflight_container([{term, _depth} | rest], visited, field)
       when is_nil(term) or is_boolean(term) or is_atom(term) or is_binary(term),
       do: preflight_container(rest, visited + 1, field)

  defp preflight_container([{term, _depth} | rest], visited, field)
       when is_integer(term) or is_float(term) do
    if finite_number?(term) do
      preflight_container(rest, visited + 1, field)
    else
      {:error, {:invalid_container, field}}
    end
  end

  defp preflight_container([_term | _rest], _visited, field),
    do: {:error, {:invalid_container, field}}

  defp invalid_map_key?(map) do
    Enum.any?(Map.keys(map), fn key -> not (is_atom(key) or is_binary(key)) end)
  end

  defp reject_generic_alias_collisions(%{} = map) do
    atom_key_strings =
      map
      |> Map.keys()
      |> Enum.filter(&is_atom/1)
      |> Enum.map(&Atom.to_string/1)
      |> MapSet.new()

    case Enum.find(Map.keys(map), fn key ->
           is_binary(key) and MapSet.member?(atom_key_strings, key)
         end) do
      nil -> :ok
      key -> {:error, {:atom_string_alias_collision, key}}
    end
  end

  defp bounded_list_items(list, field, limit) when is_list(list) do
    bounded_list_items(list, [], 0, field, limit)
  end

  defp bounded_list_items(_not_list, field, _limit), do: {:error, {:invalid_container, field}}

  defp bounded_list_items(_list, _acc, count, field, limit) when count > limit,
    do: {:error, {:container_limit_exceeded, field}}

  defp bounded_list_items([], acc, _count, _field, _limit), do: {:ok, Enum.reverse(acc)}

  defp bounded_list_items([head | tail], acc, count, field, limit) do
    bounded_list_items(tail, [head | acc], count + 1, field, limit)
  end

  defp bounded_list_items(_improper_tail, _acc, _count, field, _limit),
    do: {:error, {:invalid_container, field}}

  defp finite_number?(value) when is_integer(value), do: abs(value) <= @safe_number_limit

  defp finite_number?(value) when is_float(value) do
    value == value and value - value == 0.0 and abs(value) <= @safe_number_limit
  end

  defp finite_number?(_value), do: false
end
