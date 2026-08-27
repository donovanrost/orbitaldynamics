defmodule OrbitalDynamics.Environment.ConstantEarthRotationProvider do
  @moduledoc """
  Internal constant-rate Earth-rotation environment provider.

  This adapter exposes the same simplified rotation assumption used by surface
  geometry. It does not provide Earth orientation parameters.
  """

  @behaviour OrbitalDynamics.Environment.Provider

  alias OrbitalDynamics.AccessGeometry

  @safe_number_limit 1.0e15
  @max_opts_length 64
  @max_container_depth 8
  @max_container_entries 2_048
  @max_list_length 1_024
  @max_map_size 128
  @allowed_options [:seconds_since_j2000]

  @impl OrbitalDynamics.Environment.Provider
  def capabilities do
    assumptions = AccessGeometry.assumptions()

    %{
      "id" => "environment.provider.earth_rotation.constant_rate",
      "schema_contract" => "environment_provider_capability.v1",
      "category" => "body_rotation",
      "model" => "constant_earth_rotation",
      "source" => "internal_simplified_geometry",
      "validation_level" => "assumption_declared",
      "coverage" => %{
        "starts_at_s" => nil,
        "ends_at_s" => nil,
        "time_scale" => "seconds_since_j2000",
        "coverage_policy" => "all_times"
      },
      "interpolation" => "analytic_constant_rate",
      "supported_bodies" => ["earth"],
      "network_access" => false,
      "outputs" => ["earth_rotation", "earth_rotation_angle_rad", "earth_rotation_rate_rad_s"],
      "parameters" => %{
        "earth_rotation_rate_rad_s" => Map.fetch!(assumptions, :earth_rotation_rate_rad_s),
        "geometry_model" => Atom.to_string(Map.fetch!(assumptions, :geometry_model))
      },
      "known_limits" => [
        "no Earth orientation parameters",
        "no UT1 or polar-motion correction",
        "spherical surface geometry"
      ]
    }
  end

  def fetch(kind, opts \\ [])

  @impl OrbitalDynamics.Environment.Provider
  def fetch(:earth_rotation, opts) do
    with :ok <- validate_opts(opts),
         {:ok, seconds_since_j2000} <- required_number(opts, :seconds_since_j2000),
         {:ok, rate} <- capability_rate() do
      {:ok,
       %{
         "provider_id" => capabilities()["id"],
         "earth_rotation_rate_rad_s" => rate,
         "earth_rotation_angle_rad" => rate * seconds_since_j2000,
         "model" => "constant_earth_rotation"
       }}
    end
  end

  def fetch(kind, _opts), do: {:error, {:unsupported_environment_product, kind}}

  defp capability_rate do
    rate = capabilities()["parameters"]["earth_rotation_rate_rad_s"]

    if finite_number?(rate) do
      {:ok, rate}
    else
      {:error, {:environment_provider_error, :earth_rotation_rate_rad_s}}
    end
  end

  defp required_number(opts, key) do
    case Keyword.fetch(opts, key) do
      {:ok, value} when is_integer(value) or is_float(value) ->
        if finite_number?(value) do
          {:ok, value * 1.0}
        else
          {:error, {:invalid_option, key}}
        end

      {:ok, _value} ->
        {:error, {:invalid_option, key}}

      :error ->
        {:error, {:missing_option, key}}
    end
  end

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

  defp preflight_option_value(:seconds_since_j2000, value),
    do: preflight_numeric_option(:seconds_since_j2000, value)

  defp preflight_option_value(_key, value), do: preflight_container(value, :opts)

  defp preflight_numeric_option(key, value) when is_integer(value) or is_float(value) do
    if finite_number?(value), do: :ok, else: {:error, {:invalid_option, key}}
  end

  defp preflight_numeric_option(_key, value), do: preflight_container(value, :opts)

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
