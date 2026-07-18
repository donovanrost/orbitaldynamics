defmodule OrbitalDynamics.CadenceImport.ResourceProjectionManifestRow do
  @moduledoc false

  def build(row, rank, callbacks) when is_list(callbacks) do
    approval_status = Map.get(row, "approval_status", "operator_review_required")

    %{
      "id" => "cadence_import:resource_projection:#{row["id"] || rank}",
      "rank" => rank,
      "import_action" => "review_resource_projection",
      "import_status" => adapter_import_status(callbacks, "present", approval_status),
      "import_side" => "source",
      "source_review_row_id" => row["id"],
      "source_review_type" => row["review_type"],
      "source_review_action" => source_review_action(callbacks, row),
      "subject_id" => row["subject_id"],
      "activity_id" => row["activity_id"],
      "activity_ids" => row["activity_ids"],
      "activity_type" => row["activity_type"],
      "branch_id" => row["branch_id"],
      "spacecraft_id" => row["spacecraft_id"],
      "scenario_id" => row["scenario_id"],
      "starts_at_s" => row["starts_at_s"],
      "ends_at_s" => row["ends_at_s"],
      "approval_status" => approval_status,
      "required_operator_action" => row["required_operator_action"],
      "reason" => row["reason"],
      "invalid_activity_input" => row["invalid_activity_input"],
      "invalid_activity_input_reason" => row["invalid_activity_input_reason"],
      "invalid_resource_summary_input" => row["invalid_resource_summary_input"],
      "invalid_resource_summary_input_reason" => row["invalid_resource_summary_input_reason"],
      "duplicate_resource_summary_scope" => row["duplicate_resource_summary_scope"],
      "mixed_wildcard_resource_summary_scope" => row["mixed_wildcard_resource_summary_scope"],
      "resource_summary_key" => row["resource_summary_key"],
      "duplicate_resource_summary_index" => row["duplicate_resource_summary_index"],
      "duplicate_resource_summary_count" => row["duplicate_resource_summary_count"],
      "activity_count" => row["activity_count"],
      "effective_activity_count" => row["effective_activity_count"],
      "ignored_activity_count" => row["ignored_activity_count"],
      "ignored_activity_ids" => row["ignored_activity_ids"],
      "observation_count" => row["observation_count"],
      "downlink_count" => row["downlink_count"],
      "storage_limited_downlinked_mb" => row["storage_limited_downlinked_mb"],
      "unused_downlink_capacity_mb" => row["unused_downlink_capacity_mb"],
      "projected_storage_margin" => row["projected_storage_margin"],
      "projected_storage_remaining_mb" => row["projected_storage_remaining_mb"],
      "projected_downlink_margin" => row["projected_downlink_margin"],
      "projected_downlink_remaining_mb" => row["projected_downlink_remaining_mb"],
      "projected_storage_overflow_mb" => row["projected_storage_overflow_mb"],
      "projected_downlink_shortfall_mb" => row["projected_downlink_shortfall_mb"],
      "projected_power_margin" => row["projected_power_margin"],
      "projected_battery_energy_used_wh" => row["projected_battery_energy_used_wh"],
      "projected_battery_state_of_charge" => row["projected_battery_state_of_charge"],
      "projected_battery_overuse_wh" => row["projected_battery_overuse_wh"],
      "resource_pressure_status" => row["resource_pressure_status"],
      "resource_pressure_types" => row["resource_pressure_types"],
      "resource_flow_count" => row["resource_flow_count"],
      "total_battery_energy_consumed_wh" => row["total_battery_energy_consumed_wh"],
      "total_battery_energy_generated_wh" => row["total_battery_energy_generated_wh"],
      "net_battery_energy_delta_wh" => row["net_battery_energy_delta_wh"],
      "peak_storage_overflow_mb" => row["peak_storage_overflow_mb"],
      "peak_downlink_shortfall_mb" => row["peak_downlink_shortfall_mb"],
      "peak_battery_overuse_wh" => row["peak_battery_overuse_wh"],
      "peak_unused_downlink_capacity_mb" => row["peak_unused_downlink_capacity_mb"],
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
      "first_resource_pressure_capacity_fraction" =>
        row["first_resource_pressure_capacity_fraction"],
      "first_resource_pressure_source_window_id" =>
        row["first_resource_pressure_source_window_id"],
      "first_resource_pressure_source_window_type" =>
        row["first_resource_pressure_source_window_type"],
      "first_resource_pressure_source_window" => row["first_resource_pressure_source_window"],
      "source_window_id" =>
        row["source_window_id"] || row["first_resource_pressure_source_window_id"],
      "source_window_type" =>
        row["source_window_type"] || row["first_resource_pressure_source_window_type"],
      "source_window" => row["source_window"] || row["first_resource_pressure_source_window"],
      "resource_source_quality" => row["resource_source_quality"],
      "resource_trust_boundary" => row["resource_trust_boundary"],
      "resource_trust_boundary_status" => row["resource_trust_boundary_status"],
      "resource_provenance" => row["resource_provenance"],
      "fuel_margin" => row["fuel_margin"],
      "power_margin" => row["power_margin"],
      "thermal_margin_c" => row["thermal_margin_c"],
      "spacecraft_available" => row["spacecraft_available"],
      "payload_available" => row["payload_available"],
      "antenna_available" => row["antenna_available"],
      "degraded" => row["degraded"],
      "mode" => row["mode"],
      "incompatible_activity_types" => row["incompatible_activity_types"],
      "suppressed_activity_types" => row["suppressed_activity_types"],
      "warnings" => row["warnings"],
      "requirement_type" => row["requirement_type"],
      "required_authority" => row["required_authority"],
      "policy_bundle_id" => row["policy_bundle_id"],
      "rule_id" => row["rule_id"],
      "escalation_level" => row["escalation_level"],
      "escalation_queue" => row["escalation_queue"],
      "escalation_role" => row["escalation_role"],
      "sla_s" => row["sla_s"],
      "approval_requirements" => row["approval_requirements"],
      "approval_rule_matches" => row["approval_rule_matches"],
      "cadence_import_status" => "present",
      "has_cadence_import" => false,
      "source_activity" => row["source_activity"],
      "source_resource_summary" => row["source_resource_summary"],
      "source_resource_projection" => row["source_resource_projection"],
      "source_resource_projection_flow_summary" => row["source_resource_projection_flow_summary"],
      "source_policy_decision" => row["source_policy_decision"],
      "source_policy_escalation" => row["source_policy_escalation"],
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
