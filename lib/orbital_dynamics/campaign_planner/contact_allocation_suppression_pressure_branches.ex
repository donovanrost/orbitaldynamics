defmodule OrbitalDynamics.CampaignPlanner.ContactAllocationSuppressionPressureBranches do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ContactFilterPressureBranches,
    ResourceFilterPressureBranches,
    ValueEncoding
  }

  def resource(row, source_path, callbacks \\ default_callbacks())

  def resource(%{"source_resource_suppression" => %{} = source} = row, source_path, callbacks)
      when map_size(source) > 0 do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    trust_boundary = Keyword.fetch!(callbacks, :trust_boundary)
    resource_filter_pressure_branch = Keyword.fetch!(callbacks, :resource_filter_pressure_branch)

    source
    |> stringify_keys.()
    |> resource_suppression_fallbacks(row)
    |> Map.put_new("approval_status", row["approval_status"])
    |> Map.put("_source_report_trust_boundary", trust_boundary.(row))
    |> resource_filter_pressure_branch.("#{source_path}.source_resource_suppression")
  end

  def resource(_row, _source_path, _callbacks), do: []

  def contact(row, source_path, callbacks \\ default_callbacks())

  def contact(%{"source_contact_suppression" => %{} = source} = row, source_path, callbacks)
      when map_size(source) > 0 do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    trust_boundary = Keyword.fetch!(callbacks, :trust_boundary)
    contact_filter_pressure_branch = Keyword.fetch!(callbacks, :contact_filter_pressure_branch)

    source
    |> stringify_keys.()
    |> contact_suppression_fallbacks(row)
    |> Map.put_new("approval_status", row["approval_status"])
    |> Map.put("_source_report_trust_boundary", trust_boundary.(row))
    |> contact_filter_pressure_branch.("#{source_path}.source_contact_suppression")
  end

  def contact(_row, _source_path, _callbacks), do: []

  defp contact_suppression_fallbacks(source, row) do
    source
    |> put_if_absent("id", row["contact_id"])
    |> put_if_absent("contact_id", row["contact_id"])
    |> put_if_absent("activity_id", row["activity_id"])
    |> put_if_absent("type", row["type"])
    |> put_if_absent("activity_type", row["activity_type"])
    |> put_if_absent("direction", row["direction"])
    |> put_if_absent("scenario_id", row["scenario_id"])
    |> put_if_absent("spacecraft_id", row["spacecraft_id"])
    |> put_if_absent("ground_station_id", row["ground_station_id"] || row["station_id"])
    |> put_if_absent("starts_at_s", row["starts_at_s"] || row["start_s"])
    |> put_if_absent("ends_at_s", row["ends_at_s"] || row["end_s"])
    |> put_if_absent("suppressed_reason", row["suppressed_reason"])
    |> put_if_absent("station_reservation_id", row["station_reservation_id"])
    |> put_if_absent("station_reserved_by", row["station_reserved_by"])
    |> put_if_absent("station_reservation_status", row["station_reservation_status"])
    |> put_if_absent(
      "station_reservation_match_status",
      row["station_reservation_match_status"]
    )
    |> put_if_absent("station_calendar_entry_status", row["station_calendar_entry_status"])
    |> put_if_absent("station_calendar_entry_id", row["station_calendar_entry_id"])
    |> put_if_absent("required_downlink_mb", row["required_downlink_mb"])
    |> put_if_absent("estimated_throughput_mb", row["estimated_throughput_mb"])
    |> put_if_absent("planned_throughput_mb", row["planned_throughput_mb"])
    |> put_if_absent("throughput_model", row["throughput_model"])
    |> put_if_absent("activity_context", row["activity_context"])
    |> put_if_absent("source_window_id", row["source_window_id"])
    |> put_if_absent("source_window", row["source_window"])
  end

  defp resource_suppression_fallbacks(source, row) do
    source
    |> put_if_absent("id", row["contact_id"])
    |> put_if_absent("contact_id", row["contact_id"])
    |> put_if_absent("activity_id", row["activity_id"])
    |> put_if_absent("type", row["type"])
    |> put_if_absent("activity_type", row["activity_type"])
    |> put_if_absent("direction", row["direction"])
    |> put_if_absent("scenario_id", row["scenario_id"])
    |> put_if_absent("spacecraft_id", row["spacecraft_id"])
    |> put_if_absent("ground_station_id", row["ground_station_id"] || row["station_id"])
    |> put_if_absent("starts_at_s", row["starts_at_s"] || row["start_s"])
    |> put_if_absent("ends_at_s", row["ends_at_s"] || row["end_s"])
    |> put_if_absent("suppressed_reason", row["suppressed_reason"])
    |> put_if_absent("resource_source_quality", row["resource_source_quality"])
    |> put_if_absent("resource_trust_boundary", row["resource_trust_boundary"])
    |> put_if_absent("resource_trust_boundary_status", row["resource_trust_boundary_status"])
    |> put_if_absent("fuel_margin", row["fuel_margin"])
    |> put_if_absent("power_margin", row["power_margin"])
    |> put_if_absent("storage_margin", row["storage_margin"])
    |> put_if_absent("downlink_margin", row["downlink_margin"])
    |> put_if_absent("thermal_margin_c", row["thermal_margin_c"])
    |> put_if_absent("spacecraft_available", row["spacecraft_available"])
    |> put_if_absent("payload_available", row["payload_available"])
    |> put_if_absent("antenna_available", row["antenna_available"])
    |> put_if_absent("source_resource_summary", row["source_resource_summary"])
  end

  defp put_if_absent(map, _key, value) when value in [nil, "", [], %{}], do: map

  defp put_if_absent(map, key, value) do
    case Map.get(map, key) do
      existing when existing in [nil, "", [], %{}] -> Map.put(map, key, value)
      _existing -> map
    end
  end

  defp default_callbacks do
    [
      contact_filter_pressure_branch: &ContactFilterPressureBranches.build/2,
      resource_filter_pressure_branch: &ResourceFilterPressureBranches.build/2,
      stringify_keys: &ValueEncoding.stringify_keys/1,
      trust_boundary: &trust_boundary/1
    ]
  end

  defp trust_boundary(row) do
    Map.get(row, "trust_boundary") ||
      Map.get(row, "resource_trust_boundary") ||
      get_in(row, ["provenance", "trust_boundary"]) ||
      get_in(row, ["source_resource_suppression", "resource_trust_boundary"]) ||
      get_in(row, ["source_resource_suppression", "resource_provenance", "trust_boundary"]) ||
      row["_source_report_trust_boundary"]
  end
end
