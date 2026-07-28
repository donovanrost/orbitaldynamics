defmodule OrbitalDynamics.Schema.CampaignRepairReplacementEligibilityContracts do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ActivityIdentity,
    RepairPolicySemantics,
    RepairReplacementIntent
  }

  alias OrbitalDynamics.Schema.CampaignRepairReplacementRankingVersion

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

  @repair_policy_list_fields [
    "degraded_payload_activity_types",
    "command_health_activity_types"
  ]

  def validate(issues, %{} = artifact) do
    source_candidates_by_id =
      artifact
      |> Map.get("source_candidate_activities", [])
      |> source_candidates_by_id()

    {degraded_modes, repair_policy} =
      degraded_context(
        Map.get(artifact, "realized_state_snapshot"),
        Map.get(artifact, "repair_policy")
      )

    validate_activities(
      issues,
      Map.get(artifact, "activities", []),
      source_candidates_by_id,
      degraded_modes,
      repair_policy
    )
  end

  def validate(issues, _artifact), do: issues

  defp source_candidates_by_id(candidates) when is_list(candidates) do
    candidates
    |> Enum.filter(&is_map/1)
    |> Enum.group_by(&ActivityIdentity.activity_id/1)
  end

  defp source_candidates_by_id(_candidates), do: %{}

  defp degraded_context(%{} = realized_state, %{} = repair_policy) do
    spacecraft_states = Map.get(realized_state, "spacecraft_states", [])

    if is_list(spacecraft_states) and Enum.all?(spacecraft_states, &is_map/1) and
         valid_repair_policy_lists?(repair_policy) do
      repair_policy = RepairPolicySemantics.normalize(repair_policy)

      {
        RepairPolicySemantics.degraded_modes_by_scenario(realized_state, repair_policy),
        repair_policy
      }
    else
      {%{}, nil}
    end
  end

  defp degraded_context(_realized_state, _repair_policy), do: {%{}, nil}

  defp valid_repair_policy_lists?(repair_policy) do
    Enum.all?(@repair_policy_list_fields, fn field ->
      not Map.has_key?(repair_policy, field) or is_list(Map.get(repair_policy, field))
    end)
  end

  defp validate_activities(
         issues,
         activities,
         source_candidates_by_id,
         degraded_modes,
         repair_policy
       )
       when is_list(activities) do
    activities
    |> Enum.with_index()
    |> Enum.reduce(issues, fn {activity, activity_index}, acc ->
      {source_activity_id, source_context, rows} = ranking_context(activity)

      validate_rows(
        acc,
        "$.activities[#{activity_index}].repair.replacement_ranking.rows",
        rows,
        source_activity_id,
        source_context,
        source_candidates_by_id,
        degraded_modes,
        repair_policy
      )
    end)
  end

  defp validate_activities(
         issues,
         _activities,
         _source_candidates_by_id,
         _degraded_modes,
         _repair_policy
       ),
       do: issues

  defp ranking_context(
         %{
           "repair" => %{
             "source_activity_context" => source_context,
             "replacement_ranking" => %{"rows" => rows}
           }
         } = activity
       ),
       do: {get_in(activity, ["repair", "source_activity_id"]), source_context, rows}

  defp ranking_context(_activity), do: {nil, nil, nil}

  defp validate_rows(
         issues,
         path,
         rows,
         source_activity_id,
         %{} = source_context,
         source_candidates_by_id,
         degraded_modes,
         repair_policy
       )
       when is_list(rows) do
    if CampaignRepairReplacementRankingVersion.current?(rows) do
      rows
      |> Enum.with_index()
      |> Enum.reduce(issues, fn
        {%{} = row, index}, acc ->
          validate_row(
            acc,
            "#{path}[#{index}]",
            row,
            source_activity_id,
            source_context,
            source_candidates_by_id,
            degraded_modes,
            repair_policy
          )

        {_row, _index}, acc ->
          acc
      end)
    else
      issues
    end
  end

  defp validate_rows(
         issues,
         _path,
         _rows,
         _source_activity_id,
         _source_context,
         _source_candidates_by_id,
         _degraded_modes,
         _repair_policy
       ),
       do: issues

  defp validate_row(
         issues,
         path,
         row,
         source_activity_id,
         source_context,
         source_candidates_by_id,
         degraded_modes,
         repair_policy
       ) do
    issues = validate_source_exclusion(issues, path, row, source_activity_id)

    case Map.get(source_candidates_by_id, Map.get(row, "candidate_id"), []) do
      [%{} = candidate] ->
        issues
        |> validate_intent(path, source_context, candidate)
        |> validate_degraded_mode(path, candidate, degraded_modes, repair_policy)

      _missing_or_ambiguous_candidate ->
        issues
    end
  end

  defp validate_source_exclusion(issues, path, row, source_activity_id) do
    if is_binary(source_activity_id) and Map.get(row, "candidate_id") == source_activity_id do
      [
        error(
          path <> ".candidate_id",
          "must not identify the preserved repair source activity as its own replacement"
        )
        | issues
      ]
    else
      issues
    end
  end

  defp validate_intent(issues, path, source_context, candidate) do
    if RepairReplacementIntent.eligible?(source_context, candidate) do
      issues
    else
      [
        error(
          path <> ".candidate_id",
          "must identify an embedded source candidate within the preserved replacement kind and repair intent"
        )
        | issues
      ]
    end
  end

  defp validate_degraded_mode(issues, _path, _candidate, _degraded_modes, nil), do: issues

  defp validate_degraded_mode(issues, path, candidate, degraded_modes, repair_policy) do
    if RepairPolicySemantics.degraded_incompatible?(candidate, degraded_modes, repair_policy) do
      [
        error(
          path <> ".candidate_id",
          "must not identify a candidate incompatible with preserved degraded-mode state and repair policy"
        )
        | issues
      ]
    else
      issues
    end
  end
end
