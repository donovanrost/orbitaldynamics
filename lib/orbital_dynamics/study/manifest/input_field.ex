defmodule OrbitalDynamics.Study.Manifest.InputField do
  @moduledoc false

  def required(map, key) do
    case Map.fetch(map, key) do
      {:ok, value} when value not in [nil, ""] -> {:ok, value}
      _missing_or_empty -> {:error, {:missing_field, key}}
    end
  end

  def required_map(map, key), do: typed(map, key, &is_map/1, :required)
  def required_list(map, key), do: typed(map, key, &(is_list(&1) and &1 != []), :required)
  def optional_list(map, key), do: typed(map, key, &is_list/1, {:optional, []})
  def required_number(map, key), do: typed(map, key, &is_number/1, :required)

  def required_number_list(map, key) do
    typed(
      map,
      key,
      &(is_list(&1) and &1 != [] and Enum.all?(&1, fn value -> is_number(value) end)),
      :required
    )
  end

  def optional_number(map, key), do: optional_nullable(map, key, &is_number/1)

  def optional_string(map, key),
    do: optional_nullable(map, key, &(is_binary(&1) and &1 != ""))

  def optional_number_or_identifier(map, key) do
    optional_nullable(
      map,
      key,
      &(is_number(&1) or (is_binary(&1) and &1 != "") or is_atom(&1))
    )
  end

  def optional_boolean(map, key, default),
    do: typed(map, key, &is_boolean/1, {:optional, default})

  def optional_boolean_or_nil(map, key), do: optional_nullable(map, key, &is_boolean/1)

  def optional_string(map, key, default),
    do: typed(map, key, &(is_binary(&1) and &1 != ""), {:optional, default})

  def optional_station_availability(map, key) do
    allowed = ["available", "unavailable", "reduced_capacity", "maintenance", "reserved"]

    optional_nullable(
      map,
      key,
      &((is_binary(&1) and &1 in allowed) or
          (is_number(&1) and &1 >= 0.0 and &1 <= 1.0))
    )
  end

  def validate_optional_interval(_field, nil, nil), do: :ok
  def validate_optional_interval(_field, nil, end_s) when is_number(end_s), do: :ok
  def validate_optional_interval(_field, start_s, nil) when is_number(start_s), do: :ok

  def validate_optional_interval(field, start_s, end_s)
      when is_number(start_s) and is_number(end_s) do
    if end_s > start_s, do: :ok, else: {:error, {:invalid_field, field}}
  end

  def validate_optional_interval(field, _start_s, _end_s),
    do: {:error, {:invalid_field, field}}

  def optional_identifier(map, key) do
    optional_nullable(map, key, &((is_binary(&1) and &1 != "") or is_atom(&1)))
  end

  def optional_identifier_list(map, key) do
    typed(
      map,
      key,
      &(is_list(&1) and Enum.all?(&1, fn value -> is_binary(value) and value != "" end)),
      {:optional, []}
    )
  end

  def optional_identifier_list_or_nil(map, key) do
    case optional_identifier_list(map, key) do
      {:ok, []} ->
        if Map.has_key?(map, key), do: {:ok, []}, else: {:ok, nil}

      other ->
        other
    end
  end

  def optional_map(map, key), do: optional_nullable_map(map, key, %{})
  def optional_map_or_nil(map, key), do: optional_nullable_map(map, key, nil)

  def required_positive_integer(map, key),
    do: typed(map, key, &(is_integer(&1) and &1 > 0), :required)

  def required_non_negative_integer(map, key),
    do: typed(map, key, &(is_integer(&1) and &1 >= 0), :required)

  def optional_positive_integer(map, key, default),
    do: typed(map, key, &(is_integer(&1) and &1 > 0), {:optional, default})

  def required_vector(map, key) do
    with {:ok, value} <- required(map, key), do: vector(value, key)
  end

  def vector([x, y, z], _key)
      when is_number(x) and is_number(y) and is_number(z) do
    {:ok, {x * 1.0, y * 1.0, z * 1.0}}
  end

  def vector(_value, key), do: {:error, {:invalid_field, key}}

  def validate_non_negative_vector({x, y, z}, _key) when x >= 0.0 and y >= 0.0 and z >= 0.0,
    do: :ok

  def validate_non_negative_vector(_vector, key), do: {:error, {:invalid_field, key}}

  def required_vector_list(map, key) do
    case Map.fetch(map, key) do
      {:ok, values} when is_list(values) and values != [] ->
        Enum.reduce_while(values, {:ok, []}, fn value, {:ok, vectors} ->
          case vector(value, key) do
            {:ok, vector} -> {:cont, {:ok, vectors ++ [vector]}}
            {:error, reason} -> {:halt, {:error, reason}}
          end
        end)

      {:ok, _value} ->
        {:error, {:invalid_field, key}}

      :error ->
        {:error, {:missing_field, key}}
    end
  end

  def required_atom(map, key) do
    with {:ok, value} <- required(map, key) do
      if is_binary(value), do: {:ok, String.to_atom(value)}, else: {:error, {:invalid_field, key}}
    end
  end

  def optional_atom(map, key, default, allowed) do
    case Map.fetch(map, key) do
      {:ok, value} when is_binary(value) ->
        if value in allowed do
          {:ok, String.to_atom(value)}
        else
          {:error, {:invalid_field, key}}
        end

      {:ok, _value} ->
        {:error, {:invalid_field, key}}

      :error ->
        {:ok, default}
    end
  end

  defp typed(map, key, predicate, missing) do
    case Map.fetch(map, key) do
      {:ok, value} ->
        if predicate.(value), do: {:ok, value}, else: {:error, {:invalid_field, key}}

      :error ->
        case missing do
          :required -> {:error, {:missing_field, key}}
          {:optional, default} -> {:ok, default}
        end
    end
  end

  defp optional_nullable(map, key, predicate) do
    case Map.fetch(map, key) do
      {:ok, nil} ->
        {:ok, nil}

      {:ok, value} ->
        if predicate.(value), do: {:ok, value}, else: {:error, {:invalid_field, key}}

      :error ->
        {:ok, nil}
    end
  end

  defp optional_nullable_map(map, key, nil_default) do
    case Map.fetch(map, key) do
      {:ok, %{} = value} -> {:ok, value}
      {:ok, nil} -> {:ok, nil_default}
      {:ok, _value} -> {:error, {:invalid_field, key}}
      :error -> {:ok, nil_default}
    end
  end
end
