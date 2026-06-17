defmodule OrbitalDynamics.Schema.TimelineActivityPreconditionSummaryContracts do
  @moduledoc false

  def validate(issues, path, summary, callbacks) when is_list(callbacks) do
    preconditions = precondition_rows(summary)

    issues
    |> expect_equal(
      callbacks,
      path,
      summary,
      "schema_contract",
      "timeline_activity_precondition_summary.v1"
    )
    |> expect_equal(
      callbacks,
      path,
      summary,
      "model",
      "artifact_only_timeline_activity_precondition_summary"
    )
    |> expect_equal(callbacks, path, summary, "validation_level", "artifact_contract")
    |> expect_type(callbacks, path, summary, "model_limits", :list)
    |> validate_string_list_items(callbacks, path, summary, "model_limits")
    |> validate_optional_exact_model_limits(
      callbacks,
      path,
      summary,
      timeline_report_model_limits(callbacks),
      "must match timeline report model limits"
    )
    |> validate_stable_ids(callbacks, path, summary, ["activity_id", "timeline_id"])
    |> expect_optional_type(callbacks, path, summary, "activity_type", :binary)
    |> expect_one_of(
      callbacks,
      path,
      summary,
      "precondition_status",
      OrbitalDynamics.Timeline.capabilities().activity_precondition_statuses
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      summary,
      "blocked_precondition_count"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      summary,
      "review_precondition_count"
    )
    |> expect_optional_type(callbacks, path, summary, "blocked_precondition_types", :list)
    |> validate_optional_string_list(callbacks, path, summary, "blocked_precondition_types")
    |> expect_optional_type(callbacks, path, summary, "review_precondition_types", :list)
    |> validate_optional_string_list(callbacks, path, summary, "review_precondition_types")
    |> expect_optional_type(callbacks, path, summary, "preconditions", :list)
    |> validate_optional_timeline_preconditions(callbacks, path, summary, "preconditions")
    |> validate_row_derived_fields(callbacks, path, summary, preconditions)
    |> validate_dependency_fields(callbacks, path, summary)
    |> expect_optional_type(callbacks, path, summary, "allow_overlap", :boolean)
    |> expect_optional_type(callbacks, path, summary, "timeline_identity", :map)
    |> validate_optional_timeline_identity(callbacks, path, summary, "timeline_identity")
    |> expect_optional_type(callbacks, path, summary, "invalid_activity_input", :boolean)
    |> expect_optional_type(callbacks, path, summary, "invalid_activity_input_reason", :binary)
    |> expect_optional_type(callbacks, path, summary, "source_activity", :map)
    |> expect_optional_type(callbacks, path, summary, "assumptions", :map)
  end

  defp validate_dependency_fields(issues, callbacks, path, summary) do
    [
      "dependency_activity_ids",
      "dependency_timeline_ids",
      "exclusive_with_activity_ids",
      "exclusive_with_timeline_ids",
      "duplicate_dependency_activity_ids",
      "duplicate_dependency_timeline_ids",
      "duplicate_exclusivity_activity_ids",
      "duplicate_exclusivity_timeline_ids"
    ]
    |> Enum.reduce(issues, fn field, acc ->
      acc
      |> expect_optional_type(callbacks, path, summary, field, :list)
      |> validate_optional_stable_id_list(callbacks, path, summary, field)
    end)
  end

  defp precondition_rows(summary) do
    case Map.get(summary, "preconditions", []) do
      rows when is_list(rows) -> Enum.filter(rows, &is_map/1)
      _rows -> []
    end
  end

  defp validate_row_derived_fields(
         issues,
         callbacks,
         path,
         %{"invalid_activity_input" => true} = summary,
         _preconditions
       ) do
    issues
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "precondition_status",
      "review_required",
      "must be review_required for invalid activity input"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "blocked_precondition_count",
      0,
      "must equal 0 for invalid activity input"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "review_precondition_count",
      0,
      "must equal 0 for invalid activity input"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "blocked_precondition_types",
      [],
      "must equal [] for invalid activity input"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "review_precondition_types",
      [],
      "must equal [] for invalid activity input"
    )
  end

  defp validate_row_derived_fields(issues, callbacks, path, summary, preconditions) do
    issues
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "precondition_status",
      precondition_status(preconditions),
      "must equal row-derived precondition_status"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "blocked_precondition_count",
      precondition_count(preconditions, "blocked"),
      "must equal row-derived blocked_precondition_count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "review_precondition_count",
      precondition_count(preconditions, "review_required"),
      "must equal row-derived review_precondition_count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "blocked_precondition_types",
      precondition_types(preconditions, "blocked"),
      "must equal row-derived blocked_precondition_types"
    )
    |> expect_field_equals(
      callbacks,
      path,
      summary,
      "review_precondition_types",
      precondition_types(preconditions, "review_required"),
      "must equal row-derived review_precondition_types"
    )
  end

  defp precondition_status(preconditions) do
    cond do
      Enum.any?(preconditions, &(&1["status"] == "blocked")) -> "blocked"
      Enum.any?(preconditions, &(&1["status"] == "review_required")) -> "review_required"
      true -> "clear"
    end
  end

  defp precondition_count(preconditions, status) do
    Enum.count(preconditions, &(&1["status"] == status))
  end

  defp precondition_types(preconditions, status) do
    preconditions
    |> Enum.filter(&(&1["status"] == status))
    |> Enum.map(&Map.get(&1, "type"))
    |> sorted_unique_binary_values()
  end

  defp sorted_unique_binary_values(values) do
    values
    |> Enum.filter(&is_binary/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp expect_equal(issues, callbacks, path, map, field, expected),
    do: apply(Keyword.fetch!(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_one_of(issues, callbacks, path, map, field, allowed),
    do: apply(Keyword.fetch!(callbacks, :expect_one_of), [issues, path, map, field, allowed])

  defp expect_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_type), [issues, path, map, field, type])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_optional_type), [issues, path, map, field, type])

  defp expect_optional_non_negative_integer(issues, callbacks, path, map, field) do
    apply(Keyword.fetch!(callbacks, :expect_optional_non_negative_integer), [
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

  defp validate_stable_ids(issues, callbacks, path, map, fields),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp validate_optional_string_list(issues, callbacks, path, map, field) do
    apply(Keyword.fetch!(callbacks, :validate_optional_string_list), [
      issues,
      path,
      map,
      field
    ])
  end

  defp validate_optional_timeline_preconditions(issues, callbacks, path, map, field) do
    apply(Keyword.fetch!(callbacks, :validate_optional_timeline_preconditions), [
      issues,
      path,
      map,
      field
    ])
  end

  defp validate_optional_stable_id_list(issues, callbacks, path, map, field) do
    apply(Keyword.fetch!(callbacks, :validate_optional_stable_id_list), [
      issues,
      path,
      map,
      field
    ])
  end

  defp validate_optional_timeline_identity(issues, callbacks, path, map, field) do
    apply(Keyword.fetch!(callbacks, :validate_optional_timeline_identity), [
      issues,
      path,
      map,
      field
    ])
  end

  defp timeline_report_model_limits(callbacks),
    do: apply(Keyword.fetch!(callbacks, :timeline_report_model_limits), [])
end
