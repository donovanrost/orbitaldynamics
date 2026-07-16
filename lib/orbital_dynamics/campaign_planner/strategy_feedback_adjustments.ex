defmodule OrbitalDynamics.CampaignPlanner.StrategyFeedbackAdjustments do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ActivityIdentity,
    BranchOperationalFeedback,
    CommandActivityClassification,
    DownlinkActivityNormalization,
    RealizedFeedbackContext,
    ValueEncoding
  }

  def build(candidate_plan, repair_result, branch, feedback) do
    activities = branch_feedback_plan_activities(candidate_plan)
    source_candidate_activities = Map.get(repair_result, "source_candidate_activities", [])

    {downlink_activities, downlink_activity_source} =
      branch_feedback_activities(activities, source_candidate_activities, :downlink)

    {observation_activities, observation_activity_source} =
      branch_feedback_activities(activities, source_candidate_activities, :observe)

    contact_factor =
      average_downlink_activity_factor(
        downlink_activities,
        feedback["contact_success_rate"],
        "ground_station_id"
      )

    observation_factor =
      average_activity_factor(
        observation_activities,
        "observe",
        feedback["observation_success_rate"],
        "target_id"
      )

    image_quality_score =
      average_activity_optional_feedback_factor(
        observation_activities,
        "observe",
        feedback["image_quality_score"],
        "target_id"
      )

    image_quality_statuses =
      activity_feedback_text_values(
        observation_activities,
        "observe",
        feedback["image_quality_status"],
        "target_id"
      )

    image_quality_sources =
      activity_feedback_text_values(
        observation_activities,
        "observe",
        feedback["image_quality_source"],
        "target_id"
      )

    cloud_cover_fraction =
      average_activity_optional_feedback_factor(
        observation_activities,
        "observe",
        feedback["cloud_cover_fraction"],
        "target_id"
      )

    blur_score =
      average_activity_optional_feedback_factor(
        observation_activities,
        "observe",
        feedback["blur_score"],
        "target_id"
      )

    maneuver_factor =
      maneuver_success_factor(
        activities,
        branch,
        feedback["maneuver_success_rate"]
      )

    command_factor =
      command_success_factor(
        activities,
        feedback["command_success_rate"]
      )

    station_throughput =
      average_downlink_activity_factor(
        downlink_activities,
        feedback["station_throughput_factor"],
        "ground_station_id"
      )

    factors = [
      {"contact_success_rate", contact_factor},
      {"observation_success_rate", observation_factor},
      {"maneuver_success_rate", maneuver_factor},
      {"command_success_rate", command_factor},
      {"station_throughput_factor", station_throughput}
    ]

    risk_indicators =
      factors
      |> Enum.filter(fn {_key, value} -> is_number(value) and value < 0.8 end)
      |> Enum.map(fn {key, value} ->
        %{
          "type" => key <> "_low",
          "severity" => "medium",
          "reason" => "#{key} feedback factor #{value} reduces branch confidence",
          "value" => value
        }
      end)

    score_adjustment =
      factors
      |> Enum.map(fn {_key, value} ->
        if is_number(value), do: (value - 1.0) * 50.0, else: 0.0
      end)
      |> Enum.sum()

    feedback_weight_sources = branch_event_feedback_weight_sources(branch["events"])

    adjustments = %{
      "model" => "deterministic_success_rate_and_throughput_adjustment",
      "contact_success_factor" => contact_factor,
      "contact_success_factor_source" =>
        branch_feedback_factor_source(contact_factor, "operational_feedback.contact_success_rate"),
      "contact_success_factor_activity_source" =>
        branch_feedback_factor_source(contact_factor, downlink_activity_source),
      "observation_success_factor" => observation_factor,
      "observation_success_factor_source" =>
        branch_feedback_factor_source(
          observation_factor,
          "operational_feedback.observation_success_rate"
        ),
      "observation_success_factor_activity_source" =>
        branch_feedback_factor_source(observation_factor, observation_activity_source),
      "image_quality_score" => image_quality_score,
      "image_quality_score_source" =>
        branch_feedback_factor_source(
          image_quality_score,
          "operational_feedback.image_quality_score"
        ),
      "image_quality_statuses" => image_quality_statuses,
      "image_quality_sources" => image_quality_sources,
      "cloud_cover_fraction" => cloud_cover_fraction,
      "cloud_cover_fraction_source" =>
        branch_feedback_factor_source(
          cloud_cover_fraction,
          "operational_feedback.cloud_cover_fraction"
        ),
      "blur_score" => blur_score,
      "blur_score_source" =>
        branch_feedback_factor_source(blur_score, "operational_feedback.blur_score"),
      "maneuver_success_factor" => maneuver_factor,
      "maneuver_success_factor_source" =>
        branch_feedback_factor_source(
          maneuver_factor,
          "operational_feedback.maneuver_success_rate"
        ),
      "command_success_factor" => command_factor,
      "command_success_factor_source" =>
        branch_feedback_factor_source(command_factor, "operational_feedback.command_success_rate"),
      "station_throughput_factor" => station_throughput,
      "station_throughput_factor_source" =>
        branch_feedback_factor_source(
          station_throughput,
          "operational_feedback.station_throughput_factor"
        ),
      "station_throughput_factor_activity_source" =>
        branch_feedback_factor_source(station_throughput, downlink_activity_source),
      "score_adjustment" => score_adjustment,
      "risk_indicators" => risk_indicators,
      "branch_event_count" => length(branch["events"])
    }

    if feedback_weight_sources == [] do
      adjustments
    else
      Map.put(adjustments, "feedback_weight_sources", feedback_weight_sources)
    end
  end

  defp branch_feedback_factor_source(value, source) when is_number(value), do: source
  defp branch_feedback_factor_source(_value, _source), do: nil

  defp branch_event_feedback_weight_sources(events) when is_list(events) do
    events
    |> Enum.flat_map(&branch_event_feedback_weight_source/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp branch_event_feedback_weight_sources(_events), do: []

  defp branch_event_feedback_weight_source(%{} = event) do
    case BranchOperationalFeedback.branch_event_feedback_confidence_weight(event) do
      weight when is_number(weight) ->
        [
          event["feedback_weight_source"],
          event["feedback_sample_weight_source"],
          event["sample_weight_source"],
          event["confidence_weight_source"]
        ]
        |> Enum.map(&ValueEncoding.encode_value/1)
        |> Enum.filter(&(is_binary(&1) and &1 != ""))

      _weight ->
        []
    end
  end

  defp branch_event_feedback_weight_source(_event), do: []

  defp branch_feedback_plan_activities(candidate_plan) do
    Map.get(candidate_plan, "activities", []) ++
      Map.get(candidate_plan, "strategic_additions", [])
  end

  defp branch_feedback_activities(activities, source_candidate_activities, :downlink) do
    if Enum.any?(activities, &DownlinkActivityNormalization.downlink?/1) do
      {activities, "candidate_plan_activities"}
    else
      {source_candidate_activities, "branch_generated_source_candidates"}
    end
  end

  defp branch_feedback_activities(activities, source_candidate_activities, :observe) do
    if Enum.any?(activities, &(&1["type"] == "observe")) do
      {activities, "candidate_plan_activities"}
    else
      {source_candidate_activities, "branch_generated_source_candidates"}
    end
  end

  defp average_activity_factor(activities, type, rates, key) when is_map(rates) do
    matching = Enum.filter(activities, &(&1["type"] == type))

    if matching == [] do
      nil
    else
      matching
      |> Enum.map(fn activity ->
        feedback_factor(rates, [activity[key]])
      end)
      |> Enum.sum()
      |> Kernel./(length(matching))
    end
  end

  defp average_activity_factor(_activities, _type, _rates, _key), do: nil

  defp average_activity_optional_feedback_factor(activities, type, values, key)
       when is_map(values) do
    feedback_values =
      activities
      |> Enum.filter(&(&1["type"] == type))
      |> Enum.map(&optional_feedback_factor(values, &1[key]))
      |> Enum.reject(&is_nil/1)

    case feedback_values do
      [] -> nil
      values -> Enum.sum(values) / length(values)
    end
  end

  defp average_activity_optional_feedback_factor(_activities, _type, _values, _key), do: nil

  defp optional_feedback_factor(values, key) do
    cond do
      key not in [nil, ""] and is_number(Map.get(values, key)) -> Map.get(values, key)
      is_number(Map.get(values, "default")) -> Map.get(values, "default")
      true -> nil
    end
  end

  defp activity_feedback_text_values(activities, type, values, key) when is_map(values) do
    activities
    |> Enum.filter(&(&1["type"] == type))
    |> Enum.map(&feedback_text_value(values, &1[key]))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      values -> values
    end
  end

  defp activity_feedback_text_values(_activities, _type, _values, _key), do: nil

  defp feedback_text_value(values, key) do
    value =
      cond do
        key not in [nil, ""] -> Map.get(values, key) || Map.get(values, "default")
        true -> Map.get(values, "default")
      end

    case ValueEncoding.encode_value(value) do
      value when is_binary(value) and value != "" -> value
      _value -> nil
    end
  end

  defp average_downlink_activity_factor(activities, rates, key) when is_map(rates) do
    activities
    |> Enum.filter(&DownlinkActivityNormalization.downlink?/1)
    |> average_activity_feedback_factor(rates, key)
  end

  defp average_downlink_activity_factor(_activities, _rates, _key), do: nil

  defp average_activity_feedback_factor([], _rates, _key), do: nil

  defp average_activity_feedback_factor(activities, rates, key) do
    activities
    |> Enum.map(fn activity ->
      feedback_factor(rates, [activity[key]])
    end)
    |> Enum.sum()
    |> Kernel./(length(activities))
  end

  defp maneuver_success_factor(activities, branch, rates) when is_map(rates) do
    activity_keys =
      activities
      |> Enum.filter(&maneuver_activity?/1)
      |> Enum.map(fn activity ->
        [
          ActivityIdentity.activity_id(activity),
          activity["activity_id"],
          activity["planned_activity_id"],
          RealizedFeedbackContext.explicit_timeline_id(activity),
          activity["scenario_id"]
        ]
      end)

    event_keys =
      branch
      |> Map.get("events", [])
      |> Enum.filter(
        &(Map.get(&1, "type") in [
            "missed_maneuver",
            "delayed_maneuver",
            "maneuver_success_feedback"
          ])
      )
      |> Enum.map(fn event ->
        [event["activity_id"], event["feedback_key"], event["scenario_id"]]
      end)

    case activity_keys ++ event_keys do
      [] ->
        nil

      keys ->
        keys
        |> Enum.map(&feedback_factor(rates, &1))
        |> Enum.sum()
        |> Kernel./(length(keys))
    end
  end

  defp maneuver_success_factor(_activities, _branch, _rates), do: nil

  defp command_success_factor(activities, rates) when is_map(rates) do
    activities
    |> Enum.filter(&CommandActivityClassification.command?/1)
    |> case do
      [] ->
        nil

      command_activities ->
        command_activities
        |> Enum.map(fn activity ->
          feedback_factor(rates, [
            ActivityIdentity.activity_id(activity),
            activity["activity_id"],
            activity["planned_activity_id"],
            RealizedFeedbackContext.explicit_timeline_id(activity),
            activity["scenario_id"]
          ])
        end)
        |> Enum.sum()
        |> Kernel./(length(command_activities))
    end
  end

  defp command_success_factor(_activities, _rates), do: nil

  defp feedback_factor(rates, keys) do
    keys
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.find_value(fn key ->
      value = Map.get(rates, key)
      if is_number(value), do: value
    end)
    |> case do
      nil ->
        default = Map.get(rates, "default")
        if is_number(default), do: default, else: 1.0

      value ->
        value
    end
  end

  defp maneuver_activity?(activity), do: activity["type"] in ["maneuver", "impulsive_burn"]
end
