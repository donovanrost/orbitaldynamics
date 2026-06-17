defmodule OrbitalDynamics.Schema.ContactContentionResolutionSummaryContracts do
  @moduledoc false

  def validate(issues, path, summary, callbacks) when is_list(callbacks) do
    issues
    |> expect_equal(
      callbacks,
      path,
      summary,
      "schema_contract",
      "contact_contention_resolution_summary.v1"
    )
    |> expect_equal(
      callbacks,
      path,
      summary,
      "model",
      "artifact_only_contact_contention_resolution_summary"
    )
    |> expect_equal(
      callbacks,
      path,
      summary,
      "source_artifact_type",
      "contact_contention_resolution_report.v1"
    )
    |> expect_type(callbacks, path, summary, "policy", :map)
    |> validate_contact_contention_resolution_policy(
      callbacks,
      path <> ".policy",
      Map.get(summary, "policy")
    )
    |> expect_optional_type(callbacks, path, summary, "model_limits", :list)
    |> validate_string_list_items(callbacks, path, summary, "model_limits")
    |> validate_optional_exact_model_limits(
      callbacks,
      path,
      summary,
      contact_contention_report_model_limits(callbacks),
      "must match contact contention resolution summary model limits"
    )
    |> validate_field_types(callbacks, path, summary)
    |> expect_type(callbacks, path, summary, "assumptions", :map)
    |> validate_assumptions(callbacks, path, summary)
    |> validate_counts(callbacks, path, summary)
  end

  defp validate_field_types(issues, callbacks, path, summary) do
    issues =
      Enum.reduce(count_fields(), issues, fn field, acc ->
        expect_non_negative_integer(acc, callbacks, path, summary, field)
      end)

    issues =
      Enum.reduce(count_map_fields(), issues, fn field, acc ->
        acc
        |> expect_type(callbacks, path, summary, field, :map)
        |> validate_non_negative_integer_count_map(
          callbacks,
          path <> ".#{field}",
          Map.get(summary, field)
        )
      end)

    issues =
      Enum.reduce(stable_id_list_fields(), issues, fn field, acc ->
        acc
        |> expect_type(callbacks, path, summary, field, :list)
        |> validate_stable_id_list(callbacks, path <> ".#{field}", Map.get(summary, field))
      end)

    issues =
      Enum.reduce(stable_id_array_map_fields(), issues, fn field, acc ->
        acc
        |> expect_type(callbacks, path, summary, field, :map)
        |> validate_stable_id_array_map(callbacks, path <> ".#{field}", Map.get(summary, field))
      end)

    issues =
      Enum.reduce(optional_number_fields(), issues, fn field, acc ->
        expect_optional_non_negative_number(acc, callbacks, path, summary, field)
      end)

    Enum.reduce(optional_number_map_fields(), issues, fn field, acc ->
      acc
      |> expect_optional_type(callbacks, path, summary, field, :map)
      |> validate_non_negative_number_map(callbacks, path <> ".#{field}", Map.get(summary, field))
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

  defp validate_assumptions(issues, callbacks, path, summary) do
    case Map.get(summary, "assumptions") do
      %{} = assumptions ->
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
          "candidate_mutation",
          "none"
        )
        |> expect_equal(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "operator_authority",
          "not_granted_by_summary"
        )
        |> expect_equal(
          callbacks,
          path <> ".assumptions",
          assumptions,
          "source",
          "contact_contention_resolution_report.v1"
        )

      _assumptions ->
        issues
    end
  end

  defp validate_counts(issues, callbacks, path, summary) do
    capacity_status_totals =
      Map.get(summary, "capacity_pack_required_capacity_fraction_by_status")

    issues
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "conflict_group_count",
      list_count(callbacks, summary, "recommendation_group_ids"),
      "must equal recommendation_group_ids count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "recommendation_count",
      list_count(callbacks, summary, "recommendation_group_ids"),
      "must equal recommendation_group_ids count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "review_recommendation_count",
      list_count(callbacks, summary, "review_group_ids"),
      "must equal review_group_ids count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "selected_contact_ids",
      sorted_stable_id_array_map_values(
        callbacks,
        Map.get(summary, "selected_contact_ids_by_group_id")
      ),
      "must equal selected_contact_ids_by_group_id values"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "deferred_contact_ids",
      sorted_stable_id_array_map_values(
        callbacks,
        Map.get(summary, "deferred_contact_ids_by_group_id")
      ),
      "must equal deferred_contact_ids_by_group_id values"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "ambiguous_duplicate_contact_ids",
      sorted_stable_id_array_map_values(
        callbacks,
        Map.get(summary, "ambiguous_duplicate_contact_ids_by_group_id")
      ),
      "must equal ambiguous_duplicate_contact_ids_by_group_id values"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "review_contact_ids",
      sorted_stable_id_array_map_values(
        callbacks,
        Map.get(summary, "review_contact_ids_by_group_id")
      ),
      "must equal review_contact_ids_by_group_id values"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "selected_contact_ids",
      sorted_stable_id_array_map_values(
        callbacks,
        Map.get(summary, "selected_contact_ids_by_resource_scope")
      ),
      "must equal selected_contact_ids_by_resource_scope values"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "deferred_contact_ids",
      sorted_stable_id_array_map_values(
        callbacks,
        Map.get(summary, "deferred_contact_ids_by_resource_scope")
      ),
      "must equal deferred_contact_ids_by_resource_scope values"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "review_contact_ids",
      sorted_stable_id_array_map_values(
        callbacks,
        Map.get(summary, "review_contact_ids_by_resource_scope")
      ),
      "must equal review_contact_ids_by_resource_scope values"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "selected_contact_ids",
      sorted_stable_id_array_map_values(
        callbacks,
        Map.get(summary, "selected_contact_ids_by_selection_reason")
      ),
      "must equal selected_contact_ids_by_selection_reason values"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "review_contact_ids",
      sorted_stable_id_array_map_values(
        callbacks,
        Map.get(summary, "review_contact_ids_by_action")
      ),
      "must equal review_contact_ids_by_action values"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "recommendation_count",
      non_negative_integer_map_sum(callbacks, Map.get(summary, "resource_scope_counts")),
      "must equal resource_scope_counts total"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "recommendation_count",
      non_negative_integer_map_sum(callbacks, Map.get(summary, "selection_reason_counts")),
      "must equal selection_reason_counts total"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "recommendation_count",
      non_negative_integer_map_sum(callbacks, Map.get(summary, "action_counts")),
      "must equal action_counts total"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "capacity_pack_required_capacity_fraction",
      numeric_map_sum(callbacks, capacity_status_totals),
      "must equal capacity_pack_required_capacity_fraction_by_status total"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "capacity_pack_selected_required_capacity_fraction",
      capacity_status_value(capacity_status_totals, "selected"),
      "must equal selected capacity-pack status total"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "capacity_pack_deferred_required_capacity_fraction",
      capacity_status_value(capacity_status_totals, "deferred"),
      "must equal deferred capacity-pack status total"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "capacity_pack_required_capacity_fraction",
      numeric_map_sum(
        callbacks,
        Map.get(summary, "capacity_pack_required_capacity_fraction_by_ground_station_id")
      ),
      "must equal capacity_pack_required_capacity_fraction_by_ground_station_id total"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "capacity_pack_selected_required_capacity_fraction",
      numeric_map_sum(
        callbacks,
        Map.get(summary, "capacity_pack_selected_required_capacity_fraction_by_ground_station_id")
      ),
      "must equal capacity_pack_selected_required_capacity_fraction_by_ground_station_id total"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "capacity_pack_deferred_required_capacity_fraction",
      numeric_map_sum(
        callbacks,
        Map.get(summary, "capacity_pack_deferred_required_capacity_fraction_by_ground_station_id")
      ),
      "must equal capacity_pack_deferred_required_capacity_fraction_by_ground_station_id total"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "required_capacity_fraction_source_counts",
      source_counts(summary),
      "must equal required_capacity_fraction_contact_ids_by_source counts"
    )
  end

  defp capacity_status_value(%{} = values, status), do: Map.get(values, status)
  defp capacity_status_value(_values, _status), do: nil

  defp source_counts(summary) do
    case Map.get(summary, "required_capacity_fraction_contact_ids_by_source") do
      %{} = ids_by_source ->
        Map.new(ids_by_source, fn {source, ids} -> {source, length(List.wrap(ids))} end)

      _ids_by_source ->
        nil
    end
  end

  defp expect_equal(issues, callbacks, path, map, field, expected),
    do: apply(Keyword.fetch!(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_type), [issues, path, map, field, type])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_optional_type), [issues, path, map, field, type])

  defp expect_non_negative_integer(issues, callbacks, path, map, field) do
    apply(Keyword.fetch!(callbacks, :expect_non_negative_integer), [issues, path, map, field])
  end

  defp expect_optional_non_negative_number(issues, callbacks, path, map, field) do
    apply(Keyword.fetch!(callbacks, :expect_optional_non_negative_number), [
      issues,
      path,
      map,
      field
    ])
  end

  defp expect_field_equals(issues, callbacks, path, map, field, expected, message) do
    apply(Keyword.fetch!(callbacks, :expect_field_equals_with_message), [
      issues,
      path,
      map,
      field,
      expected,
      message
    ])
  end

  defp validate_contact_contention_resolution_policy(issues, callbacks, path, policy) do
    apply(Keyword.fetch!(callbacks, :validate_contact_contention_resolution_policy), [
      issues,
      path,
      policy
    ])
  end

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :validate_string_list_items), [issues, path, map, field])

  defp validate_optional_exact_model_limits(issues, callbacks, path, artifact, expected, message) do
    apply(Keyword.fetch!(callbacks, :validate_optional_exact_model_limits), [
      issues,
      path,
      artifact,
      expected,
      message
    ])
  end

  defp validate_non_negative_integer_count_map(issues, callbacks, path, counts) do
    apply(Keyword.fetch!(callbacks, :validate_non_negative_integer_count_map), [
      issues,
      path,
      counts
    ])
  end

  defp validate_stable_id_list(issues, callbacks, path, values),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_id_list), [issues, path, values])

  defp validate_stable_id_array_map(issues, callbacks, path, values),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_id_array_map), [issues, path, values])

  defp validate_non_negative_number_map(issues, callbacks, path, values),
    do:
      apply(Keyword.fetch!(callbacks, :validate_non_negative_number_map), [issues, path, values])

  defp contact_contention_report_model_limits(callbacks),
    do: apply(Keyword.fetch!(callbacks, :contact_contention_report_model_limits), [])

  defp sorted_stable_id_array_map_values(callbacks, values) do
    apply(Keyword.fetch!(callbacks, :sorted_stable_id_array_map_values), [values])
  end

  defp non_negative_integer_map_sum(callbacks, counts),
    do: apply(Keyword.fetch!(callbacks, :non_negative_integer_map_sum), [counts])

  defp numeric_map_sum(callbacks, values),
    do: apply(Keyword.fetch!(callbacks, :numeric_map_sum), [values])

  defp list_count(callbacks, map, field),
    do: apply(Keyword.fetch!(callbacks, :list_count), [map, field])
end
