defmodule OrbitalDynamics.Schema.CampaignRepairStationPressureContracts do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{RepairStationPressure, ScalarValues}

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

  @penalty_field "station_calendar_pressure_penalty"
  @sources_field "station_calendar_pressure_sources"
  @tolerance 1.0e-9

  def validate(issues, artifact) when is_map(artifact) do
    sources_by_candidate_id =
      RepairStationPressure.sources_by_candidate_id(
        Map.get(artifact, "source_station_calendar_report"),
        Map.get(artifact, "source_contact_allocation_report")
      )

    risk_weight =
      artifact
      |> Map.get("scoring_policy", %{})
      |> numeric_policy_value("risk_weight", 1.0)

    validate_activities(
      issues,
      Map.get(artifact, "activities", []),
      sources_by_candidate_id,
      risk_weight
    )
  end

  def validate(issues, _artifact), do: issues

  defp validate_activities(issues, activities, sources_by_candidate_id, risk_weight)
       when is_list(activities) do
    activities
    |> Enum.with_index()
    |> Enum.reduce(issues, fn {activity, activity_index}, acc ->
      rows =
        case activity do
          %{"repair" => %{"replacement_ranking" => %{"rows" => rows}}} -> rows
          _activity -> nil
        end

      validate_rows(
        acc,
        "$.activities[#{activity_index}].repair.replacement_ranking.rows",
        rows,
        sources_by_candidate_id,
        risk_weight
      )
    end)
  end

  defp validate_activities(issues, _activities, _sources_by_candidate_id, _risk_weight),
    do: issues

  defp validate_rows(issues, path, rows, sources_by_candidate_id, risk_weight)
       when is_list(rows) do
    rows
    |> Enum.with_index()
    |> Enum.reduce(issues, fn {row, index}, acc ->
      validate_row(acc, "#{path}[#{index}]", row, sources_by_candidate_id, risk_weight)
    end)
  end

  defp validate_rows(issues, _path, _rows, _sources_by_candidate_id, _risk_weight),
    do: issues

  defp validate_row(issues, path, %{} = row, sources_by_candidate_id, risk_weight) do
    expected_sources = Map.get(sources_by_candidate_id, Map.get(row, "candidate_id"), [])
    expected_penalty = if expected_sources == [], do: 0.0, else: -risk_weight

    issues
    |> validate_penalty(path, row, expected_penalty)
    |> validate_sources(path, row, expected_sources)
  end

  defp validate_row(issues, _path, _row, _sources_by_candidate_id, _risk_weight), do: issues

  defp validate_penalty(issues, path, row, expected) do
    case Map.get(row, @penalty_field) do
      actual when is_number(actual) ->
        if close?(actual, expected) do
          issues
        else
          [
            error(
              path <> "." <> @penalty_field,
              "must match exact station-pressure source evidence and risk_weight"
            )
            | issues
          ]
        end

      _actual ->
        issues
    end
  end

  defp validate_sources(issues, path, row, []) do
    if Map.has_key?(row, @sources_field) do
      [
        error(
          path <> "." <> @sources_field,
          "must be omitted without exact station-pressure source evidence"
        )
        | issues
      ]
    else
      issues
    end
  end

  defp validate_sources(issues, path, row, expected) do
    if Map.get(row, @sources_field) == expected do
      issues
    else
      [
        error(
          path <> "." <> @sources_field,
          "must match sorted exact station-pressure source evidence"
        )
        | issues
      ]
    end
  end

  defp numeric_policy_value(%{} = policy, key, default) do
    case ScalarValues.numeric_or_nil(Map.get(policy, key, default)) do
      value when is_number(value) -> value
      _value -> default
    end
  end

  defp numeric_policy_value(_policy, _key, default), do: default

  defp close?(left, right), do: abs(left - right) <= @tolerance
end
