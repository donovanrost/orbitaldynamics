defmodule OrbitalDynamics.Schema.CampaignPlanTradeoffContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

  def validate(issues, artifact) when is_map(artifact) do
    validate_report(
      issues,
      Map.get(artifact, "ranked_timelines"),
      Map.get(artifact, "objective_tradeoff_report")
    )
  end

  defp validate_report(issues, _timelines, nil), do: issues
  defp validate_report(issues, _timelines, :null), do: issues

  defp validate_report(issues, timelines, %{"tradeoffs" => tradeoffs} = report)
       when is_list(timelines) and is_list(tradeoffs) do
    if valid_timelines?(timelines) and Enum.all?(tradeoffs, &is_map/1) do
      expected_rows = expected_rows(timelines)
      expected_by_key = Map.new(expected_rows, &{row_key(&1), &1})
      expected_keys = MapSet.new(Map.keys(expected_by_key))
      actual_keys = Enum.map(tradeoffs, &row_key/1)

      issues
      |> validate_equal(
        "$.objective_tradeoff_report.model",
        Map.get(report, "model"),
        "ranked_timeline_score_term_tradeoffs",
        "must identify ranked timeline score-term tradeoffs"
      )
      |> validate_equal(
        "$.objective_tradeoff_report.assumptions.source",
        report_source(report),
        "campaign_plan.ranked_timelines",
        "must identify campaign_plan.ranked_timelines"
      )
      |> validate_equal(
        "$.objective_tradeoff_report.ranking_count",
        Map.get(report, "ranking_count"),
        length(timelines),
        "must equal enclosing ranked timeline count"
      )
      |> validate_equal(
        "$.objective_tradeoff_report.score_term_keys",
        Map.get(report, "score_term_keys"),
        expected_score_term_keys(timelines),
        "must match enclosing ranked timeline score-term keys"
      )
      |> validate_equal(
        "$.objective_tradeoff_report.tradeoffs",
        length(actual_keys),
        MapSet.size(MapSet.new(actual_keys)),
        "must contain unique rank and scenario rows"
      )
      |> validate_equal(
        "$.objective_tradeoff_report.tradeoffs",
        MapSet.new(actual_keys),
        expected_keys,
        "must contain exactly one row for each ranked timeline"
      )
      |> validate_rows(tradeoffs, expected_by_key)
    else
      issues
    end
  end

  defp validate_report(issues, _timelines, _report), do: issues

  defp valid_timelines?(timelines) do
    Enum.all?(timelines, fn
      %{
        "scenario_id" => scenario_id,
        "score" => score,
        "score_terms" => score_terms,
        "activity_count" => activity_count,
        "activities" => activities
      }
      when is_binary(scenario_id) and is_number(score) and is_map(score_terms) and
             is_integer(activity_count) and activity_count >= 0 and is_list(activities) ->
        Enum.all?(Map.values(score_terms), &is_number/1) and
          Enum.all?(activities, &valid_activity?/1)

      _timeline ->
        false
    end)
  end

  defp valid_activity?(%{"id" => id}) when is_binary(id), do: true
  defp valid_activity?(_activity), do: false

  defp expected_rows(timelines) do
    selected_score =
      case List.first(timelines) do
        %{"score" => score} when is_number(score) -> score
        _timeline -> 0.0
      end

    timelines
    |> Enum.with_index(1)
    |> Enum.map(fn {timeline, rank} ->
      score_terms = timeline["score_terms"]

      %{
        "rank" => rank,
        "scenario_id" => timeline["scenario_id"],
        "score" => timeline["score"],
        "score_delta_from_selected" => timeline["score"] - selected_score,
        "activity_count" => timeline["activity_count"],
        "score_terms" => score_terms,
        "activity_ids" => Enum.map(timeline["activities"], & &1["id"]),
        "selected_observation_count" => Map.get(score_terms, "selected_observation_count", 0),
        "selected_contact_count" => Map.get(score_terms, "selected_contact_count", 0)
      }
    end)
  end

  defp expected_score_term_keys(timelines) do
    timelines
    |> Enum.flat_map(&Map.keys(&1["score_terms"]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp validate_rows(issues, rows, expected_by_key) do
    rows
    |> Enum.with_index()
    |> Enum.reduce(issues, fn {row, index}, acc ->
      path = "$.objective_tradeoff_report.tradeoffs[#{index}]"

      case Map.fetch(expected_by_key, row_key(row)) do
        {:ok, expected} -> validate_row(acc, path, row, expected)
        :error -> [error(path, "must match an enclosing ranked timeline") | acc]
      end
    end)
  end

  defp validate_row(issues, path, row, expected) do
    issues
    |> validate_number_equal(
      path <> ".score",
      Map.get(row, "score"),
      expected["score"],
      "must match the enclosing ranked timeline score"
    )
    |> validate_number_equal(
      path <> ".score_delta_from_selected",
      Map.get(row, "score_delta_from_selected"),
      expected["score_delta_from_selected"],
      "must equal timeline score minus the selected timeline score"
    )
    |> validate_numeric_map_equal(
      path <> ".score_terms",
      Map.get(row, "score_terms"),
      expected["score_terms"],
      "must match the enclosing ranked timeline score terms"
    )
    |> validate_equal(
      path <> ".activity_count",
      Map.get(row, "activity_count"),
      expected["activity_count"],
      "must match the enclosing ranked timeline activity count"
    )
    |> validate_equal(
      path <> ".activity_ids",
      Map.get(row, "activity_ids"),
      expected["activity_ids"],
      "must match the enclosing ranked timeline activity IDs"
    )
    |> validate_equal(
      path <> ".selected_observation_count",
      Map.get(row, "selected_observation_count"),
      expected["selected_observation_count"],
      "must match the enclosing ranked timeline score term"
    )
    |> validate_equal(
      path <> ".selected_contact_count",
      Map.get(row, "selected_contact_count"),
      expected["selected_contact_count"],
      "must match the enclosing ranked timeline score term"
    )
  end

  defp row_key(row), do: {Map.get(row, "rank"), Map.get(row, "scenario_id")}

  defp report_source(%{"assumptions" => assumptions}) when is_map(assumptions),
    do: Map.get(assumptions, "source")

  defp report_source(_report), do: nil

  defp validate_numeric_map_equal(issues, _path, left, right, _message)
       when not is_map(left) or not is_map(right),
       do: issues

  defp validate_numeric_map_equal(issues, path, left, right, message) do
    left_keys = left |> Map.keys() |> Enum.sort()
    right_keys = right |> Map.keys() |> Enum.sort()

    if left_keys == right_keys and
         Enum.all?(left, fn {key, value} ->
           is_number(value) and is_number(Map.get(right, key)) and close?(value, right[key])
         end) do
      issues
    else
      [error(path, message) | issues]
    end
  end

  defp validate_number_equal(issues, _path, left, right, _message)
       when not is_number(left) or not is_number(right),
       do: issues

  defp validate_number_equal(issues, path, left, right, message) do
    if close?(left, right), do: issues, else: [error(path, message) | issues]
  end

  defp validate_equal(issues, _path, actual, expected, _message) when actual == expected,
    do: issues

  defp validate_equal(issues, path, _actual, _expected, message),
    do: [error(path, message) | issues]

  defp close?(left, right), do: abs(left - right) <= 1.0e-9
end
