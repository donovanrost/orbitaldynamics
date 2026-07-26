defmodule OrbitalDynamics.Schema.CampaignRepairResourcePressureContracts do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.ScalarValues
  alias OrbitalDynamics.ResourceProjection.ResourceSummaryInput

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

  @penalty_field "resource_projection_pressure_penalty"
  @indicators_field "resource_projection_pressure_risk_indicators"
  @tolerance 1.0e-9

  def validate(issues, artifact) when is_map(artifact) do
    risk_weight =
      artifact
      |> Map.get("scoring_policy", %{})
      |> numeric_policy_value("risk_weight", 1.0)

    scope_ids_by_candidate_id =
      source_scope_ids_by_candidate_id(
        Map.get(artifact, "source_candidate_activities"),
        Map.get(artifact, "source_resource_summaries")
      )

    validate_activities(
      issues,
      Map.get(artifact, "activities", []),
      risk_weight,
      scope_ids_by_candidate_id
    )
  end

  def validate(issues, _artifact), do: issues

  defp validate_activities(issues, activities, risk_weight, scope_ids_by_candidate_id)
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
        risk_weight,
        scope_ids_by_candidate_id
      )
    end)
  end

  defp validate_activities(issues, _activities, _risk_weight, _scope_ids_by_candidate_id),
    do: issues

  defp validate_rows(issues, path, rows, risk_weight, scope_ids_by_candidate_id)
       when is_list(rows) do
    current_indicator_identity? = Enum.any?(rows, &current_indicator_identity?/1)

    rows
    |> Enum.with_index()
    |> Enum.reduce(issues, fn {row, index}, acc ->
      validate_row(
        acc,
        "#{path}[#{index}]",
        row,
        risk_weight,
        scope_ids_by_candidate_id,
        current_indicator_identity?
      )
    end)
  end

  defp validate_rows(issues, _path, _rows, _risk_weight, _scope_ids_by_candidate_id),
    do: issues

  defp validate_row(
         issues,
         path,
         %{} = row,
         risk_weight,
         scope_ids_by_candidate_id,
         current_indicator_identity?
       ) do
    issues =
      case {Map.get(row, @penalty_field), Map.get(row, @indicators_field)} do
        {actual, indicators} when is_number(actual) and is_list(indicators) ->
          expected = -length(indicators) * risk_weight
          validate_penalty(issues, path, actual, expected)

        {actual, indicators} when is_number(actual) and indicators in [nil, :null] ->
          validate_penalty(issues, path, actual, 0.0)

        _values ->
          issues
      end

    validate_indicator_scopes(
      issues,
      path,
      row,
      scope_ids_by_candidate_id,
      current_indicator_identity?
    )
  end

  defp validate_row(
         issues,
         _path,
         _row,
         _risk_weight,
         _scope_ids_by_candidate_id,
         _current_indicator_identity?
       ),
       do: issues

  defp validate_indicator_scopes(
         issues,
         path,
         row,
         scope_ids_by_candidate_id,
         current_indicator_identity?
       ) do
    expected_scope_ids =
      Map.get(scope_ids_by_candidate_id, Map.get(row, "candidate_id"), [])

    case Map.get(row, @indicators_field) do
      indicators when is_list(indicators) ->
        indicators
        |> Enum.with_index()
        |> Enum.reduce(issues, fn
          {%{"candidate_id" => _candidate_id} = indicator, index}, acc ->
            if Map.get(indicator, "spacecraft_id") in expected_scope_ids do
              acc
            else
              [
                error(
                  "#{path}.#{@indicators_field}[#{index}].spacecraft_id",
                  "must match a valid source resource-summary scope for the exact candidate"
                )
                | acc
              ]
            end

          {%{} = _indicator, index}, acc when current_indicator_identity? ->
            [
              error(
                "#{path}.#{@indicators_field}[#{index}].candidate_id",
                "must be present on every resource-pressure indicator in a current ranking"
              )
              | acc
            ]

          {_indicator, _index}, acc ->
            acc
        end)

      _indicators ->
        issues
    end
  end

  defp current_indicator_identity?(%{} = row) do
    case Map.get(row, @indicators_field) do
      indicators when is_list(indicators) ->
        Enum.any?(indicators, &(is_map(&1) and Map.has_key?(&1, "candidate_id")))

      _indicators ->
        false
    end
  end

  defp current_indicator_identity?(_row), do: false

  defp source_scope_ids_by_candidate_id(candidates, summaries)
       when is_list(candidates) and is_list(summaries) do
    candidates
    |> Enum.filter(&is_map/1)
    |> Enum.group_by(&Map.get(&1, "id"))
    |> Enum.reduce(%{}, fn
      {candidate_id, [candidate]}, acc when candidate_id not in [nil, ""] ->
        Map.put(
          acc,
          candidate_id,
          ResourceSummaryInput.projection_scope_ids(candidate, summaries)
        )

      {_candidate_id, _candidates}, acc ->
        acc
    end)
  end

  defp source_scope_ids_by_candidate_id(_candidates, _summaries), do: %{}

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
