defmodule OrbitalDynamics.Schema.CandidateRejectionReportContracts do
  @moduledoc false

  def validate(issues, path, report, callbacks) when is_list(callbacks) do
    issues
    |> expect_equal(callbacks, path, report, "schema_contract", "candidate_rejection_report.v1")
    |> expect_equal(
      callbacks,
      path,
      report,
      "model",
      "artifact_only_candidate_rejection_explanation"
    )
    |> expect_type(callbacks, path, report, "source", :binary)
    |> expect_non_negative_integer(callbacks, path, report, "candidate_count")
    |> expect_non_negative_integer(callbacks, path, report, "row_count")
    |> expect_non_negative_integer(callbacks, path, report, "rejected_count")
    |> expect_non_negative_integer(callbacks, path, report, "not_rejected_count")
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      report,
      "invalid_candidate_input_count"
    )
    |> expect_non_negative_integer(callbacks, path, report, "reviewable_count")
    |> expect_type(callbacks, path, report, "rejection_reason_counts", :map)
    |> expect_optional_type(
      callbacks,
      path,
      report,
      "candidate_id_sets_by_rejection_reason",
      :map
    )
    |> expect_optional_type(
      callbacks,
      path,
      report,
      "candidate_ids_by_required_operator_action",
      :map
    )
    |> expect_optional_type(callbacks, path, report, "required_operator_action_counts", :map)
    |> expect_optional_type(callbacks, path, report, "model_limits", :list)
    |> validate_string_list_items(callbacks, path, report, "model_limits")
    |> validate_optional_exact_model_limits(
      callbacks,
      path,
      report,
      candidate_rejection_report_model_limits(callbacks),
      "must match candidate rejection report model limits"
    )
    |> validate_optional_stable_id_list(callbacks, path, report, "rejected_candidate_ids")
    |> validate_optional_stable_id_list(callbacks, path, report, "not_rejected_candidate_ids")
    |> validate_optional_stable_id_list(callbacks, path, report, "reviewable_candidate_ids")
    |> validate_optional_stable_id_list(callbacks, path, report, "invalid_candidate_input_ids")
    |> validate_candidate_id_sets_by_rejection_reason(
      callbacks,
      path <> ".candidate_id_sets_by_rejection_reason",
      Map.get(report, "candidate_id_sets_by_rejection_reason")
    )
    |> validate_candidate_ids_by_required_operator_action(
      callbacks,
      path <> ".candidate_ids_by_required_operator_action",
      Map.get(report, "candidate_ids_by_required_operator_action")
    )
    |> expect_type(callbacks, path, report, "rows", :list)
    |> expect_type(callbacks, path, report, "assumptions", :map)
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".rejection_reason_counts",
      Map.get(report, "rejection_reason_counts")
    )
    |> validate_non_negative_integer_count_map(
      callbacks,
      path <> ".required_operator_action_counts",
      Map.get(report, "required_operator_action_counts")
    )
    |> validate_rows(
      callbacks,
      path <> ".rows",
      Map.get(report, "rows", []),
      fn acc, row_path, row -> validate_row(acc, row_path, row, callbacks) end
    )
    |> validate_counts(callbacks, path, report)
  end

  defp validate_row(issues, path, row, callbacks) do
    issues
    |> require_fields(callbacks, path, row, [
      "id",
      "candidate_id",
      "rejection_status",
      "rejection_reasons",
      "reason_count",
      "reviewable",
      "required_operator_action",
      "activity_context"
    ])
    |> validate_stable_ids(callbacks, path, row, [
      "id",
      "candidate_id",
      "activity_id",
      "timeline_id",
      "source_window_id"
    ])
    |> expect_one_of(callbacks, path, row, "rejection_status", ["rejected", "not_rejected"])
    |> expect_optional_one_of(
      callbacks,
      path,
      row,
      "primary_rejection_reason",
      candidate_rejection_reasons()
    )
    |> expect_type(callbacks, path, row, "rejection_reasons", :list)
    |> validate_string_list_allowed(
      callbacks,
      path,
      row,
      "rejection_reasons",
      candidate_rejection_reasons()
    )
    |> expect_non_negative_integer(callbacks, path, row, "reason_count")
    |> expect_field_equals(
      callbacks,
      path,
      row,
      "reason_count",
      row |> Map.get("rejection_reasons", []) |> length()
    )
    |> expect_type(callbacks, path, row, "reviewable", :boolean)
    |> expect_one_of(
      callbacks,
      path,
      row,
      "required_operator_action",
      candidate_rejection_actions()
    )
    |> expect_optional_type(callbacks, path, row, "activity_type", :binary)
    |> expect_optional_one_of(callbacks, path, row, "operational_kind", operational_kinds())
    |> expect_optional_type(callbacks, path, row, "source_window_type", :binary)
    |> expect_optional_type(callbacks, path, row, "violated_constraint", :binary)
    |> expect_optional_number(callbacks, path, row, "required_margin")
    |> expect_optional_number(callbacks, path, row, "actual_margin")
    |> expect_optional_type(callbacks, path, row, "declared_rejection_reasons", :list)
    |> expect_type(callbacks, path, row, "activity_context", :map)
  end

  defp validate_counts(issues, callbacks, path, report) do
    rows =
      report
      |> Map.get("rows", [])
      |> Enum.filter(&is_map/1)

    issues
    |> expect_field_equals(callbacks, path, report, "row_count", length(rows))
    |> expect_field_equals(callbacks, path, report, "candidate_count", length(rows))
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "rejected_count",
      Enum.count(rows, &(&1["rejection_status"] == "rejected"))
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "not_rejected_count",
      Enum.count(rows, &(&1["rejection_status"] == "not_rejected"))
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "invalid_candidate_input_count",
      Enum.count(rows, &("invalid_candidate_input" in Map.get(&1, "rejection_reasons", [])))
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "reviewable_count",
      Enum.count(rows, & &1["reviewable"])
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "rejection_reason_counts",
      candidate_rejection_reason_frequency_map(rows),
      "must equal row-derived rejection_reason_counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "rejected_candidate_ids",
      candidate_rejection_row_ids(rows, &(&1["rejection_status"] == "rejected")),
      "must equal row-derived rejected_candidate_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "not_rejected_candidate_ids",
      candidate_rejection_row_ids(rows, &(&1["rejection_status"] == "not_rejected")),
      "must equal row-derived not_rejected_candidate_ids"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "reviewable_candidate_ids",
      candidate_rejection_row_ids(rows, & &1["reviewable"]),
      "must equal row-derived reviewable_candidate_ids"
    )
    |> expect_field_equals(
      callbacks,
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
      callbacks,
      path,
      report,
      "candidate_id_sets_by_rejection_reason",
      candidate_id_sets_by_rejection_reason(rows),
      "must equal row-derived candidate_id_sets_by_rejection_reason"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "candidate_ids_by_required_operator_action",
      candidate_ids_by_required_operator_action(rows),
      "must equal row-derived candidate_ids_by_required_operator_action"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "required_operator_action_counts",
      frequency_map(callbacks, rows, "required_operator_action"),
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

  defp validate_candidate_id_sets_by_rejection_reason(issues, _callbacks, _path, nil),
    do: issues

  defp validate_candidate_id_sets_by_rejection_reason(issues, callbacks, path, %{} = reason_ids) do
    allowed_reasons = candidate_rejection_reasons()

    Enum.reduce(reason_ids, issues, fn {reason, candidate_ids}, acc ->
      acc =
        if reason in allowed_reasons,
          do: acc,
          else: [
            error(callbacks, "#{path}.#{reason}", "must use a supported rejection reason") | acc
          ]

      case candidate_ids do
        ids when is_list(ids) ->
          validate_stable_id_list(callbacks, acc, "#{path}.#{reason}", ids)

        _value ->
          [error(callbacks, "#{path}.#{reason}", "must be a list") | acc]
      end
    end)
  end

  defp validate_candidate_id_sets_by_rejection_reason(issues, callbacks, path, _reason_ids),
    do: [error(callbacks, path, "must be an object") | issues]

  defp validate_candidate_ids_by_required_operator_action(issues, _callbacks, _path, nil),
    do: issues

  defp validate_candidate_ids_by_required_operator_action(
         issues,
         callbacks,
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
              callbacks,
              "#{path}.#{action}",
              "must use a supported candidate rejection action"
            )
            | acc
          ]

      case candidate_ids do
        ids when is_list(ids) ->
          validate_stable_id_list(callbacks, acc, "#{path}.#{action}", ids)

        _value ->
          [error(callbacks, "#{path}.#{action}", "must be a list") | acc]
      end
    end)
  end

  defp validate_candidate_ids_by_required_operator_action(issues, callbacks, path, _action_ids),
    do: [error(callbacks, path, "must be an object") | issues]

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

  defp require_callback(callbacks, name), do: Keyword.fetch!(callbacks, name)

  defp candidate_rejection_report_model_limits(callbacks),
    do: apply(require_callback(callbacks, :candidate_rejection_report_model_limits), [])

  defp require_fields(issues, callbacks, path, map, fields),
    do: apply(require_callback(callbacks, :require_fields), [issues, path, map, fields])

  defp validate_stable_ids(issues, callbacks, path, map, fields),
    do: apply(require_callback(callbacks, :validate_stable_ids), [issues, path, map, fields])

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

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :validate_string_list_items), [issues, path, map, field])

  defp validate_optional_exact_model_limits(issues, callbacks, path, map, limits, message),
    do:
      apply(require_callback(callbacks, :validate_optional_exact_model_limits), [
        issues,
        path,
        map,
        limits,
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

  defp validate_non_negative_integer_count_map(issues, callbacks, path, map),
    do:
      apply(require_callback(callbacks, :validate_non_negative_integer_count_map), [
        issues,
        path,
        map
      ])

  defp validate_rows(issues, callbacks, path, rows, validator),
    do: apply(require_callback(callbacks, :validate_rows), [issues, path, rows, validator])

  defp expect_one_of(issues, callbacks, path, map, field, allowed),
    do: apply(require_callback(callbacks, :expect_one_of), [issues, path, map, field, allowed])

  defp expect_optional_one_of(issues, callbacks, path, map, field, allowed),
    do:
      apply(require_callback(callbacks, :expect_optional_one_of), [
        issues,
        path,
        map,
        field,
        allowed
      ])

  defp validate_string_list_allowed(issues, callbacks, path, map, field, allowed),
    do:
      apply(require_callback(callbacks, :validate_string_list_allowed), [
        issues,
        path,
        map,
        field,
        allowed
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

  defp expect_optional_number(issues, callbacks, path, map, field),
    do: apply(require_callback(callbacks, :expect_optional_number), [issues, path, map, field])

  defp validate_stable_id_list(callbacks, issues, path, ids),
    do: apply(require_callback(callbacks, :validate_stable_id_list), [issues, path, ids])

  defp frequency_map(callbacks, rows, field),
    do: apply(require_callback(callbacks, :frequency_map), [rows, field])

  defp error(callbacks, path, message),
    do: apply(require_callback(callbacks, :error), [path, message])
end
