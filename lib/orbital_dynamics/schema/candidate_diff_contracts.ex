defmodule OrbitalDynamics.Schema.CandidateDiffContracts do
  @moduledoc false

  def validate_optional_report(issues, _path, nil, _callbacks), do: issues

  def validate_optional_report(issues, path, %{} = report, callbacks) when is_list(callbacks) do
    issues
    |> require_fields(callbacks, path, report, [
      "schema_contract",
      "model",
      "prior_candidate_count",
      "refreshed_candidate_count",
      "retained_candidate_count",
      "new_candidate_count",
      "invalidated_candidate_count",
      "retained_candidates",
      "new_candidates",
      "invalidated_candidates"
    ])
    |> expect_equal(callbacks, path, report, "schema_contract", "candidate_diff_report.v1")
    |> expect_equal(
      callbacks,
      path,
      report,
      "model",
      "candidate_id_set_diff_with_semantic_change_reasons"
    )
    |> expect_non_negative_integer(callbacks, path, report, "prior_candidate_count")
    |> expect_non_negative_integer(callbacks, path, report, "refreshed_candidate_count")
    |> expect_non_negative_integer(callbacks, path, report, "retained_candidate_count")
    |> expect_non_negative_integer(callbacks, path, report, "new_candidate_count")
    |> expect_non_negative_integer(callbacks, path, report, "invalidated_candidate_count")
    |> expect_type(callbacks, path, report, "retained_candidates", :list)
    |> expect_type(callbacks, path, report, "new_candidates", :list)
    |> expect_type(callbacks, path, report, "invalidated_candidates", :list)
    |> expect_optional_type(callbacks, path, report, "model_limits", :list)
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      report,
      "valid_prior_candidate_count"
    )
    |> expect_optional_non_negative_integer(
      callbacks,
      path,
      report,
      "invalid_prior_candidate_input_count"
    )
    |> expect_optional_type(callbacks, path, report, "invalid_prior_candidate_input_ids", :list)
    |> expect_optional_type(callbacks, path, report, "source_window_lineage", :list)
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      report,
      "invalid_prior_candidate_input_ids"
    )
    |> validate_string_list_items(callbacks, path, report, "model_limits")
    |> validate_report_model_limits(callbacks, path, report)
    |> validate_rows(
      callbacks,
      path <> ".retained_candidates",
      Map.get(report, "retained_candidates", []),
      fn acc, row_path, row -> validate_row(acc, row_path, row, callbacks) end
    )
    |> validate_rows(
      callbacks,
      path <> ".new_candidates",
      Map.get(report, "new_candidates", []),
      fn acc, row_path, row -> validate_row(acc, row_path, row, callbacks) end
    )
    |> validate_rows(
      callbacks,
      path <> ".invalidated_candidates",
      Map.get(report, "invalidated_candidates", []),
      fn acc, row_path, row -> validate_invalidated_candidate(acc, row_path, row, callbacks) end
    )
    |> validate_optional_rows(
      callbacks,
      path <> ".source_window_lineage",
      Map.get(report, "source_window_lineage"),
      fn acc, row_path, row -> validate_source_window_lineage(acc, row_path, row, callbacks) end
    )
    |> validate_report_counts(callbacks, path, report)
    |> validate_report_lineage(callbacks, path, report)
  end

  def validate_optional_report(issues, path, _report, callbacks) when is_list(callbacks),
    do: [error(callbacks, path, "must be an object") | issues]

  def validate_row(issues, path, candidate, callbacks) when is_list(callbacks) do
    issues
    |> require_fields(callbacks, path, candidate, ["id", "type", "scenario_id", "diff_reason"])
    |> validate_stable_ids(callbacks, path, candidate, [
      "id",
      "scenario_id",
      "target_id",
      "ground_station_id",
      "source_target_id",
      "matched_prior_candidate_id",
      "source_window_id"
    ])
    |> expect_one_of(callbacks, path, candidate, "diff_reason", [
      "present_in_prior_candidate_set",
      "present_in_prior_candidate_set_with_semantic_changes",
      "not_present_in_prior_candidate_set",
      "semantically_similar_prior_candidate_changed",
      "ambiguous_semantic_prior_candidate_match"
    ])
    |> expect_optional_number(callbacks, path, candidate, "starts_at_s")
    |> expect_optional_number(callbacks, path, candidate, "ends_at_s")
    |> expect_optional_type(callbacks, path, candidate, "direction", :binary)
    |> expect_optional_type(callbacks, path, candidate, "source_target", :map)
    |> expect_optional_number(callbacks, path, candidate, "target_latitude_deg")
    |> expect_optional_number(callbacks, path, candidate, "target_longitude_deg")
    |> expect_optional_number(callbacks, path, candidate, "target_minimum_elevation_deg")
    |> expect_optional_number(callbacks, path, candidate, "target_priority")
    |> expect_optional_type(callbacks, path, candidate, "target_priority_source", :binary)
    |> expect_optional_type(callbacks, path, candidate, "target_priority_objective_ids", :list)
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      candidate,
      "target_priority_objective_ids"
    )
    |> expect_optional_type(callbacks, path, candidate, "target_priority_objective_type", :binary)
    |> expect_optional_list(callbacks, path, candidate, "semantic_change_reasons")
    |> validate_candidate_refresh_scoped_context_fields(callbacks, path, candidate)
    |> validate_semantic_change_details(path, candidate, callbacks)
    |> validate_changed_fields(path, candidate, callbacks)
  end

  def validate_invalidated_candidate(issues, path, candidate, callbacks)
      when is_list(callbacks) do
    issues
    |> require_fields(callbacks, path, candidate, ["id", "invalidated_reason"])
    |> validate_stable_ids(callbacks, path, candidate, [
      "id",
      "scenario_id",
      "target_id",
      "ground_station_id",
      "source_target_id",
      "replacement_candidate_id",
      "source_window_id"
    ])
    |> expect_optional_type(callbacks, path, candidate, "direction", :binary)
    |> expect_optional_type(callbacks, path, candidate, "source_target", :map)
    |> expect_optional_number(callbacks, path, candidate, "target_latitude_deg")
    |> expect_optional_number(callbacks, path, candidate, "target_longitude_deg")
    |> expect_optional_number(callbacks, path, candidate, "target_minimum_elevation_deg")
    |> expect_optional_number(callbacks, path, candidate, "target_priority")
    |> expect_optional_type(callbacks, path, candidate, "target_priority_source", :binary)
    |> expect_optional_type(callbacks, path, candidate, "target_priority_objective_ids", :list)
    |> validate_optional_stable_id_list(
      callbacks,
      path,
      candidate,
      "target_priority_objective_ids"
    )
    |> expect_optional_type(callbacks, path, candidate, "target_priority_objective_type", :binary)
    |> expect_optional_list(callbacks, path, candidate, "semantic_change_reasons")
    |> expect_optional_number(callbacks, path, candidate, "starts_at_s")
    |> expect_optional_number(callbacks, path, candidate, "ends_at_s")
    |> validate_interval(callbacks, path, candidate)
    |> validate_invalidated_candidate_source_target(callbacks, path, candidate)
    |> validate_candidate_refresh_scoped_context_fields(callbacks, path, candidate)
    |> validate_semantic_change_details(path, candidate, callbacks)
    |> validate_changed_fields(path, candidate, callbacks)
  end

  def validate_semantic_change_details(issues, path, row, callbacks) when is_list(callbacks) do
    case Map.get(row, "semantic_change_details") do
      nil ->
        issues

      details when is_list(details) ->
        details
        |> Enum.with_index()
        |> Enum.reduce(issues, fn {detail, index}, acc ->
          validate_semantic_change_detail(
            acc,
            "#{path}.semantic_change_details[#{index}]",
            detail,
            callbacks
          )
        end)

      _value ->
        [error(callbacks, "#{path}.semantic_change_details", "must be a list") | issues]
    end
  end

  def validate_changed_fields(issues, path, row, callbacks) when is_list(callbacks) do
    issues
    |> expect_optional_type(callbacks, path, row, "changed_fields", :list)
    |> validate_string_list_items(callbacks, path, row, "changed_fields")
    |> expect_optional_type(callbacks, path, row, "candidate_diff_changed_fields", :list)
    |> validate_string_list_items(callbacks, path, row, "candidate_diff_changed_fields")
    |> expect_optional_integer(callbacks, path, row, "candidate_diff_changed_field_count")
    |> expect_field_at_least(callbacks, path, row, "candidate_diff_changed_field_count", 0)
    |> validate_changed_field_aliases(callbacks, path, row)
    |> validate_changed_field_count(callbacks, path, row)
    |> validate_semantic_change_reasons(callbacks, path, row)
  end

  def validate_source_window_lineage(issues, path, lineage, callbacks) when is_list(callbacks) do
    issues
    |> require_fields(callbacks, path, lineage, [
      "candidate_activity_id",
      "source_window_id",
      "source_window_type",
      "scenario_id"
    ])
    |> validate_stable_ids(callbacks, path, lineage, [
      "candidate_activity_id",
      "source_window_id",
      "scenario_id"
    ])
    |> validate_candidate_refresh_scoped_context_fields(callbacks, path, lineage)
    |> validate_source_window_lineage_identity(callbacks, path, lineage)
    |> validate_source_window_lineage_source_window_context(callbacks, path, lineage)
  end

  def validate_optional_source_window(issues, path, row, field, callbacks)
      when is_list(callbacks) do
    case Map.get(row, field) do
      nil ->
        issues

      %{} = source_window ->
        validate_source_window(issues, "#{path}.#{field}", source_window, callbacks)

      _value ->
        [error(callbacks, "#{path}.#{field}", "must be an object") | issues]
    end
  end

  def validate_optional_source_window_lineage(issues, path, row, field, callbacks)
      when is_list(callbacks) do
    case Map.get(row, field) do
      nil ->
        issues

      %{} = lineage ->
        validate_source_window_lineage(issues, "#{path}.#{field}", lineage, callbacks)

      _value ->
        [error(callbacks, "#{path}.#{field}", "must be an object") | issues]
    end
  end

  defp validate_report_model_limits(issues, callbacks, path, report) do
    case Map.get(report, "model_limits") do
      nil ->
        issues

      :null ->
        issues

      limits when is_list(limits) ->
        if limits == OrbitalDynamics.CandidateRefresh.model_limits() do
          issues
        else
          [
            error(callbacks, "#{path}.model_limits", "must match candidate refresh model limits")
            | issues
          ]
        end

      _value ->
        issues
    end
  end

  defp validate_report_counts(issues, callbacks, path, report) do
    retained = report |> Map.get("retained_candidates", []) |> Enum.filter(&is_map/1)
    added = report |> Map.get("new_candidates", []) |> Enum.filter(&is_map/1)
    invalidated = report |> Map.get("invalidated_candidates", []) |> Enum.filter(&is_map/1)

    issues
    |> expect_field_equals(callbacks, path, report, "retained_candidate_count", length(retained))
    |> expect_field_equals(callbacks, path, report, "new_candidate_count", length(added))
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "invalidated_candidate_count",
      length(invalidated)
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "refreshed_candidate_count",
      length(retained) + length(added),
      "must equal retained_candidate_count plus new_candidate_count"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "prior_candidate_count",
      row_count_sum(callbacks, report, [
        "valid_prior_candidate_count",
        "invalid_prior_candidate_input_count"
      ]),
      "must equal valid plus invalid prior candidate counts"
    )
    |> expect_field_equals(
      callbacks,
      path,
      report,
      "invalid_prior_candidate_input_count",
      list_count(callbacks, report, "invalid_prior_candidate_input_ids")
    )
  end

  defp validate_invalidated_candidate_source_target(
         issues,
         callbacks,
         path,
         %{"source_target" => %{} = source_target} = candidate
       ) do
    issues
    |> validate_stable_ids(callbacks, path <> ".source_target", source_target, ["id"])
    |> expect_field_equals(
      callbacks,
      path,
      candidate,
      "source_target_id",
      Map.get(source_target, "id"),
      "must match source_target.id"
    )
    |> expect_field_equals(
      callbacks,
      path,
      candidate,
      "target_id",
      Map.get(source_target, "id"),
      "must match source_target.id"
    )
    |> expect_field_equals(
      callbacks,
      path,
      candidate,
      "target_latitude_deg",
      Map.get(source_target, "latitude_deg"),
      "must match source_target.latitude_deg"
    )
    |> expect_field_equals(
      callbacks,
      path,
      candidate,
      "target_longitude_deg",
      Map.get(source_target, "longitude_deg"),
      "must match source_target.longitude_deg"
    )
    |> expect_field_equals(
      callbacks,
      path,
      candidate,
      "target_minimum_elevation_deg",
      Map.get(source_target, "minimum_elevation_deg"),
      "must match source_target.minimum_elevation_deg"
    )
  end

  defp validate_invalidated_candidate_source_target(issues, _callbacks, _path, _candidate),
    do: issues

  defp validate_semantic_change_detail(issues, path, %{} = detail, callbacks) do
    issues
    |> require_fields(callbacks, path, detail, [
      "field",
      "reason",
      "prior_value",
      "refreshed_value"
    ])
    |> expect_type(callbacks, path, detail, "field", :binary)
    |> expect_type(callbacks, path, detail, "reason", :binary)
    |> expect_optional_type(callbacks, path, detail, "prior_path", :binary)
    |> expect_optional_type(callbacks, path, detail, "refreshed_path", :binary)
  end

  defp validate_semantic_change_detail(issues, path, _detail, callbacks),
    do: [error(callbacks, path, "must be an object") | issues]

  defp validate_changed_field_aliases(issues, callbacks, path, row) do
    case {Map.get(row, "changed_fields"), Map.get(row, "candidate_diff_changed_fields")} do
      {changed_fields, candidate_diff_changed_fields}
      when is_list(changed_fields) and is_list(candidate_diff_changed_fields) ->
        expect_field_equals(
          issues,
          callbacks,
          path,
          row,
          "candidate_diff_changed_fields",
          changed_fields,
          "must match changed_fields"
        )

      _fields ->
        issues
    end
  end

  defp validate_changed_field_count(issues, callbacks, path, row) do
    case {Map.get(row, "candidate_diff_changed_fields"),
          Map.get(row, "candidate_diff_changed_field_count")} do
      {fields, count} when is_list(fields) and is_integer(count) ->
        expect_field_equals(
          issues,
          callbacks,
          path,
          row,
          "candidate_diff_changed_field_count",
          length(fields)
        )

      _fields_or_count ->
        issues
    end
  end

  defp validate_semantic_change_reasons(issues, callbacks, path, row) do
    case {Map.get(row, "semantic_change_reasons"), Map.get(row, "semantic_change_details")} do
      {reasons, details} when is_list(reasons) and is_list(details) ->
        detail_reasons =
          details
          |> Enum.filter(&is_map/1)
          |> Enum.map(&Map.get(&1, "reason"))

        expect_field_equals(
          issues,
          callbacks,
          path,
          row,
          "semantic_change_reasons",
          detail_reasons,
          "must match semantic_change_details reasons"
        )

      _reasons_or_details ->
        issues
    end
  end

  defp validate_source_window_lineage_identity(
         issues,
         callbacks,
         path,
         %{"source_window_id" => source_window_id, "source_window_type" => source_window_type}
       )
       when is_binary(source_window_id) and is_binary(source_window_type) do
    if String.contains?(source_window_id, ":#{source_window_type}:") do
      issues
    else
      [
        error(
          callbacks,
          path <> ".source_window_type",
          "must match source_window_id source-window type"
        )
        | issues
      ]
    end
  end

  defp validate_source_window_lineage_identity(issues, _callbacks, _path, _lineage), do: issues

  defp validate_source_window_lineage_source_window_context(
         issues,
         callbacks,
         path,
         %{"source_window" => %{} = source_window} = lineage
       ) do
    issues
    |> validate_stable_ids(callbacks, path <> ".source_window", source_window, [
      "id",
      "scenario_id",
      "target_id",
      "ground_station_id"
    ])
    |> expect_field_equals(
      callbacks,
      path <> ".source_window",
      source_window,
      "id",
      Map.get(lineage, "source_window_id"),
      "must match lineage source_window_id"
    )
    |> expect_field_equals(
      callbacks,
      path <> ".source_window",
      source_window,
      "type",
      Map.get(lineage, "source_window_type"),
      "must match lineage source_window_type"
    )
    |> expect_field_equals(
      callbacks,
      path <> ".source_window",
      source_window,
      "scenario_id",
      Map.get(lineage, "scenario_id"),
      "must match lineage scenario_id"
    )
    |> expect_optional_number(callbacks, path <> ".source_window", source_window, "starts_at_s")
    |> expect_optional_number(callbacks, path <> ".source_window", source_window, "ends_at_s")
    |> expect_optional_number(callbacks, path <> ".source_window", source_window, "duration_s")
    |> validate_candidate_refresh_scoped_context_fields(
      callbacks,
      path <> ".source_window",
      source_window
    )
  end

  defp validate_source_window_lineage_source_window_context(issues, callbacks, path, %{
         "source_window" => source_window
       })
       when not is_nil(source_window) do
    [error(callbacks, path <> ".source_window", "must be an object") | issues]
  end

  defp validate_source_window_lineage_source_window_context(issues, _callbacks, _path, _lineage),
    do: issues

  defp validate_source_window(issues, path, source_window, callbacks) do
    issues
    |> validate_stable_ids(callbacks, path, source_window, [
      "id",
      "scenario_id",
      "target_id",
      "ground_station_id"
    ])
    |> expect_optional_type(callbacks, path, source_window, "type", :binary)
    |> expect_optional_number(callbacks, path, source_window, "starts_at_s")
    |> expect_optional_number(callbacks, path, source_window, "ends_at_s")
    |> expect_optional_number(callbacks, path, source_window, "duration_s")
    |> expect_optional_number(callbacks, path, source_window, "max_elevation_deg")
    |> expect_optional_number(callbacks, path, source_window, "minimum_elevation_deg")
    |> expect_optional_type(callbacks, path, source_window, "event_timing_policy", :binary)
    |> expect_optional_type(callbacks, path, source_window, "event_detector", :binary)
    |> expect_optional_number(callbacks, path, source_window, "event_time_tolerance_s")
    |> expect_optional_number(callbacks, path, source_window, "max_sample_step_s")
    |> expect_optional_type(callbacks, path, source_window, "confidence", :binary)
    |> validate_candidate_refresh_scoped_context_fields(callbacks, path, source_window)
  end

  defp validate_report_lineage(issues, callbacks, path, report) do
    candidates =
      ["retained_candidates", "new_candidates", "invalidated_candidates"]
      |> Enum.flat_map(fn field -> Map.get(report, field, []) end)
      |> Enum.filter(&is_map/1)
      |> Map.new(fn candidate -> {Map.get(candidate, "id"), candidate} end)

    report
    |> Map.get("source_window_lineage", [])
    |> case do
      rows when is_list(rows) ->
        rows
        |> Enum.with_index()
        |> Enum.reduce(issues, fn {lineage, index}, acc ->
          candidate_activity_id =
            if is_map(lineage), do: Map.get(lineage, "candidate_activity_id")

          candidate = candidates[candidate_activity_id]

          cond do
            is_map(lineage) and is_nil(candidate) ->
              [
                error(
                  callbacks,
                  "#{path}.source_window_lineage[#{index}].candidate_activity_id",
                  "must match a candidate diff row"
                )
                | acc
              ]

            is_map(lineage) and is_map(candidate) and
                Map.get(lineage, "source_window_id") != Map.get(candidate, "source_window_id") ->
              [
                error(
                  callbacks,
                  "#{path}.source_window_lineage[#{index}].source_window_id",
                  "must match candidate activity source_window_id"
                )
                | acc
              ]

            true ->
              acc
          end
        end)

      _rows ->
        issues
    end
  end

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

  defp validate_optional_stable_id_list(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :validate_optional_stable_id_list), [
        issues,
        path,
        map,
        field
      ])

  defp validate_string_list_items(issues, callbacks, path, map, field),
    do:
      apply(require_callback(callbacks, :validate_string_list_items), [issues, path, map, field])

  defp validate_rows(issues, callbacks, path, rows, validator),
    do: apply(require_callback(callbacks, :validate_rows), [issues, path, rows, validator])

  defp validate_optional_rows(issues, callbacks, path, rows, validator),
    do:
      apply(require_callback(callbacks, :validate_optional_rows), [issues, path, rows, validator])

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

  defp list_count(callbacks, map, field),
    do: apply(require_callback(callbacks, :list_count), [map, field])

  defp row_count_sum(callbacks, report, fields),
    do: apply(require_callback(callbacks, :row_count_sum), [report, fields])

  defp expect_one_of(issues, callbacks, path, map, field, allowed),
    do: apply(require_callback(callbacks, :expect_one_of), [issues, path, map, field, allowed])

  defp expect_optional_number(issues, callbacks, path, map, field),
    do: apply(require_callback(callbacks, :expect_optional_number), [issues, path, map, field])

  defp expect_optional_list(issues, callbacks, path, map, field),
    do: apply(require_callback(callbacks, :expect_optional_list), [issues, path, map, field])

  defp validate_candidate_refresh_scoped_context_fields(issues, callbacks, path, row),
    do:
      apply(require_callback(callbacks, :validate_candidate_refresh_scoped_context_fields), [
        issues,
        path,
        row
      ])

  defp validate_interval(issues, callbacks, path, row),
    do: apply(require_callback(callbacks, :validate_interval), [issues, path, row])

  defp expect_optional_integer(issues, callbacks, path, map, field),
    do: apply(require_callback(callbacks, :expect_optional_integer), [issues, path, map, field])

  defp expect_field_at_least(issues, callbacks, path, map, field, minimum),
    do:
      apply(require_callback(callbacks, :expect_field_at_least), [
        issues,
        path,
        map,
        field,
        minimum
      ])

  defp error(callbacks, path, message),
    do: apply(require_callback(callbacks, :error), [path, message])

  defp require_callback(callbacks, key) do
    Keyword.fetch!(callbacks, key)
  end
end
