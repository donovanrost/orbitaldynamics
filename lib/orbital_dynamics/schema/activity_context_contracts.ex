defmodule OrbitalDynamics.Schema.ActivityContextContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CollectionValidation, only: [validate_numeric_map: 3]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [validate_optional_stable_id_list: 4, validate_stable_ids: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_field_at_least: 5,
      expect_optional_integer: 4,
      expect_optional_non_negative_number: 4,
      expect_optional_number: 4,
      expect_optional_number_or_string: 4,
      expect_optional_probability: 4,
      expect_optional_type: 5,
      validate_number_list_items: 4,
      validate_string_list_items: 4
    ]

  alias OrbitalDynamics.Schema.{
    CandidateDiffContracts,
    CandidateRefreshScopedContextContracts,
    ExecutionMetricContracts,
    TimelineIntegrityEvidenceContracts
  }

  @stable_id_fields [
    "activity_id",
    "planned_activity_id",
    "matched_planned_activity_id",
    "timeline_id",
    "scenario_id",
    "spacecraft_id",
    "ground_station_id",
    "target_id",
    "objective_id",
    "source_target_id",
    "source_window_id",
    "source_event_id",
    "source_branch_id",
    "source_timeline_id",
    "resource_id",
    "collection_id",
    "product_id",
    "payload_id",
    "instrument_id",
    "station_calendar_entry_id",
    "station_calendar_provider_id",
    "station_calendar_provider_entry_id",
    "pointing_target_id",
    "attitude_target_id",
    "thermal_zone_id",
    "station_reservation_id"
  ]

  @stable_id_list_fields [
    "product_ids",
    "target_ids",
    "objective_ids",
    "collection_ids",
    "payload_ids",
    "instrument_ids",
    "target_priority_objective_ids",
    "observation_objective_ids",
    "collection_latency_objective_ids",
    "station_calendar_overlap_entry_ids",
    "station_calendar_ambiguous_entry_ids",
    "station_calendar_reservation_ids",
    "dependency_activity_ids",
    "dependency_timeline_ids",
    "exclusive_with_activity_ids",
    "exclusive_with_timeline_ids",
    "missing_dependency_activity_ids",
    "missing_dependency_timeline_ids",
    "self_dependency_activity_ids",
    "self_dependency_timeline_ids",
    "duplicate_dependency_activity_ids",
    "duplicate_dependency_timeline_ids",
    "duplicate_exclusivity_activity_ids",
    "duplicate_exclusivity_timeline_ids",
    "dependency_cycle_activity_ids",
    "dependency_cycle_timeline_ids",
    "dependency_order_violation_activity_ids",
    "dependency_order_violation_timeline_ids",
    "exclusivity_violation_activity_ids",
    "exclusivity_violation_timeline_ids"
  ]

  @probability_fields [
    "throughput_completion_fraction",
    "completed_fraction",
    "contact_success_factor",
    "command_success_factor",
    "observation_success_factor",
    "maneuver_success_factor",
    "bit_error_rate",
    "packet_loss_rate",
    "frame_loss_rate",
    "eclipse_overlap_fraction",
    "cloud_cover_fraction",
    "blur_score",
    "image_quality_score",
    "pointing_confidence",
    "attitude_confidence",
    "thermal_confidence",
    "fuel_margin",
    "power_margin",
    "storage_margin",
    "downlink_margin",
    "battery_state_of_charge",
    "capacity_pack_capacity_fraction"
  ]

  def validate_optional(issues, path, map, field) when is_map(map) do
    case Map.get(map, field) do
      %{} = context -> validate(issues, "#{path}.#{field}", context)
      _value -> issues
    end
  end

  def validate(issues, path, context) when is_map(context) do
    issues
    |> validate_stable_ids(path, context, @stable_id_fields)
    |> validate_stable_id_lists(path, context)
    |> validate_probability_fields(path, context)
    |> expect_optional_integer(path, context, "observation_objective_count")
    |> expect_field_at_least(path, context, "observation_objective_count", 0)
    |> expect_optional_type(path, context, "observation_objective_types", :list)
    |> validate_string_list_items(path, context, "observation_objective_types")
    |> expect_optional_integer(path, context, "collection_latency_objective_count")
    |> expect_field_at_least(path, context, "collection_latency_objective_count", 0)
    |> expect_optional_type(path, context, "collection_latency_objective_types", :list)
    |> validate_string_list_items(path, context, "collection_latency_objective_types")
    |> expect_optional_type(path, context, "source_event_type", :binary)
    |> expect_optional_type(path, context, "source_event_provenance", :map)
    |> validate_source_event_provenance(path, context)
    |> expect_optional_type(path, context, "feedback_source", :binary)
    |> expect_optional_type(path, context, "feedback_scope", :binary)
    |> expect_optional_type(path, context, "trust_boundary", :binary)
    |> expect_optional_type(path, context, "derivation_reason", :binary)
    |> expect_optional_type(path, context, "derivation_reasons", :list)
    |> validate_string_list_items(path, context, "derivation_reasons")
    |> expect_optional_type(path, context, "allow_overlap", :boolean)
    |> expect_optional_number(path, context, "duration_s")
    |> expect_optional_non_negative_number(path, context, "setup_duration_s")
    |> expect_optional_non_negative_number(path, context, "cooldown_duration_s")
    |> expect_optional_type(path, context, "telemetry_confirmation_required", :boolean)
    |> expect_optional_type(path, context, "telemetry_confirmation_status", :binary)
    |> expect_optional_number(path, context, "score")
    |> expect_optional_type(path, context, "score_terms", :map)
    |> validate_numeric_map(path <> ".score_terms", Map.get(context, "score_terms"))
    |> expect_optional_type(
      path,
      context,
      "actual_data_rate_throughput_derivation",
      :map
    )
    |> validate_optional_actual_data_rate_throughput_derivation(
      path,
      context,
      "actual_data_rate_throughput_derivation"
    )
    |> expect_optional_type(path, context, "execution_uncertainty", :map)
    |> validate_optional_execution_uncertainty(path, context, "execution_uncertainty")
    |> expect_optional_type(path, context, "source_window", :map)
    |> validate_source_window(path, context)
    |> expect_optional_non_negative_number(
      path,
      context,
      "battery_energy_generated_wh"
    )
    |> expect_optional_number_or_string(path, context, "lighting_confidence")
    |> expect_optional_type(path, context, "feasibility_status", :binary)
    |> expect_optional_type(path, context, "repair_reason", :binary)
    |> validate_candidate_diff_changed_fields(path, context)
    |> expect_optional_integer(path, context, "station_calendar_overlap_count")
    |> expect_field_at_least(path, context, "station_calendar_overlap_count", 0)
    |> expect_optional_integer(path, context, "station_calendar_ambiguous_entry_count")
    |> expect_field_at_least(
      path,
      context,
      "station_calendar_ambiguous_entry_count",
      0
    )
    |> expect_optional_integer(
      path,
      context,
      "station_calendar_reservation_overlap_count"
    )
    |> expect_field_at_least(
      path,
      context,
      "station_calendar_reservation_overlap_count",
      0
    )
    |> expect_optional_type(
      path,
      context,
      "station_calendar_reservation_expires_at_s",
      :list
    )
    |> validate_number_list_items(
      path,
      context,
      "station_calendar_reservation_expires_at_s"
    )
    |> expect_optional_number(path, context, "station_reservation_expires_at_s")
    |> expect_optional_integer(path, context, "timeline_integrity_issue_count")
    |> expect_field_at_least(path, context, "timeline_integrity_issue_count", 0)
    |> expect_optional_type(path, context, "timeline_integrity_issue_types", :list)
    |> validate_string_list_items(path, context, "timeline_integrity_issue_types")
    |> expect_optional_type(path, context, "timeline_integrity_issues", :list)
    |> validate_timeline_integrity_evidence(path, context)
  end

  defp validate_source_window(issues, path, %{"source_window" => %{} = window}) do
    issues
    |> validate_stable_ids(path <> ".source_window", window, [
      "id",
      "scenario_id",
      "target_id",
      "ground_station_id"
    ])
    |> expect_optional_number(path <> ".source_window", window, "starts_at_s")
    |> expect_optional_number(path <> ".source_window", window, "ends_at_s")
    |> expect_optional_number(path <> ".source_window", window, "duration_s")
    |> expect_optional_number(path <> ".source_window", window, "max_elevation_deg")
    |> expect_optional_number(
      path <> ".source_window",
      window,
      "minimum_elevation_deg"
    )
    |> expect_optional_number(
      path <> ".source_window",
      window,
      "event_time_tolerance_s"
    )
    |> expect_optional_number(path <> ".source_window", window, "max_sample_step_s")
    |> validate_candidate_refresh_scoped_context_fields(
      path <> ".source_window",
      window
    )
  end

  defp validate_source_window(issues, _path, _context), do: issues

  defp validate_source_event_provenance(
         issues,
         path,
         %{"source_event_provenance" => %{} = provenance}
       ) do
    provenance_path = path <> ".source_event_provenance"

    issues
    |> expect_optional_type(provenance_path, provenance, "source", :binary)
    |> expect_optional_type(provenance_path, provenance, "adapter", :binary)
    |> expect_optional_type(provenance_path, provenance, "import_adapter", :binary)
    |> expect_optional_type(provenance_path, provenance, "trust_boundary", :binary)
    |> expect_optional_type(
      provenance_path,
      provenance,
      "trust_boundary_status",
      :binary
    )
  end

  defp validate_source_event_provenance(issues, _path, _context), do: issues

  defp validate_probability_fields(issues, path, context) do
    Enum.reduce(@probability_fields, issues, fn field, acc ->
      expect_optional_probability(acc, path, context, field)
    end)
  end

  defp validate_stable_id_lists(issues, path, context) do
    Enum.reduce(@stable_id_list_fields, issues, fn field, acc ->
      validate_optional_stable_id_list(acc, path, context, field)
    end)
  end

  defp validate_optional_actual_data_rate_throughput_derivation(
         issues,
         path,
         map,
         field
       ) do
    ExecutionMetricContracts.validate_optional_actual_data_rate_throughput_derivation(
      issues,
      path,
      map,
      field
    )
  end

  defp validate_optional_execution_uncertainty(issues, path, map, field) do
    ExecutionMetricContracts.validate_optional_execution_uncertainty(
      issues,
      path,
      map,
      field
    )
  end

  defp validate_candidate_refresh_scoped_context_fields(issues, path, context),
    do: CandidateRefreshScopedContextContracts.validate(issues, path, context)

  defp validate_candidate_diff_changed_fields(issues, path, context),
    do: CandidateDiffContracts.validate_changed_fields(issues, path, context)

  defp validate_timeline_integrity_evidence(issues, path, context),
    do: TimelineIntegrityEvidenceContracts.validate(issues, path, context)
end
