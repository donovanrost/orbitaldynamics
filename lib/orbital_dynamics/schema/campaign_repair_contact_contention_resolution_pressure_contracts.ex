defmodule OrbitalDynamics.Schema.CampaignRepairContactContentionResolutionPressureContracts do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    RepairContactContentionResolutionPressure,
    ScalarValues
  }

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

  @penalty_field "contact_contention_resolution_pressure_penalty"
  @group_ids_field "contact_contention_resolution_group_ids"
  @tolerance 1.0e-9

  def validate(issues, artifact) when is_map(artifact) do
    report = Map.get(artifact, "source_contact_contention_resolution_report")

    group_ids_by_candidate_id =
      RepairContactContentionResolutionPressure.group_ids_by_candidate_id(report)

    risk_weight =
      artifact
      |> Map.get("scoring_policy", %{})
      |> numeric_policy_value("risk_weight", 1.0)

    activities = Map.get(artifact, "activities", [])

    issues
    |> validate_rankings(activities, group_ids_by_candidate_id, risk_weight)
    |> validate_score_term(artifact, report, activities, risk_weight)
  end

  def validate(issues, _artifact), do: issues

  defp validate_rankings(issues, activities, group_ids_by_candidate_id, risk_weight)
       when is_list(activities) do
    activities
    |> Enum.with_index()
    |> Enum.reduce(issues, fn {activity, activity_index}, acc ->
      rows =
        case activity do
          %{"repair" => %{"replacement_ranking" => %{"rows" => rows}}} -> rows
          _activity -> nil
        end

      validate_ranking_rows(
        acc,
        "$.activities[#{activity_index}].repair.replacement_ranking.rows",
        rows,
        group_ids_by_candidate_id,
        risk_weight
      )
    end)
  end

  defp validate_rankings(issues, _activities, _group_ids_by_candidate_id, _risk_weight),
    do: issues

  defp validate_ranking_rows(issues, path, rows, group_ids_by_candidate_id, risk_weight)
       when is_list(rows) do
    current_explanation? =
      Enum.any?(rows, fn
        %{} = row -> Map.has_key?(row, @penalty_field) or Map.has_key?(row, @group_ids_field)
        _row -> false
      end)

    if current_explanation? do
      rows
      |> Enum.with_index()
      |> Enum.reduce(issues, fn {row, index}, acc ->
        validate_current_row(
          acc,
          "#{path}[#{index}]",
          row,
          group_ids_by_candidate_id,
          risk_weight
        )
      end)
    else
      issues
    end
  end

  defp validate_ranking_rows(issues, _path, _rows, _group_ids_by_candidate_id, _risk_weight),
    do: issues

  defp validate_current_row(issues, path, %{} = row, group_ids_by_candidate_id, risk_weight) do
    expected_group_ids = Map.get(group_ids_by_candidate_id, Map.get(row, "candidate_id"), [])
    expected_penalty = if expected_group_ids == [], do: 0.0, else: -risk_weight

    issues
    |> require_penalty(path, row)
    |> validate_penalty(path, row, expected_penalty)
    |> validate_group_ids(path, row, expected_group_ids)
  end

  defp validate_current_row(
         issues,
         _path,
         _row,
         _group_ids_by_candidate_id,
         _risk_weight
       ),
       do: issues

  defp require_penalty(issues, path, row) do
    if Map.has_key?(row, @penalty_field) do
      issues
    else
      [
        error(path <> "." <> @penalty_field, "must be present on every current ranking row")
        | issues
      ]
    end
  end

  defp validate_penalty(issues, path, row, expected) do
    case Map.get(row, @penalty_field) do
      actual when is_number(actual) and abs(actual - expected) <= @tolerance ->
        issues

      actual when is_number(actual) ->
        [
          error(
            path <> "." <> @penalty_field,
            "must match exact deferred contention evidence and risk_weight"
          )
          | issues
        ]

      _actual ->
        issues
    end
  end

  defp validate_group_ids(issues, path, row, []) do
    if Map.has_key?(row, @group_ids_field) do
      [
        error(
          path <> "." <> @group_ids_field,
          "must be omitted without exact deferred contention evidence"
        )
        | issues
      ]
    else
      issues
    end
  end

  defp validate_group_ids(issues, path, row, expected) do
    if Map.get(row, @group_ids_field) == expected do
      issues
    else
      [
        error(
          path <> "." <> @group_ids_field,
          "must match sorted unique deferred contention group IDs"
        )
        | issues
      ]
    end
  end

  defp validate_score_term(
         issues,
         %{"score_terms" => %{} = score_terms},
         report,
         activities,
         risk_weight
       ) do
    if Map.has_key?(score_terms, @penalty_field) do
      expected =
        -RepairContactContentionResolutionPressure.selected_count(report, activities) *
          risk_weight

      case Map.get(score_terms, @penalty_field) do
        actual when is_number(actual) and abs(actual - expected) <= @tolerance ->
          issues

        actual when is_number(actual) ->
          [
            error(
              "$.score_terms." <> @penalty_field,
              "must match unique selected deferred contacts and risk_weight"
            )
            | issues
          ]

        _actual ->
          issues
      end
    else
      issues
    end
  end

  defp validate_score_term(issues, _artifact, _report, _activities, _risk_weight), do: issues

  defp numeric_policy_value(%{} = policy, key, default) do
    case ScalarValues.numeric_or_nil(Map.get(policy, key, default)) do
      value when is_number(value) -> value
      _value -> default
    end
  end

  defp numeric_policy_value(_policy, _key, default), do: default
end
