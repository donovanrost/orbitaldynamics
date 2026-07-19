defmodule OrbitalDynamics.Timeline.LifecycleStateSummaryRowPolicy do
  @moduledoc false

  def build(
        timeline_id,
        rank,
        planned_matches,
        realized_matches,
        activity_lifecycle_state,
        sorted_uniq
      ) do
    cond do
      length(planned_matches) > 1 or length(realized_matches) > 1 ->
        duplicate_row(
          timeline_id,
          rank,
          planned_matches,
          realized_matches,
          sorted_uniq
        )

      Enum.any?(planned_matches ++ realized_matches, &(&1["invalid_activity_input"] == true)) ->
        invalid_row(timeline_id, rank, planned_matches, realized_matches, sorted_uniq)

      true ->
        planned_activity = List.first(planned_matches)
        realized_activity = List.first(realized_matches)

        planned_activity
        |> activity_lifecycle_state.(realized_activity)
        |> Map.put("rank", rank)
    end
  end

  defp duplicate_row(timeline_id, rank, planned_matches, realized_matches, sorted_uniq) do
    %{
      "rank" => rank,
      "timeline_id" => timeline_id,
      "planned_activity_ids" => activity_ids(planned_matches, sorted_uniq),
      "realized_activity_ids" => activity_ids(realized_matches, sorted_uniq),
      "planned_duplicate_activity_count" =>
        OrbitalDynamics.Timeline.LifecycleStateSummaryMetricsPolicy.duplicate_match_count(
          planned_matches
        ),
      "realized_duplicate_activity_count" =>
        OrbitalDynamics.Timeline.LifecycleStateSummaryMetricsPolicy.duplicate_match_count(
          realized_matches
        ),
      "timeline_identity_collision" => true,
      "transition_decision" => "review",
      "review_required" => true,
      "required_operator_action" => "review_duplicate_timeline_identity",
      "required_operator_actions" => ["review_duplicate_timeline_identity"],
      "operator_action_reasons" => ["duplicate_timeline_identity"],
      "import_action" => "review_timeline_diff",
      "assumptions" => %{
        "artifact_only" => true,
        "no_schedule_mutation" => true,
        "no_operator_authority_grant" => true,
        "no_cadence_import" => true,
        "no_command_execution" => true
      }
    }
    |> compact_map()
  end

  defp invalid_row(timeline_id, rank, planned_matches, realized_matches, sorted_uniq) do
    invalid_rows =
      Enum.filter(planned_matches ++ realized_matches, &(&1["invalid_activity_input"] == true))

    %{
      "rank" => rank,
      "timeline_id" => timeline_id,
      "planned_activity_ids" => activity_ids(planned_matches, sorted_uniq),
      "realized_activity_ids" => activity_ids(realized_matches, sorted_uniq),
      "invalid_activity_input" => true,
      "invalid_activity_input_count" => length(invalid_rows),
      "invalid_activity_input_reasons" =>
        invalid_rows
        |> Enum.map(& &1["invalid_activity_input_reason"])
        |> sorted_uniq.(),
      "transition_decision" => "review",
      "review_required" => true,
      "required_operator_action" => "review_invalid_activity_input",
      "required_operator_actions" => ["review_invalid_activity_input"],
      "operator_action_reasons" =>
        invalid_rows
        |> Enum.map(& &1["invalid_activity_input_reason"])
        |> sorted_uniq.(),
      "import_action" => "review_timeline_diff",
      "assumptions" => %{
        "artifact_only" => true,
        "no_schedule_mutation" => true,
        "no_operator_authority_grant" => true,
        "no_cadence_import" => true,
        "no_command_execution" => true
      }
    }
    |> compact_map()
  end

  defp activity_ids(matches, sorted_uniq) do
    OrbitalDynamics.Timeline.LifecycleStateSummaryMetricsPolicy.lifecycle_state_match_activity_ids(
      matches,
      sorted_uniq
    )
  end

  defp compact_map(map) do
    OrbitalDynamics.Timeline.ArtifactValueEncodingPolicy.compact(map)
  end
end
