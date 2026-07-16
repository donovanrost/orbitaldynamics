defmodule OrbitalDynamics.OperatorReview.TimelineFeedback do
  @moduledoc false

  alias OrbitalDynamics.OperatorReview.Capabilities
  alias OrbitalDynamics.OperatorReview.PackageBuilder

  @feedback_exception_statuses ~w(missed failed canceled cancelled rejected)
  @feedback_variance_statuses ~w(partial delayed)
  @feedback_completion_statuses ~w(completed executed)
  @provider_result_map_value_keys ~w(result results outcome outcomes status state disposition provider_result provider_results provider_outcome provider_outcomes provider_status provider_state provider_code code reason reasons message messages error errors details metadata provider diagnostics)
  @schema_contract "operator_review_package.v1"

  def package(report) do
    {rows, source_artifact_id, provenance} = package_input(report)

    build_package(rows, "timeline_feedback_report.v1", source_artifact_id, provenance)
  end

  def package_input(report) do
    report = stringify_keys(report || %{})

    {
      rows(Map.get(report, "rows", [])),
      Map.get(report, "id") || "timeline_feedback_report",
      Map.get(report, "provenance", %{})
    }
  end

  def candidate_refresh_rows(artifact) do
    artifact = stringify_keys(artifact)

    direct_rows =
      [
        {"candidate_refresh.source_timeline_feedback_report",
         artifact["source_timeline_feedback_report"]},
        {"candidate_refresh.timeline_feedback_report", artifact["timeline_feedback_report"]}
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
    |> realized_timeline_feedback_rows()
    |> rows("#{source}.rows")
  end

  def source_report_rows(_report, _source), do: []

  def repair_rows(artifact, source) do
    artifact
    |> get_in(["source_timeline_feedback_report", "rows"])
    |> realized_timeline_feedback_rows()
    |> rows(source)
  end

  def strategy_rows(branches) do
    branches
    |> Enum.map(&stringify_keys/1)
    |> Enum.flat_map(fn branch ->
      branch_id = Map.get(branch, "branch_id")

      branch
      |> get_in(["repair_result", "source_timeline_feedback_report", "rows"])
      |> realized_timeline_feedback_rows()
      |> rows("campaign_strategy.branches.repair_result.source_timeline_feedback_report.rows")
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
         %{"schema_contract" => "timeline_feedback_report.v1"} = report,
         source
       ) do
    source_report_rows(report, source)
  end

  defp result_artifact_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_timeline_feedback_report", artifact["source_timeline_feedback_report"]},
      {"#{source}.timeline_feedback_report", artifact["timeline_feedback_report"]}
    ]
    |> Enum.flat_map(fn {report_source, report_or_reports} ->
      source_report_rows(report_or_reports, report_source)
    end)
  end

  defp result_artifact_rows(_artifact, _source), do: []

  def rows(rows, source \\ "timeline_feedback_report.rows") do
    rows
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {row, index} ->
      {action, approval_status, reason} = feedback_review_decision(row)

      %{
        "id" => review_id(["realized_feedback", row["activity_id"], index]),
        "review_type" => "realized_feedback",
        "source" => source,
        "subject_id" => row["activity_id"],
        "activity_id" => row["activity_id"],
        "activity_type" => row["planned_type"] || row["realized_type"],
        "action" => action,
        "required_operator_action" => action,
        "approval_status" => approval_status,
        "reason" => reason,
        "feedback_status" => row["status"],
        "operational_feedback_excluded" => row["operational_feedback_excluded"],
        "operational_feedback_status" => row["operational_feedback_status"],
        "operational_feedback_exclusion_reason" => row["operational_feedback_exclusion_reason"],
        "match_strategy" => row["match_strategy"],
        "ambiguous_planned_timeline_id" => row["ambiguous_planned_timeline_id"],
        "ambiguous_planned_match_count" => row["ambiguous_planned_match_count"],
        "ambiguous_planned_activity_ids" => row["ambiguous_planned_activity_ids"],
        "ambiguous_planned_activities" => row["ambiguous_planned_activities"],
        "feedback_kind" => row["feedback_kind"],
        "realized_match_count" => row["realized_match_count"],
        "realized_activity_ids" => row["realized_activity_ids"],
        "realized_statuses" => row["realized_statuses"],
        "realized_match_strategies" => row["realized_match_strategies"],
        "realized_activities" => row["realized_activities"],
        "planned_timeline_id" => row["planned_timeline_id"],
        "timeline_identity" => row["timeline_identity"],
        "realized_timeline_id" => row["realized_timeline_id"],
        "realized_activity_id" => row["realized_activity_id"],
        "realized_source" => row["realized_source"],
        "realized_provider" => row["realized_provider"],
        "realized_source_quality" => row["realized_source_quality"],
        "realized_adapter" => row["realized_adapter"],
        "realized_adapter_version" => row["realized_adapter_version"],
        "realized_external_id" => row["realized_external_id"],
        "realized_schema_contract" => row["realized_schema_contract"],
        "realized_trust_boundary" => row["realized_trust_boundary"],
        "realized_received_at" => row["realized_received_at"],
        "realized_ingested_at" => row["realized_ingested_at"],
        "realized_provenance" => row["realized_provenance"],
        "planned_activity" => row["planned_activity"],
        "realized_activity" => row["realized_activity"],
        "invalid_realized_feedback_input" => row["invalid_realized_feedback_input"],
        "invalid_realized_feedback_input_reason" => row["invalid_realized_feedback_input_reason"],
        "invalid_realized_feedback_sections" => row["invalid_realized_feedback_sections"],
        "unsupported_realized_status" => row["unsupported_realized_status"],
        "invalid_cadence_import" => row["invalid_cadence_import"],
        "invalid_cadence_import_reason" => row["invalid_cadence_import_reason"],
        "source_cadence_import" => row["source_cadence_import"],
        "source_activity_context" => row["source_activity_context"],
        "realized_activity_context" => row["realized_activity_context"],
        "planned_status" => row["planned_status"],
        "realized_status" => row["realized_status"],
        "status_transition" => row["status_transition"],
        "planned_protection_decision" => row["planned_protection_decision"],
        "planned_protection_category" => row["planned_protection_category"],
        "planned_protection_reason" => row["planned_protection_reason"],
        "source_protection_decision" => row["source_protection_decision"],
        "realized_type" => row["realized_type"],
        "direction" => row["direction"],
        "planned_direction" => row["planned_direction"],
        "realized_direction" => row["realized_direction"],
        "direction_match_status" => row["direction_match_status"],
        "ground_station_id" => row["ground_station_id"],
        "planned_ground_station_id" => row["planned_ground_station_id"],
        "realized_ground_station_id" => row["realized_ground_station_id"],
        "ground_station_match_status" => row["ground_station_match_status"],
        "spacecraft_id" => row["spacecraft_id"],
        "target_id" => row["target_id"],
        "planned_target_id" => row["planned_target_id"],
        "realized_target_id" => row["realized_target_id"],
        "target_match_status" => row["target_match_status"],
        "resource_id" => row["resource_id"],
        "planned_resource_id" => row["planned_resource_id"],
        "realized_resource_id" => row["realized_resource_id"],
        "resource_match_status" => row["resource_match_status"],
        "identity_match_status" => row["identity_match_status"],
        "identity_mismatch_fields" => row["identity_mismatch_fields"],
        "identity_mismatch_count" => row["identity_mismatch_count"],
        "collection_id" => row["collection_id"],
        "planned_collection_id" => row["planned_collection_id"],
        "realized_collection_id" => row["realized_collection_id"],
        "collection_match_status" => row["collection_match_status"],
        "product_id" => row["product_id"],
        "planned_product_id" => row["planned_product_id"],
        "realized_product_id" => row["realized_product_id"],
        "product_match_status" => row["product_match_status"],
        "product_ids" => row["product_ids"],
        "planned_product_ids" => row["planned_product_ids"],
        "realized_product_ids" => row["realized_product_ids"],
        "product_ids_match_status" => row["product_ids_match_status"],
        "payload_id" => row["payload_id"],
        "planned_payload_id" => row["planned_payload_id"],
        "realized_payload_id" => row["realized_payload_id"],
        "payload_match_status" => row["payload_match_status"],
        "instrument_id" => row["instrument_id"],
        "planned_instrument_id" => row["planned_instrument_id"],
        "realized_instrument_id" => row["realized_instrument_id"],
        "instrument_match_status" => row["instrument_match_status"],
        "pointing_target_id" => row["pointing_target_id"],
        "planned_pointing_target_id" => row["planned_pointing_target_id"],
        "realized_pointing_target_id" => row["realized_pointing_target_id"],
        "pointing_target_match_status" => row["pointing_target_match_status"],
        "pointing_mode" => row["pointing_mode"],
        "planned_pointing_mode" => row["planned_pointing_mode"],
        "realized_pointing_mode" => row["realized_pointing_mode"],
        "pointing_mode_match_status" => row["pointing_mode_match_status"],
        "boresight_axis" => row["boresight_axis"],
        "planned_off_nadir_angle_deg" => row["planned_off_nadir_angle_deg"],
        "realized_off_nadir_angle_deg" => row["realized_off_nadir_angle_deg"],
        "off_nadir_angle_delta_deg" => row["off_nadir_angle_delta_deg"],
        "planned_slew_angle_deg" => row["planned_slew_angle_deg"],
        "realized_slew_angle_deg" => row["realized_slew_angle_deg"],
        "slew_angle_delta_deg" => row["slew_angle_delta_deg"],
        "pointing_error_deg" => row["pointing_error_deg"],
        "pointing_status" => row["pointing_status"],
        "pointing_model" => row["pointing_model"],
        "pointing_source" => row["pointing_source"],
        "pointing_confidence" => row["pointing_confidence"],
        "attitude_target_id" => row["attitude_target_id"],
        "planned_attitude_target_id" => row["planned_attitude_target_id"],
        "realized_attitude_target_id" => row["realized_attitude_target_id"],
        "attitude_target_match_status" => row["attitude_target_match_status"],
        "attitude_mode" => row["attitude_mode"],
        "planned_attitude_mode" => row["planned_attitude_mode"],
        "realized_attitude_mode" => row["realized_attitude_mode"],
        "attitude_mode_match_status" => row["attitude_mode_match_status"],
        "planned_roll_deg" => row["planned_roll_deg"],
        "realized_roll_deg" => row["realized_roll_deg"],
        "roll_delta_deg" => row["roll_delta_deg"],
        "planned_pitch_deg" => row["planned_pitch_deg"],
        "realized_pitch_deg" => row["realized_pitch_deg"],
        "pitch_delta_deg" => row["pitch_delta_deg"],
        "planned_yaw_deg" => row["planned_yaw_deg"],
        "realized_yaw_deg" => row["realized_yaw_deg"],
        "yaw_delta_deg" => row["yaw_delta_deg"],
        "attitude_error_deg" => row["attitude_error_deg"],
        "attitude_status" => row["attitude_status"],
        "attitude_model" => row["attitude_model"],
        "attitude_source" => row["attitude_source"],
        "attitude_confidence" => row["attitude_confidence"],
        "link_protocol" => row["link_protocol"],
        "planned_link_protocol" => row["planned_link_protocol"],
        "realized_link_protocol" => row["realized_link_protocol"],
        "link_protocol_match_status" => row["link_protocol_match_status"],
        "frequency_band" => row["frequency_band"],
        "planned_frequency_band" => row["planned_frequency_band"],
        "realized_frequency_band" => row["realized_frequency_band"],
        "frequency_band_match_status" => row["frequency_band_match_status"],
        "modulation" => row["modulation"],
        "planned_modulation" => row["planned_modulation"],
        "realized_modulation" => row["realized_modulation"],
        "modulation_match_status" => row["modulation_match_status"],
        "coding_scheme" => row["coding_scheme"],
        "planned_coding_scheme" => row["planned_coding_scheme"],
        "realized_coding_scheme" => row["realized_coding_scheme"],
        "coding_scheme_match_status" => row["coding_scheme_match_status"],
        "polarization" => row["polarization"],
        "planned_polarization" => row["planned_polarization"],
        "realized_polarization" => row["realized_polarization"],
        "polarization_match_status" => row["polarization_match_status"],
        "data_rate_mbps" => row["data_rate_mbps"],
        "planned_data_rate_mbps" => row["planned_data_rate_mbps"],
        "realized_data_rate_mbps" => row["realized_data_rate_mbps"],
        "data_rate_delta_mbps" => row["data_rate_delta_mbps"],
        "link_margin_db" => row["link_margin_db"],
        "planned_link_margin_db" => row["planned_link_margin_db"],
        "realized_link_margin_db" => row["realized_link_margin_db"],
        "link_margin_delta_db" => row["link_margin_delta_db"],
        "snr_db" => row["snr_db"],
        "planned_snr_db" => row["planned_snr_db"],
        "realized_snr_db" => row["realized_snr_db"],
        "snr_delta_db" => row["snr_delta_db"],
        "eb_no_db" => row["eb_no_db"],
        "planned_eb_no_db" => row["planned_eb_no_db"],
        "realized_eb_no_db" => row["realized_eb_no_db"],
        "eb_no_delta_db" => row["eb_no_delta_db"],
        "bit_error_rate" => row["bit_error_rate"],
        "planned_bit_error_rate" => row["planned_bit_error_rate"],
        "realized_bit_error_rate" => row["realized_bit_error_rate"],
        "packet_loss_rate" => row["packet_loss_rate"],
        "planned_packet_loss_rate" => row["planned_packet_loss_rate"],
        "realized_packet_loss_rate" => row["realized_packet_loss_rate"],
        "frame_loss_rate" => row["frame_loss_rate"],
        "planned_frame_loss_rate" => row["planned_frame_loss_rate"],
        "realized_frame_loss_rate" => row["realized_frame_loss_rate"],
        "carrier_lock" => row["carrier_lock"],
        "planned_carrier_lock" => row["planned_carrier_lock"],
        "realized_carrier_lock" => row["realized_carrier_lock"],
        "symbol_lock" => row["symbol_lock"],
        "planned_symbol_lock" => row["planned_symbol_lock"],
        "realized_symbol_lock" => row["realized_symbol_lock"],
        "link_quality_status" => row["link_quality_status"],
        "planned_link_quality_status" => row["planned_link_quality_status"],
        "realized_link_quality_status" => row["realized_link_quality_status"],
        "eclipse_overlap_fraction" => row["eclipse_overlap_fraction"],
        "planned_eclipse_overlap_fraction" => row["planned_eclipse_overlap_fraction"],
        "realized_eclipse_overlap_fraction" => row["realized_eclipse_overlap_fraction"],
        "eclipse_overlap_s" => row["eclipse_overlap_s"],
        "planned_eclipse_overlap_s" => row["planned_eclipse_overlap_s"],
        "realized_eclipse_overlap_s" => row["realized_eclipse_overlap_s"],
        "lighting_condition" => row["lighting_condition"],
        "planned_lighting_condition" => row["planned_lighting_condition"],
        "realized_lighting_condition" => row["realized_lighting_condition"],
        "lighting_condition_match_status" => row["lighting_condition_match_status"],
        "lighting_condition_detail" => row["lighting_condition_detail"],
        "lighting_condition_model" => row["lighting_condition_model"],
        "lighting_detail_model" => row["lighting_detail_model"],
        "lighting_confidence" => row["lighting_confidence"],
        "image_quality_score" => row["image_quality_score"],
        "planned_image_quality_score" => row["planned_image_quality_score"],
        "realized_image_quality_score" => row["realized_image_quality_score"],
        "image_quality_score_delta" => row["image_quality_score_delta"],
        "image_quality_status" => row["image_quality_status"],
        "planned_image_quality_status" => row["planned_image_quality_status"],
        "realized_image_quality_status" => row["realized_image_quality_status"],
        "image_quality_status_match_status" => row["image_quality_status_match_status"],
        "image_quality_source" => row["image_quality_source"],
        "cloud_cover_fraction" => row["cloud_cover_fraction"],
        "planned_cloud_cover_fraction" => row["planned_cloud_cover_fraction"],
        "realized_cloud_cover_fraction" => row["realized_cloud_cover_fraction"],
        "cloud_cover_fraction_delta" => row["cloud_cover_fraction_delta"],
        "blur_score" => row["blur_score"],
        "planned_blur_score" => row["planned_blur_score"],
        "realized_blur_score" => row["realized_blur_score"],
        "blur_score_delta" => row["blur_score_delta"],
        "source_window_id" => row["source_window_id"],
        "planned_source_window_id" => row["planned_source_window_id"],
        "realized_source_window_id" => row["realized_source_window_id"],
        "source_window_match_status" => row["source_window_match_status"],
        "source_window_type" => row["source_window_type"],
        "dependency_activity_ids" => row["dependency_activity_ids"],
        "dependency_timeline_ids" => row["dependency_timeline_ids"],
        "exclusive_with_activity_ids" => row["exclusive_with_activity_ids"],
        "exclusive_with_timeline_ids" => row["exclusive_with_timeline_ids"],
        "cadence_import_status" => row["cadence_import_status"],
        "cadence_import_type" => row["cadence_import_type"],
        "cadence_import_id" => row["cadence_import_id"],
        "cadence_import_contract" => row["cadence_import_contract"],
        "has_cadence_import" => row["has_cadence_import"],
        "planned_operator_action" => row["planned_operator_action"],
        "planned_operator_action_reason" => row["planned_operator_action_reason"],
        "superseded_planned_operator_action" => row["superseded_planned_operator_action"],
        "superseded_planned_operator_action_reason" =>
          row["superseded_planned_operator_action_reason"],
        "timeline_integrity_status" => row["timeline_integrity_status"],
        "timeline_integrity_issue_count" => row["timeline_integrity_issue_count"],
        "timeline_integrity_issue_types" => row["timeline_integrity_issue_types"],
        "timeline_integrity_issues" => row["timeline_integrity_issues"],
        "invalid_activity_input" => row["invalid_activity_input"],
        "invalid_activity_input_reason" => row["invalid_activity_input_reason"],
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
        "planned_starts_at_s" => row["planned_starts_at_s"],
        "planned_ends_at_s" => row["planned_ends_at_s"],
        "actual_starts_at_s" => row["actual_starts_at_s"],
        "actual_ends_at_s" => row["actual_ends_at_s"],
        "start_delta_s" => row["start_delta_s"],
        "end_delta_s" => row["end_delta_s"],
        "max_timing_delta_s" => row["max_timing_delta_s"],
        "timing_variance_threshold_s" => row["timing_variance_threshold_s"],
        "timing_variance_status" => row["timing_variance_status"],
        "planned_estimated_throughput_mb" => row["planned_estimated_throughput_mb"],
        "actual_throughput_mb" => row["actual_throughput_mb"],
        "actual_data_rate_throughput_derivation" => row["actual_data_rate_throughput_derivation"],
        "throughput_delta_mb" => row["throughput_delta_mb"],
        "throughput_completion_fraction" => row["throughput_completion_fraction"],
        "planned_data_volume_mb" => row["planned_data_volume_mb"],
        "actual_data_volume_mb" => row["actual_data_volume_mb"],
        "data_volume_delta_mb" => row["data_volume_delta_mb"],
        "data_volume_completion_fraction" => row["data_volume_completion_fraction"],
        "required_downlink_mb" => row["required_downlink_mb"],
        "collection_ends_at_s" => row["collection_ends_at_s"],
        "planned_delivery_at_s" => row["planned_delivery_at_s"],
        "actual_delivery_at_s" => row["actual_delivery_at_s"],
        "max_latency_s" => row["max_latency_s"],
        "planned_latency_s" => row["planned_latency_s"],
        "actual_latency_s" => row["actual_latency_s"],
        "latency_delta_s" => row["latency_delta_s"],
        "latency_margin_s" => row["latency_margin_s"],
        "planned_delta_v_km_s" => row["planned_delta_v_km_s"],
        "realized_delta_v_km_s" => row["realized_delta_v_km_s"],
        "delta_v_delta_km_s" => row["delta_v_delta_km_s"],
        "planned_delta_v_magnitude_km_s" => row["planned_delta_v_magnitude_km_s"],
        "realized_delta_v_magnitude_km_s" => row["realized_delta_v_magnitude_km_s"],
        "delta_v_magnitude_delta_km_s" => row["delta_v_magnitude_delta_km_s"],
        "delta_v_match_status" => row["delta_v_match_status"],
        "contact_success" => row["contact_success"],
        "contact_success_factor" => row["contact_success_factor"],
        "contact_success_factor_source" => row["contact_success_factor_source"],
        "command_success" => row["command_success"],
        "command_success_factor" => row["command_success_factor"],
        "command_success_factor_source" => row["command_success_factor_source"],
        "command_authority_status" => row["command_authority_status"],
        "planned_command_authority_status" => row["planned_command_authority_status"],
        "realized_command_authority_status" => row["realized_command_authority_status"],
        "command_authority_status_match_status" => row["command_authority_status_match_status"],
        "required_authority" => row["required_authority"],
        "planned_required_authority" => row["planned_required_authority"],
        "realized_required_authority" => row["realized_required_authority"],
        "required_authority_match_status" => row["required_authority_match_status"],
        "command_safety_status" => row["command_safety_status"],
        "planned_command_safety_status" => row["planned_command_safety_status"],
        "realized_command_safety_status" => row["realized_command_safety_status"],
        "command_safety_status_match_status" => row["command_safety_status_match_status"],
        "command_authorized" => row["command_authorized"],
        "planned_command_authorized" => row["planned_command_authorized"],
        "realized_command_authorized" => row["realized_command_authorized"],
        "command_authorized_match_status" => row["command_authorized_match_status"],
        "command_safety_checked" => row["command_safety_checked"],
        "planned_command_safety_checked" => row["planned_command_safety_checked"],
        "realized_command_safety_checked" => row["realized_command_safety_checked"],
        "command_safety_checked_match_status" => row["command_safety_checked_match_status"],
        "observation_success" => row["observation_success"],
        "observation_result" => provider_result_artifact_value(row["observation_result"]),
        "observation_success_factor" => row["observation_success_factor"],
        "observation_success_factor_source" => row["observation_success_factor_source"],
        "feedback_weight" => row["feedback_weight"],
        "feedback_weight_source" => row["feedback_weight_source"],
        "maneuver_success_factor" => row["maneuver_success_factor"],
        "maneuver_success_factor_source" => row["maneuver_success_factor_source"],
        "execution_uncertainty_status" => row["execution_uncertainty_status"],
        "execution_uncertainty" => row["execution_uncertainty"],
        "timing_3sigma_s" => row["timing_3sigma_s"],
        "delta_v_3sigma_km_s" => row["delta_v_3sigma_km_s"],
        "delta_v_3sigma_magnitude_km_s" => row["delta_v_3sigma_magnitude_km_s"],
        "execution_uncertainty_source" => row["execution_uncertainty_source"],
        "contact_result" => provider_result_artifact_value(row["contact_result"]),
        "command_result" => provider_result_artifact_value(row["command_result"]),
        "maneuver_success" => row["maneuver_success"],
        "maneuver_result" => provider_result_artifact_value(row["maneuver_result"]),
        "completed_fraction" => row["completed_fraction"],
        "resource_source_quality" => row["resource_source_quality"],
        "resource_trust_boundary" => row["resource_trust_boundary"],
        "resource_trust_boundary_status" => row["resource_trust_boundary_status"],
        "resource_provenance" => row["resource_provenance"],
        "resource_blocking_dimension" => row["resource_blocking_dimension"],
        "fuel_margin" => row["fuel_margin"],
        "thermal_zone_id" => row["thermal_zone_id"],
        "temperature_c" => row["temperature_c"],
        "planned_temperature_c" => row["planned_temperature_c"],
        "actual_temperature_c" => row["actual_temperature_c"],
        "temperature_delta_c" => row["temperature_delta_c"],
        "min_operating_temperature_c" => row["min_operating_temperature_c"],
        "max_operating_temperature_c" => row["max_operating_temperature_c"],
        "thermal_margin_c" => row["thermal_margin_c"],
        "thermal_status" => row["thermal_status"],
        "thermal_model" => row["thermal_model"],
        "thermal_source" => row["thermal_source"],
        "thermal_confidence" => row["thermal_confidence"],
        "power_margin" => row["power_margin"],
        "storage_margin" => row["storage_margin"],
        "downlink_margin" => row["downlink_margin"],
        "battery_capacity_wh" => row["battery_capacity_wh"],
        "battery_energy_used_wh" => row["battery_energy_used_wh"],
        "battery_energy_generated_wh" => row["battery_energy_generated_wh"],
        "battery_state_of_charge" => row["battery_state_of_charge"],
        "spacecraft_available" => row["spacecraft_available"],
        "planned_spacecraft_available" => row["planned_spacecraft_available"],
        "realized_spacecraft_available" => row["realized_spacecraft_available"],
        "spacecraft_available_match_status" => row["spacecraft_available_match_status"],
        "payload_available" => row["payload_available"],
        "planned_payload_available" => row["planned_payload_available"],
        "realized_payload_available" => row["realized_payload_available"],
        "payload_available_match_status" => row["payload_available_match_status"],
        "antenna_available" => row["antenna_available"],
        "planned_antenna_available" => row["planned_antenna_available"],
        "realized_antenna_available" => row["realized_antenna_available"],
        "antenna_available_match_status" => row["antenna_available_match_status"],
        "degraded" => row["degraded"],
        "planned_degraded" => row["planned_degraded"],
        "realized_degraded" => row["realized_degraded"],
        "degraded_match_status" => row["degraded_match_status"],
        "mode" => row["mode"],
        "planned_mode" => row["planned_mode"],
        "realized_mode" => row["realized_mode"],
        "mode_match_status" => row["mode_match_status"],
        "incompatible_activity_types" => row["incompatible_activity_types"],
        "suppressed_activity_types" => row["suppressed_activity_types"],
        "station_availability" => row["station_availability"],
        "station_contention_status" => row["station_contention_status"],
        "capacity_fraction" => row["capacity_fraction"],
        "capacity_fraction_min" => row["capacity_fraction_min"],
        "capacity_fraction_max" => row["capacity_fraction_max"],
        "station_calendar_entry_id" => row["station_calendar_entry_id"],
        "station_calendar_provider_id" => row["station_calendar_provider_id"],
        "station_calendar_provider_entry_id" => row["station_calendar_provider_entry_id"],
        "station_calendar_directions" => row["station_calendar_directions"],
        "station_calendar_status" => row["station_calendar_status"],
        "station_calendar_overlap_count" => row["station_calendar_overlap_count"],
        "station_calendar_overlap_entry_ids" => row["station_calendar_overlap_entry_ids"],
        "station_calendar_overlap_availabilities" =>
          row["station_calendar_overlap_availabilities"],
        "station_calendar_entry_ambiguous" => row["station_calendar_entry_ambiguous"],
        "station_calendar_ambiguous_entry_count" => row["station_calendar_ambiguous_entry_count"],
        "station_calendar_ambiguous_entry_ids" => row["station_calendar_ambiguous_entry_ids"],
        "station_calendar_reservation_overlap_count" =>
          row["station_calendar_reservation_overlap_count"],
        "station_calendar_reservation_ids" => row["station_calendar_reservation_ids"],
        "station_calendar_reserved_by" => row["station_calendar_reserved_by"],
        "station_calendar_reservation_statuses" => row["station_calendar_reservation_statuses"],
        "station_calendar_reservation_expires_at_s" =>
          row["station_calendar_reservation_expires_at_s"],
        "station_calendar_trust_boundary_status" => row["station_calendar_trust_boundary_status"],
        "source_station_calendar_entry" => row["source_station_calendar_entry"],
        "source_station_calendar_overlaps" => row["source_station_calendar_overlaps"],
        "station_reservation_id" => row["station_reservation_id"],
        "station_reservation_expires_at_s" => row["station_reservation_expires_at_s"],
        "station_reserved_by" => row["station_reserved_by"],
        "station_reservation_status" => row["station_reservation_status"],
        "station_reservation_match_status" => row["station_reservation_match_status"],
        "source_feedback" => row
      }
      |> compact_map()
    end)
  end

  defp realized_timeline_feedback_rows(nil), do: []

  defp realized_timeline_feedback_rows(rows) when is_list(rows) do
    rows
    |> Enum.map(&stringify_keys/1)
    |> Enum.reject(&(&1["status"] == "planned_only"))
  end

  defp realized_timeline_feedback_rows(_rows), do: []

  defp feedback_review_decision(%{"realized_match_count" => count})
       when is_number(count) and count > 1 do
    {"review_duplicate_realized_feedback", "operator_review_required",
     "multiple realized feedback rows match the same planned activity"}
  end

  defp feedback_review_decision(%{"match_strategy" => "ambiguous_timeline_id"} = row) do
    {"review_ambiguous_realized_feedback", "operator_review_required",
     feedback_reason(row, "realized feedback timeline id matches multiple planned activities")}
  end

  defp feedback_review_decision(%{"invalid_activity_input" => true} = row) do
    {"review_invalid_activity_input", "operator_review_required",
     feedback_reason(
       row,
       "planned feedback input is invalid: #{row["invalid_activity_input_reason"]}"
     )}
  end

  defp feedback_review_decision(%{"invalid_realized_feedback_input" => true} = row) do
    {"review_invalid_realized_feedback_input", "operator_review_required",
     invalid_realized_feedback_reason(row)}
  end

  defp feedback_review_decision(%{"invalid_cadence_import" => true} = row) do
    {"review_invalid_cadence_import", "operator_review_required",
     feedback_reason(row, "realized feedback Cadence import context is invalid")}
  end

  defp feedback_review_decision(%{"timeline_integrity_status" => "review_required"} = row) do
    {"review_timeline_integrity", "operator_review_required",
     feedback_reason(row, "planned activity has dependency or exclusivity integrity issues")}
  end

  defp feedback_review_decision(%{"status" => "planned_only"}) do
    {"review_missing_realization", "operator_review_required",
     "planned activity has no realized feedback row"}
  end

  defp feedback_review_decision(%{"status" => "realized_only"} = row) do
    {"review_unplanned_realization", "operator_review_required",
     feedback_reason(row, "realized feedback row has no planned activity")}
  end

  defp feedback_review_decision(
         %{"status" => "matched", "planned_operator_action" => "resolve_blocked_activity"} = row
       ) do
    {"resolve_blocked_activity", "operator_review_required",
     feedback_reason(row, blocked_feedback_reason(row))}
  end

  defp feedback_review_decision(
         %{"status" => "matched", "planned_operator_action" => "resolve_rejected_activity"} = row
       ) do
    {"resolve_rejected_activity", "operator_review_required",
     feedback_reason(row, "realized feedback arrived for rejected planned activity")}
  end

  defp feedback_review_decision(
         %{"feedback_kind" => "contact", "realized_status" => status} = row
       )
       when status in @feedback_exception_statuses do
    {"review_contact_exception", "operator_review_required",
     feedback_reason(row, "realized contact ended with #{status} status")}
  end

  defp feedback_review_decision(
         %{"feedback_kind" => "contact", "realized_status" => status} = row
       )
       when status in @feedback_variance_statuses do
    {"review_contact_variance", "operator_review_required",
     feedback_reason(row, "realized contact ended with #{status} status")}
  end

  defp feedback_review_decision(%{"feedback_kind" => "contact", "contact_success" => false} = row) do
    {"review_contact_exception", "operator_review_required",
     feedback_reason(row, "provider contact_success false despite completed status")}
  end

  defp feedback_review_decision(
         %{"feedback_kind" => "contact", "realized_status" => status} = row
       )
       when status in @feedback_completion_statuses do
    cond do
      contact_throughput_variance?(row) ->
        {"review_contact_variance", "operator_review_required",
         feedback_reason(row, "realized contact #{status} below planned throughput")}

      completed_fraction_variance?(row) ->
        {"review_contact_variance", "operator_review_required",
         feedback_reason(row, "realized contact #{status} with partial completion fraction")}

      contact_link_quality_variance?(row) ->
        {"review_contact_variance", "operator_review_required",
         feedback_reason(row, "realized contact #{status} with link quality variance")}

      realized_activity_identity_variance?(row) ->
        {"review_contact_variance", "operator_review_required",
         feedback_reason(
           row,
           "realized contact #{status} with planned/realized identity variance"
         )}

      realized_resource_availability_variance?(row) ->
        {"review_contact_variance", "operator_review_required",
         feedback_reason(
           row,
           "realized contact #{status} with planned/realized resource availability variance"
         )}

      timing_variance?(row) ->
        {"review_contact_variance", "operator_review_required",
         feedback_reason(row, "realized contact #{status} exceeded timing variance threshold")}

      missing_cadence_import?(row) ->
        {"prepare_cadence_import", "operator_review_required",
         feedback_reason(
           row,
           "realized contact #{status} but planned contact is missing Cadence import identity"
         )}

      true ->
        {"record_contact_completion", "not_required",
         feedback_reason(row, "realized contact #{status}")}
    end
  end

  defp feedback_review_decision(%{"feedback_kind" => kind, "realized_status" => status} = row)
       when kind in ["command", "health_check"] and status in @feedback_exception_statuses do
    {"review_command_exception", "operator_review_required",
     feedback_reason(row, "realized command activity ended with #{status} status")}
  end

  defp feedback_review_decision(%{"feedback_kind" => kind, "realized_status" => status} = row)
       when kind in ["command", "health_check"] and status in @feedback_variance_statuses do
    {"review_command_variance", "operator_review_required",
     feedback_reason(row, "realized command activity ended with #{status} status")}
  end

  defp feedback_review_decision(%{"feedback_kind" => kind, "command_success" => false} = row)
       when kind in ["command", "health_check"] do
    {"review_command_exception", "operator_review_required",
     feedback_reason(row, "provider command_success false despite completed status")}
  end

  defp feedback_review_decision(
         %{"feedback_kind" => "maneuver", "maneuver_success" => false} = row
       ) do
    {"review_maneuver_exception", "operator_review_required",
     feedback_reason(row, "provider maneuver_success false despite completed status")}
  end

  defp feedback_review_decision(%{"feedback_kind" => kind, "realized_status" => status} = row)
       when kind in ["command", "health_check"] and status in @feedback_completion_statuses do
    cond do
      realized_activity_identity_variance?(row) ->
        {"review_command_variance", "operator_review_required",
         feedback_reason(
           row,
           "realized command activity #{status} with planned/realized contact identity variance"
         )}

      realized_resource_availability_variance?(row) ->
        {"review_command_variance", "operator_review_required",
         feedback_reason(
           row,
           "realized command activity #{status} with planned/realized resource availability variance"
         )}

      timing_variance?(row) ->
        {"review_command_variance", "operator_review_required",
         feedback_reason(
           row,
           "realized command activity #{status} exceeded timing variance threshold"
         )}

      completed_fraction_variance?(row) ->
        {"review_command_variance", "operator_review_required",
         feedback_reason(
           row,
           "realized command activity #{status} with partial completion fraction"
         )}

      missing_cadence_import?(row) ->
        {"prepare_cadence_import", "operator_review_required",
         feedback_reason(
           row,
           "realized command activity #{status} but planned command is missing Cadence import identity"
         )}

      true ->
        {"record_command_completion", "not_required",
         feedback_reason(row, "realized command activity #{status}")}
    end
  end

  defp feedback_review_decision(%{"realized_status" => status} = row)
       when status in @feedback_exception_statuses do
    {"review_realized_exception", "operator_review_required",
     feedback_reason(row, "realized activity ended with #{status} status")}
  end

  defp feedback_review_decision(%{"realized_status" => status} = row)
       when status in @feedback_variance_statuses do
    {"review_realized_variance", "operator_review_required",
     feedback_reason(row, "realized activity ended with #{status} status")}
  end

  defp feedback_review_decision(%{"realized_status" => status} = row)
       when status in @feedback_completion_statuses do
    cond do
      completed_fraction_variance?(row) ->
        {"review_realized_variance", "operator_review_required",
         feedback_reason(row, "realized activity #{status} with partial completion fraction")}

      realized_activity_identity_variance?(row) ->
        {"review_realized_variance", "operator_review_required",
         feedback_reason(
           row,
           "realized activity #{status} with planned/realized identity variance"
         )}

      realized_resource_availability_variance?(row) ->
        {"review_realized_variance", "operator_review_required",
         feedback_reason(
           row,
           "realized activity #{status} with planned/realized resource availability variance"
         )}

      realized_maneuver_delta_v_variance?(row) ->
        {"review_realized_variance", "operator_review_required",
         feedback_reason(
           row,
           "realized maneuver activity #{status} with planned/realized delta-v variance"
         )}

      timing_variance?(row) ->
        {"review_realized_variance", "operator_review_required",
         feedback_reason(row, "realized activity #{status} exceeded timing variance threshold")}

      missing_cadence_import?(row) ->
        {"prepare_cadence_import", "operator_review_required",
         feedback_reason(
           row,
           "realized activity #{status} but planned activity is missing Cadence import identity"
         )}

      true ->
        {"record_realized_completion", "not_required",
         feedback_reason(row, "realized activity #{status}")}
    end
  end

  defp feedback_review_decision(%{"status" => status} = row) do
    {"review_realized_feedback", "operator_review_required",
     feedback_reason(row, "realized feedback row has #{status} reconciliation status")}
  end

  defp blocked_feedback_reason(%{
         "planned_operator_action_reason" => "activity_status_blocked_by_policy"
       }) do
    "realized feedback arrived for status-blocked planned activity"
  end

  defp blocked_feedback_reason(_row) do
    "realized feedback arrived for policy-blocked planned activity"
  end

  defp contact_throughput_variance?(row) do
    case row["throughput_completion_fraction"] do
      value when is_number(value) -> value < 1.0
      _value -> false
    end
  end

  defp completed_fraction_variance?(row) do
    case row["completed_fraction"] do
      value when is_number(value) -> value < 1.0
      _value -> false
    end
  end

  defp timing_variance?(%{"timing_variance_status" => "exceeds_threshold"}), do: true
  defp timing_variance?(_row), do: false

  defp contact_link_quality_variance?(row) do
    row["realized_carrier_lock"] == false or
      row["realized_symbol_lock"] == false or
      negative_number?(row["realized_link_margin_db"]) or
      link_quality_failure_status?(row["realized_link_quality_status"])
  end

  defp link_quality_failure_status?(status) when is_binary(status) do
    status
    |> normalize_status()
    |> then(
      &(&1 in [
          "below_threshold",
          "degraded",
          "failed",
          "link_failed",
          "lock_lost",
          "low_margin",
          "no_lock",
          "poor",
          "unusable"
        ])
    )
  end

  defp link_quality_failure_status?(_status), do: false

  defp negative_number?(value), do: is_number(value) and value < 0.0

  defp normalize_status(status) when is_binary(status) do
    status
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[\s-]+/, "_")
  end

  defp normalize_status(status) when is_atom(status),
    do: status |> Atom.to_string() |> normalize_status()

  defp normalize_status(_status), do: nil

  defp realized_contact_identity_variance?(row) do
    Enum.any?(
      [
        row["direction_match_status"],
        row["ground_station_match_status"],
        row["source_window_match_status"],
        row["link_protocol_match_status"],
        row["frequency_band_match_status"],
        row["modulation_match_status"],
        row["coding_scheme_match_status"],
        row["polarization_match_status"]
      ],
      &(&1 == "mismatch")
    )
  end

  defp realized_activity_identity_variance?(row) do
    realized_contact_identity_variance?(row) or
      Enum.any?(
        [
          row["target_match_status"],
          row["collection_match_status"],
          row["product_match_status"],
          row["product_ids_match_status"],
          row["payload_match_status"],
          row["instrument_match_status"]
        ],
        &(&1 == "mismatch")
      )
  end

  defp realized_resource_availability_variance?(row) do
    Enum.any?(
      [
        row["spacecraft_available_match_status"],
        row["payload_available_match_status"],
        row["antenna_available_match_status"],
        row["degraded_match_status"],
        row["mode_match_status"]
      ],
      &(&1 == "mismatch")
    )
  end

  defp realized_maneuver_delta_v_variance?(%{"feedback_kind" => "maneuver"} = row) do
    row["delta_v_match_status"] == "mismatch"
  end

  defp realized_maneuver_delta_v_variance?(_row), do: false

  defp missing_cadence_import?(row), do: row["cadence_import_status"] == "missing"

  defp invalid_realized_feedback_reason(%{
         "invalid_realized_feedback_input_reason" => "unsupported_realized_status",
         "unsupported_realized_status" => status
       })
       when is_binary(status) and status != "" do
    "realized feedback input has unsupported status #{status}"
  end

  defp invalid_realized_feedback_reason(%{
         "invalid_realized_feedback_input_reason" => "missing_realized_status"
       }) do
    "realized feedback input is missing status"
  end

  defp invalid_realized_feedback_reason(row) do
    "realized feedback input is invalid: #{row["invalid_realized_feedback_input_reason"]}"
  end

  defp feedback_reason(%{"reason" => reason}, _fallback) when is_binary(reason) and reason != "",
    do: reason

  defp feedback_reason(_row, fallback), do: fallback

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
