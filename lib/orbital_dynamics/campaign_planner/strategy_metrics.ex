defmodule OrbitalDynamics.CampaignPlanner.StrategyMetrics do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ActivityTiming,
    DownlinkActivityNormalization,
    DownlinkObjectiveRequirements,
    PriorityCommitmentSatisfaction,
    ScalarValues,
    ValueEncoding
  }

  def target_count(activities) do
    activities
    |> Enum.filter(&(&1["type"] == "observe"))
    |> Enum.map(& &1["target_id"])
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> length()
  end

  def revisit_count(activities) do
    activities
    |> Enum.filter(&(&1["type"] == "observe"))
    |> Enum.map(& &1["target_id"])
    |> Enum.frequencies()
    |> Map.values()
    |> Enum.map(&max(&1 - 1, 0))
    |> Enum.sum()
  end

  def collection_latency_s(activities), do: collection_latency_s(activities, default_callbacks())

  def collection_latency_s(activities, callbacks) do
    downlink_activity? = Keyword.fetch!(callbacks, :downlink_activity?)
    activity_start = Keyword.fetch!(callbacks, :activity_start)
    activity_end = Keyword.fetch!(callbacks, :activity_end)

    observations = Enum.filter(activities, &(&1["type"] == "observe"))
    downlinks = Enum.filter(activities, downlink_activity?)

    observations
    |> Enum.map(fn observation ->
      downlinks
      |> Enum.filter(fn downlink ->
        downlink["scenario_id"] == observation["scenario_id"] and
          activity_start.(downlink) >= activity_end.(observation)
      end)
      |> Enum.map(&(activity_start.(&1) - activity_end.(observation)))
      |> Enum.min(fn -> 0.0 end)
    end)
    |> Enum.sum()
  end

  def downlink_completion_ratio(activities, request),
    do: downlink_completion_ratio(activities, request, default_callbacks())

  def downlink_completion_ratio(activities, request, callbacks) do
    downlink_completion_satisfaction =
      Keyword.fetch!(callbacks, :downlink_completion_satisfaction)

    activities
    |> downlink_completion_satisfaction.(request)
    |> Map.get("ratio", 0.0)
  end

  def downlink_completion_satisfaction(activities, request) do
    downlink_completion_satisfaction(activities, request, default_callbacks())
  end

  def schedule_stability_penalty(repair_score_terms) do
    Map.get(repair_score_terms, "schedule_churn_penalty", 0.0) +
      Map.get(repair_score_terms, "schedule_move_penalty", 0.0)
  end

  def asset_balance_score([]), do: 0.0

  def asset_balance_score(activities) do
    counts =
      activities
      |> Enum.map(& &1["scenario_id"])
      |> Enum.reject(&is_nil/1)
      |> Enum.frequencies()
      |> Map.values()

    case counts do
      [] -> 0.0
      [_single] -> 1.0
      values -> 1.0 / (1.0 + Enum.max(values) - Enum.min(values))
    end
  end

  def priority_commitment_score(activities, request),
    do: priority_commitment_score(activities, request, default_callbacks())

  def priority_commitment_score(activities, request, callbacks) do
    priority_commitment_satisfaction =
      Keyword.fetch!(callbacks, :priority_commitment_satisfaction)

    satisfaction = priority_commitment_satisfaction.(request.mission_state, activities)

    if satisfaction["required_target_ids"] == [] do
      0.0
    else
      satisfaction["ratio"]
    end
  end

  def priority_commitment_satisfaction(mission_state, activities) do
    PriorityCommitmentSatisfaction.summary(mission_state, activities, [])
  end

  defp default_callbacks do
    [
      downlink_activity?: &DownlinkActivityNormalization.downlink?/1,
      activity_start: &ActivityTiming.activity_start/1,
      activity_end: &ActivityTiming.activity_end/1,
      downlink_completion_satisfaction: &downlink_completion_satisfaction/2,
      priority_commitment_satisfaction: &priority_commitment_satisfaction/2
    ]
  end

  defp downlink_completion_satisfaction(activities, request, _callbacks) do
    objectives =
      case DownlinkObjectiveRequirements.objectives(request.mission_state) do
        [] -> [nil]
        objectives -> objectives
      end

    objectives
    |> Enum.map(&downlink_completion_objective_satisfaction(activities, request, &1))
    |> aggregate_downlink_completion_satisfaction()
  end

  defp downlink_completion_objective_satisfaction(activities, request, objective) do
    required_contacts =
      if is_nil(objective) do
        DownlinkObjectiveRequirements.required_contacts(request.mission_state, request.prior_plan)
      else
        DownlinkObjectiveRequirements.required_contacts(objective, request.prior_plan)
      end

    required_downlink_mb = objective_required_downlink_mb(objective || %{})
    planned_contacts = DownlinkObjectiveRequirements.planned_count(activities, objective)
    planned_downlink_mb = DownlinkObjectiveRequirements.planned_mb(activities, objective)

    ratio =
      downlink_completion_objective_ratio(
        planned_contacts,
        required_contacts,
        planned_downlink_mb,
        required_downlink_mb,
        objective
      )

    %{
      "required_contacts" => required_contacts,
      "planned_contacts" => planned_contacts,
      "required_downlink_mb" => required_downlink_mb,
      "planned_downlink_mb" => planned_downlink_mb,
      "ratio" => ratio
    }
    |> ValueEncoding.compact_map()
  end

  defp objective_required_downlink_mb(%{} = objective) do
    DownlinkObjectiveRequirements.required_mb(objective)
  end

  defp objective_required_downlink_mb(_objective), do: nil

  defp aggregate_downlink_completion_satisfaction(rows) do
    required_downlink_mbs =
      rows
      |> Enum.map(&Map.get(&1, "required_downlink_mb"))
      |> Enum.filter(&is_number/1)

    %{
      "required_contacts" => sum_number_field(rows, "required_contacts"),
      "planned_contacts" => sum_number_field(rows, "planned_contacts"),
      "required_downlink_mb" =>
        if(required_downlink_mbs == [], do: nil, else: Enum.sum(required_downlink_mbs)),
      "planned_downlink_mb" => sum_number_field(rows, "planned_downlink_mb"),
      "ratio" =>
        rows
        |> Enum.map(&Map.get(&1, "ratio", 0.0))
        |> average_ratio()
    }
    |> ValueEncoding.compact_map()
  end

  defp sum_number_field(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field, 0))
    |> Enum.filter(&is_number/1)
    |> Enum.sum()
  end

  defp average_ratio([]), do: 0.0

  defp average_ratio(values) do
    Enum.sum(values) / length(values)
  end

  defp downlink_completion_objective_ratio(
         planned_contacts,
         required_contacts,
         planned_downlink_mb,
         required_downlink_mb,
         objective
       ) do
    contact_ratio =
      if downlink_contact_requirement_declared?(objective) or
           not (is_number(required_downlink_mb) and required_downlink_mb > 0.0) do
        min(planned_contacts / max(required_contacts, 1), 1.0)
      end

    mb_ratio =
      if is_number(required_downlink_mb) and required_downlink_mb > 0.0 do
        min(planned_downlink_mb / required_downlink_mb, 1.0)
      end

    [contact_ratio, mb_ratio]
    |> Enum.reject(&is_nil/1)
    |> Enum.min(fn -> 0.0 end)
  end

  defp downlink_contact_requirement_declared?(%{} = objective),
    do: is_number(ScalarValues.numeric_or_nil(Map.get(objective, "required_contacts")))

  defp downlink_contact_requirement_declared?(_objective), do: true
end
