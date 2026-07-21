defmodule OrbitalDynamics.Schema.CampaignRepairReplacementRankingContracts do
  @moduledoc false

  @model "greedy_repair_replacement_ranking"
  @selection_scope "viable_unique_candidates_within_repair_intent"
  @station_pressure_sources [
    "campaign_repair.source_contact_allocation_report.rows",
    "campaign_repair.source_station_calendar_report.affected_contacts"
  ]
  @required_row_fields [
    "rank",
    "candidate_id",
    "semantic_candidate_diff_match",
    "candidate_diff_priority",
    "candidate_score",
    "schedule_churn_s",
    "schedule_churn_penalty",
    "schedule_move_penalty",
    "station_calendar_pressure_penalty",
    "link_capacity_pressure_penalty",
    "resource_projection_pressure_penalty",
    "ranking_score",
    "selected"
  ]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_equal: 5,
      expect_field_at_least: 5,
      expect_non_negative_integer: 4,
      expect_number: 4,
      expect_one_of: 5,
      expect_optional_list: 4,
      expect_optional_non_negative_number: 4,
      expect_optional_type: 5,
      expect_type: 5,
      require_fields: 4,
      validate_string_list_items: 4
    ]

  import OrbitalDynamics.Schema.StableIdValidation, only: [validate_stable_ids: 4]

  def validate_activities(issues, path, activities) when is_list(activities) do
    activities
    |> Enum.with_index()
    |> Enum.reduce(issues, fn {activity, index}, acc ->
      validate_activity(acc, "#{path}[#{index}]", activity)
    end)
  end

  def validate_activities(issues, _path, _activities), do: issues

  defp validate_activity(issues, path, %{} = activity) do
    case Map.get(activity, "repair") do
      nil ->
        issues

      :null ->
        issues

      %{} = repair ->
        validate_repair(issues, path <> ".repair", repair)

      _value ->
        [error(path <> ".repair", "must be a map") | issues]
    end
  end

  defp validate_activity(issues, _path, _activity), do: issues

  defp validate_repair(issues, path, repair) do
    case Map.get(repair, "replacement_ranking") do
      nil ->
        issues

      :null ->
        issues

      %{} = ranking ->
        validate_ranking(issues, path <> ".replacement_ranking", ranking)

      _value ->
        [error(path <> ".replacement_ranking", "must be a map") | issues]
    end
  end

  defp validate_ranking(issues, path, ranking) do
    rows = Map.get(ranking, "rows")

    issues
    |> require_fields(path, ranking, [
      "model",
      "selection_scope",
      "selected_candidate_id",
      "evaluated_candidate_count",
      "rows",
      "global_optimization"
    ])
    |> expect_equal(path, ranking, "model", @model)
    |> expect_equal(path, ranking, "selection_scope", @selection_scope)
    |> expect_equal(path, ranking, "global_optimization", false)
    |> expect_non_negative_integer(path, ranking, "evaluated_candidate_count")
    |> expect_field_at_least(path, ranking, "evaluated_candidate_count", 1)
    |> expect_type(path, ranking, "rows", :list)
    |> validate_stable_ids(path, ranking, ["selected_candidate_id"])
    |> validate_rows(path <> ".rows", rows)
    |> validate_consistency(path, ranking, rows)
  end

  defp validate_rows(issues, path, rows) when is_list(rows) do
    rows
    |> Enum.with_index()
    |> Enum.reduce(issues, fn {row, index}, acc ->
      validate_row(acc, "#{path}[#{index}]", row)
    end)
  end

  defp validate_rows(issues, _path, _rows), do: issues

  defp validate_row(issues, path, %{} = row) do
    issues
    |> require_fields(path, row, @required_row_fields)
    |> expect_non_negative_integer(path, row, "rank")
    |> expect_one_of(path, row, "candidate_diff_priority", [0, 1])
    |> expect_number(path, row, "candidate_score")
    |> expect_number(path, row, "schedule_churn_s")
    |> expect_field_at_least(path, row, "schedule_churn_s", 0.0)
    |> expect_number(path, row, "schedule_churn_penalty")
    |> expect_number(path, row, "schedule_move_penalty")
    |> expect_number(path, row, "station_calendar_pressure_penalty")
    |> expect_number(path, row, "link_capacity_pressure_penalty")
    |> expect_number(path, row, "resource_projection_pressure_penalty")
    |> expect_number(path, row, "ranking_score")
    |> expect_type(path, row, "semantic_candidate_diff_match", :boolean)
    |> expect_type(path, row, "selected", :boolean)
    |> validate_stable_ids(path, row, ["candidate_id"])
    |> expect_optional_list(path, row, "station_calendar_pressure_sources")
    |> validate_string_list_items(path, row, "station_calendar_pressure_sources")
    |> validate_station_pressure_sources(path, row)
    |> expect_optional_non_negative_number(path, row, "link_capacity_pressure_shortfall_mb")
    |> validate_positive_optional_number(path, row, "link_capacity_pressure_shortfall_mb")
    |> expect_optional_list(path, row, "resource_projection_pressure_risk_indicators")
    |> validate_resource_risk_indicators(path, row)
  end

  defp validate_row(issues, path, _row),
    do: [error(path, "must be a map") | issues]

  defp validate_station_pressure_sources(issues, path, row) do
    case Map.get(row, "station_calendar_pressure_sources") do
      sources when is_list(sources) and sources != [] ->
        cond do
          Enum.any?(sources, &(&1 not in @station_pressure_sources)) ->
            [
              error(
                path <> ".station_calendar_pressure_sources",
                "must contain only known station-pressure source paths"
              )
              | issues
            ]

          sources != sources |> Enum.uniq() |> Enum.sort() ->
            [
              error(
                path <> ".station_calendar_pressure_sources",
                "must be unique and lexically sorted"
              )
              | issues
            ]

          true ->
            issues
        end

      [] ->
        [
          error(
            path <> ".station_calendar_pressure_sources",
            "must be omitted instead of empty"
          )
          | issues
        ]

      _value ->
        issues
    end
  end

  defp validate_positive_optional_number(issues, path, row, field) do
    case Map.get(row, field) do
      value when is_number(value) and value <= 0.0 ->
        [error("#{path}.#{field}", "must be positive when present") | issues]

      _value ->
        issues
    end
  end

  defp validate_resource_risk_indicators(issues, path, row) do
    case Map.get(row, "resource_projection_pressure_risk_indicators") do
      indicators when is_list(indicators) and indicators != [] ->
        indicators
        |> Enum.with_index()
        |> Enum.reduce(issues, fn {indicator, index}, acc ->
          validate_resource_risk_indicator(
            acc,
            "#{path}.resource_projection_pressure_risk_indicators[#{index}]",
            indicator
          )
        end)

      [] ->
        [
          error(
            path <> ".resource_projection_pressure_risk_indicators",
            "must be omitted instead of empty"
          )
          | issues
        ]

      _value ->
        issues
    end
  end

  defp validate_resource_risk_indicator(issues, path, %{} = indicator) do
    issues
    |> require_fields(path, indicator, ["type", "severity", "reason", "spacecraft_id"])
    |> expect_type(path, indicator, "type", :binary)
    |> expect_type(path, indicator, "severity", :binary)
    |> expect_type(path, indicator, "reason", :binary)
    |> validate_stable_ids(path, indicator, ["spacecraft_id"])
    |> expect_optional_type(path, indicator, "resource_pressure_types", :list)
    |> validate_string_list_items(path, indicator, "resource_pressure_types")
  end

  defp validate_resource_risk_indicator(issues, path, _indicator),
    do: [error(path, "must be a map") | issues]

  defp validate_consistency(issues, path, ranking, rows) when is_list(rows) do
    if Enum.all?(rows, &is_map/1) do
      candidate_ids = Enum.map(rows, &Map.get(&1, "candidate_id"))
      selected_rows = Enum.filter(rows, &(Map.get(&1, "selected") == true))
      expected_ranks = if rows == [], do: [], else: Enum.to_list(1..length(rows))

      issues
      |> validate_equal(
        path <> ".evaluated_candidate_count",
        Map.get(ranking, "evaluated_candidate_count"),
        length(rows),
        "must match replacement-ranking row count"
      )
      |> validate_equal(
        path <> ".rows",
        Enum.map(rows, &Map.get(&1, "rank")),
        expected_ranks,
        "must use sequential ranks in row order"
      )
      |> validate_equal(
        path <> ".rows",
        length(Enum.uniq(candidate_ids)),
        length(candidate_ids),
        "must contain unique candidate IDs"
      )
      |> validate_selected_candidate(path, ranking, selected_rows)
    else
      issues
    end
  end

  defp validate_consistency(issues, _path, _ranking, _rows), do: issues

  defp validate_selected_candidate(issues, path, ranking, [selected_row]) do
    issues
    |> validate_equal(
      path <> ".selected_candidate_id",
      Map.get(ranking, "selected_candidate_id"),
      Map.get(selected_row, "candidate_id"),
      "must match the only selected ranking row"
    )
    |> validate_equal(
      path <> ".rows",
      Map.get(selected_row, "rank"),
      1,
      "selected ranking row must have rank 1"
    )
  end

  defp validate_selected_candidate(issues, path, _ranking, _selected_rows) do
    [error(path <> ".rows", "must contain exactly one selected row") | issues]
  end

  defp validate_equal(issues, _path, actual, expected, _message) when actual == expected,
    do: issues

  defp validate_equal(issues, path, _actual, _expected, message),
    do: [error(path, message) | issues]
end
