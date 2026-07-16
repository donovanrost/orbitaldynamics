defmodule OrbitalDynamics.Schema.TimelineIntegrityEvidenceContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_field_equals: 6,
      require_fields: 4,
      validate_string_list_allowed: 5
    ]

  import OrbitalDynamics.Schema.StableIdValidation, only: [validate_stable_id: 3]

  @evidence_id_fields [
    "missing_dependency_activity_id",
    "missing_dependency_timeline_id",
    "self_dependency_activity_id",
    "self_dependency_timeline_id",
    "duplicate_dependency_activity_id",
    "duplicate_dependency_timeline_id",
    "duplicate_exclusivity_activity_id",
    "duplicate_exclusivity_timeline_id",
    "dependency_cycle_activity_id",
    "dependency_cycle_timeline_id",
    "dependency_order_violation_activity_id",
    "dependency_order_violation_timeline_id",
    "exclusivity_violation_activity_id",
    "exclusivity_violation_timeline_id"
  ]

  def validate(issues, path, row) do
    issues =
      case Map.get(row, "timeline_integrity_issues") do
        issues_list when is_list(issues_list) ->
          issues_list
          |> Enum.with_index()
          |> Enum.reduce(issues, fn {issue, index}, acc ->
            acc =
              if is_map(issue) do
                require_fields(
                  acc,
                  "#{path}.timeline_integrity_issues[#{index}]",
                  issue,
                  [
                    "type"
                  ]
                )
              else
                [
                  error(
                    "#{path}.timeline_integrity_issues[#{index}]",
                    "must be an object"
                  )
                  | acc
                ]
              end

            issue_type = if is_map(issue), do: Map.get(issue, "type")

            if is_binary(issue_type) and issue_type not in timeline_integrity_issue_types() do
              [
                error(
                  "#{path}.timeline_integrity_issues[#{index}].type",
                  "must be one of #{inspect(timeline_integrity_issue_types())}"
                )
                | acc
              ]
            else
              validate_issue_evidence(
                acc,
                "#{path}.timeline_integrity_issues[#{index}]",
                issue
              )
            end
          end)

        _issues ->
          issues
      end

    issue_types = Map.get(row, "timeline_integrity_issue_types")
    issues_list = Map.get(row, "timeline_integrity_issues")

    issues
    |> expect_field_equals(
      path,
      row,
      "timeline_integrity_issue_count",
      if(is_list(issues_list), do: length(issues_list), else: nil),
      "must match timeline_integrity_issues length"
    )
    |> expect_field_equals(
      path,
      row,
      "timeline_integrity_issue_types",
      if is_list(issues_list) do
        issues_list
        |> Enum.filter(&is_map/1)
        |> Enum.map(&Map.get(&1, "type"))
        |> Enum.reject(&is_nil/1)
        |> Enum.uniq()
        |> Enum.sort()
      else
        nil
      end,
      "must match timeline_integrity_issues types"
    )
    |> expect_field_equals(
      path,
      row,
      "missing_dependency_activity_ids",
      issue_ids(issues_list, "missing_dependency_activity_id"),
      "must match timeline_integrity_issues missing_dependency_activity_id values"
    )
    |> expect_field_equals(
      path,
      row,
      "missing_dependency_timeline_ids",
      issue_ids(issues_list, "missing_dependency_timeline_id"),
      "must match timeline_integrity_issues missing_dependency_timeline_id values"
    )
    |> expect_field_equals(
      path,
      row,
      "self_dependency_activity_ids",
      issue_ids(issues_list, "self_dependency_activity_id"),
      "must match timeline_integrity_issues self_dependency_activity_id values"
    )
    |> expect_field_equals(
      path,
      row,
      "self_dependency_timeline_ids",
      issue_ids(issues_list, "self_dependency_timeline_id"),
      "must match timeline_integrity_issues self_dependency_timeline_id values"
    )
    |> expect_field_equals(
      path,
      row,
      "duplicate_dependency_activity_ids",
      issue_ids(issues_list, "duplicate_dependency_activity_id"),
      "must match timeline_integrity_issues duplicate_dependency_activity_id values"
    )
    |> expect_field_equals(
      path,
      row,
      "duplicate_dependency_timeline_ids",
      issue_ids(issues_list, "duplicate_dependency_timeline_id"),
      "must match timeline_integrity_issues duplicate_dependency_timeline_id values"
    )
    |> expect_field_equals(
      path,
      row,
      "duplicate_exclusivity_activity_ids",
      issue_ids(issues_list, "duplicate_exclusivity_activity_id"),
      "must match timeline_integrity_issues duplicate_exclusivity_activity_id values"
    )
    |> expect_field_equals(
      path,
      row,
      "duplicate_exclusivity_timeline_ids",
      issue_ids(issues_list, "duplicate_exclusivity_timeline_id"),
      "must match timeline_integrity_issues duplicate_exclusivity_timeline_id values"
    )
    |> expect_field_equals(
      path,
      row,
      "dependency_cycle_activity_ids",
      issue_ids(issues_list, "dependency_cycle_activity_id"),
      "must match timeline_integrity_issues dependency_cycle_activity_id values"
    )
    |> expect_field_equals(
      path,
      row,
      "dependency_cycle_timeline_ids",
      issue_ids(issues_list, "dependency_cycle_timeline_id"),
      "must match timeline_integrity_issues dependency_cycle_timeline_id values"
    )
    |> expect_field_equals(
      path,
      row,
      "dependency_order_violation_activity_ids",
      issue_ids(issues_list, "dependency_order_violation_activity_id"),
      "must match timeline_integrity_issues dependency_order_violation_activity_id values"
    )
    |> expect_field_equals(
      path,
      row,
      "dependency_order_violation_timeline_ids",
      issue_ids(issues_list, "dependency_order_violation_timeline_id"),
      "must match timeline_integrity_issues dependency_order_violation_timeline_id values"
    )
    |> expect_field_equals(
      path,
      row,
      "exclusivity_violation_activity_ids",
      issue_ids(issues_list, "exclusivity_violation_activity_id"),
      "must match timeline_integrity_issues exclusivity_violation_activity_id values"
    )
    |> expect_field_equals(
      path,
      row,
      "exclusivity_violation_timeline_ids",
      issue_ids(issues_list, "exclusivity_violation_timeline_id"),
      "must match timeline_integrity_issues exclusivity_violation_timeline_id values"
    )
    |> then(fn acc ->
      if is_list(issue_types) do
        validate_string_list_allowed(
          acc,
          path,
          row,
          "timeline_integrity_issue_types",
          timeline_integrity_issue_types()
        )
      else
        acc
      end
    end)
  end

  defp validate_issue_evidence(issues, path, issue) when is_map(issue) do
    issues =
      issue
      |> Map.take(@evidence_id_fields)
      |> Enum.reduce(issues, fn {field, value}, acc ->
        validate_stable_id(acc, "#{path}.#{field}", value)
      end)

    cond do
      Map.get(issue, "type") == "exclusivity_group_overlap" and
          not Map.has_key?(issue, "exclusivity_violation_group") ->
        [error(path <> ".exclusivity_violation_group", "is required") | issues]

      issue
      |> Map.keys()
      |> Enum.any?(&String.ends_with?(&1, "_id")) ->
        issues

      Map.has_key?(issue, "exclusivity_violation_group") ->
        issues

      Map.get(issue, "type") == "dependency_cycle" ->
        [
          error(
            path,
            "must include one of the timeline integrity evidence identifiers"
          )
          | issues
        ]

      true ->
        issues
    end
  end

  defp validate_issue_evidence(issues, _path, _issue), do: issues

  defp issue_ids(issues_list, field) when is_list(issues_list) do
    issues_list
    |> Enum.filter(&is_map/1)
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp issue_ids(_issues_list, _field), do: nil

  defp timeline_integrity_issue_types do
    OrbitalDynamics.Timeline.capabilities().timeline_integrity_issue_types
  end
end
