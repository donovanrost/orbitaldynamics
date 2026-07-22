defmodule OrbitalDynamics.Schema.ContactContentionResolutionSummaryContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CollectionAggregation,
    only: [list_count: 2, sorted_unique_binary_values: 1]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_equal: 5,
      expect_field_equals: 6,
      expect_non_negative_integer: 4,
      expect_optional_non_negative_number: 4,
      expect_optional_type: 5,
      expect_type: 5,
      validate_non_negative_integer_count_map: 3,
      validate_non_negative_number_map: 3,
      validate_optional_exact_model_limits: 5,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [validate_stable_id_array_map: 3, validate_stable_id_list: 3]

  def validate(issues, path, summary, contact_contention_report_model_limits, policy_validator)
      when is_list(contact_contention_report_model_limits) and is_function(policy_validator, 3) do
    issues
    |> expect_equal(
      path,
      summary,
      "schema_contract",
      "contact_contention_resolution_summary.v1"
    )
    |> expect_equal(
      path,
      summary,
      "model",
      "artifact_only_contact_contention_resolution_summary"
    )
    |> expect_equal(
      path,
      summary,
      "source_artifact_type",
      "contact_contention_resolution_report.v1"
    )
    |> expect_type(path, summary, "policy", :map)
    |> validate_contact_contention_resolution_policy(
      path <> ".policy",
      Map.get(summary, "policy"),
      policy_validator
    )
    |> expect_optional_type(path, summary, "model_limits", :list)
    |> validate_string_list_items(path, summary, "model_limits")
    |> validate_optional_exact_model_limits(
      path,
      summary,
      contact_contention_report_model_limits,
      "must match contact contention resolution summary model limits"
    )
    |> validate_field_types(path, summary)
    |> expect_type(path, summary, "assumptions", :map)
    |> validate_assumptions(path, summary)
    |> validate_counts(path, summary)
  end

  defp validate_field_types(issues, path, summary) do
    issues =
      Enum.reduce(count_fields(), issues, fn field, acc ->
        expect_non_negative_integer(acc, path, summary, field)
      end)

    issues =
      Enum.reduce(count_map_fields(), issues, fn field, acc ->
        acc
        |> expect_type(path, summary, field, :map)
        |> validate_non_negative_integer_count_map(
          path <> ".#{field}",
          Map.get(summary, field)
        )
      end)

    issues =
      Enum.reduce(stable_id_list_fields(), issues, fn field, acc ->
        acc
        |> expect_type(path, summary, field, :list)
        |> validate_stable_id_list(path <> ".#{field}", Map.get(summary, field))
      end)

    issues =
      Enum.reduce(stable_id_array_map_fields(), issues, fn field, acc ->
        acc
        |> expect_type(path, summary, field, :map)
        |> validate_stable_id_array_map(path <> ".#{field}", Map.get(summary, field))
      end)

    issues =
      Enum.reduce(optional_number_fields(), issues, fn field, acc ->
        expect_optional_non_negative_number(acc, path, summary, field)
      end)

    Enum.reduce(optional_number_map_fields(), issues, fn field, acc ->
      acc
      |> expect_optional_type(path, summary, field, :map)
      |> validate_non_negative_number_map(path <> ".#{field}", Map.get(summary, field))
    end)
  end

  defp count_fields do
    [
      "conflict_group_count",
      "recommendation_count",
      "review_recommendation_count"
    ]
  end

  defp count_map_fields do
    [
      "resource_scope_counts",
      "selection_reason_counts",
      "action_counts",
      "required_capacity_fraction_source_counts"
    ]
  end

  defp stable_id_list_fields do
    [
      "recommendation_group_ids",
      "review_group_ids",
      "selected_contact_ids",
      "deferred_contact_ids",
      "ambiguous_group_ids",
      "ambiguous_duplicate_contact_ids",
      "review_contact_ids"
    ]
  end

  defp stable_id_array_map_fields do
    [
      "selected_contact_ids_by_group_id",
      "deferred_contact_ids_by_group_id",
      "ambiguous_duplicate_contact_ids_by_group_id",
      "review_contact_ids_by_group_id",
      "selected_contact_ids_by_resource_scope",
      "deferred_contact_ids_by_resource_scope",
      "review_contact_ids_by_resource_scope",
      "selected_contact_ids_by_selection_reason",
      "review_contact_ids_by_action",
      "required_capacity_fraction_contact_ids_by_source"
    ]
  end

  defp optional_number_fields do
    [
      "capacity_pack_required_capacity_fraction",
      "capacity_pack_selected_required_capacity_fraction",
      "capacity_pack_deferred_required_capacity_fraction"
    ]
  end

  defp optional_number_map_fields do
    [
      "capacity_pack_required_capacity_fraction_by_ground_station_id",
      "capacity_pack_selected_required_capacity_fraction_by_ground_station_id",
      "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id",
      "capacity_pack_required_capacity_fraction_by_status"
    ]
  end

  defp validate_assumptions(issues, path, summary) do
    case Map.get(summary, "assumptions") do
      %{} = assumptions ->
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
          "candidate_mutation",
          "none"
        )
        |> expect_equal(
          path <> ".assumptions",
          assumptions,
          "operator_authority",
          "not_granted_by_summary"
        )
        |> expect_equal(
          path <> ".assumptions",
          assumptions,
          "source",
          "contact_contention_resolution_report.v1"
        )

      _assumptions ->
        issues
    end
  end

  defp validate_counts(issues, path, summary) do
    capacity_status_totals =
      Map.get(summary, "capacity_pack_required_capacity_fraction_by_status")

    issues
    |> expect_field_equals(
      path,
      summary,
      "conflict_group_count",
      list_count(summary, "recommendation_group_ids"),
      "must equal recommendation_group_ids count"
    )
    |> expect_field_equals(
      path,
      summary,
      "recommendation_count",
      list_count(summary, "recommendation_group_ids"),
      "must equal recommendation_group_ids count"
    )
    |> expect_field_equals(
      path,
      summary,
      "review_recommendation_count",
      list_count(summary, "review_group_ids"),
      "must equal review_group_ids count"
    )
    |> validate_group_id_subset(path, summary, "review_group_ids", "recommendation_group_ids")
    |> validate_group_id_subset(path, summary, "ambiguous_group_ids", "recommendation_group_ids")
    |> validate_group_map_keys(
      path,
      summary,
      "selected_contact_ids_by_group_id",
      "recommendation_group_ids"
    )
    |> validate_group_map_keys(
      path,
      summary,
      "deferred_contact_ids_by_group_id",
      "recommendation_group_ids"
    )
    |> validate_group_map_keys(
      path,
      summary,
      "review_contact_ids_by_group_id",
      "review_group_ids"
    )
    |> validate_group_map_keys(
      path,
      summary,
      "ambiguous_duplicate_contact_ids_by_group_id",
      "ambiguous_group_ids"
    )
    |> validate_positive_count_map_keys(
      path,
      summary,
      "selected_contact_ids_by_resource_scope",
      "resource_scope_counts"
    )
    |> validate_positive_count_map_keys(
      path,
      summary,
      "deferred_contact_ids_by_resource_scope",
      "resource_scope_counts"
    )
    |> validate_positive_count_map_keys(
      path,
      summary,
      "review_contact_ids_by_resource_scope",
      "resource_scope_counts"
    )
    |> validate_positive_count_map_keys(
      path,
      summary,
      "selected_contact_ids_by_selection_reason",
      "selection_reason_counts"
    )
    |> validate_positive_count_map_keys(
      path,
      summary,
      "review_contact_ids_by_action",
      "action_counts"
    )
    |> expect_field_equals(
      path,
      summary,
      "selected_contact_ids",
      sorted_stable_id_array_map_values(Map.get(summary, "selected_contact_ids_by_group_id")),
      "must equal selected_contact_ids_by_group_id values"
    )
    |> expect_field_equals(
      path,
      summary,
      "deferred_contact_ids",
      sorted_stable_id_array_map_values(Map.get(summary, "deferred_contact_ids_by_group_id")),
      "must equal deferred_contact_ids_by_group_id values"
    )
    |> expect_field_equals(
      path,
      summary,
      "ambiguous_duplicate_contact_ids",
      sorted_stable_id_array_map_values(
        Map.get(summary, "ambiguous_duplicate_contact_ids_by_group_id")
      ),
      "must equal ambiguous_duplicate_contact_ids_by_group_id values"
    )
    |> expect_field_equals(
      path,
      summary,
      "review_contact_ids",
      sorted_stable_id_array_map_values(Map.get(summary, "review_contact_ids_by_group_id")),
      "must equal review_contact_ids_by_group_id values"
    )
    |> expect_field_equals(
      path,
      summary,
      "selected_contact_ids",
      sorted_stable_id_array_map_values(
        Map.get(summary, "selected_contact_ids_by_resource_scope")
      ),
      "must equal selected_contact_ids_by_resource_scope values"
    )
    |> expect_field_equals(
      path,
      summary,
      "deferred_contact_ids",
      sorted_stable_id_array_map_values(
        Map.get(summary, "deferred_contact_ids_by_resource_scope")
      ),
      "must equal deferred_contact_ids_by_resource_scope values"
    )
    |> expect_field_equals(
      path,
      summary,
      "review_contact_ids",
      sorted_stable_id_array_map_values(Map.get(summary, "review_contact_ids_by_resource_scope")),
      "must equal review_contact_ids_by_resource_scope values"
    )
    |> expect_field_equals(
      path,
      summary,
      "selected_contact_ids",
      sorted_stable_id_array_map_values(
        Map.get(summary, "selected_contact_ids_by_selection_reason")
      ),
      "must equal selected_contact_ids_by_selection_reason values"
    )
    |> expect_field_equals(
      path,
      summary,
      "review_contact_ids",
      sorted_stable_id_array_map_values(Map.get(summary, "review_contact_ids_by_action")),
      "must equal review_contact_ids_by_action values"
    )
    |> expect_field_equals(
      path,
      summary,
      "recommendation_count",
      non_negative_integer_map_sum(Map.get(summary, "resource_scope_counts")),
      "must equal resource_scope_counts total"
    )
    |> expect_field_equals(
      path,
      summary,
      "recommendation_count",
      non_negative_integer_map_sum(Map.get(summary, "selection_reason_counts")),
      "must equal selection_reason_counts total"
    )
    |> expect_field_equals(
      path,
      summary,
      "recommendation_count",
      non_negative_integer_map_sum(Map.get(summary, "action_counts")),
      "must equal action_counts total"
    )
    |> expect_field_equals(
      path,
      summary,
      "capacity_pack_required_capacity_fraction",
      numeric_map_sum(capacity_status_totals),
      "must equal capacity_pack_required_capacity_fraction_by_status total"
    )
    |> expect_field_equals(
      path,
      summary,
      "capacity_pack_selected_required_capacity_fraction",
      capacity_status_value(capacity_status_totals, "selected"),
      "must equal selected capacity-pack status total"
    )
    |> expect_field_equals(
      path,
      summary,
      "capacity_pack_deferred_required_capacity_fraction",
      capacity_status_value(capacity_status_totals, "deferred"),
      "must equal deferred capacity-pack status total"
    )
    |> expect_field_equals(
      path,
      summary,
      "capacity_pack_required_capacity_fraction",
      numeric_map_sum(
        Map.get(summary, "capacity_pack_required_capacity_fraction_by_ground_station_id")
      ),
      "must equal capacity_pack_required_capacity_fraction_by_ground_station_id total"
    )
    |> expect_field_equals(
      path,
      summary,
      "capacity_pack_selected_required_capacity_fraction",
      numeric_map_sum(
        Map.get(summary, "capacity_pack_selected_required_capacity_fraction_by_ground_station_id")
      ),
      "must equal capacity_pack_selected_required_capacity_fraction_by_ground_station_id total"
    )
    |> expect_field_equals(
      path,
      summary,
      "capacity_pack_deferred_required_capacity_fraction",
      numeric_map_sum(
        Map.get(summary, "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id")
      ),
      "must equal capacity_pack_deferred_required_capacity_fraction_by_ground_station_id total"
    )
    |> expect_field_equals(
      path,
      summary,
      "required_capacity_fraction_source_counts",
      source_counts(summary),
      "must equal required_capacity_fraction_contact_ids_by_source counts"
    )
  end

  defp capacity_status_value(%{} = values, status), do: Map.get(values, status)
  defp capacity_status_value(_values, _status), do: nil

  defp validate_group_id_subset(issues, path, summary, field, allowed_field) do
    values = Map.get(summary, field)
    allowed_values = Map.get(summary, allowed_field)

    if is_list(values) and is_list(allowed_values) and
         Enum.all?(values, &(&1 in allowed_values)) do
      issues
    else
      if is_list(values) and is_list(allowed_values) do
        [error("#{path}.#{field}", "must reference #{allowed_field}") | issues]
      else
        issues
      end
    end
  end

  defp validate_group_map_keys(issues, path, summary, field, allowed_field) do
    values = Map.get(summary, field)
    allowed_values = Map.get(summary, allowed_field)

    if is_map(values) and is_list(allowed_values) and
         Enum.all?(Map.keys(values), &(&1 in allowed_values)) do
      issues
    else
      if is_map(values) and is_list(allowed_values) do
        [error("#{path}.#{field}", "keys must reference #{allowed_field}") | issues]
      else
        issues
      end
    end
  end

  defp validate_positive_count_map_keys(issues, path, summary, field, count_field) do
    values = Map.get(summary, field)
    counts = Map.get(summary, count_field)

    if is_map(values) and is_map(counts) do
      positive_count_keys =
        counts
        |> Enum.filter(fn {_key, count} -> is_integer(count) and count > 0 end)
        |> Map.new()
        |> Map.keys()

      if Enum.all?(Map.keys(values), &(&1 in positive_count_keys)) do
        issues
      else
        [
          error("#{path}.#{field}", "keys must reference positive #{count_field} entries")
          | issues
        ]
      end
    else
      issues
    end
  end

  defp source_counts(summary) do
    case Map.get(summary, "required_capacity_fraction_contact_ids_by_source") do
      %{} = ids_by_source ->
        Map.new(ids_by_source, fn {source, ids} -> {source, length(List.wrap(ids))} end)

      _ids_by_source ->
        nil
    end
  end

  defp validate_contact_contention_resolution_policy(issues, path, policy, validator),
    do: validator.(issues, path, policy)

  defp sorted_stable_id_array_map_values(values) when is_map(values) do
    values
    |> Map.values()
    |> List.flatten()
    |> sorted_unique_binary_values()
  end

  defp sorted_stable_id_array_map_values(_values), do: nil

  defp non_negative_integer_map_sum(counts) when is_map(counts) do
    values = Map.values(counts)

    if Enum.all?(values, &(is_integer(&1) and &1 >= 0)),
      do: Enum.sum(values),
      else: nil
  end

  defp non_negative_integer_map_sum(_counts), do: nil

  defp numeric_map_sum(values) when is_map(values) do
    values = Map.values(values)

    if Enum.all?(values, &is_number/1),
      do: Enum.sum(values),
      else: nil
  end

  defp numeric_map_sum(_values), do: nil
end
