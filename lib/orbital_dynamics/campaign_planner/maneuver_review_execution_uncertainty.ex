defmodule OrbitalDynamics.CampaignPlanner.ManeuverReviewExecutionUncertainty do
  @moduledoc false

  def feedback(rows, opts) when is_list(opts) do
    realized_feedback_activity_id = Keyword.fetch!(opts, :realized_feedback_activity_id)
    operational_feedback_key? = Keyword.fetch!(opts, :operational_feedback_key?)

    rows
    |> Enum.map(fn row ->
      {realized_feedback_activity_id.(row), entry(row)}
    end)
    |> Enum.filter(fn {activity_id, entry} ->
      operational_feedback_key?.(activity_id) and entry != %{}
    end)
    |> Enum.group_by(fn {activity_id, _entry} -> activity_id end, fn {_activity_id, entry} ->
      entry
    end)
    |> Map.new(fn {activity_id, entries} ->
      {activity_id, Enum.max_by(entries, &entry_rank/1)}
    end)
  end

  def entry(row) do
    raw_uncertainty =
      case Map.get(row, "execution_uncertainty") do
        %{} = uncertainty -> stringify_keys(uncertainty)
        _uncertainty -> nil
      end

    delta_v_3sigma_km_s =
      numeric_triplet_or_nil(row["delta_v_3sigma_km_s"]) ||
        numeric_triplet_or_nil(raw_uncertainty && raw_uncertainty["delta_v_3sigma_km_s"])

    entry =
      %{
        "execution_uncertainty_status" =>
          row["execution_uncertainty_status"] ||
            if(is_map(raw_uncertainty), do: "declared"),
        "execution_uncertainty" => raw_uncertainty,
        "timing_3sigma_s" =>
          numeric_or_nil(row["timing_3sigma_s"]) ||
            numeric_or_nil(raw_uncertainty && raw_uncertainty["timing_3sigma_s"]),
        "delta_v_3sigma_km_s" => delta_v_3sigma_km_s,
        "delta_v_3sigma_magnitude_km_s" =>
          numeric_or_nil(row["delta_v_3sigma_magnitude_km_s"]) ||
            numeric_or_nil(raw_uncertainty && raw_uncertainty["delta_v_3sigma_magnitude_km_s"]) ||
            vector_magnitude_or_nil(delta_v_3sigma_km_s),
        "execution_uncertainty_source" =>
          row["execution_uncertainty_source"] ||
            (raw_uncertainty && (raw_uncertainty["source"] || raw_uncertainty["model"]))
      }
      |> compact_map()

    case entry do
      %{"execution_uncertainty_status" => status} when status in ["declared", "missing"] ->
        entry

      _entry ->
        %{}
    end
  end

  def status_count(rows, status) do
    count =
      Enum.count(rows, fn row ->
        row
        |> entry()
        |> Map.get("execution_uncertainty_status")
        |> Kernel.==(status)
      end)

    if count > 0, do: count
  end

  defp entry_rank(entry) do
    {
      if(entry["execution_uncertainty_status"] == "missing", do: 1, else: 0),
      entry["timing_3sigma_s"] || -1.0,
      entry["delta_v_3sigma_magnitude_km_s"] || -1.0,
      entry["execution_uncertainty_source"] || ""
    }
  end

  defp numeric_triplet_or_nil(values) when is_list(values) and length(values) == 3 do
    triplet = Enum.map(values, &numeric_or_nil/1)

    if Enum.all?(triplet, &is_number/1), do: triplet, else: nil
  end

  defp numeric_triplet_or_nil(_values), do: nil

  defp vector_magnitude_or_nil(values) when is_list(values) do
    if Enum.all?(values, &is_number/1) do
      values
      |> Enum.reduce(0.0, fn value, sum -> sum + value * value end)
      |> :math.sqrt()
    end
  end

  defp vector_magnitude_or_nil(_values), do: nil

  defp numeric_or_nil(nil), do: nil
  defp numeric_or_nil(value) when is_integer(value) or is_float(value), do: value

  defp numeric_or_nil(value) when is_binary(value) do
    case Float.parse(value) do
      {number, ""} -> number
      _error -> nil
    end
  end

  defp numeric_or_nil(_value), do: nil

  defp stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp encode_value(%_{} = struct), do: struct |> Map.from_struct() |> encode_value()

  defp encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values) do
    if Keyword.keyword?(values) do
      Map.new(values, fn {key, value} -> {encode_value(key), encode_value(value)} end)
    else
      Enum.map(values, &encode_value/1)
    end
  end

  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
