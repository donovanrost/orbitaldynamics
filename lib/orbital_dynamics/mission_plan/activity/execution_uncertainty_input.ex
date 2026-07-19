defmodule OrbitalDynamics.MissionPlan.Activity.ExecutionUncertaintyInput do
  @moduledoc false

  def optional!(nil), do: nil

  def optional!(%{} = uncertainty) do
    uncertainty
    |> normalize_number_field(:timing_3sigma_s)
    |> normalize_number_field("timing_3sigma_s")
    |> normalize_triplet_field(:delta_v_3sigma_km_s)
    |> normalize_triplet_field("delta_v_3sigma_km_s")
    |> normalize_number_field(:delta_v_3sigma_magnitude_km_s)
    |> normalize_number_field("delta_v_3sigma_magnitude_km_s")
  end

  def optional!(_value), do: raise(ArgumentError, "map fields must be maps")

  def delta_v!([x, y, z]), do: numeric_triplet!([x, y, z])
  def delta_v!({x, y, z}), do: numeric_triplet!([x, y, z])

  def delta_v!(_value),
    do: raise(ArgumentError, "delta_v_km_s must be a numeric {x, y, z} tuple")

  def numeric_or_nil(value) when is_integer(value) or is_float(value), do: value * 1.0

  def numeric_or_nil(value) when is_binary(value) do
    case Float.parse(String.trim(value)) do
      {number, ""} -> number
      _other -> nil
    end
  end

  def numeric_or_nil(_value), do: nil

  defp numeric_triplet!(values) do
    triplet = Enum.map(values, &numeric_or_nil/1)

    if Enum.all?(triplet, &is_number/1) do
      List.to_tuple(triplet)
    else
      delta_v!(:invalid_triplet)
    end
  end

  defp normalize_triplet_field(%{} = map, key) do
    case Map.fetch(map, key) do
      {:ok, values} ->
        case numeric_triplet_or_nil(values) do
          nil -> map
          triplet -> Map.put(map, key, triplet)
        end

      :error ->
        map
    end
  end

  defp numeric_triplet_or_nil(values) when is_list(values) and length(values) == 3 do
    triplet = Enum.map(values, &numeric_or_nil/1)

    if Enum.all?(triplet, &is_number/1), do: triplet
  end

  defp numeric_triplet_or_nil(_values), do: nil

  defp normalize_number_field(%{} = map, key) do
    case Map.fetch(map, key) do
      {:ok, value} ->
        case numeric_or_nil(value) do
          nil -> map
          number -> Map.put(map, key, number)
        end

      :error ->
        map
    end
  end
end
