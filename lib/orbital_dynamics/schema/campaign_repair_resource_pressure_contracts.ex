defmodule OrbitalDynamics.Schema.CampaignRepairResourcePressureContracts do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.ScalarValues

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

  @penalty_field "resource_projection_pressure_penalty"
  @indicators_field "resource_projection_pressure_risk_indicators"
  @tolerance 1.0e-9

  def validate(issues, artifact) when is_map(artifact) do
    risk_weight =
      artifact
      |> Map.get("scoring_policy", %{})
      |> numeric_policy_value("risk_weight", 1.0)

    validate_activities(issues, Map.get(artifact, "activities", []), risk_weight)
  end

  def validate(issues, _artifact), do: issues

  defp validate_activities(issues, activities, risk_weight) when is_list(activities) do
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
        risk_weight
      )
    end)
  end

  defp validate_activities(issues, _activities, _risk_weight), do: issues

  defp validate_rows(issues, path, rows, risk_weight) when is_list(rows) do
    rows
    |> Enum.with_index()
    |> Enum.reduce(issues, fn {row, index}, acc ->
      validate_row(acc, "#{path}[#{index}]", row, risk_weight)
    end)
  end

  defp validate_rows(issues, _path, _rows, _risk_weight), do: issues

  defp validate_row(issues, path, %{} = row, risk_weight) do
    case {Map.get(row, @penalty_field), Map.get(row, @indicators_field)} do
      {actual, indicators} when is_number(actual) and is_list(indicators) ->
        expected = -length(indicators) * risk_weight
        validate_penalty(issues, path, actual, expected)

      {actual, indicators} when is_number(actual) and indicators in [nil, :null] ->
        validate_penalty(issues, path, actual, 0.0)

      _values ->
        issues
    end
  end

  defp validate_row(issues, _path, _row, _risk_weight), do: issues

  defp validate_penalty(issues, _path, actual, expected)
       when abs(actual - expected) <= @tolerance,
       do: issues

  defp validate_penalty(issues, path, _actual, _expected) do
    [
      error(
        path <> "." <> @penalty_field,
        "must equal negative resource-risk indicator count times risk_weight"
      )
      | issues
    ]
  end

  defp numeric_policy_value(%{} = policy, key, default) do
    case ScalarValues.numeric_or_nil(Map.get(policy, key, default)) do
      value when is_number(value) -> value
      _value -> default
    end
  end

  defp numeric_policy_value(_policy, _key, default), do: default
end
