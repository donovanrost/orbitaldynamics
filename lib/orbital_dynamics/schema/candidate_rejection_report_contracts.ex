defmodule OrbitalDynamics.Schema.CandidateRejectionReportContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CollectionValidation, only: [validate_rows: 4]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [
      validate_optional_stable_id_list: 4,
      validate_stable_id_list: 3,
      validate_stable_ids: 4
    ]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_equal: 5,
      expect_field_equals: 6,
      expect_non_negative_integer: 4,
      expect_one_of: 5,
      expect_optional_non_negative_integer: 4,
      expect_optional_number: 4,
      expect_optional_one_of: 5,
      expect_optional_type: 5,
      expect_type: 5,
      require_fields: 4,
      validate_non_negative_integer_count_map: 3,
      validate_optional_exact_model_limits: 5,
      validate_string_list_allowed: 5,
      validate_string_list_items: 4
    ]

  alias OrbitalDynamics.Schema.{ActivityContextContracts, CollectionAggregation}

  def validate(issues, path, report, candidate_rejection_report_model_limits)
      when is_list(candidate_rejection_report_model_limits) do
    issues
    |> expect_equal(path, report, "schema_contract", "candidate_rejection_report.v1")
    |> expect_equal(
      path,
      report,
      "model",
      "artifact_only_candidate_rejection_explanation"
    )
    |> expect_type(path, report, "source", :binary)
    |> expect_non_negative_integer(path, report, "candidate_count")
    |> expect_non_negative_integer(path, report, "row_count")
    |> expect_non_negative_integer(path, report, "rejected_count")
    |> expect_non_negative_integer(path, report, "not_rejected_count")
    |> expect_optional_non_negative_integer(
      path,
      report,
      "invalid_candidate_input_count"
    )
    |> expect_non_negative_integer(path, report, "reviewable_count")
    |> expect_type(path, report, "rejection_reason_counts", :map)
    |> expect_optional_type(
      path,
      report,
      "candidate_id_sets_by_rejection_reason",
      :map
    )
    |> expect_optional_type(
      path,
      report,
      "candidate_ids_by_required_operator_action",
      :map
    )
    |> expect_optional_type(path, report, "required_operator_action_counts", :map)
    |> expect_optional_type(path, report, "model_limits", :list)
    |> validate_string_list_items(path, report, "model_limits")
    |> validate_optional_exact_model_limits(
      path,
      report,
      candidate_rejection_report_model_limits,
      "must match candidate rejection report model limits"
    )
    |> validate_optional_stable_id_list(path, report, "rejected_candidate_ids")
    |> validate_optional_stable_id_list(path, report, "not_rejected_candidate_ids")
    |> validate_optional_stable_id_list(path, report, "reviewable_candidate_ids")
    |> validate_optional_stable_id_list(path, report, "invalid_candidate_input_ids")
    |> validate_candidate_id_sets_by_rejection_reason(
      path <> ".candidate_id_sets_by_rejection_reason",
      Map.get(report, "candidate_id_sets_by_rejection_reason")
    )
    |> validate_candidate_ids_by_required_operator_action(
      path <> ".candidate_ids_by_required_operator_action",
      Map.get(report, "candidate_ids_by_required_operator_action")
    )
    |> expect_type(path, report, "rows", :list)
    |> expect_type(path, report, "assumptions", :map)
    |> validate_non_negative_integer_count_map(
      path <> ".rejection_reason_counts",
      Map.get(report, "rejection_reason_counts")
    )
    |> validate_non_negative_integer_count_map(
      path <> ".required_operator_action_counts",
      Map.get(report, "required_operator_action_counts")
    )
    |> validate_rows(
      path <> ".rows",
      Map.get(report, "rows", []),
      fn acc, row_path, row -> validate_row(acc, row_path, row) end
    )
    |> validate_counts(path, report)
  end

  def validate_optional_source_row(issues, _path, nil), do: issues

  def validate_optional_source_row(issues, path, %{} = row) do
    issues
    |> validate_stable_ids(path, row, [
      "id",
      "candidate_id",
      "activity_id",
      "timeline_id",
      "source_window_id"
    ])
    |> expect_optional_one_of(path, row, "rejection_status", [
      "rejected",
      "not_rejected"
    ])
    |> expect_optional_one_of(
      path,
      row,
      "primary_rejection_reason",
      candidate_rejection_reasons()
    )
    |> expect_optional_type(path, row, "rejection_reasons", :list)
    |> validate_string_list_allowed(
      path,
      row,
      "rejection_reasons",
      candidate_rejection_reasons()
    )
    |> expect_optional_non_negative_integer(path, row, "reason_count")
    |> validate_optional_reason_count(path, row)
    |> expect_optional_type(path, row, "reviewable", :boolean)
    |> expect_optional_one_of(
      path,
      row,
      "required_operator_action",
      candidate_rejection_actions()
    )
    |> expect_optional_type(path, row, "activity_type", :binary)
    |> expect_optional_one_of(path, row, "operational_kind", operational_kinds())
    |> expect_optional_type(path, row, "source_window_type", :binary)
    |> expect_optional_type(path, row, "violated_constraint", :binary)
    |> expect_optional_number(path, row, "required_margin")
    |> expect_optional_number(path, row, "actual_margin")
    |> expect_optional_type(path, row, "declared_rejection_reasons", :list)
    |> validate_string_list_allowed(
      path,
      row,
      "declared_rejection_reasons",
      candidate_rejection_reasons()
    )
    |> expect_optional_type(path, row, "activity_context", :map)
    |> validate_optional_activity_context(path, row, "activity_context")
  end

  def validate_optional_source_row(issues, path, _row) do
    [error(path, "must be an object") | issues]
  end

  defp validate_row(issues, path, row) do
    issues
    |> require_fields(path, row, [
      "id",
      "candidate_id",
      "rejection_status",
      "rejection_reasons",
      "reason_count",
      "reviewable",
      "required_operator_action",
      "activity_context"
    ])
    |> validate_stable_ids(path, row, [
      "id",
      "candidate_id",
      "activity_id",
      "timeline_id",
      "source_window_id"
    ])
    |> expect_one_of(path, row, "rejection_status", ["rejected", "not_rejected"])
    |> expect_optional_one_of(
      path,
      row,
      "primary_rejection_reason",
      candidate_rejection_reasons()
    )
    |> expect_type(path, row, "rejection_reasons", :list)
    |> validate_string_list_allowed(
      path,
      row,
      "rejection_reasons",
      candidate_rejection_reasons()
    )
    |> expect_non_negative_integer(path, row, "reason_count")
    |> expect_field_equals(
      path,
      row,
      "reason_count",
      row |> Map.get("rejection_reasons", []) |> length()
    )
    |> expect_type(path, row, "reviewable", :boolean)
    |> expect_one_of(
      path,
      row,
      "required_operator_action",
      candidate_rejection_actions()
    )
    |> expect_optional_type(path, row, "activity_type", :binary)
    |> expect_optional_one_of(path, row, "operational_kind", operational_kinds())
    |> expect_optional_type(path, row, "source_window_type", :binary)
    |> expect_optional_type(path, row, "violated_constraint", :binary)
    |> expect_optional_number(path, row, "required_margin")
    |> expect_optional_number(path, row, "actual_margin")
    |> expect_optional_type(path, row, "declared_rejection_reasons", :list)
    |> expect_type(path, row, "activity_context", :map)
  end

  defp validate_optional_reason_count(issues, path, row) do
    case {Map.get(row, "reason_count"), Map.get(row, "rejection_reasons")} do
      {count, reasons} when is_integer(count) and is_list(reasons) ->
        expect_field_equals(issues, path, row, "reason_count", length(reasons))

      _values ->
        issues
    end
  end

  defp validate_counts(issues, path, report) do
    rows =
      report
      |> Map.get("rows", [])
      |> Enum.filter(&is_map/1)

    issues
    |> expect_field_equals(path, report, "row_count", length(rows))
    |> expect_field_equals(path, report, "candidate_count", length(rows))
    |> expect_field_equals(
      path,
      report,
      "rejected_count",
      Enum.count(rows, &(&1["rejection_status"] == "rejected"))
    )
    |> expect_field_equals(
      path,
      report,
      "not_rejected_count",
      Enum.count(rows, &(&1["rejection_status"] == "not_rejected"))
    )
    |> expect_field_equals(
      path,
      report,
      "invalid_candidate_input_count",
      Enum.count(rows, &("invalid_candidate_input" in Map.get(&1, "rejection_reasons", [])))
    )
    |> expect_field_equals(
      path,
      report,
      "reviewable_count",
      Enum.count(rows, & &1["reviewable"])
    )
    |> expect_field_equals(
      path,
      report,
      "rejection_reason_counts",
      candidate_rejection_reason_frequency_map(rows),
      "must equal row-derived rejection_reason_counts"
    )
    |> expect_field_equals(
      path,
      report,
      "rejected_candidate_ids",
      candidate_rejection_row_ids(rows, &(&1["rejection_status"] == "rejected")),
      "must equal row-derived rejected_candidate_ids"
    )
    |> expect_field_equals(
      path,
      report,
      "not_rejected_candidate_ids",
      candidate_rejection_row_ids(rows, &(&1["rejection_status"] == "not_rejected")),
      "must equal row-derived not_rejected_candidate_ids"
    )
    |> expect_field_equals(
      path,
      report,
      "reviewable_candidate_ids",
      candidate_rejection_row_ids(rows, & &1["reviewable"]),
      "must equal row-derived reviewable_candidate_ids"
    )
    |> expect_field_equals(
      path,
      report,
      "invalid_candidate_input_ids",
      candidate_rejection_row_ids(
        rows,
        &("invalid_candidate_input" in Map.get(&1, "rejection_reasons", []))
      ),
      "must equal row-derived invalid_candidate_input_ids"
    )
    |> expect_field_equals(
      path,
      report,
      "candidate_id_sets_by_rejection_reason",
      candidate_id_sets_by_rejection_reason(rows),
      "must equal row-derived candidate_id_sets_by_rejection_reason"
    )
    |> expect_field_equals(
      path,
      report,
      "candidate_ids_by_required_operator_action",
      candidate_ids_by_required_operator_action(rows),
      "must equal row-derived candidate_ids_by_required_operator_action"
    )
    |> expect_field_equals(
      path,
      report,
      "required_operator_action_counts",
      frequency_map(rows, "required_operator_action"),
      "must equal row-derived required_operator_action_counts"
    )
  end

  defp candidate_rejection_reason_frequency_map(rows) do
    rows
    |> Enum.flat_map(&Map.get(&1, "rejection_reasons", []))
    |> Enum.frequencies()
  end

  defp candidate_rejection_row_ids(rows, predicate) do
    rows
    |> Enum.filter(predicate)
    |> Enum.map(&Map.get(&1, "candidate_id"))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp candidate_id_sets_by_rejection_reason(rows) do
    rows
    |> Enum.flat_map(fn row ->
      row
      |> Map.get("rejection_reasons", [])
      |> Enum.map(&{&1, Map.get(row, "candidate_id")})
    end)
    |> Enum.group_by(fn {reason, _candidate_id} -> reason end, fn {_reason, candidate_id} ->
      candidate_id
    end)
    |> Map.new(fn {reason, candidate_ids} ->
      candidate_ids =
        candidate_ids
        |> Enum.reject(&is_nil/1)
        |> Enum.uniq()
        |> Enum.sort()

      {reason, candidate_ids}
    end)
  end

  defp validate_candidate_id_sets_by_rejection_reason(issues, _path, nil),
    do: issues

  defp validate_candidate_id_sets_by_rejection_reason(issues, path, %{} = reason_ids) do
    allowed_reasons = candidate_rejection_reasons()

    Enum.reduce(reason_ids, issues, fn {reason, candidate_ids}, acc ->
      acc =
        if reason in allowed_reasons,
          do: acc,
          else: [
            error("#{path}.#{reason}", "must use a supported rejection reason") | acc
          ]

      case candidate_ids do
        ids when is_list(ids) ->
          validate_stable_id_list(acc, "#{path}.#{reason}", ids)

        _value ->
          [error("#{path}.#{reason}", "must be a list") | acc]
      end
    end)
  end

  defp validate_candidate_id_sets_by_rejection_reason(issues, path, _reason_ids),
    do: [error(path, "must be an object") | issues]

  defp validate_candidate_ids_by_required_operator_action(issues, _path, nil),
    do: issues

  defp validate_candidate_ids_by_required_operator_action(
         issues,
         path,
         %{} = action_ids
       ) do
    allowed_actions = candidate_rejection_actions()

    Enum.reduce(action_ids, issues, fn {action, candidate_ids}, acc ->
      acc =
        if action in allowed_actions,
          do: acc,
          else: [
            error(
              "#{path}.#{action}",
              "must use a supported candidate rejection action"
            )
            | acc
          ]

      case candidate_ids do
        ids when is_list(ids) ->
          validate_stable_id_list(acc, "#{path}.#{action}", ids)

        _value ->
          [error("#{path}.#{action}", "must be a list") | acc]
      end
    end)
  end

  defp validate_candidate_ids_by_required_operator_action(issues, path, _action_ids),
    do: [error(path, "must be an object") | issues]

  defp candidate_ids_by_required_operator_action(rows) do
    rows
    |> Enum.group_by(&Map.get(&1, "required_operator_action"), &Map.get(&1, "candidate_id"))
    |> Map.new(fn {action, candidate_ids} ->
      candidate_ids =
        candidate_ids
        |> Enum.reject(&is_nil/1)
        |> Enum.uniq()
        |> Enum.sort()

      {action, candidate_ids}
    end)
  end

  defp candidate_rejection_reasons,
    do: OrbitalDynamics.Timeline.capabilities().candidate_rejection_reasons

  defp candidate_rejection_actions,
    do: OrbitalDynamics.Timeline.capabilities().candidate_rejection_actions

  defp operational_kinds,
    do: OrbitalDynamics.Timeline.capabilities().operational_kinds

  defp validate_optional_activity_context(issues, path, map, field),
    do: ActivityContextContracts.validate_optional(issues, path, map, field)

  defp frequency_map(rows, field),
    do: CollectionAggregation.frequency_map(rows, field)

  defp expect_field_equals(issues, path, map, field, nil),
    do: expect_field_equals(issues, path, map, field, nil, nil)

  defp expect_field_equals(issues, path, map, field, expected),
    do: expect_field_equals(issues, path, map, field, expected, "must equal #{expected}")
end
