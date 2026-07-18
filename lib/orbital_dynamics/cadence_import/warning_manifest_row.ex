defmodule OrbitalDynamics.CadenceImport.WarningManifestRow do
  @moduledoc false

  def build(row, rank, callbacks) when is_list(callbacks) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")
    import_status = Map.get(row, "cadence_import_status", "present")

    %{
      "id" => "cadence_import:warning:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => "review_warning",
      "import_status" => adapter_import_status(callbacks, import_status, approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(callbacks, row),
      "source" => row["source"],
      "subject_id" => row["subject_id"],
      "branch_id" => row["branch_id"],
      "scenario_id" => row["scenario_id"],
      "activity_id" => row["activity_id"] || row["first_resource_pressure_activity_id"],
      "activity_type" => row["activity_type"] || row["first_resource_pressure_activity_type"],
      "ground_station_id" =>
        row["ground_station_id"] || row["first_resource_pressure_ground_station_id"],
      "spacecraft_id" => row["spacecraft_id"],
      "target_id" => row["target_id"],
      "direction" => row["direction"] || row["first_resource_pressure_direction"],
      "station_calendar_entry_id" =>
        row["station_calendar_entry_id"] ||
          row["first_resource_pressure_station_calendar_entry_id"],
      "station_calendar_provider_id" =>
        row["station_calendar_provider_id"] ||
          row["first_resource_pressure_station_calendar_provider_id"],
      "station_calendar_provider_entry_id" =>
        row["station_calendar_provider_entry_id"] ||
          row["first_resource_pressure_station_calendar_provider_entry_id"],
      "station_calendar_directions" =>
        row["station_calendar_directions"] ||
          row["first_resource_pressure_station_calendar_directions"],
      "first_resource_pressure_activity_id" => row["first_resource_pressure_activity_id"],
      "first_resource_pressure_activity_type" => row["first_resource_pressure_activity_type"],
      "first_resource_pressure_kind" => row["first_resource_pressure_kind"],
      "first_resource_pressure_starts_at_s" => row["first_resource_pressure_starts_at_s"],
      "first_resource_pressure_direction" => row["first_resource_pressure_direction"],
      "first_resource_pressure_ground_station_id" =>
        row["first_resource_pressure_ground_station_id"],
      "first_resource_pressure_station_calendar_entry_id" =>
        row["first_resource_pressure_station_calendar_entry_id"],
      "first_resource_pressure_station_calendar_provider_id" =>
        row["first_resource_pressure_station_calendar_provider_id"],
      "first_resource_pressure_station_calendar_provider_entry_id" =>
        row["first_resource_pressure_station_calendar_provider_entry_id"],
      "first_resource_pressure_station_calendar_directions" =>
        row["first_resource_pressure_station_calendar_directions"],
      "approval_status" => approval_status,
      "required_operator_action" => row["required_operator_action"],
      "reason" => row["reason"],
      "severity" => row["severity"],
      "operational_feedback_trust_boundary_status" =>
        row["operational_feedback_trust_boundary_status"],
      "operational_feedback_trust_boundary" => row["operational_feedback_trust_boundary"],
      "operational_feedback_trust_boundaries" => row["operational_feedback_trust_boundaries"],
      "operational_feedback_field_trust_boundaries" =>
        row["operational_feedback_field_trust_boundaries"],
      "operational_feedback_input_keys" => row["operational_feedback_input_keys"],
      "source_operational_feedback" => row["source_operational_feedback"],
      "source_operational_feedback_provenance" => row["source_operational_feedback_provenance"],
      "cadence_import_status" => import_status,
      "has_cadence_import" => false,
      "source_review_row" => row
    }
    |> compact_map(callbacks)
  end

  defp source_review_action(callbacks, row),
    do: invoke(callbacks, :source_review_action, [row])

  defp adapter_import_status(callbacks, status, approval_status),
    do: invoke(callbacks, :adapter_import_status, [status, approval_status])

  defp compact_map(value, callbacks), do: invoke(callbacks, :compact_map, [value])

  defp invoke(callbacks, name, args), do: apply(Keyword.fetch!(callbacks, name), args)
end
