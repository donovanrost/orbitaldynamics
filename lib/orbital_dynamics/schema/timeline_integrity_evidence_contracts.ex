defmodule OrbitalDynamics.Schema.TimelineIntegrityEvidenceContracts do
  @moduledoc false

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

  def validate(issues, path, row, callbacks) when is_list(callbacks) do
    issues =
      case Map.get(row, "timeline_integrity_issues") do
        issues_list when is_list(issues_list) ->
          issues_list
          |> Enum.with_index()
          |> Enum.reduce(issues, fn {issue, index}, acc ->
            acc =
              if is_map(issue) do
                require_fields(
                  callbacks,
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
                    callbacks,
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
                  callbacks,
                  "#{path}.timeline_integrity_issues[#{index}].type",
                  "must be one of #{inspect(timeline_integrity_issue_types())}"
                )
                | acc
              ]
            else
              validate_issue_evidence(
                acc,
                callbacks,
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
      callbacks,
      path,
      row,
      "timeline_integrity_issue_count",
      if(is_list(issues_list), do: length(issues_list), else: nil),
      "must match timeline_integrity_issues length"
    )
    |> expect_field_equals(
      callbacks,
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
      callbacks,
      path,
      row,
      "missing_dependency_activity_ids",
      issue_ids(issues_list, "missing_dependency_activity_id"),
      "must match timeline_integrity_issues missing_dependency_activity_id values"
    )
    |> expect_field_equals(
      callbacks,
      path,
      row,
      "missing_dependency_timeline_ids",
      issue_ids(issues_list, "missing_dependency_timeline_id"),
      "must match timeline_integrity_issues missing_dependency_timeline_id values"
    )
    |> expect_field_equals(
      callbacks,
      path,
      row,
      "self_dependency_activity_ids",
      issue_ids(issues_list, "self_dependency_activity_id"),
      "must match timeline_integrity_issues self_dependency_activity_id values"
    )
    |> expect_field_equals(
      callbacks,
      path,
      row,
      "self_dependency_timeline_ids",
      issue_ids(issues_list, "self_dependency_timeline_id"),
      "must match timeline_integrity_issues self_dependency_timeline_id values"
    )
    |> expect_field_equals(
      callbacks,
      path,
      row,
      "duplicate_dependency_activity_ids",
      issue_ids(issues_list, "duplicate_dependency_activity_id"),
      "must match timeline_integrity_issues duplicate_dependency_activity_id values"
    )
    |> expect_field_equals(
      callbacks,
      path,
      row,
      "duplicate_dependency_timeline_ids",
      issue_ids(issues_list, "duplicate_dependency_timeline_id"),
      "must match timeline_integrity_issues duplicate_dependency_timeline_id values"
    )
    |> expect_field_equals(
      callbacks,
      path,
      row,
      "duplicate_exclusivity_activity_ids",
      issue_ids(issues_list, "duplicate_exclusivity_activity_id"),
      "must match timeline_integrity_issues duplicate_exclusivity_activity_id values"
    )
    |> expect_field_equals(
      callbacks,
      path,
      row,
      "duplicate_exclusivity_timeline_ids",
      issue_ids(issues_list, "duplicate_exclusivity_timeline_id"),
      "must match timeline_integrity_issues duplicate_exclusivity_timeline_id values"
    )
    |> expect_field_equals(
      callbacks,
      path,
      row,
      "dependency_cycle_activity_ids",
      issue_ids(issues_list, "dependency_cycle_activity_id"),
      "must match timeline_integrity_issues dependency_cycle_activity_id values"
    )
    |> expect_field_equals(
      callbacks,
      path,
      row,
      "dependency_cycle_timeline_ids",
      issue_ids(issues_list, "dependency_cycle_timeline_id"),
      "must match timeline_integrity_issues dependency_cycle_timeline_id values"
    )
    |> expect_field_equals(
      callbacks,
      path,
      row,
      "dependency_order_violation_activity_ids",
      issue_ids(issues_list, "dependency_order_violation_activity_id"),
      "must match timeline_integrity_issues dependency_order_violation_activity_id values"
    )
    |> expect_field_equals(
      callbacks,
      path,
      row,
      "dependency_order_violation_timeline_ids",
      issue_ids(issues_list, "dependency_order_violation_timeline_id"),
      "must match timeline_integrity_issues dependency_order_violation_timeline_id values"
    )
    |> expect_field_equals(
      callbacks,
      path,
      row,
      "exclusivity_violation_activity_ids",
      issue_ids(issues_list, "exclusivity_violation_activity_id"),
      "must match timeline_integrity_issues exclusivity_violation_activity_id values"
    )
    |> expect_field_equals(
      callbacks,
      path,
      row,
      "exclusivity_violation_timeline_ids",
      issue_ids(issues_list, "exclusivity_violation_timeline_id"),
      "must match timeline_integrity_issues exclusivity_violation_timeline_id values"
    )
    |> then(fn acc ->
      if is_list(issue_types) do
        validate_string_list_allowed(
          callbacks,
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

  defp validate_issue_evidence(issues, callbacks, path, issue) when is_map(issue) do
    issues =
      issue
      |> Map.take(@evidence_id_fields)
      |> Enum.reduce(issues, fn {field, value}, acc ->
        validate_stable_id(callbacks, acc, "#{path}.#{field}", value)
      end)

    cond do
      Map.get(issue, "type") == "exclusivity_group_overlap" and
          not Map.has_key?(issue, "exclusivity_violation_group") ->
        [error(callbacks, path <> ".exclusivity_violation_group", "is required") | issues]

      issue
      |> Map.keys()
      |> Enum.any?(&String.ends_with?(&1, "_id")) ->
        issues

      Map.has_key?(issue, "exclusivity_violation_group") ->
        issues

      Map.get(issue, "type") == "dependency_cycle" ->
        [
          error(
            callbacks,
            path,
            "must include one of the timeline integrity evidence identifiers"
          )
          | issues
        ]

      true ->
        issues
    end
  end

  defp validate_issue_evidence(issues, _callbacks, _path, _issue), do: issues

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

  defp expect_field_equals(issues, callbacks, path, row, field, expected, message) do
    callback!(callbacks, :expect_field_equals).(issues, path, row, field, expected, message)
  end

  defp require_fields(callbacks, issues, path, row, fields) do
    callback!(callbacks, :require_fields).(issues, path, row, fields)
  end

  defp validate_stable_id(callbacks, issues, path, value) do
    callback!(callbacks, :validate_stable_id).(issues, path, value)
  end

  defp validate_string_list_allowed(callbacks, issues, path, row, field, values) do
    callback!(callbacks, :validate_string_list_allowed).(issues, path, row, field, values)
  end

  defp error(callbacks, path, message) do
    callback!(callbacks, :error).(path, message)
  end

  defp callback!(callbacks, name), do: Keyword.fetch!(callbacks, name)
end
