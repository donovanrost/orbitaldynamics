defmodule OrbitalDynamics.Schema.ContactContentionReportContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.ExecutionMetricContracts
  alias OrbitalDynamics.Schema.PriorityOverrideContracts

  import OrbitalDynamics.Schema.CollectionValidation,
    only: [
      validate_ids_match_row_multiset: 6,
      validate_optional_rows: 4,
      validate_rows: 4
    ]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_equal: 5,
      expect_field_at_least: 5,
      expect_field_equals: 6,
      expect_non_negative_integer: 4,
      expect_number: 4,
      expect_optional_field_equals: 6,
      expect_optional_integer: 4,
      expect_optional_non_negative_integer: 4,
      expect_optional_number: 4,
      expect_optional_one_of: 5,
      expect_optional_probability: 4,
      expect_optional_type: 5,
      expect_type: 5,
      require_fields: 4,
      validate_number_list_items: 4,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [
      reject_duplicate_ids: 3,
      validate_optional_stable_id_list: 4,
      validate_stable_id_list: 3,
      validate_stable_ids: 4
    ]

  def validate_report(issues, path, report) do
    issues
    |> require_fields(path, report, [
      "schema_contract",
      "model",
      "input_contact_count",
      "conflicted_contact_count",
      "conflict_group_count",
      "conflict_groups"
    ])
    |> expect_equal(path, report, "schema_contract", "contact_contention_report.v1")
    |> expect_equal(path, report, "model", "single_station_interval_overlap")
    |> expect_non_negative_integer(path, report, "input_contact_count")
    |> expect_non_negative_integer(path, report, "conflicted_contact_count")
    |> expect_non_negative_integer(path, report, "conflict_group_count")
    |> expect_type(path, report, "conflict_groups", :list)
    |> expect_optional_type(path, report, "assumptions", :map)
    |> expect_optional_type(path, report, "provenance", :map)
    |> expect_optional_type(path, report, "model_limits", :list)
    |> expect_optional_non_negative_integer(
      path,
      report,
      "duplicate_contact_candidate_count"
    )
    |> expect_optional_non_negative_integer(path, report, "duplicate_contact_id_count")
    |> expect_optional_non_negative_integer(
      path,
      report,
      "invalid_contact_input_count"
    )
    |> expect_optional_type(path, report, "invalid_contact_input_ids", :list)
    |> validate_optional_stable_id_list(path, report, "invalid_contact_input_ids")
    |> validate_string_list_items(path, report, "model_limits")
    |> validate_report_model_limits(path, report)
    |> validate_report_assumptions(path, report)
    |> validate_optional_rows(
      path <> ".invalid_contact_inputs",
      Map.get(report, "invalid_contact_inputs"),
      fn acc, row_path, row -> validate_invalid_contact_input(acc, row_path, row) end
    )
    |> validate_rows(
      path <> ".conflict_groups",
      Map.get(report, "conflict_groups", []),
      fn acc, row_path, row -> validate_group(acc, row_path, row) end
    )
    |> validate_report_counts(path, report)
  end

  def validate_group(issues, path, group) do
    issues
    |> require_fields(path, group, [
      "id",
      "ground_station_id",
      "contact_count",
      "starts_at_s",
      "ends_at_s",
      "direction",
      "required_operator_action",
      "approval_status",
      "contact_ids",
      "source_window_ids",
      "scenario_ids"
    ])
    |> validate_stable_ids(path, group, ["id", "ground_station_id", "spacecraft_id"])
    |> expect_optional_type(path, group, "resource_scope", :binary)
    |> expect_optional_type(path, group, "directions", :list)
    |> validate_string_list_items(path, group, "directions")
    |> expect_optional_type(path, group, "ground_station_ids", :list)
    |> validate_optional_stable_id_list(path, group, "ground_station_ids")
    |> expect_optional_type(path, group, "spacecraft_ids", :list)
    |> validate_optional_stable_id_list(path, group, "spacecraft_ids")
    |> expect_non_negative_integer(path, group, "contact_count")
    |> expect_number(path, group, "starts_at_s")
    |> expect_number(path, group, "ends_at_s")
    |> expect_optional_number(path, group, "contention_window_s")
    |> expect_optional_number(path, group, "total_contact_duration_s")
    |> expect_optional_number(path, group, "overlap_duration_s")
    |> expect_optional_non_negative_integer(path, group, "max_concurrent_contacts")
    |> expect_optional_non_negative_integer(path, group, "overlap_contact_pair_count")
    |> expect_type(path, group, "direction", :binary)
    |> expect_type(path, group, "required_operator_action", :binary)
    |> expect_type(path, group, "approval_status", :binary)
    |> expect_optional_one_of(path, group, "review_status", [
      "operator_review_required",
      "review_required",
      "pending_operator_review",
      "ready_for_review"
    ])
    |> expect_optional_type(path, group, "operator_action_reason", :binary)
    |> expect_optional_number(path, group, "actual_throughput_mb")
    |> expect_optional_type(
      path,
      group,
      "actual_data_rate_throughput_derivations",
      :list
    )
    |> ExecutionMetricContracts.validate_optional_actual_data_rate_throughput_derivations(
      path,
      group,
      "actual_data_rate_throughput_derivations"
    )
    |> expect_optional_type(path, group, "station_availability", :binary)
    |> expect_optional_type(path, group, "station_calendar_status", :binary)
    |> expect_optional_type(
      path,
      group,
      "station_calendar_reservation_expires_at_s",
      :list
    )
    |> validate_number_list_items(
      path,
      group,
      "station_calendar_reservation_expires_at_s"
    )
    |> expect_optional_probability(path, group, "capacity_fraction")
    |> expect_optional_probability(path, group, "capacity_fraction_min")
    |> expect_optional_probability(path, group, "capacity_fraction_max")
    |> expect_type(path, group, "contact_ids", :list)
    |> expect_type(path, group, "source_window_ids", :list)
    |> expect_type(path, group, "scenario_ids", :list)
    |> expect_optional_non_negative_integer(
      path,
      group,
      "duplicate_contact_candidate_count"
    )
    |> expect_optional_non_negative_integer(path, group, "duplicate_contact_id_count")
    |> expect_optional_type(path, group, "duplicate_contact_ids", :list)
    |> validate_optional_stable_id_list(path, group, "duplicate_contact_ids")
    |> expect_optional_type(path, group, "source_contact_candidates", :list)
    |> validate_optional_rows(
      path <> ".source_contact_candidates",
      Map.get(group, "source_contact_candidates"),
      fn acc, row_path, row ->
        validate_source_contact_candidate(acc, row_path, row)
      end
    )
    |> expect_field_equals(
      path,
      group,
      "contact_count",
      list_count(group, "contact_ids")
    )
    |> expect_field_equals(
      path,
      group,
      "duplicate_contact_id_count",
      list_count(group, "duplicate_contact_ids")
    )
  end

  def validate_resolution_report(issues, path, report) do
    issues
    |> require_fields(path, report, [
      "schema_contract",
      "model",
      "policy",
      "conflict_group_count",
      "recommendation_count",
      "recommendations"
    ])
    |> expect_equal(
      path,
      report,
      "schema_contract",
      "contact_contention_resolution_report.v1"
    )
    |> expect_equal(
      path,
      report,
      "model",
      "deterministic_contact_contention_recommendation"
    )
    |> expect_type(path, report, "policy", :map)
    |> validate_resolution_policy(path <> ".policy", Map.get(report, "policy"))
    |> expect_non_negative_integer(path, report, "conflict_group_count")
    |> expect_non_negative_integer(path, report, "recommendation_count")
    |> expect_type(path, report, "recommendations", :list)
    |> expect_optional_type(path, report, "assumptions", :map)
    |> expect_optional_type(path, report, "model_limits", :list)
    |> validate_string_list_items(path, report, "model_limits")
    |> validate_resolution_report_model_limits(path, report)
    |> validate_rows(
      path <> ".recommendations",
      Map.get(report, "recommendations", []),
      fn acc, row_path, row -> validate_recommendation(acc, row_path, row) end
    )
    |> validate_resolution_report_counts(path, report)
  end

  def validate_recommendation(issues, path, recommendation) do
    issues
    |> require_fields(path, recommendation, [
      "group_id",
      "ground_station_id",
      "starts_at_s",
      "ends_at_s",
      "deferred_contact_ids",
      "candidate_count",
      "selection_reason",
      "action",
      "review_status"
    ])
    |> validate_stable_ids(path, recommendation, [
      "group_id",
      "ground_station_id",
      "spacecraft_id",
      "selected_contact_id",
      "selected_scenario_id"
    ])
    |> expect_optional_type(path, recommendation, "resource_scope", :binary)
    |> expect_optional_type(path, recommendation, "direction", :binary)
    |> expect_optional_type(path, recommendation, "directions", :list)
    |> validate_string_list_items(path, recommendation, "directions")
    |> expect_optional_type(path, recommendation, "ground_station_ids", :list)
    |> validate_optional_stable_id_list(path, recommendation, "ground_station_ids")
    |> expect_optional_type(path, recommendation, "spacecraft_ids", :list)
    |> validate_optional_stable_id_list(path, recommendation, "spacecraft_ids")
    |> expect_number(path, recommendation, "starts_at_s")
    |> expect_number(path, recommendation, "ends_at_s")
    |> expect_type(path, recommendation, "deferred_contact_ids", :list)
    |> expect_non_negative_integer(path, recommendation, "candidate_count")
    |> expect_optional_type(path, recommendation, "source_contact_candidates", :list)
    |> validate_optional_rows(
      path <> ".source_contact_candidates",
      Map.get(recommendation, "source_contact_candidates"),
      fn acc, row_path, row ->
        validate_source_contact_candidate(acc, row_path, row)
      end
    )
    |> expect_optional_number(path, recommendation, "contention_window_s")
    |> expect_optional_number(path, recommendation, "total_contact_duration_s")
    |> expect_optional_number(path, recommendation, "overlap_duration_s")
    |> expect_optional_non_negative_integer(
      path,
      recommendation,
      "max_concurrent_contacts"
    )
    |> expect_optional_non_negative_integer(
      path,
      recommendation,
      "overlap_contact_pair_count"
    )
    |> expect_optional_number(path, recommendation, "selected_priority")
    |> expect_optional_type(path, recommendation, "selected_priority_source", :binary)
    |> expect_optional_number(path, recommendation, "actual_throughput_mb")
    |> expect_optional_type(
      path,
      recommendation,
      "actual_data_rate_throughput_derivations",
      :list
    )
    |> expect_optional_type(path, recommendation, "station_availability", :binary)
    |> expect_optional_type(path, recommendation, "station_calendar_status", :binary)
    |> expect_optional_type(
      path,
      recommendation,
      "station_calendar_reservation_expires_at_s",
      :list
    )
    |> validate_number_list_items(
      path,
      recommendation,
      "station_calendar_reservation_expires_at_s"
    )
    |> expect_optional_probability(path, recommendation, "capacity_fraction")
    |> expect_optional_probability(path, recommendation, "capacity_fraction_min")
    |> expect_optional_probability(path, recommendation, "capacity_fraction_max")
    |> expect_optional_type(path, recommendation, "deferred_contact_priorities", :list)
    |> validate_optional_rows(
      path <> ".deferred_contact_priorities",
      Map.get(recommendation, "deferred_contact_priorities"),
      fn acc, row_path, row -> validate_deferred_priority(acc, row_path, row) end
    )
    |> expect_optional_type(path, recommendation, "resolution_selection_rule", :binary)
    |> expect_optional_type(path, recommendation, "resolution_priority_fields", :list)
    |> validate_string_list_items(path, recommendation, "resolution_priority_fields")
    |> expect_optional_type(path, recommendation, "requested_priority_fields", :list)
    |> validate_string_list_items(path, recommendation, "requested_priority_fields")
    |> expect_optional_type(
      path,
      recommendation,
      "priority_field_evidence_counts",
      :map
    )
    |> PriorityOverrideContracts.validate_field_evidence_counts(
      path <> ".priority_field_evidence_counts",
      Map.get(recommendation, "priority_field_evidence_counts")
    )
    |> expect_optional_integer(
      path,
      recommendation,
      "priority_fields_without_numeric_evidence_count"
    )
    |> expect_field_at_least(
      path,
      recommendation,
      "priority_fields_without_numeric_evidence_count",
      0
    )
    |> expect_optional_type(
      path,
      recommendation,
      "priority_fields_without_numeric_evidence",
      :list
    )
    |> validate_string_list_items(
      path,
      recommendation,
      "priority_fields_without_numeric_evidence"
    )
    |> expect_optional_type(path, recommendation, "resolution_tie_breakers", :list)
    |> validate_string_list_items(path, recommendation, "resolution_tie_breakers")
    |> expect_optional_integer(
      path,
      recommendation,
      "resolution_priority_override_count"
    )
    |> expect_field_at_least(
      path,
      recommendation,
      "resolution_priority_override_count",
      0
    )
    |> expect_optional_type(
      path,
      recommendation,
      "resolution_priority_override_contact_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      path,
      recommendation,
      "resolution_priority_override_contact_ids"
    )
    |> PriorityOverrideContracts.validate_count_matches_ids(
      path,
      recommendation,
      "resolution_priority_override_count",
      "resolution_priority_override_contact_ids"
    )
    |> expect_optional_integer(path, recommendation, "ignored_priority_override_count")
    |> expect_field_at_least(
      path,
      recommendation,
      "ignored_priority_override_count",
      0
    )
    |> expect_optional_type(
      path,
      recommendation,
      "ignored_priority_override_keys",
      :list
    )
    |> validate_string_list_items(
      path,
      recommendation,
      "ignored_priority_override_keys"
    )
    |> expect_optional_type(
      path,
      recommendation,
      "ignored_priority_override_contact_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      path,
      recommendation,
      "ignored_priority_override_contact_ids"
    )
    |> expect_optional_type(
      path,
      recommendation,
      "ignored_priority_override_input",
      :binary
    )
    |> PriorityOverrideContracts.validate_count_matches_ids(
      path,
      recommendation,
      "ignored_priority_override_count",
      "ignored_priority_override_keys"
    )
    |> expect_optional_type(path, recommendation, "requested_selection_rule", :binary)
    |> expect_optional_type(path, recommendation, "ignored_tie_breakers", :list)
    |> validate_string_list_items(path, recommendation, "ignored_tie_breakers")
    |> expect_optional_type(path, recommendation, "ignored_policy_input", :binary)
    |> expect_optional_type(path, recommendation, "policy_warnings", :list)
    |> validate_string_list_items(path, recommendation, "policy_warnings")
    |> validate_recommendation_counts(path, recommendation)
    |> validate_recommendation_identity(path, recommendation)
    |> validate_recommendation_duplicate_evidence(path, recommendation)
  end

  def validate_source_contact_candidate(issues, path, candidate) do
    issues
    |> validate_stable_ids(path, candidate, [
      "id",
      "scenario_id",
      "source_window_id",
      "ground_station_id",
      "spacecraft_id"
    ])
    |> expect_optional_type(path, candidate, "type", :binary)
    |> expect_optional_type(path, candidate, "direction", :binary)
    |> expect_optional_number(path, candidate, "starts_at_s")
    |> expect_optional_number(path, candidate, "ends_at_s")
    |> expect_optional_number(path, candidate, "score")
  end

  def validate_resolution_policy(issues, path, policy) when is_map(policy) do
    issues
    |> expect_optional_type(path, policy, "selection_rule", :binary)
    |> expect_optional_type(path, policy, "priority_fields", :list)
    |> validate_string_list_items(path, policy, "priority_fields")
    |> expect_optional_type(path, policy, "requested_priority_fields", :list)
    |> validate_string_list_items(path, policy, "requested_priority_fields")
    |> expect_optional_type(path, policy, "tie_breakers", :list)
    |> validate_string_list_items(path, policy, "tie_breakers")
    |> expect_optional_type(path, policy, "action", :binary)
    |> expect_optional_type(path, policy, "requested_selection_rule", :binary)
    |> expect_optional_type(path, policy, "ignored_tie_breakers", :list)
    |> validate_string_list_items(path, policy, "ignored_tie_breakers")
    |> expect_optional_type(path, policy, "ignored_policy_input", :binary)
    |> expect_optional_type(path, policy, "policy_warnings", :list)
    |> validate_string_list_items(path, policy, "policy_warnings")
    |> expect_optional_type(path, policy, "priority_overrides", :map)
    |> PriorityOverrideContracts.validate_map(
      path <> ".priority_overrides",
      Map.get(policy, "priority_overrides")
    )
    |> expect_optional_integer(path, policy, "priority_override_count")
    |> expect_field_at_least(path, policy, "priority_override_count", 0)
    |> expect_optional_type(path, policy, "priority_override_contact_ids", :list)
    |> validate_optional_stable_id_list(path, policy, "priority_override_contact_ids")
    |> PriorityOverrideContracts.validate_count_matches_ids(
      path,
      policy,
      "priority_override_count",
      "priority_override_contact_ids"
    )
    |> expect_optional_integer(path, policy, "ignored_priority_override_count")
    |> expect_field_at_least(path, policy, "ignored_priority_override_count", 0)
    |> expect_optional_type(path, policy, "ignored_priority_override_keys", :list)
    |> validate_string_list_items(path, policy, "ignored_priority_override_keys")
    |> expect_optional_type(
      path,
      policy,
      "ignored_priority_override_contact_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      path,
      policy,
      "ignored_priority_override_contact_ids"
    )
    |> expect_optional_type(path, policy, "ignored_priority_override_input", :binary)
    |> PriorityOverrideContracts.validate_count_matches_ids(
      path,
      policy,
      "ignored_priority_override_count",
      "ignored_priority_override_keys"
    )
    |> PriorityOverrideContracts.validate_ids_match_map(path, policy)
  end

  def validate_resolution_policy(issues, _path, _policy),
    do: issues

  def validate_deferred_priority(issues, path, row) do
    issues
    |> validate_stable_ids(path, row, ["contact_id"])
    |> expect_optional_number(path, row, "priority")
    |> expect_optional_type(path, row, "priority_source", :binary)
  end

  defp validate_recommendation_duplicate_evidence(issues, path, recommendation) do
    if Map.get(recommendation, "resolution_issue") == "duplicate_contact_id" or
         Map.has_key?(recommendation, "duplicate_contact_ids") do
      issues
      |> require_fields(path, recommendation, ["duplicate_contact_candidates"])
      |> expect_field_equals(
        path,
        recommendation,
        "duplicate_contact_id_count",
        list_count(recommendation, "duplicate_contact_ids")
      )
      |> expect_field_equals(
        path,
        recommendation,
        "duplicate_contact_candidate_count",
        list_count(recommendation, "duplicate_contact_candidates")
      )
      |> validate_stable_id_list(
        path <> ".duplicate_contact_ids",
        Map.get(recommendation, "duplicate_contact_ids")
      )
    else
      issues
    end
  end

  defp validate_report_model_limits(issues, path, report) do
    case Map.get(report, "model_limits") do
      nil ->
        issues

      :null ->
        issues

      limits when is_list(limits) ->
        if limits == report_model_limits() do
          issues
        else
          [
            error(
              "#{path}.model_limits",
              "must match contact contention report model limits"
            )
            | issues
          ]
        end

      _value ->
        issues
    end
  end

  defp validate_resolution_report_model_limits(issues, path, report) do
    case Map.get(report, "model_limits") do
      nil ->
        issues

      :null ->
        issues

      limits when is_list(limits) ->
        if limits == report_model_limits() do
          issues
        else
          [
            error(
              "#{path}.model_limits",
              "must match contact contention resolution report model limits"
            )
            | issues
          ]
        end

      _value ->
        issues
    end
  end

  defp validate_report_assumptions(issues, path, report) do
    case Map.get(report, "assumptions") do
      nil ->
        issues

      :null ->
        issues

      assumptions when is_map(assumptions) ->
        issues
        |> expect_optional_field_equals(
          path <> ".assumptions",
          assumptions,
          "contact_types",
          contact_types(),
          "must match ContactContention contact types"
        )
        |> expect_optional_field_equals(
          path <> ".assumptions",
          assumptions,
          "contact_directions",
          contact_directions(),
          "must match ContactContention contact directions"
        )
        |> expect_optional_field_equals(
          path <> ".assumptions",
          assumptions,
          "row_review_statuses",
          row_review_statuses(),
          "must match ContactContention row review statuses"
        )
        |> expect_optional_field_equals(
          path <> ".assumptions",
          assumptions,
          "station_unavailable_aliases",
          station_unavailable_aliases(),
          "must match ContactContention station unavailable aliases"
        )
        |> expect_optional_field_equals(
          path <> ".assumptions",
          assumptions,
          "station_availability_precedence",
          station_availability_precedence(),
          "must match ContactContention station availability precedence"
        )
        |> expect_optional_field_equals(
          path <> ".assumptions",
          assumptions,
          "station_capacity_value_paths",
          station_capacity_value_path_assumptions(),
          "must match ContactContention station capacity value paths"
        )
        |> expect_optional_field_equals(
          path <> ".assumptions",
          assumptions,
          "source_station_capacity_value_paths",
          source_station_capacity_value_path_assumptions(),
          "must match ContactContention source station capacity value paths"
        )
        |> expect_optional_field_equals(
          path <> ".assumptions",
          assumptions,
          "required_capacity_value_paths",
          required_capacity_value_path_assumptions(),
          "must match ContactContention required capacity value paths"
        )
        |> expect_optional_field_equals(
          path <> ".assumptions",
          assumptions,
          "required_capacity_fraction_source_values",
          required_capacity_fraction_source_values(),
          "must match ContactContention required capacity fraction source values"
        )
        |> expect_optional_field_equals(
          path <> ".assumptions",
          assumptions,
          "station_reservation_priority_match_statuses",
          station_reservation_priority_match_statuses(),
          "must match ContactContention station reservation priority match statuses"
        )
        |> expect_optional_field_equals(
          path <> ".assumptions",
          assumptions,
          "station_reservation_priority_statuses",
          station_reservation_priority_statuses(),
          "must match ContactContention station reservation priority statuses"
        )
        |> expect_optional_field_equals(
          path <> ".assumptions",
          assumptions,
          "resolution_selection_rules",
          resolution_selection_rules(),
          "must match ContactContention resolution selection rules"
        )
        |> expect_optional_field_equals(
          path <> ".assumptions",
          assumptions,
          "resolution_tie_breakers",
          resolution_tie_breakers(),
          "must match ContactContention resolution tie breakers"
        )
        |> expect_optional_field_equals(
          path <> ".assumptions",
          assumptions,
          "default_resolution_priority_fields",
          default_resolution_priority_fields(),
          "must match ContactContention default resolution priority fields"
        )
        |> expect_optional_field_equals(
          path <> ".assumptions",
          assumptions,
          "resolution_priority_override_aliases",
          resolution_priority_override_aliases(),
          "must match ContactContention resolution priority override aliases"
        )
        |> expect_optional_field_equals(
          path <> ".assumptions",
          assumptions,
          "provider_direction_aliases",
          provider_direction_aliases(),
          "must match ContactContention provider direction aliases"
        )
        |> expect_optional_field_equals(
          path <> ".assumptions",
          assumptions,
          "provider_result_map_value_keys",
          provider_result_map_value_keys(),
          "must match ContactContention provider result map value keys"
        )
        |> expect_optional_field_equals(
          path <> ".assumptions",
          assumptions,
          "contact_stable_identity_fields",
          contact_stable_identity_fields(),
          "must match ContactContention contact stable identity fields"
        )
        |> expect_optional_field_equals(
          path <> ".assumptions",
          assumptions,
          "command_contact_directions",
          command_contact_directions(),
          "must match ContactContention command contact directions"
        )

      _assumptions ->
        issues
    end
  end

  defp validate_report_counts(issues, path, report) do
    groups =
      report
      |> Map.get("conflict_groups", [])
      |> Enum.filter(&is_map/1)

    invalid_rows =
      report
      |> Map.get("invalid_contact_inputs", [])
      |> case do
        rows when is_list(rows) -> Enum.filter(rows, &is_map/1)
        _rows -> []
      end

    issues
    |> expect_field_equals(path, report, "conflict_group_count", length(groups))
    |> expect_field_equals(
      path,
      report,
      "conflicted_contact_count",
      sum_row_numbers(groups, "contact_count"),
      "must equal row-derived conflicted contact count"
    )
    |> expect_field_equals(
      path,
      report,
      "duplicate_contact_id_count",
      groups
      |> Enum.flat_map(&Map.get(&1, "duplicate_contact_ids", []))
      |> Enum.uniq()
      |> length(),
      "must equal row-derived duplicate contact ID count"
    )
    |> expect_field_equals(
      path,
      report,
      "duplicate_contact_candidate_count",
      sum_row_numbers(groups, "duplicate_contact_candidate_count"),
      "must equal row-derived duplicate contact candidate count"
    )
    |> expect_field_equals(
      path,
      report,
      "invalid_contact_input_count",
      length(invalid_rows)
    )
    |> validate_ids_match_row_multiset(
      path,
      report,
      "invalid_contact_input_ids",
      Enum.map(invalid_rows, &Map.get(&1, "contact_id")),
      "must equal row-derived invalid_contact_input_ids"
    )
  end

  defp validate_resolution_report_counts(issues, path, report) do
    recommendations =
      report
      |> Map.get("recommendations", [])
      |> Enum.filter(&is_map/1)

    issues
    |> expect_field_equals(
      path,
      report,
      "recommendation_count",
      length(recommendations)
    )
    |> expect_field_equals(
      path,
      report,
      "conflict_group_count",
      length(recommendations),
      "must equal recommendation_count for one recommendation per contention group"
    )
  end

  defp validate_recommendation_counts(issues, path, recommendation) do
    issues
    |> expect_field_equals(
      path,
      recommendation,
      "candidate_count",
      list_count(recommendation, "source_contact_candidates"),
      "must equal source_contact_candidates count"
    )
    |> expect_field_equals(
      path,
      recommendation,
      "candidate_count",
      selected_deferred_candidate_count(recommendation),
      "must equal selected plus deferred contact count"
    )
  end

  defp validate_recommendation_identity(
         issues,
         path,
         %{
           "selected_contact_id" => selected_contact_id,
           "deferred_contact_ids" => deferred_contact_ids,
           "source_contact_candidates" => source_contact_candidates
         }
       )
       when is_binary(selected_contact_id) and is_list(deferred_contact_ids) and
              is_list(source_contact_candidates) do
    decision_ids = [selected_contact_id | deferred_contact_ids]

    candidate_ids =
      Enum.map(source_contact_candidates, fn
        %{} = candidate -> Map.get(candidate, "id")
        _candidate -> nil
      end)

    issues
    |> reject_duplicate_ids(path <> ".deferred_contact_ids", decision_ids)
    |> validate_recommendation_candidate_ids(path, decision_ids, candidate_ids)
  end

  defp validate_recommendation_identity(issues, _path, _recommendation), do: issues

  defp validate_recommendation_candidate_ids(issues, path, decision_ids, candidate_ids) do
    if Enum.sort(decision_ids) == Enum.sort(candidate_ids) do
      issues
    else
      [
        error(
          path <> ".source_contact_candidates",
          "contact IDs must match selected_contact_id plus deferred_contact_ids"
        )
        | issues
      ]
    end
  end

  defp selected_deferred_candidate_count(%{
         "selected_contact_id" => selected_contact_id,
         "deferred_contact_ids" => deferred_contact_ids
       })
       when is_binary(selected_contact_id) and is_list(deferred_contact_ids) do
    1 + length(deferred_contact_ids)
  end

  defp selected_deferred_candidate_count(_recommendation), do: nil

  defp list_count(map, field) do
    case Map.get(map, field) do
      list when is_list(list) -> length(list)
      _value -> nil
    end
  end

  defp sum_row_numbers(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reduce(0, fn
      value, acc when is_number(value) -> acc + value
      _value, acc -> acc
    end)
  end

  defp capability_value(key),
    do: OrbitalDynamics.Communications.ContactContention.capabilities() |> Map.fetch!(key)

  defp report_model_limits, do: :known_limits |> capability_value() |> Enum.map(&Atom.to_string/1)
  defp contact_types, do: capability_value(:contact_types)
  defp contact_directions, do: capability_value(:contact_directions)
  defp row_review_statuses, do: capability_value(:row_review_statuses)
  defp station_unavailable_aliases, do: capability_value(:station_unavailable_aliases)
  defp station_availability_precedence, do: capability_value(:station_availability_precedence)

  defp station_capacity_value_path_assumptions,
    do: :station_capacity_value_paths |> capability_value() |> capacity_value_path_assumptions()

  defp source_station_capacity_value_path_assumptions,
    do:
      :source_station_capacity_value_paths
      |> capability_value()
      |> capacity_value_path_assumptions()

  defp required_capacity_value_path_assumptions,
    do: :required_capacity_value_paths |> capability_value() |> capacity_value_path_assumptions()

  defp capacity_value_path_assumptions(paths) do
    Enum.map(paths, fn %{unit: unit, path: path} ->
      %{"unit" => Atom.to_string(unit), "path" => path}
    end)
  end

  defp required_capacity_fraction_source_values,
    do: capability_value(:required_capacity_fraction_source_values)

  defp station_reservation_priority_match_statuses,
    do: capability_value(:station_reservation_priority_match_statuses)

  defp station_reservation_priority_statuses,
    do: capability_value(:station_reservation_priority_statuses)

  defp resolution_selection_rules, do: capability_value(:resolution_selection_rules)
  defp resolution_tie_breakers, do: capability_value(:resolution_tie_breakers)

  defp default_resolution_priority_fields,
    do: capability_value(:default_resolution_priority_fields)

  defp resolution_priority_override_aliases,
    do: capability_value(:resolution_priority_override_aliases)

  defp provider_direction_aliases, do: capability_value(:provider_direction_aliases)
  defp provider_result_map_value_keys, do: capability_value(:provider_result_map_value_keys)
  defp contact_stable_identity_fields, do: capability_value(:contact_stable_identity_fields)
  defp command_contact_directions, do: capability_value(:command_contact_directions)

  defp expect_field_equals(issues, path, map, field, nil),
    do: expect_field_equals(issues, path, map, field, nil, nil)

  defp expect_field_equals(issues, path, map, field, expected),
    do: expect_field_equals(issues, path, map, field, expected, "must equal #{expected}")

  defp validate_invalid_contact_input(issues, path, row) do
    expect_optional_one_of(issues, path, row, "review_status", [
      "operator_review_required",
      "review_required",
      "pending_operator_review",
      "ready_for_review"
    ])
  end
end
