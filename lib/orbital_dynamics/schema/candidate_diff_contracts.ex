defmodule OrbitalDynamics.Schema.CandidateDiffContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CollectionValidation,
    only: [validate_optional_rows: 4, validate_rows: 4]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [validate_optional_stable_id_list: 4, validate_stable_ids: 4]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_equal: 5,
      expect_field_at_least: 5,
      expect_field_equals: 6,
      expect_non_negative_integer: 4,
      expect_one_of: 5,
      expect_optional_integer: 4,
      expect_optional_list: 4,
      expect_optional_non_negative_integer: 4,
      expect_optional_number: 4,
      expect_optional_type: 5,
      expect_type: 5,
      require_fields: 4,
      validate_interval: 3,
      validate_string_list_items: 4
    ]

  alias OrbitalDynamics.Schema.{CandidateRefreshScopedContextContracts, CollectionAggregation}

  def validate_optional_report(issues, _path, nil), do: issues

  def validate_optional_report(issues, path, %{} = report) do
    issues
    |> require_fields(path, report, [
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
    |> expect_equal(path, report, "schema_contract", "candidate_diff_report.v1")
    |> expect_equal(
      path,
      report,
      "model",
      "candidate_id_set_diff_with_semantic_change_reasons"
    )
    |> expect_non_negative_integer(path, report, "prior_candidate_count")
    |> expect_non_negative_integer(path, report, "refreshed_candidate_count")
    |> expect_non_negative_integer(path, report, "retained_candidate_count")
    |> expect_non_negative_integer(path, report, "new_candidate_count")
    |> expect_non_negative_integer(path, report, "invalidated_candidate_count")
    |> expect_type(path, report, "retained_candidates", :list)
    |> expect_type(path, report, "new_candidates", :list)
    |> expect_type(path, report, "invalidated_candidates", :list)
    |> expect_optional_type(path, report, "model_limits", :list)
    |> expect_optional_non_negative_integer(
      path,
      report,
      "valid_prior_candidate_count"
    )
    |> expect_optional_non_negative_integer(
      path,
      report,
      "invalid_prior_candidate_input_count"
    )
    |> expect_optional_type(path, report, "invalid_prior_candidate_input_ids", :list)
    |> expect_optional_type(path, report, "source_window_lineage", :list)
    |> validate_optional_stable_id_list(
      path,
      report,
      "invalid_prior_candidate_input_ids"
    )
    |> validate_string_list_items(path, report, "model_limits")
    |> validate_report_model_limits(path, report)
    |> validate_rows(
      path <> ".retained_candidates",
      Map.get(report, "retained_candidates", []),
      fn acc, row_path, row -> validate_row(acc, row_path, row) end
    )
    |> validate_rows(
      path <> ".new_candidates",
      Map.get(report, "new_candidates", []),
      fn acc, row_path, row -> validate_row(acc, row_path, row) end
    )
    |> validate_rows(
      path <> ".invalidated_candidates",
      Map.get(report, "invalidated_candidates", []),
      fn acc, row_path, row -> validate_invalidated_candidate(acc, row_path, row) end
    )
    |> validate_optional_rows(
      path <> ".source_window_lineage",
      Map.get(report, "source_window_lineage"),
      fn acc, row_path, row -> validate_source_window_lineage(acc, row_path, row) end
    )
    |> validate_report_counts(path, report)
    |> validate_report_lineage(path, report)
  end

  def validate_optional_report(issues, path, _report),
    do: [error(path, "must be an object") | issues]

  def validate_optional_source_window_lineage(issues, _path, nil), do: issues

  def validate_optional_source_window_lineage(issues, path, lineage) when is_list(lineage) do
    validate_rows(issues, path, lineage, fn acc, row_path, row ->
      acc =
        if Map.has_key?(row, "schema_contract") do
          expect_equal(acc, row_path, row, "schema_contract", "source_window_lineage.v1")
        else
          acc
        end

      validate_source_window_lineage(acc, row_path, row)
    end)
  end

  def validate_optional_source_window_lineage(issues, path, _lineage),
    do: [error(path, "must be a list") | issues]

  def validate_row(issues, path, candidate) do
    issues
    |> require_fields(path, candidate, ["id", "type", "scenario_id", "diff_reason"])
    |> validate_stable_ids(path, candidate, [
      "id",
      "scenario_id",
      "target_id",
      "ground_station_id",
      "source_target_id",
      "matched_prior_candidate_id",
      "source_window_id"
    ])
    |> expect_one_of(path, candidate, "diff_reason", [
      "present_in_prior_candidate_set",
      "present_in_prior_candidate_set_with_semantic_changes",
      "not_present_in_prior_candidate_set",
      "semantically_similar_prior_candidate_changed",
      "ambiguous_semantic_prior_candidate_match"
    ])
    |> expect_optional_number(path, candidate, "starts_at_s")
    |> expect_optional_number(path, candidate, "ends_at_s")
    |> expect_optional_type(path, candidate, "direction", :binary)
    |> expect_optional_type(path, candidate, "source_target", :map)
    |> expect_optional_number(path, candidate, "target_latitude_deg")
    |> expect_optional_number(path, candidate, "target_longitude_deg")
    |> expect_optional_number(path, candidate, "target_minimum_elevation_deg")
    |> expect_optional_number(path, candidate, "target_priority")
    |> expect_optional_type(path, candidate, "target_priority_source", :binary)
    |> expect_optional_type(path, candidate, "target_priority_objective_ids", :list)
    |> validate_optional_stable_id_list(
      path,
      candidate,
      "target_priority_objective_ids"
    )
    |> expect_optional_type(path, candidate, "target_priority_objective_type", :binary)
    |> expect_optional_list(path, candidate, "semantic_change_reasons")
    |> validate_candidate_refresh_scoped_context_fields(path, candidate)
    |> validate_semantic_change_details(path, candidate)
    |> validate_changed_fields(path, candidate)
  end

  def validate_invalidated_candidate(issues, path, candidate) do
    issues
    |> require_fields(path, candidate, ["id", "invalidated_reason"])
    |> validate_stable_ids(path, candidate, [
      "id",
      "scenario_id",
      "target_id",
      "ground_station_id",
      "source_target_id",
      "replacement_candidate_id",
      "source_window_id"
    ])
    |> expect_optional_type(path, candidate, "direction", :binary)
    |> expect_optional_type(path, candidate, "source_target", :map)
    |> expect_optional_number(path, candidate, "target_latitude_deg")
    |> expect_optional_number(path, candidate, "target_longitude_deg")
    |> expect_optional_number(path, candidate, "target_minimum_elevation_deg")
    |> expect_optional_number(path, candidate, "target_priority")
    |> expect_optional_type(path, candidate, "target_priority_source", :binary)
    |> expect_optional_type(path, candidate, "target_priority_objective_ids", :list)
    |> validate_optional_stable_id_list(
      path,
      candidate,
      "target_priority_objective_ids"
    )
    |> expect_optional_type(path, candidate, "target_priority_objective_type", :binary)
    |> expect_optional_list(path, candidate, "semantic_change_reasons")
    |> expect_optional_number(path, candidate, "starts_at_s")
    |> expect_optional_number(path, candidate, "ends_at_s")
    |> validate_interval(path, candidate)
    |> validate_invalidated_candidate_source_target(path, candidate)
    |> validate_candidate_refresh_scoped_context_fields(path, candidate)
    |> validate_semantic_change_details(path, candidate)
    |> validate_changed_fields(path, candidate)
  end

  def validate_semantic_change_details(issues, path, row) do
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
            detail
          )
        end)

      _value ->
        [error("#{path}.semantic_change_details", "must be a list") | issues]
    end
  end

  def validate_changed_fields(issues, path, row) do
    issues
    |> expect_optional_type(path, row, "changed_fields", :list)
    |> validate_string_list_items(path, row, "changed_fields")
    |> expect_optional_type(path, row, "candidate_diff_changed_fields", :list)
    |> validate_string_list_items(path, row, "candidate_diff_changed_fields")
    |> expect_optional_integer(path, row, "candidate_diff_changed_field_count")
    |> expect_field_at_least(path, row, "candidate_diff_changed_field_count", 0)
    |> validate_changed_field_aliases(path, row)
    |> validate_changed_field_count(path, row)
    |> validate_semantic_change_reasons(path, row)
  end

  def validate_source_window_lineage(issues, path, lineage) do
    issues
    |> require_fields(path, lineage, [
      "candidate_activity_id",
      "source_window_id",
      "source_window_type",
      "scenario_id"
    ])
    |> validate_stable_ids(path, lineage, [
      "candidate_activity_id",
      "source_window_id",
      "scenario_id"
    ])
    |> validate_candidate_refresh_scoped_context_fields(path, lineage)
    |> validate_source_window_lineage_identity(path, lineage)
    |> validate_source_window_lineage_source_window_context(path, lineage)
  end

  def validate_optional_source_window(issues, path, row, field) do
    case Map.get(row, field) do
      nil ->
        issues

      %{} = source_window ->
        validate_source_window(issues, "#{path}.#{field}", source_window)

      _value ->
        [error("#{path}.#{field}", "must be an object") | issues]
    end
  end

  def validate_optional_source_window_lineage(issues, path, row, field) do
    case Map.get(row, field) do
      nil ->
        issues

      %{} = lineage ->
        validate_source_window_lineage(issues, "#{path}.#{field}", lineage)

      _value ->
        [error("#{path}.#{field}", "must be an object") | issues]
    end
  end

  defp validate_report_model_limits(issues, path, report) do
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
            error("#{path}.model_limits", "must match candidate refresh model limits")
            | issues
          ]
        end

      _value ->
        issues
    end
  end

  defp validate_report_counts(issues, path, report) do
    retained = report |> Map.get("retained_candidates", []) |> Enum.filter(&is_map/1)
    added = report |> Map.get("new_candidates", []) |> Enum.filter(&is_map/1)
    invalidated = report |> Map.get("invalidated_candidates", []) |> Enum.filter(&is_map/1)

    issues
    |> expect_field_equals(path, report, "retained_candidate_count", length(retained))
    |> expect_field_equals(path, report, "new_candidate_count", length(added))
    |> expect_field_equals(
      path,
      report,
      "invalidated_candidate_count",
      length(invalidated)
    )
    |> expect_field_equals(
      path,
      report,
      "refreshed_candidate_count",
      length(retained) + length(added),
      "must equal retained_candidate_count plus new_candidate_count"
    )
    |> expect_field_equals(
      path,
      report,
      "prior_candidate_count",
      row_count_sum(report, [
        "valid_prior_candidate_count",
        "invalid_prior_candidate_input_count"
      ]),
      "must equal valid plus invalid prior candidate counts"
    )
    |> expect_field_equals(
      path,
      report,
      "invalid_prior_candidate_input_count",
      list_count(report, "invalid_prior_candidate_input_ids")
    )
  end

  defp validate_invalidated_candidate_source_target(
         issues,
         path,
         %{"source_target" => %{} = source_target} = candidate
       ) do
    issues
    |> validate_stable_ids(path <> ".source_target", source_target, ["id"])
    |> expect_field_equals(
      path,
      candidate,
      "source_target_id",
      Map.get(source_target, "id"),
      "must match source_target.id"
    )
    |> expect_field_equals(
      path,
      candidate,
      "target_id",
      Map.get(source_target, "id"),
      "must match source_target.id"
    )
    |> expect_field_equals(
      path,
      candidate,
      "target_latitude_deg",
      Map.get(source_target, "latitude_deg"),
      "must match source_target.latitude_deg"
    )
    |> expect_field_equals(
      path,
      candidate,
      "target_longitude_deg",
      Map.get(source_target, "longitude_deg"),
      "must match source_target.longitude_deg"
    )
    |> expect_field_equals(
      path,
      candidate,
      "target_minimum_elevation_deg",
      Map.get(source_target, "minimum_elevation_deg"),
      "must match source_target.minimum_elevation_deg"
    )
  end

  defp validate_invalidated_candidate_source_target(issues, _path, _candidate),
    do: issues

  defp validate_semantic_change_detail(issues, path, %{} = detail) do
    issues
    |> require_fields(path, detail, [
      "field",
      "reason",
      "prior_value",
      "refreshed_value"
    ])
    |> expect_type(path, detail, "field", :binary)
    |> expect_type(path, detail, "reason", :binary)
    |> expect_optional_type(path, detail, "prior_path", :binary)
    |> expect_optional_type(path, detail, "refreshed_path", :binary)
  end

  defp validate_semantic_change_detail(issues, path, _detail),
    do: [error(path, "must be an object") | issues]

  defp validate_changed_field_aliases(issues, path, row) do
    case {Map.get(row, "changed_fields"), Map.get(row, "candidate_diff_changed_fields")} do
      {changed_fields, candidate_diff_changed_fields}
      when is_list(changed_fields) and is_list(candidate_diff_changed_fields) ->
        expect_field_equals(
          issues,
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

  defp validate_changed_field_count(issues, path, row) do
    case {Map.get(row, "candidate_diff_changed_fields"),
          Map.get(row, "candidate_diff_changed_field_count")} do
      {fields, count} when is_list(fields) and is_integer(count) ->
        expect_field_equals(
          issues,
          path,
          row,
          "candidate_diff_changed_field_count",
          length(fields)
        )

      _fields_or_count ->
        issues
    end
  end

  defp validate_semantic_change_reasons(issues, path, row) do
    case {Map.get(row, "semantic_change_reasons"), Map.get(row, "semantic_change_details")} do
      {reasons, details} when is_list(reasons) and is_list(details) ->
        detail_reasons =
          details
          |> Enum.filter(&is_map/1)
          |> Enum.map(&Map.get(&1, "reason"))

        expect_field_equals(
          issues,
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
         path,
         %{"source_window_id" => source_window_id, "source_window_type" => source_window_type}
       )
       when is_binary(source_window_id) and is_binary(source_window_type) do
    if String.contains?(source_window_id, ":#{source_window_type}:") do
      issues
    else
      [
        error(
          path <> ".source_window_type",
          "must match source_window_id source-window type"
        )
        | issues
      ]
    end
  end

  defp validate_source_window_lineage_identity(issues, _path, _lineage), do: issues

  defp validate_source_window_lineage_source_window_context(
         issues,
         path,
         %{"source_window" => %{} = source_window} = lineage
       ) do
    issues
    |> validate_stable_ids(path <> ".source_window", source_window, [
      "id",
      "scenario_id",
      "target_id",
      "ground_station_id"
    ])
    |> expect_field_equals(
      path <> ".source_window",
      source_window,
      "id",
      Map.get(lineage, "source_window_id"),
      "must match lineage source_window_id"
    )
    |> expect_field_equals(
      path <> ".source_window",
      source_window,
      "type",
      Map.get(lineage, "source_window_type"),
      "must match lineage source_window_type"
    )
    |> expect_field_equals(
      path <> ".source_window",
      source_window,
      "scenario_id",
      Map.get(lineage, "scenario_id"),
      "must match lineage scenario_id"
    )
    |> expect_optional_number(path <> ".source_window", source_window, "starts_at_s")
    |> expect_optional_number(path <> ".source_window", source_window, "ends_at_s")
    |> expect_optional_number(path <> ".source_window", source_window, "duration_s")
    |> validate_candidate_refresh_scoped_context_fields(
      path <> ".source_window",
      source_window
    )
  end

  defp validate_source_window_lineage_source_window_context(issues, path, %{
         "source_window" => source_window
       })
       when not is_nil(source_window) do
    [error(path <> ".source_window", "must be an object") | issues]
  end

  defp validate_source_window_lineage_source_window_context(issues, _path, _lineage),
    do: issues

  defp validate_source_window(issues, path, source_window) do
    issues
    |> validate_stable_ids(path, source_window, [
      "id",
      "scenario_id",
      "target_id",
      "ground_station_id"
    ])
    |> expect_optional_type(path, source_window, "type", :binary)
    |> expect_optional_number(path, source_window, "starts_at_s")
    |> expect_optional_number(path, source_window, "ends_at_s")
    |> expect_optional_number(path, source_window, "duration_s")
    |> expect_optional_number(path, source_window, "max_elevation_deg")
    |> expect_optional_number(path, source_window, "minimum_elevation_deg")
    |> expect_optional_type(path, source_window, "event_timing_policy", :binary)
    |> expect_optional_type(path, source_window, "event_detector", :binary)
    |> expect_optional_number(path, source_window, "event_time_tolerance_s")
    |> expect_optional_number(path, source_window, "max_sample_step_s")
    |> expect_optional_type(path, source_window, "confidence", :binary)
    |> validate_candidate_refresh_scoped_context_fields(path, source_window)
  end

  defp validate_report_lineage(issues, path, report) do
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
                  "#{path}.source_window_lineage[#{index}].candidate_activity_id",
                  "must match a candidate diff row"
                )
                | acc
              ]

            is_map(lineage) and is_map(candidate) and
                Map.get(lineage, "source_window_id") != Map.get(candidate, "source_window_id") ->
              [
                error(
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

  defp list_count(map, field),
    do: CollectionAggregation.list_count(map, field)

  defp row_count_sum(report, fields),
    do: CollectionAggregation.row_count_sum(report, fields)

  defp validate_candidate_refresh_scoped_context_fields(issues, path, row),
    do: CandidateRefreshScopedContextContracts.validate(issues, path, row)

  defp expect_field_equals(issues, path, map, field, nil),
    do: expect_field_equals(issues, path, map, field, nil, nil)

  defp expect_field_equals(issues, path, map, field, expected),
    do: expect_field_equals(issues, path, map, field, expected, "must equal #{expected}")
end
