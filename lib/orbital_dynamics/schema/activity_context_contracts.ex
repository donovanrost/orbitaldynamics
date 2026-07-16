defmodule OrbitalDynamics.Schema.ActivityContextContracts do
  @moduledoc false

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

  def validate_optional(issues, path, map, field, callbacks)
      when is_map(map) and is_list(callbacks) do
    case Map.get(map, field) do
      %{} = context -> validate(issues, "#{path}.#{field}", context, callbacks)
      _value -> issues
    end
  end

  def validate(issues, path, context, callbacks) when is_map(context) and is_list(callbacks) do
    issues
    |> validate_stable_ids(callbacks, path, context, @stable_id_fields)
    |> validate_stable_id_lists(callbacks, path, context)
    |> validate_probability_fields(callbacks, path, context)
    |> expect_optional_integer(callbacks, path, context, "observation_objective_count")
    |> expect_field_at_least(callbacks, path, context, "observation_objective_count", 0)
    |> expect_optional_type(callbacks, path, context, "observation_objective_types", :list)
    |> validate_string_list_items(callbacks, path, context, "observation_objective_types")
    |> expect_optional_integer(callbacks, path, context, "collection_latency_objective_count")
    |> expect_field_at_least(callbacks, path, context, "collection_latency_objective_count", 0)
    |> expect_optional_type(callbacks, path, context, "collection_latency_objective_types", :list)
    |> validate_string_list_items(callbacks, path, context, "collection_latency_objective_types")
    |> expect_optional_type(callbacks, path, context, "source_event_type", :binary)
    |> expect_optional_type(callbacks, path, context, "source_event_provenance", :map)
    |> validate_source_event_provenance(callbacks, path, context)
    |> expect_optional_type(callbacks, path, context, "feedback_source", :binary)
    |> expect_optional_type(callbacks, path, context, "feedback_scope", :binary)
    |> expect_optional_type(callbacks, path, context, "trust_boundary", :binary)
    |> expect_optional_type(callbacks, path, context, "derivation_reason", :binary)
    |> expect_optional_type(callbacks, path, context, "derivation_reasons", :list)
    |> validate_string_list_items(callbacks, path, context, "derivation_reasons")
    |> expect_optional_type(callbacks, path, context, "allow_overlap", :boolean)
    |> expect_optional_number(callbacks, path, context, "duration_s")
    |> expect_optional_non_negative_number(callbacks, path, context, "setup_duration_s")
    |> expect_optional_non_negative_number(callbacks, path, context, "cooldown_duration_s")
    |> expect_optional_type(callbacks, path, context, "telemetry_confirmation_required", :boolean)
    |> expect_optional_type(callbacks, path, context, "telemetry_confirmation_status", :binary)
    |> expect_optional_number(callbacks, path, context, "score")
    |> expect_optional_type(callbacks, path, context, "score_terms", :map)
    |> validate_numeric_map(callbacks, path <> ".score_terms", Map.get(context, "score_terms"))
    |> expect_optional_type(
      callbacks,
      path,
      context,
      "actual_data_rate_throughput_derivation",
      :map
    )
    |> validate_optional_actual_data_rate_throughput_derivation(
      callbacks,
      path,
      context,
      "actual_data_rate_throughput_derivation"
    )
    |> expect_optional_type(callbacks, path, context, "execution_uncertainty", :map)
    |> validate_optional_execution_uncertainty(callbacks, path, context, "execution_uncertainty")
    |> expect_optional_type(callbacks, path, context, "source_window", :map)
    |> validate_source_window(callbacks, path, context)
    |> expect_optional_non_negative_number(
      callbacks,
      path,
      context,
      "battery_energy_generated_wh"
    )
    |> expect_optional_number_or_string(callbacks, path, context, "lighting_confidence")
    |> expect_optional_type(callbacks, path, context, "feasibility_status", :binary)
    |> expect_optional_type(callbacks, path, context, "repair_reason", :binary)
    |> validate_candidate_diff_changed_fields(callbacks, path, context)
    |> expect_optional_integer(callbacks, path, context, "station_calendar_overlap_count")
    |> expect_field_at_least(callbacks, path, context, "station_calendar_overlap_count", 0)
    |> expect_optional_integer(callbacks, path, context, "station_calendar_ambiguous_entry_count")
    |> expect_field_at_least(
      callbacks,
      path,
      context,
      "station_calendar_ambiguous_entry_count",
      0
    )
    |> expect_optional_integer(
      callbacks,
      path,
      context,
      "station_calendar_reservation_overlap_count"
    )
    |> expect_field_at_least(
      callbacks,
      path,
      context,
      "station_calendar_reservation_overlap_count",
      0
    )
    |> expect_optional_type(
      callbacks,
      path,
      context,
      "station_calendar_reservation_expires_at_s",
      :list
    )
    |> validate_number_list_items(
      callbacks,
      path,
      context,
      "station_calendar_reservation_expires_at_s"
    )
    |> expect_optional_number(callbacks, path, context, "station_reservation_expires_at_s")
    |> expect_optional_integer(callbacks, path, context, "timeline_integrity_issue_count")
    |> expect_field_at_least(callbacks, path, context, "timeline_integrity_issue_count", 0)
    |> expect_optional_type(callbacks, path, context, "timeline_integrity_issue_types", :list)
    |> validate_string_list_items(callbacks, path, context, "timeline_integrity_issue_types")
    |> expect_optional_type(callbacks, path, context, "timeline_integrity_issues", :list)
    |> validate_timeline_integrity_evidence(callbacks, path, context)
  end

  defp validate_source_window(issues, callbacks, path, %{"source_window" => %{} = window}) do
    issues
    |> validate_stable_ids(callbacks, path <> ".source_window", window, [
      "id",
      "scenario_id",
      "target_id",
      "ground_station_id"
    ])
    |> expect_optional_number(callbacks, path <> ".source_window", window, "starts_at_s")
    |> expect_optional_number(callbacks, path <> ".source_window", window, "ends_at_s")
    |> expect_optional_number(callbacks, path <> ".source_window", window, "duration_s")
    |> expect_optional_number(callbacks, path <> ".source_window", window, "max_elevation_deg")
    |> expect_optional_number(
      callbacks,
      path <> ".source_window",
      window,
      "minimum_elevation_deg"
    )
    |> expect_optional_number(
      callbacks,
      path <> ".source_window",
      window,
      "event_time_tolerance_s"
    )
    |> expect_optional_number(callbacks, path <> ".source_window", window, "max_sample_step_s")
    |> validate_candidate_refresh_scoped_context_fields(
      callbacks,
      path <> ".source_window",
      window
    )
  end

  defp validate_source_window(issues, _callbacks, _path, _context), do: issues

  defp validate_source_event_provenance(
         issues,
         callbacks,
         path,
         %{"source_event_provenance" => %{} = provenance}
       ) do
    provenance_path = path <> ".source_event_provenance"

    issues
    |> expect_optional_type(callbacks, provenance_path, provenance, "source", :binary)
    |> expect_optional_type(callbacks, provenance_path, provenance, "adapter", :binary)
    |> expect_optional_type(callbacks, provenance_path, provenance, "import_adapter", :binary)
    |> expect_optional_type(callbacks, provenance_path, provenance, "trust_boundary", :binary)
    |> expect_optional_type(
      callbacks,
      provenance_path,
      provenance,
      "trust_boundary_status",
      :binary
    )
  end

  defp validate_source_event_provenance(issues, _callbacks, _path, _context), do: issues

  defp validate_probability_fields(issues, callbacks, path, context) do
    Enum.reduce(@probability_fields, issues, fn field, acc ->
      expect_optional_probability(acc, callbacks, path, context, field)
    end)
  end

  defp validate_stable_id_lists(issues, callbacks, path, context) do
    Enum.reduce(@stable_id_list_fields, issues, fn field, acc ->
      validate_optional_stable_id_list(acc, callbacks, path, context, field)
    end)
  end

  defp validate_stable_ids(issues, callbacks, path, map, fields),
    do: apply(require_callback(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp validate_optional_stable_id_list(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :validate_optional_stable_id_list), [
        issues,
        path,
        map,
        field
      ])

  defp expect_optional_probability(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :expect_optional_probability), [
        issues,
        path,
        map,
        field
      ])

  defp expect_optional_integer(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :expect_optional_integer), [
        issues,
        path,
        map,
        field
      ])

  defp expect_field_at_least(issues, callbacks, path, map, field, minimum),
    do:
      apply(require_callback(callbacks, :expect_field_at_least), [
        issues,
        path,
        map,
        field,
        minimum
      ])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do:
      apply(require_callback(callbacks, :expect_optional_type), [
        issues,
        path,
        map,
        field,
        type
      ])

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :validate_string_list_items), [
        issues,
        path,
        map,
        field
      ])

  defp expect_optional_number(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :expect_optional_number), [
        issues,
        path,
        map,
        field
      ])

  defp expect_optional_non_negative_number(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :expect_optional_non_negative_number), [
        issues,
        path,
        map,
        field
      ])

  defp validate_numeric_map(issues, callbacks, path, map),
    do: apply(require_callback(callbacks, :validate_numeric_map), [issues, path, map])

  defp validate_optional_actual_data_rate_throughput_derivation(
         issues,
         callbacks,
         path,
         map,
         field
       ),
       do:
         apply(
           require_callback(callbacks, :validate_optional_actual_data_rate_throughput_derivation),
           [
             issues,
             path,
             map,
             field
           ]
         )

  defp validate_optional_execution_uncertainty(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :validate_optional_execution_uncertainty), [
        issues,
        path,
        map,
        field
      ])

  defp validate_candidate_refresh_scoped_context_fields(issues, callbacks, path, context),
    do:
      apply(require_callback(callbacks, :validate_candidate_refresh_scoped_context_fields), [
        issues,
        path,
        context
      ])

  defp expect_optional_number_or_string(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :expect_optional_number_or_string), [
        issues,
        path,
        map,
        field
      ])

  defp validate_candidate_diff_changed_fields(issues, callbacks, path, context),
    do:
      apply(require_callback(callbacks, :validate_candidate_diff_changed_fields), [
        issues,
        path,
        context
      ])

  defp validate_number_list_items(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :validate_number_list_items), [
        issues,
        path,
        map,
        field
      ])

  defp validate_timeline_integrity_evidence(issues, callbacks, path, context),
    do:
      apply(require_callback(callbacks, :validate_timeline_integrity_evidence), [
        issues,
        path,
        context
      ])

  defp require_callback(callbacks, name), do: Keyword.fetch!(callbacks, name)
end
