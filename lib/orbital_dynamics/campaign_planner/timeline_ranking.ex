defmodule OrbitalDynamics.CampaignPlanner.TimelineRanking do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ActivityTiming,
    DownlinkActivityNormalization,
    DownlinkObjectiveRequirements,
    ResourceProjectionRisk,
    ScalarValues,
    ValueEncoding
  }

  alias OrbitalDynamics.ResourceProjection
  alias OrbitalDynamics.Timeline

  def ranked_timeline(scenario_id, candidates, constraints, policy, campaign) do
    ranked_timeline(scenario_id, candidates, constraints, policy, campaign, callbacks())
  end

  def ranked_timeline(scenario_id, candidates, constraints, policy, campaign, callbacks) do
    policy_count_value = Keyword.fetch!(callbacks, :policy_count_value)
    numeric_policy_value = Keyword.fetch!(callbacks, :numeric_policy_value)
    activity_start = Keyword.fetch!(callbacks, :activity_start)
    overlaps? = Keyword.fetch!(callbacks, :overlaps?)
    candidate_score = Keyword.fetch!(callbacks, :candidate_score)
    encode_value = Keyword.fetch!(callbacks, :encode_value)
    downlink_activity? = Keyword.fetch!(callbacks, :downlink_activity?)

    max_activities =
      policy_count_value.(constraints, "max_timeline_activities", length(candidates))

    activity_count_penalty = numeric_policy_value.(policy, "activity_count_penalty", 0.0)
    downlink_completion_context = downlink_completion_score_context(campaign, policy, callbacks)
    timeline_precondition_context = timeline_precondition_score_context(policy, callbacks)
    resource_projection_context = resource_projection_score_context(campaign, policy, callbacks)

    activities =
      candidates
      |> Enum.sort_by(
        &{
          -candidate_selection_score(
            &1,
            downlink_completion_context,
            timeline_precondition_context,
            resource_projection_context,
            callbacks
          ),
          activity_start.(&1),
          &1["id"]
        }
      )
      |> Enum.reduce([], fn candidate, selected ->
        cond do
          length(selected) >= max_activities -> selected
          Enum.any?(selected, &overlaps?.(candidate, &1)) -> selected
          true -> [candidate | selected]
        end
      end)
      |> Enum.sort_by(&{&1["starts_at_s"], &1["id"]})

    gross_score = activities |> Enum.map(candidate_score) |> Enum.sum()
    penalty = length(activities) * activity_count_penalty
    component_terms = timeline_component_score_terms(activities, callbacks)

    objective_terms =
      downlink_completion_score_terms(activities, downlink_completion_context, callbacks)

    precondition_terms =
      timeline_precondition_score_terms(activities, timeline_precondition_context, callbacks)

    resource_projection_terms =
      resource_projection_score_terms(activities, resource_projection_context, callbacks)

    score =
      gross_score - penalty + Map.get(objective_terms, "downlink_completion_score", 0.0) +
        Map.get(precondition_terms, "timeline_precondition_pressure_penalty", 0.0) +
        Map.get(resource_projection_terms, "resource_projection_pressure_penalty", 0.0)

    %{
      "scenario_id" => encode_value.(scenario_id),
      "score" => score,
      "score_terms" =>
        component_terms
        |> Map.merge(objective_terms)
        |> Map.merge(precondition_terms)
        |> Map.merge(resource_projection_terms)
        |> Map.merge(%{
          "activity_score" => gross_score,
          "activity_count_penalty" => -penalty,
          "selected_observation_count" => Enum.count(activities, &(&1["type"] == "observe")),
          "selected_contact_count" => Enum.count(activities, downlink_activity?)
        }),
      "activity_count" => length(activities),
      "activities" => activities
    }
  end

  defp candidate_selection_score(
         candidate,
         downlink_completion_context,
         timeline_precondition_context,
         resource_projection_context,
         callbacks
       ) do
    candidate_score = Keyword.fetch!(callbacks, :candidate_score)

    candidate_score.(candidate) +
      Map.get(
        downlink_completion_score_terms([candidate], downlink_completion_context, callbacks),
        "downlink_completion_score",
        0.0
      ) +
      Map.get(
        timeline_precondition_score_terms([candidate], timeline_precondition_context, callbacks),
        "timeline_precondition_pressure_penalty",
        0.0
      ) +
      Map.get(
        resource_projection_score_terms([candidate], resource_projection_context, callbacks),
        "resource_projection_pressure_penalty",
        0.0
      )
  end

  defp downlink_completion_score_context(campaign, policy, callbacks) do
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)
    numeric_policy_value = Keyword.fetch!(callbacks, :numeric_policy_value)
    campaign_required_downlink_mb = Keyword.fetch!(callbacks, :campaign_required_downlink_mb)

    required_downlink_mb =
      numeric_or_nil.(Map.get(policy, "required_downlink_mb")) ||
        campaign_required_downlink_mb.(campaign)

    weight = numeric_policy_value.(policy, "downlink_completion_weight", 0.0)

    if is_number(required_downlink_mb) and required_downlink_mb > 0.0 and weight > 0.0 do
      %{required_downlink_mb: required_downlink_mb, weight: weight}
    else
      nil
    end
  end

  defp downlink_completion_score_terms(
         activities,
         %{required_downlink_mb: required_downlink_mb, weight: weight},
         callbacks
       ) do
    planned_downlink_mb = Keyword.fetch!(callbacks, :planned_downlink_mb)
    selected_downlink_mb = planned_downlink_mb.(activities, %{})
    ratio = min(selected_downlink_mb / required_downlink_mb, 1.0)

    %{
      "downlink_completion_score" => ratio * weight,
      "downlink_completion_ratio" => ratio,
      "selected_downlink_mb" => selected_downlink_mb,
      "required_downlink_mb" => required_downlink_mb
    }
  end

  defp downlink_completion_score_terms(_activities, _terms, _callbacks), do: %{}

  defp timeline_precondition_score_context(policy, callbacks) do
    numeric_policy_value = Keyword.fetch!(callbacks, :numeric_policy_value)
    weight = numeric_policy_value.(policy, "timeline_precondition_weight", 0.0)

    if weight > 0.0 do
      %{weight: weight}
    end
  end

  defp timeline_precondition_score_terms(activities, %{weight: weight}, callbacks) do
    sum_number_field = Keyword.fetch!(callbacks, :sum_number_field)
    summaries = Enum.map(activities, &Timeline.activity_precondition_summary/1)
    blocked_count = sum_number_field.(summaries, "blocked_precondition_count")
    review_count = sum_number_field.(summaries, "review_precondition_count")
    pressure_count = blocked_count + review_count
    penalty = -pressure_count * weight

    if pressure_count > 0.0 do
      %{
        "timeline_precondition_pressure_penalty" => penalty,
        "timeline_precondition_pressure_count" => pressure_count,
        "blocked_precondition_count" => blocked_count,
        "review_precondition_count" => review_count
      }
    else
      %{}
    end
  end

  defp timeline_precondition_score_terms(_activities, _context, _callbacks), do: %{}

  defp resource_projection_score_context(campaign, policy, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    numeric_policy_value = Keyword.fetch!(callbacks, :numeric_policy_value)

    summaries =
      campaign
      |> Map.get("resource_summaries", [])
      |> List.wrap()
      |> Enum.map(stringify_keys)

    weight = numeric_policy_value.(policy, "resource_projection_weight", 0.0)

    if weight > 0.0 and summaries != [] do
      %{
        weight: weight,
        summaries: summaries,
        approval_policy:
          Map.get(campaign, "approval_policy") || Map.get(campaign, :approval_policy)
      }
    end
  end

  defp resource_projection_score_terms(
         activities,
         %{weight: weight, summaries: summaries, approval_policy: approval_policy},
         callbacks
       ) do
    resource_projection_report = Keyword.fetch!(callbacks, :resource_projection_report)
    maximum_present = Keyword.fetch!(callbacks, :maximum_present)

    report =
      resource_projection_report.(
        activities,
        summaries,
        "thin_campaign_resource_projection_score",
        "campaign.resource_summaries",
        approval_policy
      )

    risks = ResourceProjectionRisk.risk_indicators(report)
    pressure_count = length(risks)

    if pressure_count > 0 do
      rows = Map.get(report, "projected_resources", [])

      %{
        "resource_projection_pressure_penalty" => -pressure_count * weight,
        "resource_projection_pressure_count" => pressure_count,
        "projected_storage_overflow_mb" =>
          maximum_present.(rows, "projected_storage_overflow_mb") || 0.0,
        "projected_downlink_shortfall_mb" =>
          maximum_present.(rows, "projected_downlink_shortfall_mb") || 0.0,
        "projected_battery_overuse_wh" =>
          maximum_present.(rows, "projected_battery_overuse_wh") || 0.0
      }
    else
      %{}
    end
  end

  defp resource_projection_score_terms(_activities, _context, _callbacks), do: %{}

  defp timeline_component_score_terms(activities, callbacks) do
    numeric_or_zero = Keyword.fetch!(callbacks, :numeric_or_zero)

    Enum.reduce(
      activities,
      %{"target_value" => 0.0, "contact_value" => 0.0, "eclipse_penalty" => 0.0},
      fn activity, acc ->
        terms = Map.get(activity, "score_terms", %{})

        Map.merge(acc, terms, fn _key, left, right ->
          numeric_or_zero.(left) + numeric_or_zero.(right)
        end)
      end
    )
  end

  defp callbacks do
    [
      policy_count_value: &policy_count_value/3,
      numeric_policy_value: &numeric_policy_value/3,
      numeric_or_nil: &ScalarValues.numeric_or_nil/1,
      numeric_or_zero: &ScalarValues.numeric_or_zero/1,
      stringify_keys: &ValueEncoding.stringify_keys/1,
      activity_start: &ActivityTiming.activity_start/1,
      overlaps?: &ActivityTiming.overlaps?/2,
      candidate_score: &candidate_score/1,
      encode_value: &ValueEncoding.encode_value/1,
      downlink_activity?: &DownlinkActivityNormalization.downlink?/1,
      campaign_required_downlink_mb: &campaign_required_downlink_mb/1,
      planned_downlink_mb: &DownlinkObjectiveRequirements.planned_mb/2,
      sum_number_field: &sum_number_field/2,
      resource_projection_report: &resource_projection_report/5,
      maximum_present: &maximum_present/2
    ]
  end

  defp numeric_policy_value(policy, key, default) do
    case ScalarValues.numeric_or_nil(Map.get(policy, key)) do
      value when is_number(value) -> value
      _value -> default
    end
  end

  defp policy_count_value(policy, key, default) do
    case numeric_policy_value(policy, key, default) do
      value when is_number(value) -> max(trunc(value), 0)
      _value -> default
    end
  end

  defp candidate_score(candidate),
    do: ScalarValues.numeric_or_nil(Map.get(candidate, "score")) || 0.0

  defp campaign_required_downlink_mb(campaign) do
    campaign
    |> DownlinkObjectiveRequirements.objectives()
    |> Enum.map(&DownlinkObjectiveRequirements.required_mb/1)
    |> Enum.filter(&is_number/1)
    |> case do
      [] -> nil
      values -> Enum.sum(values)
    end
  end

  defp resource_projection_report(activities, summaries, model, source, approval_policy) do
    ResourceProjection.report(activities, summaries,
      model: model,
      source: source,
      approval_policy: approval_policy
    )
  end

  defp sum_number_field(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field, 0))
    |> Enum.filter(&is_number/1)
    |> Enum.sum()
  end

  defp maximum_present(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.filter(&is_number/1)
    |> case do
      [] -> nil
      values -> Enum.max(values)
    end
  end
end
