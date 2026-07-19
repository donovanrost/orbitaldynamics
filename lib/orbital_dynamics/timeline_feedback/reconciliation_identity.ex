defmodule OrbitalDynamics.TimelineFeedback.ReconciliationIdentity do
  @moduledoc false

  @compared_fields [
    {"direction", "direction"},
    {"ground_station", "ground_station_id"},
    {"target", "target_id"},
    {"resource", "resource_id"},
    {"collection", "collection_id"},
    {"product", "product_id"},
    {"product_ids", "product_ids"},
    {"payload", "payload_id"},
    {"instrument", "instrument_id"},
    {"pointing_target", "pointing_target_id"},
    {"pointing_mode", "pointing_mode"},
    {"attitude_target", "attitude_target_id"},
    {"attitude_mode", "attitude_mode"},
    {"link_protocol", "link_protocol"},
    {"frequency_band", "frequency_band"},
    {"modulation", "modulation"},
    {"coding_scheme", "coding_scheme"},
    {"polarization", "polarization"},
    {"source_window", "source_window_id"}
  ]

  @mismatch_fields [
    {"direction", "direction_match_status"},
    {"ground_station", "ground_station_match_status"},
    {"target", "target_match_status"},
    {"resource", "resource_match_status"},
    {"collection", "collection_match_status"},
    {"product", "product_match_status"},
    {"product_ids", "product_ids_match_status"},
    {"payload", "payload_match_status"},
    {"instrument", "instrument_match_status"},
    {"pointing_target", "pointing_target_match_status"},
    {"link_protocol", "link_protocol_match_status"},
    {"frequency_band", "frequency_band_match_status"},
    {"modulation", "modulation_match_status"},
    {"coding_scheme", "coding_scheme_match_status"},
    {"polarization", "polarization_match_status"},
    {"source_window", "source_window_match_status"}
  ]

  def context(planned, realized) do
    @compared_fields
    |> Enum.reduce(
      %{
        "spacecraft_id" => value(planned, "spacecraft_id") || value(realized, "spacecraft_id"),
        "source_window_type" => value(planned, "source_window_type")
      },
      fn {identity, field}, context ->
        planned_value = value(planned, field)
        realized_value = value(realized, field)

        context
        |> Map.put(field, planned_value || realized_value)
        |> Map.put("planned_#{field}", planned_value)
        |> Map.put("realized_#{field}", realized_value)
        |> Map.put("#{identity}_match_status", match_status(planned_value, realized_value))
      end
    )
  end

  def put_mismatch_summary(row) do
    mismatch_fields =
      @mismatch_fields
      |> Enum.filter(fn {_field, status_field} -> row[status_field] == "mismatch" end)
      |> Enum.map(fn {field, _status_field} -> field end)

    if mismatch_fields == [] do
      row
    else
      row
      |> Map.put("identity_mismatch_fields", mismatch_fields)
      |> Map.put("identity_mismatch_count", length(mismatch_fields))
      |> Map.put("identity_match_status", "mismatch")
    end
  end

  defp value(nil, _key), do: nil
  defp value(map, key), do: Map.get(map, key)

  defp match_status(planned, realized)
       when planned in [nil, "", []] and realized in [nil, "", []],
       do: nil

  defp match_status(planned, _realized) when planned in [nil, "", []], do: "realized_only"
  defp match_status(_planned, realized) when realized in [nil, "", []], do: "planned_only"
  defp match_status(value, value), do: "matched"
  defp match_status(_planned, _realized), do: "mismatch"
end
