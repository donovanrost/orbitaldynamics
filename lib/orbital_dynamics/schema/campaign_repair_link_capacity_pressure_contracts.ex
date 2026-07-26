defmodule OrbitalDynamics.Schema.CampaignRepairLinkCapacityPressureContracts do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.ScalarValues

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

  @penalty_field "link_capacity_pressure_penalty"
  @shortfall_field "link_capacity_pressure_shortfall_mb"
  @required_field "link_capacity_pressure_required_downlink_mb"
  @selected_field "link_capacity_pressure_selected_capacity_adjusted_throughput_mb"
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
    issues
    |> validate_projection_evidence(path, row)
    |> validate_row_penalty(path, row, risk_weight)
  end

  defp validate_row(issues, _path, _row, _risk_weight), do: issues

  defp validate_row_penalty(issues, path, row, risk_weight) do
    case {Map.get(row, @penalty_field), Map.get(row, @shortfall_field)} do
      {actual, shortfall} when is_number(actual) and is_number(shortfall) and shortfall > 0 ->
        validate_penalty(issues, path, actual, -risk_weight)

      {actual, shortfall} when is_number(actual) and shortfall in [nil, :null] ->
        validate_penalty(issues, path, actual, 0.0)

      _values ->
        issues
    end
  end

  defp validate_projection_evidence(issues, path, row) do
    required = Map.get(row, @required_field)
    selected = Map.get(row, @selected_field)
    shortfall = Map.get(row, @shortfall_field)

    cond do
      absent?(required) and absent?(selected) ->
        issues

      absent?(required) ->
        [error(path <> "." <> @required_field, "must accompany selected throughput") | issues]

      absent?(selected) ->
        [error(path <> "." <> @selected_field, "must accompany required demand") | issues]

      is_number(required) and is_number(selected) and not is_number(shortfall) ->
        [
          error(
            path <> "." <> @shortfall_field,
            "must be present with projected demand and selected throughput"
          )
          | issues
        ]

      is_number(required) and is_number(selected) and is_number(shortfall) and
          abs(required - selected - shortfall) > @tolerance ->
        [
          error(
            path <> "." <> @shortfall_field,
            "must equal required demand minus selected capacity-adjusted throughput"
          )
          | issues
        ]

      true ->
        issues
    end
  end

  defp absent?(value), do: value in [nil, :null]

  defp validate_penalty(issues, _path, actual, expected)
       when abs(actual - expected) <= @tolerance,
       do: issues

  defp validate_penalty(issues, path, _actual, _expected) do
    [
      error(
        path <> "." <> @penalty_field,
        "must equal one negative risk_weight unit exactly when link shortfall is present"
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
