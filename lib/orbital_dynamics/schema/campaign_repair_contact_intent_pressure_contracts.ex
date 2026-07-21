defmodule OrbitalDynamics.Schema.CampaignRepairContactIntentPressureContracts do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ActivityIdentity,
    ContactIntentPressureBranches,
    DownlinkActivityNormalization,
    ScalarValues
  }

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

  @penalty_field "contact_intent_pressure_penalty"
  @statuses_field "contact_intent_pressure_statuses"
  @tolerance 1.0e-9

  def validate(issues, artifact) when is_map(artifact) do
    statuses_by_candidate_id =
      pressure_statuses_by_candidate_id(Map.get(artifact, "source_contact_intents"))

    risk_weight =
      artifact
      |> Map.get("scoring_policy", %{})
      |> numeric_policy_value("risk_weight", 1.0)

    activities = Map.get(artifact, "activities", [])

    issues
    |> validate_rankings(activities, statuses_by_candidate_id, risk_weight)
    |> validate_score_term(artifact, activities, statuses_by_candidate_id, risk_weight)
  end

  def validate(issues, _artifact), do: issues

  defp pressure_statuses_by_candidate_id(rows) when is_list(rows) do
    rows
    |> Enum.filter(&is_map/1)
    |> Enum.map(&{&1, "campaign_repair.source_contact_intents"})
    |> ContactIntentPressureBranches.pressure_statuses_by_contact_id()
  end

  defp pressure_statuses_by_candidate_id(_rows), do: %{}

  defp validate_rankings(issues, activities, statuses_by_candidate_id, risk_weight)
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
        statuses_by_candidate_id,
        risk_weight
      )
    end)
  end

  defp validate_rankings(issues, _activities, _statuses_by_candidate_id, _risk_weight),
    do: issues

  defp validate_ranking_rows(issues, path, rows, statuses_by_candidate_id, risk_weight)
       when is_list(rows) do
    current_explanation? =
      Enum.any?(rows, fn
        %{} = row -> Map.has_key?(row, @penalty_field) or Map.has_key?(row, @statuses_field)
        _row -> false
      end)

    if current_explanation? do
      rows
      |> Enum.with_index()
      |> Enum.reduce(issues, fn {row, index}, acc ->
        validate_current_ranking_row(
          acc,
          "#{path}[#{index}]",
          row,
          statuses_by_candidate_id,
          risk_weight
        )
      end)
    else
      issues
    end
  end

  defp validate_ranking_rows(issues, _path, _rows, _statuses_by_candidate_id, _risk_weight),
    do: issues

  defp validate_current_ranking_row(
         issues,
         path,
         %{} = row,
         statuses_by_candidate_id,
         risk_weight
       ) do
    expected_statuses = Map.get(statuses_by_candidate_id, Map.get(row, "candidate_id"), [])
    expected_penalty = if expected_statuses == [], do: 0.0, else: -risk_weight

    issues
    |> require_current_penalty(path, row)
    |> validate_penalty(path, row, expected_penalty)
    |> validate_statuses(path, row, expected_statuses)
  end

  defp validate_current_ranking_row(
         issues,
         _path,
         _row,
         _statuses_by_candidate_id,
         _risk_weight
       ),
       do: issues

  defp require_current_penalty(issues, path, row) do
    if Map.has_key?(row, @penalty_field) do
      issues
    else
      [
        error(
          path <> "." <> @penalty_field,
          "must be present on every current contact-intent ranking row"
        )
        | issues
      ]
    end
  end

  defp validate_penalty(issues, path, row, expected) do
    case Map.get(row, @penalty_field) do
      actual when is_number(actual) ->
        if close?(actual, expected) do
          issues
        else
          [
            error(
              path <> "." <> @penalty_field,
              "must match exact source contact-intent pressure and risk_weight"
            )
            | issues
          ]
        end

      _actual ->
        issues
    end
  end

  defp validate_statuses(issues, path, row, []) do
    if Map.has_key?(row, @statuses_field) do
      [
        error(
          path <> "." <> @statuses_field,
          "must be omitted without exact source contact-intent pressure"
        )
        | issues
      ]
    else
      issues
    end
  end

  defp validate_statuses(issues, path, row, expected) do
    if Map.get(row, @statuses_field) == expected do
      issues
    else
      [
        error(
          path <> "." <> @statuses_field,
          "must match sorted unique source contact-intent pressure statuses"
        )
        | issues
      ]
    end
  end

  defp validate_score_term(
         issues,
         %{"score_terms" => %{} = score_terms},
         activities,
         statuses_by_candidate_id,
         risk_weight
       ) do
    if Map.has_key?(score_terms, @penalty_field) do
      expected =
        activities
        |> selected_downlink_ids()
        |> MapSet.intersection(MapSet.new(Map.keys(statuses_by_candidate_id)))
        |> MapSet.size()
        |> then(fn count -> -count * risk_weight end)

      case Map.get(score_terms, @penalty_field) do
        actual when is_number(actual) ->
          if close?(actual, expected) do
            issues
          else
            [
              error(
                "$.score_terms." <> @penalty_field,
                "must match unique selected source contact-intent pressure and risk_weight"
              )
              | issues
            ]
          end

        _actual ->
          issues
      end
    else
      issues
    end
  end

  defp validate_score_term(
         issues,
         _artifact,
         _activities,
         _statuses_by_candidate_id,
         _risk_weight
       ),
       do: issues

  defp selected_downlink_ids(activities) when is_list(activities) do
    activities
    |> Enum.filter(&(is_map(&1) and DownlinkActivityNormalization.downlink?(&1)))
    |> Enum.map(&ActivityIdentity.activity_id/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> MapSet.new()
  end

  defp selected_downlink_ids(_activities), do: MapSet.new()

  defp numeric_policy_value(%{} = policy, key, default) do
    case ScalarValues.numeric_or_nil(Map.get(policy, key, default)) do
      value when is_number(value) -> value
      _value -> default
    end
  end

  defp numeric_policy_value(_policy, _key, default), do: default

  defp close?(left, right), do: abs(left - right) <= @tolerance
end
