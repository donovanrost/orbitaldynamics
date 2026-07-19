defmodule OrbitalDynamics.TimelineFeedback.ExecutionUncertainty do
  @moduledoc false

  alias OrbitalDynamics.TimelineFeedback.ArtifactValue

  def maneuver_delta_v_context(activity) do
    delta_v = maneuver_delta_v(activity)

    %{
      "delta_v_km_s" => delta_v,
      "delta_v_magnitude_km_s" => vector_norm(delta_v)
    }
    |> compact_map()
  end

  def activity_context(activity) do
    uncertainty = activity_execution_uncertainty(activity)

    cond do
      is_map(uncertainty) ->
        uncertainty
        |> fields()
        |> Map.merge(%{
          "execution_uncertainty_status" => "declared",
          "execution_uncertainty" => uncertainty
        })
        |> compact_map()

      relevant?(activity) ->
        %{"execution_uncertainty_status" => "missing"}

      true ->
        %{}
    end
  end

  def reconciliation_context(planned, realized) do
    planned_context = row_context(planned)
    realized_context = row_context(realized)

    cond do
      declared?(realized_context) -> realized_context
      declared?(planned_context) -> planned_context
      missing?(realized_context) -> realized_context
      missing?(planned_context) -> planned_context
      true -> %{}
    end
  end

  def maneuver_delta_v(activity) do
    first_value(activity, [
      "delta_v_km_s",
      "actual_delta_v_km_s",
      "executed_delta_v_km_s",
      ["metadata", "delta_v_km_s"],
      ["metadata", "actual_delta_v_km_s"],
      ["metadata", "executed_delta_v_km_s"]
    ])
    |> numeric_triplet()
  end

  def numeric_triplet([x, y, z]) do
    triplet = Enum.map([x, y, z], &numeric_value/1)

    if Enum.all?(triplet, &is_number/1), do: triplet, else: nil
  end

  def numeric_triplet(_value), do: nil

  def numeric_value(value) when is_number(value), do: value

  def numeric_value(value) when is_binary(value) do
    case Float.parse(String.trim(value)) do
      {number, ""} -> number
      _other -> nil
    end
  end

  def numeric_value(_value), do: nil

  def vector_norm(nil), do: nil

  def vector_norm([x, y, z]) do
    :math.sqrt(x * x + y * y + z * z)
  end

  def vector_delta([actual_x, actual_y, actual_z], [planned_x, planned_y, planned_z]) do
    [actual_x - planned_x, actual_y - planned_y, actual_z - planned_z]
  end

  def vector_delta(_actual, _planned), do: nil

  defp activity_execution_uncertainty(activity) do
    uncertainty =
      Map.get(activity, "execution_uncertainty") ||
        Map.get(activity, "maneuver_execution_uncertainty") ||
        get_in(activity, ["metadata", "execution_uncertainty"]) ||
        get_in(activity, ["metadata", "maneuver_execution_uncertainty"]) ||
        get_in(activity, ["assumptions", "execution_uncertainty"]) ||
        get_in(activity, ["assumptions", "maneuver_execution_uncertainty"])

    case uncertainty do
      %{} = uncertainty -> normalize(stringify_keys(uncertainty))
      _value -> nil
    end
  end

  defp relevant?(%{"type" => "impulsive_burn"}), do: true
  defp relevant?(_activity), do: false

  defp normalize(%{} = uncertainty) do
    uncertainty
    |> normalize_number("timing_3sigma_s")
    |> normalize_triplet("delta_v_3sigma_km_s")
    |> normalize_number("delta_v_3sigma_magnitude_km_s")
  end

  defp normalize_number(%{} = uncertainty, key) do
    case Map.fetch(uncertainty, key) do
      {:ok, value} ->
        case numeric_value(value) do
          nil -> uncertainty
          number -> Map.put(uncertainty, key, number)
        end

      :error ->
        uncertainty
    end
  end

  defp normalize_triplet(%{} = uncertainty, key) do
    case Map.fetch(uncertainty, key) do
      {:ok, value} ->
        case numeric_triplet(value) do
          nil -> uncertainty
          triplet -> Map.put(uncertainty, key, triplet)
        end

      :error ->
        uncertainty
    end
  end

  defp fields(uncertainty) do
    delta_v_3sigma_km_s = numeric_triplet(Map.get(uncertainty, "delta_v_3sigma_km_s"))

    %{
      "timing_3sigma_s" => numeric_value(Map.get(uncertainty, "timing_3sigma_s")),
      "delta_v_3sigma_km_s" => delta_v_3sigma_km_s,
      "delta_v_3sigma_magnitude_km_s" => vector_norm(delta_v_3sigma_km_s),
      "execution_uncertainty_source" =>
        Map.get(uncertainty, "source") || Map.get(uncertainty, "model")
    }
    |> compact_map()
  end

  defp row_context(nil), do: %{}

  defp row_context(row) do
    %{
      "execution_uncertainty_status" => value(row, "execution_uncertainty_status"),
      "execution_uncertainty" => value(row, "execution_uncertainty"),
      "timing_3sigma_s" => value(row, "timing_3sigma_s"),
      "delta_v_3sigma_km_s" => value(row, "delta_v_3sigma_km_s"),
      "delta_v_3sigma_magnitude_km_s" => value(row, "delta_v_3sigma_magnitude_km_s"),
      "execution_uncertainty_source" => value(row, "execution_uncertainty_source")
    }
    |> compact_map()
  end

  defp declared?(%{"execution_uncertainty_status" => "declared"}), do: true
  defp declared?(_context), do: false

  defp missing?(%{"execution_uncertainty_status" => "missing"}), do: true
  defp missing?(_context), do: false

  defp value(map, key), do: Map.get(map, key)

  defp first_value(map, keys) do
    Enum.reduce_while(keys, nil, fn key, _value ->
      metadata = Map.get(map, "metadata") || Map.get(map, :metadata) || %{}

      case fetch_key_or_atom(map, key) do
        {:ok, nil} -> first_value_from_metadata(metadata, key)
        {:ok, value} -> {:halt, value}
        :error -> first_value_from_metadata(metadata, key)
      end
    end)
  end

  defp first_value_from_metadata(metadata, key) do
    case fetch_key_or_atom(metadata, key) do
      {:ok, nil} -> {:cont, nil}
      {:ok, value} -> {:halt, value}
      :error -> {:cont, nil}
    end
  end

  defp fetch_key_or_atom(map, key) when is_map(map) do
    case Map.fetch(map, key) do
      {:ok, value} -> {:ok, value}
      :error when is_binary(key) -> fetch_existing_atom_key(map, key)
      :error -> :error
    end
  end

  defp fetch_key_or_atom(_map, _key), do: :error

  defp fetch_existing_atom_key(map, key) do
    atom_key = String.to_existing_atom(key)
    Map.fetch(map, atom_key)
  rescue
    ArgumentError -> :error
  end

  defp stringify_keys(value), do: ArtifactValue.stringify_keys(value)

  defp compact_map(map),
    do: ArtifactValue.compact_map(map, :nil_and_empty_lists)
end
