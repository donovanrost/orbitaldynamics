defmodule OrbitalDynamics.Schema.ContactContentionReportContracts do
  @moduledoc false

  def validate_report(issues, path, report, callbacks) when is_list(callbacks) do
    issues
    |> require_fields(callbacks, path, report, [
      "schema_contract",
      "model",
      "input_contact_count",
      "conflicted_contact_count",
      "conflict_group_count",
      "conflict_groups"
    ])
    |> expect_equal(callbacks, path, report, "schema_contract", "contact_contention_report.v1")
    |> expect_equal(callbacks, path, report, "model", "single_station_interval_overlap")
    |> expect_non_negative_integer(callbacks, path, report, "input_contact_count")
    |> expect_non_negative_integer(callbacks, path, report, "conflicted_contact_count")
    |> expect_non_negative_integer(callbacks, path, report, "conflict_group_count")
    |> expect_type(callbacks, path, report, "conflict_groups", :list)
    |> expect_optional_type(callbacks, path, report, "assumptions", :map)
    |> expect_optional_type(callbacks, path, report, "provenance", :map)
    |> expect_optional_type(callbacks, path, report, "model_limits", :list)
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      report,
      "duplicate_contact_candidate_count"
    )
    |> expect_optional_non_negative_integer(callbacks, path, report, "duplicate_contact_id_count")
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      report,
      "invalid_contact_input_count"
    )
    |> expect_optional_type(callbacks, path, report, "invalid_contact_input_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, report, "invalid_contact_input_ids")
    |> validate_string_list_items(callbacks, path, report, "model_limits")
    |> validate_report_model_limits(callbacks, path, report)
    |> validate_report_assumptions(callbacks, path, report)
    |> validate_optional_rows(
      callbacks,
      path <> ".invalid_contact_inputs",
      Map.get(report, "invalid_contact_inputs"),
      fn acc, row_path, row -> validate_invalid_contact_input(callbacks, acc, row_path, row) end
    )
    |> validate_rows(
      callbacks,
      path <> ".conflict_groups",
      Map.get(report, "conflict_groups", []),
      fn acc, row_path, row -> validate_group(acc, row_path, row, callbacks) end
    )
    |> validate_report_counts(callbacks, path, report)
  end

  def validate_group(issues, path, group, callbacks) when is_list(callbacks) do
    issues
    |> require_fields(callbacks, path, group, [
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
    |> validate_stable_ids(callbacks, path, group, ["id", "ground_station_id", "spacecraft_id"])
    |> expect_optional_type(callbacks, path, group, "resource_scope", :binary)
    |> expect_optional_type(callbacks, path, group, "directions", :list)
    |> validate_string_list_items(callbacks, path, group, "directions")
    |> expect_optional_type(callbacks, path, group, "ground_station_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, group, "ground_station_ids")
    |> expect_optional_type(callbacks, path, group, "spacecraft_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, group, "spacecraft_ids")
    |> expect_non_negative_integer(callbacks, path, group, "contact_count")
    |> expect_number(callbacks, path, group, "starts_at_s")
    |> expect_number(callbacks, path, group, "ends_at_s")
    |> expect_optional_number(callbacks, path, group, "contention_window_s")
    |> expect_optional_number(callbacks, path, group, "total_contact_duration_s")
    |> expect_optional_number(callbacks, path, group, "overlap_duration_s")
    |> expect_optional_non_negative_integer(callbacks, path, group, "max_concurrent_contacts")
    |> expect_optional_non_negative_integer(callbacks, path, group, "overlap_contact_pair_count")
    |> expect_type(callbacks, path, group, "direction", :binary)
    |> expect_type(callbacks, path, group, "required_operator_action", :binary)
    |> expect_type(callbacks, path, group, "approval_status", :binary)
    |> expect_optional_one_of(callbacks, path, group, "review_status", [
      "operator_review_required",
      "review_required",
      "pending_operator_review",
      "ready_for_review"
    ])
    |> expect_optional_type(callbacks, path, group, "operator_action_reason", :binary)
    |> expect_optional_number(callbacks, path, group, "actual_throughput_mb")
    |> expect_optional_type(
      callbacks,
      path,
      group,
      "actual_data_rate_throughput_derivations",
      :list
    )
    |> validate_optional_actual_data_rate_throughput_derivations(
      callbacks,
      path,
      group,
      "actual_data_rate_throughput_derivations"
    )
    |> expect_optional_type(callbacks, path, group, "station_availability", :binary)
    |> expect_optional_type(callbacks, path, group, "station_calendar_status", :binary)
    |> expect_optional_type(
      callbacks,
      path,
      group,
      "station_calendar_reservation_expires_at_s",
      :list
    )
    |> validate_number_list_items(
      callbacks,
      path,
      group,
      "station_calendar_reservation_expires_at_s"
    )
    |> expect_optional_probability(callbacks, path, group, "capacity_fraction")
    |> expect_optional_probability(callbacks, path, group, "capacity_fraction_min")
    |> expect_optional_probability(callbacks, path, group, "capacity_fraction_max")
    |> expect_type(callbacks, path, group, "contact_ids", :list)
    |> expect_type(callbacks, path, group, "source_window_ids", :list)
    |> expect_type(callbacks, path, group, "scenario_ids", :list)
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      group,
      "duplicate_contact_candidate_count"
    )
    |> expect_optional_non_negative_integer(callbacks, path, group, "duplicate_contact_id_count")
    |> expect_optional_type(callbacks, path, group, "duplicate_contact_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, group, "duplicate_contact_ids")
    |> expect_optional_type(callbacks, path, group, "source_contact_candidates", :list)
    |> validate_optional_rows(
      callbacks,
      path <> ".source_contact_candidates",
      Map.get(group, "source_contact_candidates"),
      fn acc, row_path, row ->
        validate_source_contact_candidate(acc, row_path, row, callbacks)
      end
    )
    |> expect_field_equals(
      callbacks,
      path,
      group,
      "contact_count",
      list_count(group, "contact_ids")
    )
    |> expect_field_equals(
      callbacks,
      path,
      group,
      "duplicate_contact_id_count",
      list_count(group, "duplicate_contact_ids")
    )
  end

  def validate_resolution_report(issues, path, report, callbacks) when is_list(callbacks) do
    issues
    |> require_fields(callbacks, path, report, [
      "schema_contract",
      "model",
      "policy",
      "conflict_group_count",
      "recommendation_count",
      "recommendations"
    ])
    |> expect_equal(
      callbacks,
      path,
      report,
      "schema_contract",
      "contact_contention_resolution_report.v1"
    )
    |> expect_equal(
      callbacks,
      path,
      report,
      "model",
      "deterministic_contact_contention_recommendation"
    )
    |> expect_type(callbacks, path, report, "policy", :map)
    |> validate_resolution_policy(path <> ".policy", Map.get(report, "policy"), callbacks)
    |> expect_non_negative_integer(callbacks, path, report, "conflict_group_count")
    |> expect_non_negative_integer(callbacks, path, report, "recommendation_count")
    |> expect_type(callbacks, path, report, "recommendations", :list)
    |> expect_optional_type(callbacks, path, report, "assumptions", :map)
    |> expect_optional_type(callbacks, path, report, "model_limits", :list)
    |> validate_string_list_items(callbacks, path, report, "model_limits")
    |> validate_resolution_report_model_limits(callbacks, path, report)
    |> validate_rows(
      callbacks,
      path <> ".recommendations",
      Map.get(report, "recommendations", []),
      fn acc, row_path, row -> validate_recommendation(acc, row_path, row, callbacks) end
    )
    |> validate_resolution_report_counts(callbacks, path, report)
  end

  def validate_recommendation(issues, path, recommendation, callbacks) when is_list(callbacks) do
    issues
    |> require_fields(callbacks, path, recommendation, [
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
    |> validate_stable_ids(callbacks, path, recommendation, [
      "group_id",
      "ground_station_id",
      "spacecraft_id",
      "selected_contact_id",
      "selected_scenario_id"
    ])
    |> expect_optional_type(callbacks, path, recommendation, "resource_scope", :binary)
    |> expect_optional_type(callbacks, path, recommendation, "direction", :binary)
    |> expect_optional_type(callbacks, path, recommendation, "directions", :list)
    |> validate_string_list_items(callbacks, path, recommendation, "directions")
    |> expect_optional_type(callbacks, path, recommendation, "ground_station_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, recommendation, "ground_station_ids")
    |> expect_optional_type(callbacks, path, recommendation, "spacecraft_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, recommendation, "spacecraft_ids")
    |> expect_number(callbacks, path, recommendation, "starts_at_s")
    |> expect_number(callbacks, path, recommendation, "ends_at_s")
    |> expect_type(callbacks, path, recommendation, "deferred_contact_ids", :list)
    |> expect_non_negative_integer(callbacks, path, recommendation, "candidate_count")
    |> expect_optional_type(callbacks, path, recommendation, "source_contact_candidates", :list)
    |> validate_optional_rows(
      callbacks,
      path <> ".source_contact_candidates",
      Map.get(recommendation, "source_contact_candidates"),
      fn acc, row_path, row ->
        validate_source_contact_candidate(acc, row_path, row, callbacks)
      end
    )
    |> expect_optional_number(callbacks, path, recommendation, "contention_window_s")
    |> expect_optional_number(callbacks, path, recommendation, "total_contact_duration_s")
    |> expect_optional_number(callbacks, path, recommendation, "overlap_duration_s")
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      recommendation,
      "max_concurrent_contacts"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      recommendation,
      "overlap_contact_pair_count"
    )
    |> expect_optional_number(callbacks, path, recommendation, "selected_priority")
    |> expect_optional_type(callbacks, path, recommendation, "selected_priority_source", :binary)
    |> expect_optional_number(callbacks, path, recommendation, "actual_throughput_mb")
    |> expect_optional_type(
      callbacks,
      path,
      recommendation,
      "actual_data_rate_throughput_derivations",
      :list
    )
    |> expect_optional_type(callbacks, path, recommendation, "station_availability", :binary)
    |> expect_optional_type(callbacks, path, recommendation, "station_calendar_status", :binary)
    |> expect_optional_type(
      callbacks,
      path,
      recommendation,
      "station_calendar_reservation_expires_at_s",
      :list
    )
    |> validate_number_list_items(
      callbacks,
      path,
      recommendation,
      "station_calendar_reservation_expires_at_s"
    )
    |> expect_optional_probability(callbacks, path, recommendation, "capacity_fraction")
    |> expect_optional_probability(callbacks, path, recommendation, "capacity_fraction_min")
    |> expect_optional_probability(callbacks, path, recommendation, "capacity_fraction_max")
    |> expect_optional_type(callbacks, path, recommendation, "deferred_contact_priorities", :list)
    |> validate_optional_rows(
      callbacks,
      path <> ".deferred_contact_priorities",
      Map.get(recommendation, "deferred_contact_priorities"),
      fn acc, row_path, row -> validate_deferred_priority(acc, row_path, row, callbacks) end
    )
    |> expect_optional_type(callbacks, path, recommendation, "resolution_selection_rule", :binary)
    |> expect_optional_type(callbacks, path, recommendation, "resolution_priority_fields", :list)
    |> validate_string_list_items(callbacks, path, recommendation, "resolution_priority_fields")
    |> expect_optional_type(callbacks, path, recommendation, "requested_priority_fields", :list)
    |> validate_string_list_items(callbacks, path, recommendation, "requested_priority_fields")
    |> expect_optional_type(
      callbacks,
      path,
      recommendation,
      "priority_field_evidence_counts",
      :map
    )
    |> validate_priority_field_evidence_counts(
      callbacks,
      path <> ".priority_field_evidence_counts",
      Map.get(recommendation, "priority_field_evidence_counts")
    )
    |> expect_optional_integer(
      callbacks,
      path,
      recommendation,
      "priority_fields_without_numeric_evidence_count"
    )
    |> expect_field_at_least(
      callbacks,
      path,
      recommendation,
      "priority_fields_without_numeric_evidence_count",
      0
    )
    |> expect_optional_type(
      callbacks,
      path,
      recommendation,
      "priority_fields_without_numeric_evidence",
      :list
    )
    |> validate_string_list_items(
      callbacks,
      path,
      recommendation,
      "priority_fields_without_numeric_evidence"
    )
    |> expect_optional_type(callbacks, path, recommendation, "resolution_tie_breakers", :list)
    |> validate_string_list_items(callbacks, path, recommendation, "resolution_tie_breakers")
    |> expect_optional_integer(
      callbacks,
      path,
      recommendation,
      "resolution_priority_override_count"
    )
    |> expect_field_at_least(
      callbacks,
      path,
      recommendation,
      "resolution_priority_override_count",
      0
    )
    |> expect_optional_type(
      callbacks,
      path,
      recommendation,
      "resolution_priority_override_contact_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      recommendation,
      "resolution_priority_override_contact_ids"
    )
    |> validate_override_count_matches_ids(
      callbacks,
      path,
      recommendation,
      "resolution_priority_override_count",
      "resolution_priority_override_contact_ids"
    )
    |> expect_optional_integer(callbacks, path, recommendation, "ignored_priority_override_count")
    |> expect_field_at_least(
      callbacks,
      path,
      recommendation,
      "ignored_priority_override_count",
      0
    )
    |> expect_optional_type(
      callbacks,
      path,
      recommendation,
      "ignored_priority_override_keys",
      :list
    )
    |> validate_string_list_items(
      callbacks,
      path,
      recommendation,
      "ignored_priority_override_keys"
    )
    |> expect_optional_type(
      callbacks,
      path,
      recommendation,
      "ignored_priority_override_contact_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      recommendation,
      "ignored_priority_override_contact_ids"
    )
    |> expect_optional_type(
      callbacks,
      path,
      recommendation,
      "ignored_priority_override_input",
      :binary
    )
    |> validate_override_count_matches_ids(
      callbacks,
      path,
      recommendation,
      "ignored_priority_override_count",
      "ignored_priority_override_keys"
    )
    |> expect_optional_type(callbacks, path, recommendation, "requested_selection_rule", :binary)
    |> expect_optional_type(callbacks, path, recommendation, "ignored_tie_breakers", :list)
    |> validate_string_list_items(callbacks, path, recommendation, "ignored_tie_breakers")
    |> expect_optional_type(callbacks, path, recommendation, "ignored_policy_input", :binary)
    |> expect_optional_type(callbacks, path, recommendation, "policy_warnings", :list)
    |> validate_string_list_items(callbacks, path, recommendation, "policy_warnings")
    |> validate_recommendation_counts(callbacks, path, recommendation)
    |> validate_recommendation_duplicate_evidence(path, recommendation, callbacks)
  end

  def validate_source_contact_candidate(issues, path, candidate, callbacks)
      when is_list(callbacks) do
    issues
    |> validate_stable_ids(callbacks, path, candidate, [
      "id",
      "scenario_id",
      "source_window_id",
      "ground_station_id",
      "spacecraft_id"
    ])
    |> expect_optional_type(callbacks, path, candidate, "type", :binary)
    |> expect_optional_type(callbacks, path, candidate, "direction", :binary)
    |> expect_optional_number(callbacks, path, candidate, "starts_at_s")
    |> expect_optional_number(callbacks, path, candidate, "ends_at_s")
    |> expect_optional_number(callbacks, path, candidate, "score")
  end

  def validate_resolution_policy(issues, path, policy, callbacks)
      when is_map(policy) and is_list(callbacks) do
    issues
    |> expect_optional_type(callbacks, path, policy, "selection_rule", :binary)
    |> expect_optional_type(callbacks, path, policy, "priority_fields", :list)
    |> validate_string_list_items(callbacks, path, policy, "priority_fields")
    |> expect_optional_type(callbacks, path, policy, "requested_priority_fields", :list)
    |> validate_string_list_items(callbacks, path, policy, "requested_priority_fields")
    |> expect_optional_type(callbacks, path, policy, "tie_breakers", :list)
    |> validate_string_list_items(callbacks, path, policy, "tie_breakers")
    |> expect_optional_type(callbacks, path, policy, "action", :binary)
    |> expect_optional_type(callbacks, path, policy, "requested_selection_rule", :binary)
    |> expect_optional_type(callbacks, path, policy, "ignored_tie_breakers", :list)
    |> validate_string_list_items(callbacks, path, policy, "ignored_tie_breakers")
    |> expect_optional_type(callbacks, path, policy, "ignored_policy_input", :binary)
    |> expect_optional_type(callbacks, path, policy, "policy_warnings", :list)
    |> validate_string_list_items(callbacks, path, policy, "policy_warnings")
    |> expect_optional_type(callbacks, path, policy, "priority_overrides", :map)
    |> validate_priority_override_map(
      callbacks,
      path <> ".priority_overrides",
      Map.get(policy, "priority_overrides")
    )
    |> expect_optional_integer(callbacks, path, policy, "priority_override_count")
    |> expect_field_at_least(callbacks, path, policy, "priority_override_count", 0)
    |> expect_optional_type(callbacks, path, policy, "priority_override_contact_ids", :list)
    |> validate_optional_stable_id_list(callbacks, path, policy, "priority_override_contact_ids")
    |> validate_override_count_matches_ids(
      callbacks,
      path,
      policy,
      "priority_override_count",
      "priority_override_contact_ids"
    )
    |> expect_optional_integer(callbacks, path, policy, "ignored_priority_override_count")
    |> expect_field_at_least(callbacks, path, policy, "ignored_priority_override_count", 0)
    |> expect_optional_type(callbacks, path, policy, "ignored_priority_override_keys", :list)
    |> validate_string_list_items(callbacks, path, policy, "ignored_priority_override_keys")
    |> expect_optional_type(
      callbacks,
      path,
      policy,
      "ignored_priority_override_contact_ids",
      :list
    )
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      policy,
      "ignored_priority_override_contact_ids"
    )
    |> expect_optional_type(callbacks, path, policy, "ignored_priority_override_input", :binary)
    |> validate_override_count_matches_ids(
      callbacks,
      path,
      policy,
      "ignored_priority_override_count",
      "ignored_priority_override_keys"
    )
    |> validate_priority_override_ids_match_map(callbacks, path, policy)
  end

  def validate_resolution_policy(issues, _path, _policy, callbacks) when is_list(callbacks),
    do: issues

  def validate_deferred_priority(issues, path, row, callbacks) when is_list(callbacks) do
    issues
    |> validate_stable_ids(callbacks, path, row, ["contact_id"])
    |> expect_optional_number(callbacks, path, row, "priority")
    |> expect_optional_type(callbacks, path, row, "priority_source", :binary)
  end

  defp validate_recommendation_duplicate_evidence(issues, path, recommendation, callbacks) do
    if Map.get(recommendation, "resolution_issue") == "duplicate_contact_id" or
         Map.has_key?(recommendation, "duplicate_contact_ids") do
      issues
      |> require_fields(callbacks, path, recommendation, ["duplicate_contact_candidates"])
      |> expect_field_equals(
        callbacks,
        path,
        recommendation,
        "duplicate_contact_id_count",
        list_count(recommendation, "duplicate_contact_ids")
      )
      |> expect_field_equals(
        callbacks,
        path,
        recommendation,
        "duplicate_contact_candidate_count",
        list_count(recommendation, "duplicate_contact_candidates")
      )
      |> validate_stable_id_list(
        callbacks,
        path <> ".duplicate_contact_ids",
        Map.get(recommendation, "duplicate_contact_ids")
      )
    else
      issues
    end
  end

  defp validate_report_model_limits(issues, callbacks, path, report) do
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
              callbacks,
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

  defp validate_resolution_report_model_limits(issues, callbacks, path, report) do
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
              callbacks,
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

  defp validate_report_assumptions(issues, callbacks, path, report) do
    case Map.get(report, "assumptions") do
      nil ->
        issues

      :null ->
        issues

      assumptions when is_map(assumptions) ->
        issues
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "contact_types",
          contact_types(),
          "must match ContactContention contact types"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "contact_directions",
          contact_directions(),
          "must match ContactContention contact directions"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "row_review_statuses",
          row_review_statuses(),
          "must match ContactContention row review statuses"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "station_unavailable_aliases",
          station_unavailable_aliases(),
          "must match ContactContention station unavailable aliases"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "station_availability_precedence",
          station_availability_precedence(),
          "must match ContactContention station availability precedence"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "station_capacity_value_paths",
          station_capacity_value_path_assumptions(),
          "must match ContactContention station capacity value paths"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "source_station_capacity_value_paths",
          source_station_capacity_value_path_assumptions(),
          "must match ContactContention source station capacity value paths"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "required_capacity_value_paths",
          required_capacity_value_path_assumptions(),
          "must match ContactContention required capacity value paths"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "required_capacity_fraction_source_values",
          required_capacity_fraction_source_values(),
          "must match ContactContention required capacity fraction source values"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "station_reservation_priority_match_statuses",
          station_reservation_priority_match_statuses(),
          "must match ContactContention station reservation priority match statuses"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "station_reservation_priority_statuses",
          station_reservation_priority_statuses(),
          "must match ContactContention station reservation priority statuses"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "resolution_selection_rules",
          resolution_selection_rules(),
          "must match ContactContention resolution selection rules"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "resolution_tie_breakers",
          resolution_tie_breakers(),
          "must match ContactContention resolution tie breakers"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "default_resolution_priority_fields",
          default_resolution_priority_fields(),
          "must match ContactContention default resolution priority fields"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "resolution_priority_override_aliases",
          resolution_priority_override_aliases(),
          "must match ContactContention resolution priority override aliases"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "provider_direction_aliases",
          provider_direction_aliases(),
          "must match ContactContention provider direction aliases"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "provider_result_map_value_keys",
          provider_result_map_value_keys(),
          "must match ContactContention provider result map value keys"
        )
        |> expect_optional_field_equals(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "contact_stable_identity_fields",
          contact_stable_identity_fields(),
          "must match ContactContention contact stable identity fields"
        )
        |> expect_optional_field_equals(
          callbacks,
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

  defp validate_report_counts(issues, callbacks, path, report) do
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
    |> expect_field_equals(callbacks, path, report, "conflict_group_count", length(groups))
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "conflicted_contact_count",
      sum_row_numbers(groups, "contact_count"),
      "must equal row-derived conflicted contact count"
    )
    |> expect_field_equals(
      callbacks,
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
      callbacks,
      path,
      report,
      "duplicate_contact_candidate_count",
      sum_row_numbers(groups, "duplicate_contact_candidate_count"),
      "must equal row-derived duplicate contact candidate count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "invalid_contact_input_count",
      length(invalid_rows)
    )
    |> validate_ids_match_row_multiset(
      callbacks,
      path,
      report,
      "invalid_contact_input_ids",
      Enum.map(invalid_rows, &Map.get(&1, "contact_id")),
      "must equal row-derived invalid_contact_input_ids"
    )
  end

  defp validate_resolution_report_counts(issues, callbacks, path, report) do
    recommendations =
      report
      |> Map.get("recommendations", [])
      |> Enum.filter(&is_map/1)

    issues
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "recommendation_count",
      length(recommendations)
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "conflict_group_count",
      length(recommendations),
      "must equal recommendation_count for one recommendation per contention group"
    )
  end

  defp validate_recommendation_counts(issues, callbacks, path, recommendation) do
    issues
    |> expect_field_equals(
      callbacks,
      path,
      recommendation,
      "candidate_count",
      list_count(recommendation, "source_contact_candidates"),
      "must equal source_contact_candidates count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      recommendation,
      "candidate_count",
      selected_deferred_candidate_count(recommendation),
      "must equal selected plus deferred contact count"
    )
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

  defp expect_optional_integer(issues, callbacks, path, map, field),
    do: apply(require_callback(callbacks, :expect_optional_integer), [issues, path, map, field])

  defp expect_number(issues, callbacks, path, map, field),
    do: apply(require_callback(callbacks, :expect_number), [issues, path, map, field])

  defp expect_optional_number(issues, callbacks, path, map, field),
    do: apply(require_callback(callbacks, :expect_optional_number), [issues, path, map, field])

  defp expect_optional_probability(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :expect_optional_probability), [issues, path, map, field])

  defp expect_optional_one_of(issues, callbacks, path, map, field, allowed),
    do:
      apply(require_callback(callbacks, :expect_optional_one_of), [
        issues,
        path,
        map,
        field,
        allowed
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

  defp expect_field_equals(issues, callbacks, path, map, field, expected),
    do:
      apply(require_callback(callbacks, :expect_field_equals), [
        issues,
        path,
        map,
        field,
        expected
      ])

  defp expect_field_equals(issues, callbacks, path, map, field, expected, message),
    do:
      apply(require_callback(callbacks, :expect_field_equals_with_message), [
        issues,
        path,
        map,
        field,
        expected,
        message
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

  defp validate_optional_stable_id_list(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :validate_optional_stable_id_list), [
        issues,
        path,
        map,
        field
      ])

  defp validate_stable_id_list(issues, callbacks, path, rows),
    do: apply(require_callback(callbacks, :validate_stable_id_list), [issues, path, rows])

  defp validate_stable_ids(issues, callbacks, path, map, fields),
    do: apply(require_callback(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :validate_string_list_items), [issues, path, map, field])

  defp validate_number_list_items(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :validate_number_list_items), [issues, path, map, field])

  defp validate_optional_rows(issues, callbacks, path, rows, validator),
    do:
      apply(require_callback(callbacks, :validate_optional_rows), [issues, path, rows, validator])

  defp validate_rows(issues, callbacks, path, rows, validator),
    do: apply(require_callback(callbacks, :validate_rows), [issues, path, rows, validator])

  defp validate_optional_actual_data_rate_throughput_derivations(
         issues,
         callbacks,
         path,
         map,
         field
       ),
       do:
         apply(
           require_callback(
             callbacks,
             :validate_optional_actual_data_rate_throughput_derivations
           ),
           [
             issues,
             path,
             map,
             field
           ]
         )

  defp validate_invalid_contact_input(callbacks, issues, path, row),
    do: apply(require_callback(callbacks, :validate_invalid_contact_input), [issues, path, row])

  defp validate_priority_field_evidence_counts(issues, callbacks, path, counts),
    do:
      apply(require_callback(callbacks, :validate_priority_field_evidence_counts), [
        issues,
        path,
        counts
      ])

  defp validate_priority_override_map(issues, callbacks, path, overrides),
    do:
      apply(require_callback(callbacks, :validate_priority_override_map), [
        issues,
        path,
        overrides
      ])

  defp validate_priority_override_ids_match_map(issues, callbacks, path, policy),
    do:
      apply(require_callback(callbacks, :validate_priority_override_ids_match_map), [
        issues,
        path,
        policy
      ])

  defp validate_override_count_matches_ids(issues, callbacks, path, map, count_field, ids_field),
    do:
      apply(require_callback(callbacks, :validate_override_count_matches_ids), [
        issues,
        path,
        map,
        count_field,
        ids_field
      ])

  defp validate_ids_match_row_multiset(
         issues,
         callbacks,
         path,
         report,
         field,
         expected_ids,
         message
       ),
       do:
         apply(require_callback(callbacks, :validate_ids_match_row_multiset), [
           issues,
           path,
           report,
           field,
           expected_ids,
           message
         ])

  defp error(callbacks, path, message),
    do: apply(require_callback(callbacks, :error), [path, message])
end
