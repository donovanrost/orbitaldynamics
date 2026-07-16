defmodule OrbitalDynamics.Schema.TimelineActivityPreconditionSummaryContracts do
  @moduledoc false

  alias OrbitalDynamics.Schema.TimelineIdentityContracts
  alias OrbitalDynamics.Schema.TimelinePreconditionContracts

  import OrbitalDynamics.Schema.CollectionValidation,
    only: [validate_optional_string_list: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      expect_equal: 5,
      expect_field_equals: 6,
      expect_one_of: 5,
      expect_optional_non_negative_integer: 4,
      expect_optional_type: 5,
      expect_type: 5,
      validate_optional_exact_model_limits: 5,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [validate_optional_stable_id_list: 4, validate_stable_ids: 4]

  def validate(issues, path, summary, timeline_report_model_limits)
      when is_list(timeline_report_model_limits) do
    preconditions = precondition_rows(summary)

    issues
    |> expect_equal(
      path,
      summary,
      "schema_contract",
      "timeline_activity_precondition_summary.v1"
    )
    |> expect_equal(
      path,
      summary,
      "model",
      "artifact_only_timeline_activity_precondition_summary"
    )
    |> expect_equal(path, summary, "validation_level", "artifact_contract")
    |> expect_type(path, summary, "model_limits", :list)
    |> validate_string_list_items(path, summary, "model_limits")
    |> validate_optional_exact_model_limits(
      path,
      summary,
      timeline_report_model_limits,
      "must match timeline report model limits"
    )
    |> validate_stable_ids(path, summary, ["activity_id", "timeline_id"])
    |> expect_optional_type(path, summary, "activity_type", :binary)
    |> expect_one_of(
      path,
      summary,
      "precondition_status",
      OrbitalDynamics.Timeline.capabilities().activity_precondition_statuses
    )
    |> expect_optional_non_negative_integer(
      path,
      summary,
      "blocked_precondition_count"
    )
    |> expect_optional_non_negative_integer(
      path,
      summary,
      "review_precondition_count"
    )
    |> expect_optional_type(path, summary, "blocked_precondition_types", :list)
    |> validate_optional_string_list(path, summary, "blocked_precondition_types")
    |> expect_optional_type(path, summary, "review_precondition_types", :list)
    |> validate_optional_string_list(path, summary, "review_precondition_types")
    |> expect_optional_type(path, summary, "preconditions", :list)
    |> TimelinePreconditionContracts.validate_optional(path, summary, "preconditions")
    |> validate_row_derived_fields(path, summary, preconditions)
    |> validate_dependency_fields(path, summary)
    |> expect_optional_type(path, summary, "allow_overlap", :boolean)
    |> expect_optional_type(path, summary, "timeline_identity", :map)
    |> TimelineIdentityContracts.validate_optional_identity(path, summary, "timeline_identity")
    |> expect_optional_type(path, summary, "invalid_activity_input", :boolean)
    |> expect_optional_type(path, summary, "invalid_activity_input_reason", :binary)
    |> expect_optional_type(path, summary, "source_activity", :map)
    |> expect_optional_type(path, summary, "assumptions", :map)
  end

  defp validate_dependency_fields(issues, path, summary) do
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
      |> expect_optional_type(path, summary, field, :list)
      |> validate_optional_stable_id_list(path, summary, field)
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
         path,
         %{"invalid_activity_input" => true} = summary,
         _preconditions
       ) do
    issues
    |> expect_field_equals(
      path,
      summary,
      "precondition_status",
      "review_required",
      "must be review_required for invalid activity input"
    )
    |> expect_field_equals(
      path,
      summary,
      "blocked_precondition_count",
      0,
      "must equal 0 for invalid activity input"
    )
    |> expect_field_equals(
      path,
      summary,
      "review_precondition_count",
      0,
      "must equal 0 for invalid activity input"
    )
    |> expect_field_equals(
      path,
      summary,
      "blocked_precondition_types",
      [],
      "must equal [] for invalid activity input"
    )
    |> expect_field_equals(
      path,
      summary,
      "review_precondition_types",
      [],
      "must equal [] for invalid activity input"
    )
  end

  defp validate_row_derived_fields(issues, path, summary, preconditions) do
    issues
    |> expect_field_equals(
      path,
      summary,
      "precondition_status",
      precondition_status(preconditions),
      "must equal row-derived precondition_status"
    )
    |> expect_field_equals(
      path,
      summary,
      "blocked_precondition_count",
      precondition_count(preconditions, "blocked"),
      "must equal row-derived blocked_precondition_count"
    )
    |> expect_field_equals(
      path,
      summary,
      "review_precondition_count",
      precondition_count(preconditions, "review_required"),
      "must equal row-derived review_precondition_count"
    )
    |> expect_field_equals(
      path,
      summary,
      "blocked_precondition_types",
      precondition_types(preconditions, "blocked"),
      "must equal row-derived blocked_precondition_types"
    )
    |> expect_field_equals(
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
end
