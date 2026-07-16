defmodule OrbitalDynamics.CampaignPlanner.ObjectiveSatisfactionReports do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    DownlinkActivityNormalization,
    DownlinkCompletionCandidates,
    DownlinkObjectiveRequirements,
    ValueEncoding
  }

  def target_commitments(campaign, candidates, selected_activities) do
    campaign
    |> campaign_targets()
    |> Enum.map(&ValueEncoding.encode_value/1)
    |> Enum.sort_by(&(Map.get(&1, "id") || ""))
    |> Enum.map(fn target ->
      target_id = Map.get(target, "id")
      candidate_rows = target_activity_rows(candidates, target_id)
      selected_rows = target_activity_rows(selected_activities, target_id)

      %{
        "target_id" => target_id,
        "priority" => Map.get(target, "priority"),
        "candidate_activity_count" => length(candidate_rows),
        "candidate_duration_s" => activity_duration_sum(candidate_rows),
        "selected_activity_count" => length(selected_rows),
        "selected_duration_s" => activity_duration_sum(selected_rows),
        "selected_activity_ids" => Enum.map(selected_rows, & &1["id"]),
        "status" => target_commitment_status(candidate_rows, selected_rows)
      }
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Map.new()
    end)
  end

  def report(campaign, candidates, selected_activities, model_limits) do
    report(campaign, candidates, selected_activities, model_limits, callbacks())
  end

  def report(campaign, candidates, selected_activities, model_limits, callbacks) do
    rows =
      [
        coverage_objective_row(campaign, candidates, selected_activities),
        downlink_completion_objective_row(campaign, candidates, selected_activities, callbacks)
      ] ++ target_commitment_objective_rows(campaign, candidates, selected_activities)

    %{
      "schema_contract" => "objective_satisfaction_report.v1",
      "model" => "campaign_v1_selected_activity_objective_summary",
      "model_limits" => model_limits,
      "source" => "campaign_plan.activities",
      "objective_count" => length(rows),
      "rows" => rows,
      "assumptions" => %{
        "selection" => "best_ranked_timeline_is_selected",
        "coverage_model" => "selected_observe_activity_targets",
        "downlink_completion_model" => "selected_downlink_activity_count_or_data_volume",
        "execution_status" => "planned_not_executed"
      }
    }
  end

  defp campaign_targets(campaign), do: Map.get(campaign, "targets", [])

  defp target_activity_rows(activities, target_id) do
    activities
    |> Enum.map(&ValueEncoding.encode_value/1)
    |> Enum.filter(&(&1["type"] == "observe" and &1["target_id"] == target_id))
  end

  defp activity_duration_sum(activities) do
    activities
    |> Enum.map(&(Map.get(&1, "duration_s") || 0.0))
    |> Enum.sum()
  end

  defp target_commitment_status(_candidates, selected) when selected != [], do: "selected"

  defp target_commitment_status(candidates, _selected) when candidates != [],
    do: "candidate_available"

  defp target_commitment_status(_candidates, _selected), do: "no_candidate_window"

  defp coverage_objective_row(campaign, candidates, selected_activities) do
    target_ids =
      campaign
      |> campaign_targets()
      |> Enum.map(&(Map.get(&1, "id") || Map.get(&1, :id)))
      |> Enum.map(&ValueEncoding.encode_value/1)
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()
      |> Enum.sort()

    candidate_target_ids = observed_target_ids(candidates)
    selected_target_ids = observed_target_ids(selected_activities)
    required_count = length(target_ids)
    selected_count = length(selected_target_ids)

    %{
      "id" => "objective:target_coverage",
      "objective" => "target_coverage",
      "status" => coverage_status(required_count, selected_count),
      "required_count" => required_count,
      "candidate_count" => length(candidate_target_ids),
      "selected_count" => length(selected_target_ids),
      "satisfied_count" => selected_count,
      "candidate_target_ids" => candidate_target_ids,
      "selected_target_ids" => selected_target_ids
    }
  end

  defp downlink_completion_objective_row(campaign, candidates, selected_activities, callbacks) do
    downlink_completion_objectives = Keyword.fetch!(callbacks, :downlink_completion_objectives)
    objectives = downlink_completion_objectives.(campaign)

    objective_rows =
      campaign_downlink_objective_summaries(
        objectives,
        candidates,
        selected_activities,
        callbacks
      )

    required_count = downlink_required_contact_count(campaign, callbacks)
    required_downlink_mb = campaign_required_downlink_mb(campaign, callbacks)
    candidate_count = sum_number_field(objective_rows, "candidate_count")
    selected_count = sum_number_field(objective_rows, "selected_count")
    satisfied_count = sum_number_field(objective_rows, "satisfied_count")
    candidate_downlink_mb = sum_number_field(objective_rows, "candidate_downlink_mb")
    selected_downlink_mb = sum_number_field(objective_rows, "selected_downlink_mb")
    satisfied_downlink_mb = sum_number_field(objective_rows, "satisfied_downlink_mb")

    %{
      "id" => "objective:downlink_completion",
      "objective" => "downlink_completion",
      "status" =>
        downlink_completion_status(
          required_count,
          selected_count,
          required_downlink_mb,
          selected_downlink_mb
        ),
      "required_count" => required_count,
      "required_downlink_mb" => required_downlink_mb,
      "candidate_count" => candidate_count,
      "selected_count" => selected_count,
      "satisfied_count" => satisfied_count,
      "candidate_downlink_mb" => candidate_downlink_mb,
      "selected_downlink_mb" => selected_downlink_mb,
      "satisfied_downlink_mb" => satisfied_downlink_mb,
      "selected_contact_ids" =>
        campaign_downlink_selected_contact_ids(objectives, selected_activities, callbacks)
    }
    |> ValueEncoding.compact_map()
  end

  defp target_commitment_objective_rows(campaign, candidates, selected_activities) do
    campaign
    |> target_commitments(candidates, selected_activities)
    |> Enum.map(fn commitment ->
      %{
        "id" => "objective:target_commitment:#{commitment["target_id"]}",
        "objective" => "target_commitment",
        "target_id" => commitment["target_id"],
        "status" => commitment["status"],
        "required_count" => 1,
        "candidate_count" => commitment["candidate_activity_count"],
        "selected_count" => commitment["selected_activity_count"],
        "satisfied_count" => if(commitment["status"] == "selected", do: 1, else: 0),
        "selected_activity_ids" => commitment["selected_activity_ids"]
      }
    end)
  end

  defp observed_target_ids(activities) do
    activities
    |> Enum.filter(&(&1["type"] == "observe"))
    |> Enum.map(& &1["target_id"])
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp downlink_required_contact_count(campaign, callbacks) do
    downlink_completion_objectives = Keyword.fetch!(callbacks, :downlink_completion_objectives)

    campaign
    |> downlink_completion_objectives.()
    |> Enum.map(&Map.get(&1, "required_contacts"))
    |> Enum.filter(&is_number/1)
    |> case do
      [] -> nil
      counts -> Enum.sum(counts)
    end
  end

  defp campaign_required_downlink_mb(campaign, callbacks) do
    downlink_completion_objectives = Keyword.fetch!(callbacks, :downlink_completion_objectives)
    objective_required_downlink_mb = Keyword.fetch!(callbacks, :objective_required_downlink_mb)

    campaign
    |> downlink_completion_objectives.()
    |> Enum.map(objective_required_downlink_mb)
    |> Enum.filter(&is_number/1)
    |> case do
      [] -> nil
      values -> Enum.sum(values)
    end
  end

  defp campaign_downlink_objective_summaries([], candidates, selected_activities, callbacks) do
    [
      campaign_downlink_objective_summary(
        %{},
        candidates,
        selected_activities,
        nil,
        nil,
        callbacks
      )
    ]
  end

  defp campaign_downlink_objective_summaries(
         objectives,
         candidates,
         selected_activities,
         callbacks
       ) do
    objective_required_downlink_mb = Keyword.fetch!(callbacks, :objective_required_downlink_mb)

    Enum.map(objectives, fn objective ->
      campaign_downlink_objective_summary(
        objective,
        candidates,
        selected_activities,
        Map.get(objective, "required_contacts"),
        objective_required_downlink_mb.(objective),
        callbacks
      )
    end)
  end

  defp campaign_downlink_selected_contact_ids([], selected_activities, callbacks) do
    downlink_activity? = Keyword.fetch!(callbacks, :downlink_activity?)

    selected_activities
    |> Enum.filter(downlink_activity?)
    |> Enum.map(& &1["id"])
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp campaign_downlink_selected_contact_ids(objectives, selected_activities, callbacks) do
    downlink_activity? = Keyword.fetch!(callbacks, :downlink_activity?)

    downlink_completion_event_match? =
      Keyword.fetch!(callbacks, :downlink_completion_event_match?)

    selected_activities
    |> Enum.filter(fn activity ->
      downlink_activity?.(activity) and
        Enum.any?(objectives, &downlink_completion_event_match?.(activity, &1))
    end)
    |> Enum.map(& &1["id"])
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp campaign_downlink_objective_summary(
         objective,
         candidates,
         selected_activities,
         required_count,
         required_downlink_mb,
         callbacks
       ) do
    downlink_activity? = Keyword.fetch!(callbacks, :downlink_activity?)

    downlink_completion_event_match? =
      Keyword.fetch!(callbacks, :downlink_completion_event_match?)

    planned_downlink_mb = Keyword.fetch!(callbacks, :planned_downlink_mb)

    candidate_downlinks =
      Enum.filter(
        candidates,
        &(downlink_activity?.(&1) and downlink_completion_event_match?.(&1, objective))
      )

    selected_downlinks =
      Enum.filter(
        selected_activities,
        &(downlink_activity?.(&1) and downlink_completion_event_match?.(&1, objective))
      )

    selected_count = length(selected_downlinks)
    selected_downlink_mb = planned_downlink_mb.(selected_downlinks, objective)

    %{
      "required_count" => required_count,
      "required_downlink_mb" => required_downlink_mb,
      "candidate_count" => length(candidate_downlinks),
      "selected_count" => selected_count,
      "satisfied_count" => min(selected_count, required_count || selected_count),
      "candidate_downlink_mb" => planned_downlink_mb.(candidate_downlinks, objective),
      "selected_downlink_mb" => selected_downlink_mb,
      "satisfied_downlink_mb" =>
        if(is_number(required_downlink_mb),
          do: min(selected_downlink_mb, required_downlink_mb),
          else: selected_downlink_mb
        )
    }
    |> ValueEncoding.compact_map()
  end

  defp coverage_status(0, _selected_count), do: "no_requirement"

  defp coverage_status(required_count, selected_count) when selected_count >= required_count,
    do: "met"

  defp coverage_status(_required_count, 0), do: "unmet"
  defp coverage_status(_required_count, _selected_count), do: "partial"

  defp downlink_completion_status(nil, _selected_count), do: "no_requirement"

  defp downlink_completion_status(required_count, selected_count)
       when selected_count >= required_count,
       do: "met"

  defp downlink_completion_status(_required_count, 0), do: "unmet"
  defp downlink_completion_status(_required_count, _selected_count), do: "partial"

  defp downlink_completion_status(
         required_count,
         selected_count,
         required_downlink_mb,
         selected_mb
       )
       when is_number(required_downlink_mb) do
    cond do
      selected_mb >= required_downlink_mb and
          (not is_number(required_count) or selected_count >= required_count) ->
        "met"

      selected_mb == 0.0 and selected_count == 0 ->
        "unmet"

      is_number(required_count) and selected_count < required_count ->
        "partial"

      true ->
        "partial"
    end
  end

  defp downlink_completion_status(
         required_count,
         selected_count,
         _required_downlink_mb,
         _selected_mb
       ),
       do: downlink_completion_status(required_count, selected_count)

  defp sum_number_field(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.filter(&is_number/1)
    |> case do
      [] -> nil
      values -> Enum.sum(values)
    end
  end

  defp callbacks do
    [
      downlink_completion_objectives: &DownlinkObjectiveRequirements.objectives/1,
      objective_required_downlink_mb: &DownlinkObjectiveRequirements.required_mb/1,
      downlink_activity?: &DownlinkActivityNormalization.downlink?/1,
      downlink_completion_event_match?: &DownlinkCompletionCandidates.event_match?/2,
      planned_downlink_mb: &DownlinkObjectiveRequirements.planned_mb/2
    ]
  end
end
