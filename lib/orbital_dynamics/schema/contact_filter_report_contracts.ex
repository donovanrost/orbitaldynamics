defmodule OrbitalDynamics.Schema.ContactFilterReportContracts do
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
    |> expect_equal(callbacks, path, report, "schema_contract", "contact_filter_report.v1")
    |> expect_equal(callbacks, path, report, "model", "thin_ground_network_availability_filter")
    |> expect_non_negative_integer(callbacks, path, report, "input_candidate_count")
    |> expect_non_negative_integer(callbacks, path, report, "kept_candidate_count")
    |> expect_non_negative_integer(callbacks, path, report, "suppressed_candidate_count")
    |> expect_optional_type(callbacks, path, report, "policy", :map)
    |> expect_optional_type(callbacks, path, report, "model_limits", :list)
    |> expect_optional_type(callbacks, path, report, "assumptions", :map)
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      report,
      "invalid_contact_input_count"
    )
    |> expect_optional_type(callbacks, path, report, "invalid_contact_input_ids", :list)
    |> expect_optional_type(callbacks, path, report, "suppression_reason_counts", :map)
    |> expect_optional_type(callbacks, path, report, "suppressed_candidate_ids_by_reason", :map)
    |> expect_optional_type(
      callbacks,
      path,
      report,
      "station_calendar_trust_boundary_status_counts",
      :map
    )
    |> expect_optional_type(
      callbacks,
      path,
      report,
      "suppressed_candidate_ids_by_station_calendar_trust_boundary_status",
      :map
    )
    |> expect_optional_type(
      callbacks,
      path,
      report,
      "station_reservation_match_status_counts",
      :map
    )
    |> expect_optional_type(
      callbacks,
      path,
      report,
      "suppressed_candidate_ids_by_reservation_match_status",
      :map
    )
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
    |> expect_type(callbacks, path, report, "suppressed_candidates", :list)
    |> validate_optional_stable_id_list(callbacks, path, report, "invalid_contact_input_ids")
    |> validate_optional_stable_id_array_map(
      callbacks,
      path,
      report,
      "suppressed_candidate_ids_by_reason"
    )
    |> validate_optional_stable_id_array_map(
      callbacks,
      path,
      report,
      "suppressed_candidate_ids_by_station_calendar_trust_boundary_status"
    )
    |> validate_optional_stable_id_array_map(
      callbacks,
      path,
      report,
      "suppressed_candidate_ids_by_reservation_match_status"
    )
    |> validate_string_list_items(callbacks, path, report, "model_limits")
    |> validate_model_limits(callbacks, path, report)
    |> validate_assumptions(callbacks, path, report)
    |> validate_rows(
      callbacks,
      path <> ".suppressed_candidates",
      Map.get(report, "suppressed_candidates", []),
      fn acc, row_path, row -> validate_suppressed_candidate(callbacks, acc, row_path, row) end
    )
    |> validate_filter_report_counts(callbacks, path, report, "contact")
  end

  defp validate_model_limits(issues, callbacks, path, report) do
    case Map.get(report, "model_limits") do
      nil ->
        issues

      :null ->
        issues

      limits when is_list(limits) ->
        if limits == contact_filter_report_model_limits(callbacks) do
          issues
        else
          [
            error(
              callbacks,
              "#{path}.model_limits",
              "must match contact filter report model limits"
            )
            | issues
          ]
        end

      _value ->
        issues
    end
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
          "artifact_only_no_provider_reservation_or_schedule_mutation"
        )
        |> expect_equal(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "operator_authority",
          "not_granted_by_filter"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "suppressed_directions",
          contact_filter_suppressed_directions(callbacks),
          "must match ContactFilter suppressed directions"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "suppression_reasons",
          contact_filter_suppression_reasons(callbacks),
          "must match ContactFilter suppression reasons"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "station_unavailable_aliases",
          contact_filter_station_unavailable_aliases(callbacks),
          "must match ContactFilter station unavailable aliases"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "station_availability_precedence",
          contact_filter_station_availability_precedence(callbacks),
          "must match ContactFilter station availability precedence"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "station_capacity_value_paths",
          contact_filter_station_capacity_value_path_assumptions(callbacks),
          "must match ContactFilter station capacity value paths"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "contact_capacity_value_paths",
          contact_filter_contact_capacity_value_path_assumptions(callbacks),
          "must match ContactFilter contact capacity value paths"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "provider_direction_aliases",
          contact_filter_provider_direction_aliases(callbacks),
          "must match ContactFilter provider direction aliases"
        )

      _value ->
        issues
    end
  end

  defp require_callback(callbacks, name), do: Keyword.fetch!(callbacks, name)

  defp contact_filter_report_model_limits(callbacks),
    do: apply(require_callback(callbacks, :contact_filter_report_model_limits), [])

  defp contact_filter_suppressed_directions(callbacks),
    do: apply(require_callback(callbacks, :contact_filter_suppressed_directions), [])

  defp contact_filter_suppression_reasons(callbacks),
    do: apply(require_callback(callbacks, :contact_filter_suppression_reasons), [])

  defp contact_filter_station_unavailable_aliases(callbacks),
    do: apply(require_callback(callbacks, :contact_filter_station_unavailable_aliases), [])

  defp contact_filter_station_availability_precedence(callbacks),
    do: apply(require_callback(callbacks, :contact_filter_station_availability_precedence), [])

  defp contact_filter_station_capacity_value_path_assumptions(callbacks),
    do:
      apply(
        require_callback(callbacks, :contact_filter_station_capacity_value_path_assumptions),
        []
      )

  defp contact_filter_contact_capacity_value_path_assumptions(callbacks),
    do:
      apply(
        require_callback(callbacks, :contact_filter_contact_capacity_value_path_assumptions),
        []
      )

  defp contact_filter_provider_direction_aliases(callbacks),
    do: apply(require_callback(callbacks, :contact_filter_provider_direction_aliases), [])

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

  defp validate_rows(issues, callbacks, path, rows, validator),
    do: apply(require_callback(callbacks, :validate_rows), [issues, path, rows, validator])

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

  defp error(callbacks, path, message),
    do: apply(require_callback(callbacks, :error), [path, message])
end
