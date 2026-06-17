defmodule OrbitalDynamics.Schema.ResourceFilterReportContracts do
  @moduledoc false

  def validate(issues, path, report, callbacks) when is_list(callbacks) do
    issues
    |> require_fields(callbacks, path, report, [
      "schema_contract",
      "model",
      "input_candidate_count",
      "kept_candidate_count",
      "suppressed_candidate_count",
      "suppressed_candidates"
    ])
    |> expect_equal(callbacks, path, report, "schema_contract", "resource_filter_report.v1")
    |> expect_equal(
      callbacks,
      path,
      report,
      "model",
      "resource_summary_availability_and_margin_filter"
    )
    |> expect_non_negative_integer(callbacks, path, report, "input_candidate_count")
    |> expect_non_negative_integer(callbacks, path, report, "kept_candidate_count")
    |> expect_non_negative_integer(callbacks, path, report, "suppressed_candidate_count")
    |> expect_type(callbacks, path, report, "suppressed_candidates", :list)
    |> expect_optional_type(callbacks, path, report, "policy", :map)
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      report,
      "input_resource_summary_count"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      report,
      "valid_resource_summary_count"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      report,
      "invalid_resource_summary_input_count"
    )
    |> expect_optional_type(callbacks, path, report, "invalid_resource_summary_input_ids", :list)
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      report,
      "invalid_resource_summary_input_ids"
    )
    |> expect_optional_type(callbacks, path, report, "invalid_resource_summary_inputs", :list)
    |> expect_optional_type(callbacks, path, report, "resource_source_quality_counts", :map)
    |> expect_optional_type(
      callbacks,
      path,
      report,
      "resource_trust_boundary_status_counts",
      :map
    )
    |> expect_optional_type(
      callbacks,
      path,
      report,
      "suppressed_resource_source_quality_counts",
      :map
    )
    |> expect_optional_type(
      callbacks,
      path,
      report,
      "suppressed_candidate_ids_by_resource_source_quality",
      :map
    )
    |> validate_optional_stable_id_array_map(
      callbacks,
      path,
      report,
      "suppressed_candidate_ids_by_resource_source_quality"
    )
    |> expect_optional_type(
      callbacks,
      path,
      report,
      "suppressed_resource_trust_boundary_status_counts",
      :map
    )
    |> expect_optional_type(
      callbacks,
      path,
      report,
      "suppressed_candidate_ids_by_resource_trust_boundary_status",
      :map
    )
    |> validate_optional_stable_id_array_map(
      callbacks,
      path,
      report,
      "suppressed_candidate_ids_by_resource_trust_boundary_status"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      report,
      "invalid_candidate_input_count"
    )
    |> expect_optional_type(callbacks, path, report, "invalid_candidate_input_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, report, "invalid_candidate_input_ids")
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      report,
      "duplicate_suppressed_candidate_row_count"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      report,
      "duplicate_suppressed_candidate_id_count"
    )
    |> expect_optional_type(callbacks, path, report, "model_limits", :list)
    |> expect_optional_type(callbacks, path, report, "assumptions", :map)
    |> validate_string_list_items(callbacks, path, report, "model_limits")
    |> validate_optional_exact_model_limits(
      callbacks,
      path,
      report,
      resource_filter_report_model_limits(),
      "must match resource filter report model limits"
    )
    |> validate_assumptions(callbacks, path, report)
    |> validate_optional_rows(
      callbacks,
      path <> ".invalid_resource_summary_inputs",
      Map.get(report, "invalid_resource_summary_inputs"),
      fn acc, row_path, row ->
        validate_invalid_resource_summary_input(callbacks, acc, row_path, row)
      end
    )
    |> validate_rows(
      callbacks,
      path <> ".suppressed_candidates",
      Map.get(report, "suppressed_candidates", []),
      fn acc, row_path, row -> validate_suppressed_candidate(callbacks, acc, row_path, row) end
    )
    |> validate_filter_report_counts(callbacks, path, report, "resource")
  end

  defp validate_assumptions(issues, callbacks, path, report) do
    case Map.get(report, "assumptions") do
      nil ->
        issues

      :null ->
        issues

      assumptions when is_map(assumptions) ->
        issues
        |> expect_equal(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "execution_boundary",
          "artifact_only_no_schedule_mutation"
        )
        |> expect_equal(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "operator_authority",
          "not_granted_by_resource_filter"
        )
        |> expect_equal(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "resource_state_propagation",
          "not_performed"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "resource_filter_policy_fields",
          resource_filter_policy_fields(),
          "must match ResourceFilter policy fields"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "resource_availability_aliases",
          resource_filter_availability_aliases(),
          "must match ResourceFilter resource availability aliases"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "resource_degraded_aliases",
          resource_filter_degraded_aliases(),
          "must match ResourceFilter resource degraded aliases"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "resource_margin_aliases",
          resource_filter_margin_aliases(),
          "must match ResourceFilter resource margin aliases"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "resource_power_margin_source_aliases",
          resource_filter_power_margin_source_aliases(),
          "must match ResourceFilter resource power margin source aliases"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "resource_availability_true_tokens",
          resource_filter_availability_true_tokens(),
          "must match ResourceFilter resource availability true tokens"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "resource_availability_false_tokens",
          resource_filter_availability_false_tokens(),
          "must match ResourceFilter resource availability false tokens"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "provider_direction_aliases",
          resource_filter_provider_direction_aliases(),
          "must match ResourceFilter provider direction aliases"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "station_calendar_direction_aliases",
          resource_filter_station_calendar_direction_aliases(),
          "must match ResourceFilter station calendar direction aliases"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "provider_result_map_value_keys",
          resource_filter_provider_result_map_value_keys(),
          "must match ResourceFilter provider result map value keys"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "candidate_stable_identity_fields",
          resource_filter_candidate_stable_identity_fields(),
          "must match ResourceFilter candidate stable identity fields"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "station_calendar_id_list_fields",
          resource_filter_station_calendar_id_list_fields(),
          "must match ResourceFilter station calendar ID list fields"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "suppression_reasons",
          resource_filter_suppression_reasons(),
          "must match ResourceFilter suppression reasons"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "row_review_statuses",
          resource_filter_row_review_statuses(),
          "must match ResourceFilter row review statuses"
        )

      _assumptions ->
        issues
    end
  end

  defp capability_value(key),
    do: OrbitalDynamics.ResourceFilter.capabilities() |> Map.fetch!(key)

  defp resource_filter_report_model_limits,
    do: :known_limits |> capability_value() |> Enum.map(&Atom.to_string/1)

  defp resource_filter_policy_fields, do: capability_value(:resource_filter_policy_fields)
  defp resource_filter_availability_aliases, do: capability_value(:resource_availability_aliases)
  defp resource_filter_degraded_aliases, do: capability_value(:resource_degraded_aliases)
  defp resource_filter_margin_aliases, do: capability_value(:resource_margin_aliases)

  defp resource_filter_power_margin_source_aliases,
    do: capability_value(:resource_power_margin_source_aliases)

  defp resource_filter_availability_true_tokens,
    do: capability_value(:resource_availability_true_tokens)

  defp resource_filter_availability_false_tokens,
    do: capability_value(:resource_availability_false_tokens)

  defp resource_filter_provider_direction_aliases,
    do: capability_value(:provider_direction_aliases)

  defp resource_filter_station_calendar_direction_aliases,
    do: capability_value(:station_calendar_direction_aliases)

  defp resource_filter_provider_result_map_value_keys,
    do: capability_value(:provider_result_map_value_keys)

  defp resource_filter_candidate_stable_identity_fields,
    do: capability_value(:candidate_stable_identity_fields)

  defp resource_filter_station_calendar_id_list_fields,
    do: capability_value(:station_calendar_id_list_fields)

  defp resource_filter_suppression_reasons, do: capability_value(:suppression_reasons)
  defp resource_filter_row_review_statuses, do: capability_value(:row_review_statuses)

  defp require_callback(callbacks, name), do: Keyword.fetch!(callbacks, name)

  defp require_fields(issues, callbacks, path, map, fields),
    do: apply(require_callback(callbacks, :require_fields), [issues, path, map, fields])

  defp expect_equal(issues, callbacks, path, map, field, expected),
    do: apply(require_callback(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_type(issues, callbacks, path, map, field, type),
    do: apply(require_callback(callbacks, :expect_type), [issues, path, map, field, type])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do:
      apply(require_callback(callbacks, :expect_optional_type), [issues, path, map, field, type])

  defp expect_non_negative_integer(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :expect_non_negative_integer), [issues, path, map, field])

  defp expect_optional_non_negative_integer(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :expect_optional_non_negative_integer), [
        issues,
        path,
        map,
        field
      ])

  defp validate_optional_stable_id_list(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :validate_optional_stable_id_list), [
        issues,
        path,
        map,
        field
      ])

  defp validate_optional_stable_id_array_map(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :validate_optional_stable_id_array_map), [
        issues,
        path,
        map,
        field
      ])

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :validate_string_list_items), [issues, path, map, field])

  defp validate_optional_exact_model_limits(issues, callbacks, path, map, limits, message),
    do:
      apply(require_callback(callbacks, :validate_optional_exact_model_limits), [
        issues,
        path,
        map,
        limits,
        message
      ])

  defp validate_optional_rows(issues, callbacks, path, rows, validator),
    do:
      apply(require_callback(callbacks, :validate_optional_rows), [issues, path, rows, validator])

  defp validate_rows(issues, callbacks, path, rows, validator),
    do: apply(require_callback(callbacks, :validate_rows), [issues, path, rows, validator])

  defp validate_invalid_resource_summary_input(callbacks, issues, path, row),
    do:
      apply(require_callback(callbacks, :validate_invalid_resource_summary_input), [
        issues,
        path,
        row
      ])

  defp validate_suppressed_candidate(callbacks, issues, path, candidate),
    do:
      apply(require_callback(callbacks, :validate_suppressed_candidate), [issues, path, candidate])

  defp validate_filter_report_counts(issues, callbacks, path, report, kind),
    do:
      apply(require_callback(callbacks, :validate_filter_report_counts), [
        issues,
        path,
        report,
        kind
      ])

  defp expect_optional_field_equals(issues, callbacks, path, map, field, expected, message),
    do:
      apply(require_callback(callbacks, :expect_optional_field_equals), [
        issues,
        path,
        map,
        field,
        expected,
        message
      ])
end
