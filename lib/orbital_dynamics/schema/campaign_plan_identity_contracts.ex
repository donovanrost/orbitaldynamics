defmodule OrbitalDynamics.Schema.CampaignPlanIdentityContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation, only: [error: 2]

  alias OrbitalDynamics.Schema.StableIdValidation

  def validate(issues, artifact) when is_map(artifact) do
    issues
    |> validate_generated_at(Map.get(artifact, "generated_at"))
    |> validate_plan_id(artifact)
    |> validate_ranked_scenario_identity(Map.get(artifact, "ranked_timelines"))
  end

  defp validate_generated_at(issues, generated_at) when is_binary(generated_at) do
    case DateTime.from_iso8601(generated_at) do
      {:ok, _date_time, _utc_offset} -> issues
      {:error, _reason} -> invalid_generated_at(issues)
    end
  end

  defp validate_generated_at(issues, nil), do: issues
  defp validate_generated_at(issues, _generated_at), do: invalid_generated_at(issues)

  defp invalid_generated_at(issues) do
    [error("$.generated_at", "must be an ISO 8601 date-time string") | issues]
  end

  defp validate_plan_id(
         issues,
         %{
           "plan_id" => plan_id,
           "study_id" => study_id,
           "generated_at" => generated_at
         }
       )
       when is_binary(plan_id) and is_binary(study_id) and is_binary(generated_at) do
    expected = "campaign_plan:#{study_id}:#{generated_at}"

    if plan_id == expected do
      issues
    else
      [
        error(
          "$.plan_id",
          "must equal campaign_plan:<study_id>:<generated_at>"
        )
        | issues
      ]
    end
  end

  defp validate_plan_id(issues, _artifact), do: issues

  defp validate_ranked_scenario_identity(issues, timelines) when is_list(timelines) do
    issues
    |> reject_duplicate_scenario_ids(timelines)
    |> validate_activity_scenario_ownership(timelines)
  end

  defp validate_ranked_scenario_identity(issues, _timelines), do: issues

  defp reject_duplicate_scenario_ids(issues, timelines) do
    timelines
    |> Enum.with_index()
    |> Enum.reduce({issues, MapSet.new()}, fn
      {%{"scenario_id" => scenario_id}, index}, {acc, seen} ->
        cond do
          not StableIdValidation.valid?(scenario_id) ->
            {acc, seen}

          MapSet.member?(seen, scenario_id) ->
            {
              [
                error(
                  "$.ranked_timelines[#{index}].scenario_id",
                  "must be unique across ranked timelines"
                )
                | acc
              ],
              seen
            }

          true ->
            {acc, MapSet.put(seen, scenario_id)}
        end

      {_timeline, _index}, state ->
        state
    end)
    |> elem(0)
  end

  defp validate_activity_scenario_ownership(issues, timelines) do
    timelines
    |> Enum.with_index()
    |> Enum.reduce(issues, fn
      {%{"scenario_id" => scenario_id, "activities" => activities}, timeline_index}, acc
      when is_list(activities) ->
        validate_timeline_activity_scenarios(acc, activities, timeline_index, scenario_id)

      {_timeline, _timeline_index}, acc ->
        acc
    end)
  end

  defp validate_timeline_activity_scenarios(issues, activities, timeline_index, scenario_id) do
    activities
    |> Enum.with_index()
    |> Enum.reduce(issues, fn
      {%{"scenario_id" => activity_scenario_id}, activity_index}, acc ->
        if StableIdValidation.valid?(scenario_id) and
             StableIdValidation.valid?(activity_scenario_id) and
             scenario_id != activity_scenario_id do
          [
            error(
              "$.ranked_timelines[#{timeline_index}].activities[#{activity_index}].scenario_id",
              "must match enclosing ranked timeline scenario_id"
            )
            | acc
          ]
        else
          acc
        end

      {_activity, _activity_index}, acc ->
        acc
    end)
  end
end
