defmodule OrbitalDynamics.Schema.ContactFilterReportContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.FilterReportCountContracts

  import OrbitalDynamics.Schema.CollectionValidation, only: [validate_rows: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_equal: 5,
      expect_non_negative_integer: 4,
      expect_optional_field_equals: 6,
      expect_optional_non_negative_integer: 4,
      expect_optional_type: 5,
      expect_type: 5,
      require_fields: 4,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [
      validate_optional_stable_id_list: 4,
      validate_stable_id_array_map: 3
    ]

  def validate(issues, path, report, suppressed_candidate_validator)
      when is_function(suppressed_candidate_validator, 3) do
    issues
    |> require_fields(path, report, [
      "schema_contract",
      "model",
      "input_candidate_count",
      "kept_candidate_count",
      "suppressed_candidate_count",
      "suppressed_candidates"
    ])
    |> expect_equal(path, report, "schema_contract", "contact_filter_report.v1")
    |> expect_equal(path, report, "model", "thin_ground_network_availability_filter")
    |> expect_non_negative_integer(path, report, "input_candidate_count")
    |> expect_non_negative_integer(path, report, "kept_candidate_count")
    |> expect_non_negative_integer(path, report, "suppressed_candidate_count")
    |> expect_optional_type(path, report, "policy", :map)
    |> expect_optional_type(path, report, "model_limits", :list)
    |> expect_optional_type(path, report, "assumptions", :map)
    |> expect_optional_non_negative_integer(
      path,
      report,
      "invalid_contact_input_count"
    )
    |> expect_optional_type(path, report, "invalid_contact_input_ids", :list)
    |> expect_optional_type(path, report, "suppression_reason_counts", :map)
    |> expect_optional_type(path, report, "suppressed_candidate_ids_by_reason", :map)
    |> expect_optional_type(
      path,
      report,
      "station_calendar_trust_boundary_status_counts",
      :map
    )
    |> expect_optional_type(
      path,
      report,
      "suppressed_candidate_ids_by_station_calendar_trust_boundary_status",
      :map
    )
    |> expect_optional_type(
      path,
      report,
      "station_reservation_match_status_counts",
      :map
    )
    |> expect_optional_type(
      path,
      report,
      "suppressed_candidate_ids_by_reservation_match_status",
      :map
    )
    |> expect_optional_non_negative_integer(
      path,
      report,
      "duplicate_suppressed_candidate_row_count"
    )
    |> expect_optional_non_negative_integer(
      path,
      report,
      "duplicate_suppressed_candidate_id_count"
    )
    |> expect_type(path, report, "suppressed_candidates", :list)
    |> validate_optional_stable_id_list(path, report, "invalid_contact_input_ids")
    |> validate_optional_stable_id_array_map(
      path,
      report,
      "suppressed_candidate_ids_by_reason"
    )
    |> validate_optional_stable_id_array_map(
      path,
      report,
      "suppressed_candidate_ids_by_station_calendar_trust_boundary_status"
    )
    |> validate_optional_stable_id_array_map(
      path,
      report,
      "suppressed_candidate_ids_by_reservation_match_status"
    )
    |> validate_string_list_items(path, report, "model_limits")
    |> validate_model_limits(path, report)
    |> validate_assumptions(path, report)
    |> validate_rows(
      path <> ".suppressed_candidates",
      Map.get(report, "suppressed_candidates", []),
      suppressed_candidate_validator
    )
    |> FilterReportCountContracts.validate_counts(path, report, "contact")
  end

  defp validate_model_limits(issues, path, report) do
    case Map.get(report, "model_limits") do
      nil ->
        issues

      :null ->
        issues

      limits when is_list(limits) ->
        if limits == contact_filter_report_model_limits() do
          issues
        else
          [
            error(
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

  defp validate_assumptions(issues, path, report) do
    case Map.get(report, "assumptions") do
      nil ->
        issues

      :null ->
        issues

      assumptions when is_map(assumptions) ->
        issues
        |> expect_equal(
          path <> ".assumptions",
          assumptions,
          "execution_boundary",
          "artifact_only_no_provider_reservation_or_schedule_mutation"
        )
        |> expect_equal(
          path <> ".assumptions",
          assumptions,
          "operator_authority",
          "not_granted_by_filter"
        )
        |> expect_optional_field_equals(
          path <> ".assumptions",
          assumptions,
          "suppressed_directions",
          contact_filter_suppressed_directions(),
          "must match ContactFilter suppressed directions"
        )
        |> expect_optional_field_equals(
          path <> ".assumptions",
          assumptions,
          "suppression_reasons",
          contact_filter_suppression_reasons(),
          "must match ContactFilter suppression reasons"
        )
        |> expect_optional_field_equals(
          path <> ".assumptions",
          assumptions,
          "station_unavailable_aliases",
          contact_filter_station_unavailable_aliases(),
          "must match ContactFilter station unavailable aliases"
        )
        |> expect_optional_field_equals(
          path <> ".assumptions",
          assumptions,
          "station_availability_precedence",
          contact_filter_station_availability_precedence(),
          "must match ContactFilter station availability precedence"
        )
        |> expect_optional_field_equals(
          path <> ".assumptions",
          assumptions,
          "station_capacity_value_paths",
          contact_filter_station_capacity_value_path_assumptions(),
          "must match ContactFilter station capacity value paths"
        )
        |> expect_optional_field_equals(
          path <> ".assumptions",
          assumptions,
          "contact_capacity_value_paths",
          contact_filter_contact_capacity_value_path_assumptions(),
          "must match ContactFilter contact capacity value paths"
        )
        |> expect_optional_field_equals(
          path <> ".assumptions",
          assumptions,
          "provider_direction_aliases",
          contact_filter_provider_direction_aliases(),
          "must match ContactFilter provider direction aliases"
        )

      _value ->
        issues
    end
  end

  defp contact_filter_report_model_limits,
    do: :known_limits |> capability_value() |> Enum.map(&Atom.to_string/1)

  defp contact_filter_suppressed_directions, do: capability_value(:suppressed_directions)
  defp contact_filter_suppression_reasons, do: capability_value(:suppression_reasons)

  defp contact_filter_station_unavailable_aliases,
    do: capability_value(:station_unavailable_aliases)

  defp contact_filter_station_availability_precedence,
    do: capability_value(:station_availability_precedence)

  defp contact_filter_station_capacity_value_path_assumptions,
    do: :station_capacity_value_paths |> capability_value() |> capacity_value_path_assumptions()

  defp contact_filter_contact_capacity_value_path_assumptions,
    do: :contact_capacity_value_paths |> capability_value() |> capacity_value_path_assumptions()

  defp contact_filter_provider_direction_aliases,
    do: capability_value(:provider_direction_aliases)

  defp capacity_value_path_assumptions(paths) do
    Enum.map(paths, fn %{unit: unit, path: path} ->
      %{"unit" => Atom.to_string(unit), "path" => path}
    end)
  end

  defp capability_value(key),
    do: OrbitalDynamics.Communications.ContactFilter.capabilities() |> Map.fetch!(key)

  defp validate_optional_stable_id_array_map(issues, path, report, field) do
    issues
    |> expect_optional_type(path, report, field, :map)
    |> validate_stable_id_array_map(path <> ".#{field}", Map.get(report, field))
  end
end
