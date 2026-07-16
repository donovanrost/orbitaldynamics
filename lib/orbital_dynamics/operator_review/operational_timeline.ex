defmodule OrbitalDynamics.OperatorReview.OperationalTimeline do
  @moduledoc false

  alias OrbitalDynamics.OperatorReview.Capabilities
  alias OrbitalDynamics.OperatorReview.PackageBuilder

  @provider_result_fields ~w(contact_result command_result observation_result maneuver_result)
  @provider_result_map_value_keys ~w(result results outcome outcomes status state disposition provider_result provider_results provider_outcome provider_outcomes provider_status provider_state provider_code code reason reasons message messages error errors details metadata provider diagnostics)
  @schema_contract "operator_review_package.v1"

  def report_package(report) do
    {rows, source_artifact_id, provenance} = report_package_input(report)

    build_package(rows, "operational_timeline_report.v1", source_artifact_id, provenance)
  end

  def planned_activity_package(activity) do
    {rows, source_artifact_id, provenance} = planned_activity_package_input(activity)

    build_package(rows, "planned_activity.v1", source_artifact_id, provenance)
  end

  def report_package_input(report) do
    report = stringify_keys(report || %{})

    {
      rows(Map.get(report, "rows", [])),
      Map.get(report, "id") || Map.get(report, "source") || "operational_timeline_report",
      Map.get(report, "provenance", %{})
    }
  end

  def planned_activity_package_input(activity) do
    activity = stringify_keys(activity || %{})

    report =
      OrbitalDynamics.Timeline.operational_report([activity],
        source: "planned_activity",
        source_assumption: "standalone planned_activity.v1 row"
      )

    {
      rows(Map.get(report, "rows", []), "planned_activity"),
      Map.get(activity, "id") || Map.get(activity, "activity_id") || "planned_activity",
      Map.get(activity, "provenance", %{})
    }
  end

  def candidate_refresh_rows(artifact) do
    artifact = stringify_keys(artifact)

    direct_rows =
      [
        {"candidate_refresh.source_operational_timeline_report",
         artifact["source_operational_timeline_report"]},
        {"candidate_refresh.operational_timeline_report", artifact["operational_timeline_report"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_report_rows(report_or_reports, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_rows(artifact)
  end

  def source_report_rows(reports, source) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_report_rows(report, "#{source}[#{index}]")
    end)
  end

  def source_report_rows(%{} = report, source) do
    report
    |> stringify_keys()
    |> Map.get("rows", [])
    |> rows("#{source}.rows")
  end

  def source_report_rows(_report, _source), do: []

  def strategy_rows(branches) do
    branches
    |> Enum.map(&stringify_keys/1)
    |> Enum.flat_map(fn branch ->
      branch_id = Map.get(branch, "branch_id")

      branch
      |> get_in(["repair_result", "operational_timeline_report", "rows"])
      |> List.wrap()
      |> rows("campaign_strategy.branches.repair_result.operational_timeline_report.rows")
      |> Enum.map(fn row ->
        row
        |> Map.put("branch_id", branch_id)
        |> Map.update("id", nil, &review_id(["strategy", branch_id, &1]))
      end)
    end)
  end

  defp candidate_refresh_result_artifact_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_rows(
         %{"schema_contract" => "operational_timeline_report.v1"} = report,
         source
       ) do
    source_report_rows(report, source)
  end

  defp result_artifact_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_operational_timeline_report",
       artifact["source_operational_timeline_report"]},
      {"#{source}.operational_timeline_report", artifact["operational_timeline_report"]}
    ]
    |> Enum.flat_map(fn {report_source, report_or_reports} ->
      source_report_rows(report_or_reports, report_source)
    end)
  end

  defp result_artifact_rows(_artifact, _source), do: []

  defp first_map(values) when is_list(values) do
    Enum.find(values, %{}, &is_map/1)
  end

  defp first_map(_values), do: %{}

  defp preferred_approval_rule_match(%{} = row) do
    preferred_classification =
      row["approval_status"] || get_in(row, ["policy_decision", "classification"])

    preferred_approval_rule_match(row["approval_rule_matches"], preferred_classification)
  end

  defp preferred_approval_rule_match(rule_matches, preferred_classification)
       when is_list(rule_matches) do
    rule_matches =
      rule_matches
      |> Enum.filter(&is_map/1)
      |> Enum.map(&stringify_keys/1)

    Enum.find(rule_matches, &(&1["classification"] == preferred_classification)) ||
      List.first(rule_matches) ||
      %{}
  end

  defp preferred_approval_rule_match(_rule_matches, _preferred_classification), do: %{}

  defp matched_policy_escalation(row) do
    preferred_rule_id =
      row
      |> preferred_approval_rule_match()
      |> Map.get("rule_id")

    rule_ids =
      row
      |> Map.get("approval_rule_matches", [])
      |> List.wrap()
      |> Enum.map(&Map.get(&1, "rule_id"))
      |> Enum.reject(&is_nil/1)

    escalations =
      row
      |> get_in(["policy_decision", "escalations"])
      |> List.wrap()
      |> Enum.filter(&is_map/1)

    escalation =
      Enum.find(escalations, &(Map.get(&1, "rule_id") == preferred_rule_id)) ||
        Enum.find(escalations, &(Map.get(&1, "rule_id") in rule_ids)) ||
        List.first(escalations) ||
        row
        |> Map.get("approval_rule_matches", [])
        |> List.wrap()
        |> Enum.find(&policy_escalation_context?/1)

    escalation || %{}
  end

  defp policy_escalation_context?(%{} = row) do
    Enum.any?(
      ["escalation_level", "escalation_queue", "escalation_role", "required_authority", "sla_s"],
      &Map.has_key?(row, &1)
    )
  end

  defp policy_escalation_context?(_row), do: false

  defp non_empty_map(%{} = map) when map_size(map) > 0, do: map
  defp non_empty_map(_map), do: nil

  def rows(rows, source \\ "operational_timeline_report.rows") do
    rows
    |> Enum.map(&stringify_keys/1)
    |> Enum.reject(&(&1["required_operator_action"] in no_operational_timeline_review_actions()))
    |> Enum.with_index(1)
    |> Enum.map(fn {row, index} ->
      row = sanitize_row_activity_context_cadence_import(row)
      requirement = row["approval_requirements"] |> first_map() |> stringify_keys()
      rule_match = row["approval_rule_matches"] |> first_map() |> stringify_keys()
      policy_decision = stringify_keys(row["policy_decision"] || %{})
      policy_escalation = row |> matched_policy_escalation() |> stringify_keys()

      %{
        "id" =>
          review_id(["operational_timeline", row["timeline_id"], row["activity_id"], index]),
        "review_type" => "operational_timeline_review",
        "source" => source,
        "subject_id" => row["timeline_id"] || row["activity_id"],
        "activity_id" => row["activity_id"],
        "timeline_id" => row["timeline_id"],
        "scenario_id" => row["scenario_id"],
        "activity_type" => row["activity_type"],
        "operational_kind" => row["operational_kind"],
        "direction" => row["direction"],
        "spacecraft_id" => row["spacecraft_id"],
        "ground_station_id" => row["ground_station_id"],
        "target_id" => row["target_id"],
        "resource_id" => row["resource_id"],
        "collection_id" => row["collection_id"],
        "product_id" => row["product_id"],
        "product_ids" => row["product_ids"],
        "payload_id" => row["payload_id"],
        "instrument_id" => row["instrument_id"],
        "pointing_mode" => row_or_context_value(row, "pointing_mode"),
        "pointing_target_id" => row_or_context_value(row, "pointing_target_id"),
        "boresight_axis" => row_or_context_value(row, "boresight_axis"),
        "off_nadir_angle_deg" => row_or_context_value(row, "off_nadir_angle_deg"),
        "slew_angle_deg" => row_or_context_value(row, "slew_angle_deg"),
        "slew_rate_deg_s" => row_or_context_value(row, "slew_rate_deg_s"),
        "pointing_error_deg" => row_or_context_value(row, "pointing_error_deg"),
        "pointing_status" => row_or_context_value(row, "pointing_status"),
        "pointing_model" => row_or_context_value(row, "pointing_model"),
        "pointing_source" => row_or_context_value(row, "pointing_source"),
        "pointing_confidence" => row_or_context_value(row, "pointing_confidence"),
        "attitude_mode" => row_or_context_value(row, "attitude_mode"),
        "attitude_target_id" => row_or_context_value(row, "attitude_target_id"),
        "roll_deg" => row_or_context_value(row, "roll_deg"),
        "pitch_deg" => row_or_context_value(row, "pitch_deg"),
        "yaw_deg" => row_or_context_value(row, "yaw_deg"),
        "attitude_error_deg" => row_or_context_value(row, "attitude_error_deg"),
        "attitude_status" => row_or_context_value(row, "attitude_status"),
        "attitude_model" => row_or_context_value(row, "attitude_model"),
        "attitude_source" => row_or_context_value(row, "attitude_source"),
        "attitude_confidence" => row_or_context_value(row, "attitude_confidence"),
        "starts_at_s" => row["starts_at_s"],
        "ends_at_s" => row["ends_at_s"],
        "setup_duration_s" => row_or_context_value(row, "setup_duration_s"),
        "cooldown_duration_s" => row_or_context_value(row, "cooldown_duration_s"),
        "telemetry_confirmation_required" =>
          row_or_context_value(row, "telemetry_confirmation_required"),
        "telemetry_confirmation_status" =>
          row_or_context_value(row, "telemetry_confirmation_status"),
        "status" => row["status"],
        "approval_status" => operational_timeline_approval_status(row),
        "source_approval_status" => row["approval_status"],
        "locked" => row["locked"],
        "action" => row["required_operator_action"],
        "required_operator_action" => row["required_operator_action"],
        "reason" => row["operator_action_reason"] || "operational timeline row requires review",
        "operator_action_reason" => row["operator_action_reason"],
        "precondition_status" => row["precondition_status"],
        "blocked_precondition_count" => row["blocked_precondition_count"],
        "review_precondition_count" => row["review_precondition_count"],
        "blocked_precondition_types" => row["blocked_precondition_types"],
        "review_precondition_types" => row["review_precondition_types"],
        "preconditions" => row["preconditions"],
        "execution_boundary" => row["execution_boundary"],
        "cadence_import_status" => row["cadence_import_status"],
        "cadence_import_type" => row["cadence_import_type"],
        "cadence_import_id" => row["cadence_import_id"],
        "cadence_import_contract" => row["cadence_import_contract"],
        "cadence_import_provider" =>
          row_or_cadence_import_value(row, "cadence_import_provider", "provider"),
        "cadence_import_adapter" =>
          row_or_cadence_import_value(row, "cadence_import_adapter", "adapter"),
        "cadence_import_adapter_version" =>
          row_or_cadence_import_value(row, "cadence_import_adapter_version", "adapter_version"),
        "cadence_import_trust_boundary" =>
          row_or_cadence_import_value(row, "cadence_import_trust_boundary", "trust_boundary") ||
            row_or_cadence_import_value(row, "cadence_import_trust_boundary", [
              "provenance",
              "trust_boundary"
            ]),
        "cadence_import_provenance" =>
          row_or_cadence_import_value(row, "cadence_import_provenance", "provenance"),
        "invalid_cadence_import" => row["invalid_cadence_import"],
        "invalid_cadence_import_reason" => row["invalid_cadence_import_reason"],
        "source_cadence_import" => row["source_cadence_import"],
        "source_cadence_import_status" => row["source_cadence_import_status"],
        "replacement_cadence_import_status" => row["replacement_cadence_import_status"],
        "execution_uncertainty_status" => row["execution_uncertainty_status"],
        "execution_uncertainty" => row["execution_uncertainty"],
        "timing_3sigma_s" => row["timing_3sigma_s"],
        "delta_v_3sigma_km_s" => row["delta_v_3sigma_km_s"],
        "delta_v_3sigma_magnitude_km_s" => row["delta_v_3sigma_magnitude_km_s"],
        "execution_uncertainty_source" => row["execution_uncertainty_source"],
        "link_protocol" => row_or_context_value(row, "link_protocol"),
        "frequency_band" => row_or_context_value(row, "frequency_band"),
        "modulation" => row_or_context_value(row, "modulation"),
        "coding_scheme" => row_or_context_value(row, "coding_scheme"),
        "polarization" => row_or_context_value(row, "polarization"),
        "data_rate_mbps" => row_or_context_value(row, "data_rate_mbps"),
        "downlink_rate_mbps" => row_or_context_value(row, "downlink_rate_mbps"),
        "data_rate_mb_s" => row_or_context_value(row, "data_rate_mb_s"),
        "downlink_rate_mb_s" => row_or_context_value(row, "downlink_rate_mb_s"),
        "actual_data_rate_mbps" => row_or_context_value(row, "actual_data_rate_mbps"),
        "actual_downlink_rate_mbps" => row_or_context_value(row, "actual_downlink_rate_mbps"),
        "actual_data_rate_mb_s" => row_or_context_value(row, "actual_data_rate_mb_s"),
        "actual_downlink_rate_mb_s" => row_or_context_value(row, "actual_downlink_rate_mb_s"),
        "delivered_rate_mbps" => row_or_context_value(row, "delivered_rate_mbps"),
        "received_rate_mbps" => row_or_context_value(row, "received_rate_mbps"),
        "delivered_rate_mb_s" => row_or_context_value(row, "delivered_rate_mb_s"),
        "received_rate_mb_s" => row_or_context_value(row, "received_rate_mb_s"),
        "actual_duration_s" => row_or_context_value(row, "actual_duration_s"),
        "actual_contact_duration_s" => row_or_context_value(row, "actual_contact_duration_s"),
        "contact_duration_s" => row_or_context_value(row, "contact_duration_s"),
        "link_margin_db" => row_or_context_value(row, "link_margin_db"),
        "snr_db" => row_or_context_value(row, "snr_db"),
        "eb_no_db" => row_or_context_value(row, "eb_no_db"),
        "bit_error_rate" => row_or_context_value(row, "bit_error_rate"),
        "packet_loss_rate" => row_or_context_value(row, "packet_loss_rate"),
        "frame_loss_rate" => row_or_context_value(row, "frame_loss_rate"),
        "carrier_lock" => row_or_context_value(row, "carrier_lock"),
        "symbol_lock" => row_or_context_value(row, "symbol_lock"),
        "link_quality_status" => row_or_context_value(row, "link_quality_status"),
        "eclipse_overlap_fraction" => row_or_context_value(row, "eclipse_overlap_fraction"),
        "planned_eclipse_overlap_fraction" => row["planned_eclipse_overlap_fraction"],
        "realized_eclipse_overlap_fraction" => row["realized_eclipse_overlap_fraction"],
        "eclipse_overlap_s" => row_or_context_value(row, "eclipse_overlap_s"),
        "planned_eclipse_overlap_s" => row["planned_eclipse_overlap_s"],
        "realized_eclipse_overlap_s" => row["realized_eclipse_overlap_s"],
        "lighting_condition" => row_or_context_value(row, "lighting_condition"),
        "planned_lighting_condition" => row["planned_lighting_condition"],
        "realized_lighting_condition" => row["realized_lighting_condition"],
        "lighting_condition_match_status" => row["lighting_condition_match_status"],
        "lighting_condition_detail" => row_or_context_value(row, "lighting_condition_detail"),
        "lighting_condition_model" => row_or_context_value(row, "lighting_condition_model"),
        "lighting_detail_model" => row_or_context_value(row, "lighting_detail_model"),
        "lighting_confidence" => row_or_context_value(row, "lighting_confidence"),
        "planned_estimated_throughput_mb" => row["planned_estimated_throughput_mb"],
        "actual_throughput_mb" => row["actual_throughput_mb"],
        "actual_data_rate_throughput_derivation" =>
          row_or_context_value(row, "actual_data_rate_throughput_derivation"),
        "throughput_delta_mb" => row["throughput_delta_mb"],
        "throughput_completion_fraction" => row["throughput_completion_fraction"],
        "data_volume_mb" => row["data_volume_mb"],
        "planned_data_volume_mb" => row["planned_data_volume_mb"],
        "actual_data_volume_mb" => row["actual_data_volume_mb"],
        "data_volume_delta_mb" => row["data_volume_delta_mb"],
        "data_volume_completion_fraction" => row["data_volume_completion_fraction"],
        "estimated_data_volume_mb" => row["estimated_data_volume_mb"],
        "estimated_storage_mb" => row["estimated_storage_mb"],
        "estimated_downlink_mb" => row["estimated_downlink_mb"],
        "required_downlink_mb" => row["required_downlink_mb"],
        "collection_ends_at_s" => row["collection_ends_at_s"],
        "planned_delivery_at_s" => row["planned_delivery_at_s"],
        "actual_delivery_at_s" => row["actual_delivery_at_s"],
        "max_latency_s" => row["max_latency_s"],
        "planned_latency_s" => row["planned_latency_s"],
        "actual_latency_s" => row["actual_latency_s"],
        "latency_delta_s" => row["latency_delta_s"],
        "latency_margin_s" => row["latency_margin_s"],
        "resource_source_quality" => row_or_context_value(row, "resource_source_quality"),
        "resource_trust_boundary" => row_or_context_value(row, "resource_trust_boundary"),
        "resource_trust_boundary_status" =>
          row_or_context_value(row, "resource_trust_boundary_status"),
        "resource_provenance" => row_or_context_value(row, "resource_provenance"),
        "resource_blocking_dimension" => row_or_context_value(row, "resource_blocking_dimension"),
        "fuel_margin" => row_or_context_value(row, "fuel_margin"),
        "thermal_zone_id" => row_or_context_value(row, "thermal_zone_id"),
        "temperature_c" => row_or_context_value(row, "temperature_c"),
        "planned_temperature_c" => row_or_context_value(row, "planned_temperature_c"),
        "actual_temperature_c" => row_or_context_value(row, "actual_temperature_c"),
        "temperature_delta_c" => row_or_context_value(row, "temperature_delta_c"),
        "min_operating_temperature_c" => row_or_context_value(row, "min_operating_temperature_c"),
        "max_operating_temperature_c" => row_or_context_value(row, "max_operating_temperature_c"),
        "thermal_margin_c" => row_or_context_value(row, "thermal_margin_c"),
        "thermal_status" => row_or_context_value(row, "thermal_status"),
        "thermal_model" => row_or_context_value(row, "thermal_model"),
        "thermal_source" => row_or_context_value(row, "thermal_source"),
        "thermal_confidence" => row_or_context_value(row, "thermal_confidence"),
        "power_margin" => row_or_context_value(row, "power_margin"),
        "storage_margin" => row_or_context_value(row, "storage_margin"),
        "downlink_margin" => row_or_context_value(row, "downlink_margin"),
        "battery_capacity_wh" => row_or_context_value(row, "battery_capacity_wh"),
        "battery_energy_used_wh" => row_or_context_value(row, "battery_energy_used_wh"),
        "battery_energy_generated_wh" => row_or_context_value(row, "battery_energy_generated_wh"),
        "battery_state_of_charge" => row_or_context_value(row, "battery_state_of_charge"),
        "spacecraft_available" => row_or_context_value(row, "spacecraft_available"),
        "payload_available" => row_or_context_value(row, "payload_available"),
        "antenna_available" => row_or_context_value(row, "antenna_available"),
        "degraded" => row_or_context_value(row, "degraded"),
        "mode" => row_or_context_value(row, "mode"),
        "incompatible_activity_types" => row_or_context_value(row, "incompatible_activity_types"),
        "suppressed_activity_types" => row_or_context_value(row, "suppressed_activity_types"),
        "score" => row_or_context_value(row, "score"),
        "score_terms" => row_or_context_value(row, "score_terms"),
        "target_priority" => row_or_context_value(row, "target_priority"),
        "target_priority_source" => row_or_context_value(row, "target_priority_source"),
        "target_priority_objective_ids" =>
          row_or_context_value(row, "target_priority_objective_ids"),
        "target_priority_objective_type" =>
          row_or_context_value(row, "target_priority_objective_type"),
        "image_quality_score" => row_or_context_value(row, "image_quality_score"),
        "image_quality_status" => row_or_context_value(row, "image_quality_status"),
        "image_quality_source" => row_or_context_value(row, "image_quality_source"),
        "cloud_cover_fraction" => row_or_context_value(row, "cloud_cover_fraction"),
        "blur_score" => row_or_context_value(row, "blur_score"),
        "contact_success" => row_or_context_value(row, "contact_success"),
        "contact_success_factor" => row_or_context_value(row, "contact_success_factor"),
        "contact_success_factor_source" =>
          row_or_context_value(row, "contact_success_factor_source"),
        "command_success" => row_or_context_value(row, "command_success"),
        "contact_result" => row_or_context_provider_result_value(row, "contact_result"),
        "command_result" => row_or_context_provider_result_value(row, "command_result"),
        "command_authority_status" => row_or_context_value(row, "command_authority_status"),
        "command_safety_status" => row_or_context_value(row, "command_safety_status"),
        "command_authorized" => row_or_context_value(row, "command_authorized"),
        "command_safety_checked" => row_or_context_value(row, "command_safety_checked"),
        "command_success_factor" => row_or_context_value(row, "command_success_factor"),
        "command_success_factor_source" =>
          row_or_context_value(row, "command_success_factor_source"),
        "observation_success" => row_or_context_value(row, "observation_success"),
        "observation_result" => row_or_context_provider_result_value(row, "observation_result"),
        "observation_success_factor" => row_or_context_value(row, "observation_success_factor"),
        "observation_success_factor_source" =>
          row_or_context_value(row, "observation_success_factor_source"),
        "feedback_weight" => row_or_context_value(row, "feedback_weight"),
        "feedback_weight_source" => row_or_context_value(row, "feedback_weight_source"),
        "maneuver_success" => row_or_context_value(row, "maneuver_success"),
        "maneuver_result" => row_or_context_provider_result_value(row, "maneuver_result"),
        "maneuver_success_factor" => row_or_context_value(row, "maneuver_success_factor"),
        "maneuver_success_factor_source" =>
          row_or_context_value(row, "maneuver_success_factor_source"),
        "source_window_id" => row["source_window_id"],
        "source_window_type" => row["source_window_type"],
        "station_availability" => row_or_context_value(row, "station_availability"),
        "station_contention_status" => row_or_context_value(row, "station_contention_status"),
        "station_calendar_entry_id" => row_or_context_value(row, "station_calendar_entry_id"),
        "station_calendar_status" => row_or_context_value(row, "station_calendar_status"),
        "station_calendar_overlap_count" =>
          row_or_context_value(row, "station_calendar_overlap_count"),
        "station_calendar_overlap_entry_ids" =>
          row_or_context_value(row, "station_calendar_overlap_entry_ids"),
        "station_calendar_overlap_availabilities" =>
          row_or_context_value(row, "station_calendar_overlap_availabilities"),
        "station_calendar_entry_ambiguous" =>
          row_or_context_value(row, "station_calendar_entry_ambiguous"),
        "station_calendar_ambiguous_entry_count" =>
          row_or_context_value(row, "station_calendar_ambiguous_entry_count"),
        "station_calendar_ambiguous_entry_ids" =>
          row_or_context_value(row, "station_calendar_ambiguous_entry_ids"),
        "station_calendar_reservation_overlap_count" =>
          row_or_context_value(row, "station_calendar_reservation_overlap_count"),
        "station_calendar_reservation_ids" =>
          row_or_context_value(row, "station_calendar_reservation_ids"),
        "station_calendar_reserved_by" =>
          row_or_context_value(row, "station_calendar_reserved_by"),
        "station_calendar_reservation_statuses" =>
          row_or_context_value(row, "station_calendar_reservation_statuses"),
        "station_calendar_reservation_expires_at_s" =>
          row_or_context_value(row, "station_calendar_reservation_expires_at_s"),
        "station_calendar_trust_boundary_status" =>
          row_or_context_value(row, "station_calendar_trust_boundary_status"),
        "trust_boundary" => row_or_context_value(row, "trust_boundary"),
        "provenance" => row_or_context_value(row, "provenance"),
        "station_reservation_id" => row_or_context_value(row, "station_reservation_id"),
        "station_reservation_expires_at_s" =>
          row_or_context_value(row, "station_reservation_expires_at_s"),
        "station_reserved_by" => row_or_context_value(row, "station_reserved_by"),
        "station_reservation_status" => row_or_context_value(row, "station_reservation_status"),
        "station_reservation_match_status" =>
          row_or_context_value(row, "station_reservation_match_status"),
        "schedule_conflict_status" => row["schedule_conflict_status"],
        "exclusivity_group" => row["exclusivity_group"],
        "timeline_integrity_status" => row["timeline_integrity_status"],
        "timeline_integrity_issue_count" => row["timeline_integrity_issue_count"],
        "timeline_integrity_issue_types" => row["timeline_integrity_issue_types"],
        "timeline_integrity_issues" => row["timeline_integrity_issues"],
        "missing_dependency_activity_ids" => row["missing_dependency_activity_ids"],
        "missing_dependency_timeline_ids" => row["missing_dependency_timeline_ids"],
        "self_dependency_activity_ids" => row["self_dependency_activity_ids"],
        "self_dependency_timeline_ids" => row["self_dependency_timeline_ids"],
        "dependency_cycle_activity_ids" => row["dependency_cycle_activity_ids"],
        "dependency_cycle_timeline_ids" => row["dependency_cycle_timeline_ids"],
        "dependency_order_violation_activity_ids" =>
          row["dependency_order_violation_activity_ids"],
        "dependency_order_violation_timeline_ids" =>
          row["dependency_order_violation_timeline_ids"],
        "exclusivity_violation_activity_ids" => row["exclusivity_violation_activity_ids"],
        "exclusivity_violation_timeline_ids" => row["exclusivity_violation_timeline_ids"],
        "exclusivity_violation_group" => row["exclusivity_violation_group"],
        "timeline_identity_collision" => row["timeline_identity_collision"],
        "duplicate_timeline_identity_activity_count" =>
          row["duplicate_timeline_identity_activity_count"],
        "duplicate_timeline_identity_activity_ids" =>
          row["duplicate_timeline_identity_activity_ids"],
        "duplicate_timeline_identity_activities" => row["duplicate_timeline_identity_activities"],
        "superseded_required_operator_action" => row["superseded_required_operator_action"],
        "superseded_operator_action_reason" => row["superseded_operator_action_reason"],
        "requirement_type" => requirement["requirement_type"],
        "required_authority" =>
          row_or_context_value(row, "required_authority") || requirement["required_authority"] ||
            rule_match["required_authority"] || policy_escalation["required_authority"],
        "policy_bundle_id" =>
          requirement["policy_bundle_id"] || policy_decision["policy_bundle_id"],
        "rule_id" =>
          requirement["rule_id"] || rule_match["rule_id"] || policy_escalation["rule_id"],
        "escalation_level" =>
          rule_match["escalation_level"] || policy_escalation["escalation_level"],
        "escalation_queue" =>
          rule_match["escalation_queue"] || policy_escalation["escalation_queue"],
        "escalation_role" =>
          rule_match["escalation_role"] || policy_escalation["escalation_role"],
        "sla_s" => rule_match["sla_s"] || policy_escalation["sla_s"],
        "approval_requirements" => row["approval_requirements"],
        "approval_rule_matches" => row["approval_rule_matches"],
        "source_policy_decision" => row["policy_decision"],
        "source_policy_escalation" => non_empty_map(policy_escalation),
        "invalid_activity_input" => row["invalid_activity_input"],
        "invalid_activity_input_reason" => row["invalid_activity_input_reason"],
        "source_activity" => row["source_activity"],
        "dependency_activity_ids" => Map.get(row, "dependency_activity_ids", []),
        "dependency_timeline_ids" => Map.get(row, "dependency_timeline_ids", []),
        "exclusive_with_activity_ids" => Map.get(row, "exclusive_with_activity_ids", []),
        "exclusive_with_timeline_ids" => Map.get(row, "exclusive_with_timeline_ids", []),
        "has_source_window" => row["has_source_window"],
        "has_cadence_import" => row["has_cadence_import"],
        "timeline_identity" => row["timeline_identity"],
        "source_activity_context" =>
          normalize_provider_result_artifact_fields(row["activity_context"]),
        "source_station_calendar_entry" =>
          row_or_context_value(row, "source_station_calendar_entry"),
        "source_station_calendar_overlaps" =>
          row_or_context_value(row, "source_station_calendar_overlaps"),
        "source_operational_timeline" => row
      }
      |> compact_map()
    end)
  end

  defp no_operational_timeline_review_actions,
    do: ["monitor_activity", "none_locked_activity", "none_terminal_activity"]

  defp row_or_context_value(row, field) do
    case Map.fetch(row, field) do
      {:ok, nil} -> get_in(row, ["activity_context", field])
      {:ok, value} -> value
      :error -> get_in(row, ["activity_context", field])
    end
  end

  defp row_or_context_provider_result_value(row, field) do
    row
    |> row_or_context_value(field)
    |> provider_result_artifact_value()
  end

  defp normalize_provider_result_artifact_fields(%{} = map) do
    Enum.reduce(@provider_result_fields, map, fn field, acc ->
      case Map.fetch(acc, field) do
        {:ok, value} ->
          case provider_result_artifact_value(value) do
            nil -> Map.delete(acc, field)
            normalized -> Map.put(acc, field, normalized)
          end

        :error ->
          acc
      end
    end)
  end

  defp normalize_provider_result_artifact_fields(value), do: value

  defp provider_result_values(result) when is_binary(result) do
    result
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp provider_result_values(values) when is_list(values) do
    Enum.flat_map(values, &provider_result_values/1)
  end

  defp provider_result_values(%{} = result) do
    Enum.flat_map(@provider_result_map_value_keys, fn key ->
      result
      |> Map.get(key)
      |> provider_result_values()
    end)
  end

  defp provider_result_values(nil), do: []

  defp provider_result_values(result) when is_atom(result) do
    result
    |> Atom.to_string()
    |> provider_result_values()
  end

  defp provider_result_values(result)
       when is_integer(result) or is_float(result) or is_boolean(result) do
    result
    |> to_string()
    |> provider_result_values()
  end

  defp provider_result_values(_result), do: []

  defp provider_result_artifact_value(nil), do: nil

  defp provider_result_artifact_value(result) when is_binary(result) do
    case String.trim(result) do
      "" -> nil
      _value -> result
    end
  end

  defp provider_result_artifact_value(results) when is_list(results) do
    case provider_result_values(results) do
      [] -> nil
      values -> Enum.join(values, ",")
    end
  end

  defp provider_result_artifact_value(%{} = result) do
    case provider_result_values(result) do
      [] -> nil
      values -> Enum.join(values, ",")
    end
  end

  defp provider_result_artifact_value(result) when is_integer(result),
    do: Integer.to_string(result)

  defp provider_result_artifact_value(result) when is_float(result), do: Float.to_string(result)
  defp provider_result_artifact_value(result) when is_boolean(result), do: Atom.to_string(result)

  defp provider_result_artifact_value(result) when is_atom(result) do
    result
    |> Atom.to_string()
    |> provider_result_artifact_value()
  end

  defp provider_result_artifact_value(_result), do: nil

  defp row_or_cadence_import_value(row, field, cadence_import_path) do
    case Map.fetch(row, field) do
      {:ok, value} ->
        value

      :error ->
        path = List.wrap(cadence_import_path)

        case row_activity_context_cadence_import(row) do
          %{} = cadence_import -> get_in(cadence_import, path)
          _cadence_import -> nil
        end
    end
  end

  defp sanitize_row_activity_context_cadence_import(
         %{"activity_context" => %{"cadence_import" => cadence_import} = context} = row
       )
       when not is_map(cadence_import) do
    source_cadence_import = %{"invalid_import_shape" => stringify_keys(cadence_import)}

    sanitized_context =
      context
      |> Map.delete("cadence_import")
      |> Map.put("invalid_cadence_import", true)
      |> Map.put("invalid_cadence_import_reason", "cadence_import_must_be_object")
      |> Map.put("source_cadence_import", source_cadence_import)

    row
    |> Map.put("activity_context", sanitized_context)
    |> Map.put("cadence_import_status", row["cadence_import_status"] || "invalid")
    |> Map.put("invalid_cadence_import", true)
    |> Map.put("invalid_cadence_import_reason", "cadence_import_must_be_object")
    |> Map.put("source_cadence_import", source_cadence_import)
  end

  defp sanitize_row_activity_context_cadence_import(row), do: row

  defp row_activity_context_cadence_import(%{"activity_context" => %{} = context}),
    do: Map.get(context, "cadence_import")

  defp row_activity_context_cadence_import(_row), do: nil

  defp operational_timeline_approval_status(%{"required_operator_action" => action})
       when action in [
              "review_command_contact",
              "review_activity_approval",
              "resolve_rejected_activity",
              "resolve_contact_conflict",
              "review_terminal_activity_exception"
            ],
       do: "operator_review_required"

  defp operational_timeline_approval_status(row),
    do: Map.get(row, "approval_status", "operator_review_required")

  defp review_id(parts) do
    parts
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&encode_value/1)
    |> Enum.join(":")
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp encode_value(nil), do: nil
  defp encode_value(:null), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp build_package(rows, source_artifact_type, source_artifact_id, provenance) do
    PackageBuilder.build(
      rows,
      source_artifact_type,
      source_artifact_id,
      provenance,
      @schema_contract,
      Capabilities.model_limits()
    )
  end
end
