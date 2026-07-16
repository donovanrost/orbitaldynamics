defmodule OrbitalDynamics.CampaignPlanner.OperationalFeedbackBranches do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ActivitySuccessFeedbackEvents,
    DownlinkDemandFeedbackEvents,
    ManeuverExecutionUncertaintyFeedbackEvents,
    ObservationFeedbackEvents,
    OperationalFeedbackPlanningContext,
    OperationalFeedbackSourceMetadata,
    SpacecraftResourceFeedbackEvents,
    StationFeedbackEvents,
    TargetPriorityFeedbackEvents
  }

  def branches(
        mission_state,
        prior_plan,
        operational_feedback,
        operational_feedback_provenance,
        policy,
        callbacks \\ default_callbacks()
      ) do
    horizon_end_s = get_in(prior_plan, ["planning_horizon", "duration_s"]) || 0.0
    station_ids = planning_ground_station_ids(mission_state, prior_plan, callbacks)
    target_ids = planning_target_ids(mission_state, prior_plan, callbacks)
    target_priorities = planning_target_priorities(mission_state, prior_plan, callbacks)
    maneuver_activities = planning_maneuver_activities(prior_plan, callbacks)
    command_activities = planning_command_activities(prior_plan, callbacks)

    trust_boundary =
      operational_feedback_trust_boundary_context(operational_feedback_provenance, callbacks)

    throughput_events =
      operational_feedback
      |> Map.get("station_throughput_factor", %{})
      |> low_station_throughput_feedback_events(
        station_ids,
        policy["station_throughput_feedback_threshold"],
        horizon_end_s,
        trust_boundary,
        callbacks
      )

    contact_success_events =
      operational_feedback
      |> Map.get("contact_success_rate", %{})
      |> low_contact_success_feedback_events(
        station_ids,
        policy["contact_success_feedback_threshold"],
        horizon_end_s,
        trust_boundary,
        callbacks
      )

    observation_success_events =
      operational_feedback
      |> Map.get("observation_success_rate", %{})
      |> low_observation_success_feedback_events(
        target_ids,
        target_priorities,
        policy["observation_success_feedback_threshold"],
        horizon_end_s,
        trust_boundary,
        callbacks
      )

    observation_quality_events =
      operational_feedback
      |> Map.get("image_quality_score", %{})
      |> low_observation_quality_feedback_events(
        Map.get(operational_feedback, "image_quality_status", %{}),
        Map.get(operational_feedback, "image_quality_source", %{}),
        Map.get(operational_feedback, "cloud_cover_fraction", %{}),
        Map.get(operational_feedback, "blur_score", %{}),
        target_ids,
        target_priorities,
        policy["observation_success_feedback_threshold"],
        horizon_end_s,
        trust_boundary,
        callbacks
      )

    maneuver_success_events =
      operational_feedback
      |> Map.get("maneuver_success_rate", %{})
      |> low_maneuver_success_feedback_events(
        maneuver_activities,
        policy["maneuver_success_feedback_threshold"],
        horizon_end_s,
        trust_boundary,
        callbacks
      )

    maneuver_execution_uncertainty_events =
      operational_feedback
      |> Map.get("maneuver_execution_uncertainty", %{})
      |> maneuver_execution_uncertainty_feedback_events(
        maneuver_activities,
        policy,
        horizon_end_s,
        trust_boundary,
        callbacks
      )

    command_success_events =
      operational_feedback
      |> Map.get("command_success_rate", %{})
      |> low_command_success_feedback_events(
        command_activities,
        policy["command_success_feedback_threshold"],
        horizon_end_s,
        trust_boundary,
        callbacks
      )

    downlink_demand_events =
      operational_feedback
      |> Map.get("downlink_demand_mb", %{})
      |> downlink_demand_feedback_events(
        Map.get(operational_feedback, "downlink_demand_sources", %{}),
        station_ids,
        policy["downlink_demand_feedback_threshold_mb"],
        horizon_end_s,
        trust_boundary,
        callbacks
      )

    target_priority_events =
      operational_feedback
      |> Map.get("target_priority_overrides", %{})
      |> high_target_priority_feedback_events(
        target_ids,
        policy["target_priority_feedback_threshold"],
        horizon_end_s,
        trust_boundary,
        callbacks
      )

    resource_margin_events =
      operational_feedback
      |> Map.get("resource_margin_overrides", %{})
      |> low_resource_margin_feedback_events(policy, horizon_end_s, trust_boundary, callbacks)

    resource_availability_events =
      operational_feedback
      |> Map.get("resource_availability_overrides", %{})
      |> resource_availability_feedback_events(horizon_end_s, trust_boundary, callbacks)

    [
      branch(
        "derived_station_throughput_feedback",
        "Derived station throughput feedback",
        throughput_events,
        "operational_feedback.station_throughput_factor"
      ),
      branch(
        "derived_contact_success_feedback",
        "Derived contact success feedback",
        contact_success_events,
        "operational_feedback.contact_success_rate"
      ),
      branch(
        "derived_observation_success_feedback",
        "Derived observation success feedback",
        observation_success_events,
        "operational_feedback.observation_success_rate"
      ),
      branch(
        "derived_observation_quality_feedback",
        "Derived observation quality feedback",
        observation_quality_events,
        "operational_feedback.image_quality_score"
      ),
      branch(
        "derived_maneuver_success_feedback",
        "Derived maneuver success feedback",
        maneuver_success_events,
        "operational_feedback.maneuver_success_rate"
      ),
      branch(
        "derived_maneuver_execution_uncertainty_feedback",
        "Derived maneuver execution uncertainty feedback",
        maneuver_execution_uncertainty_events,
        "operational_feedback.maneuver_execution_uncertainty"
      ),
      branch(
        "derived_command_success_feedback",
        "Derived command success feedback",
        command_success_events,
        "operational_feedback.command_success_rate"
      ),
      branch(
        "derived_downlink_demand_feedback",
        "Derived downlink demand feedback",
        downlink_demand_events,
        "operational_feedback.downlink_demand_mb"
      ),
      branch(
        "derived_target_priority_feedback",
        "Derived target priority feedback",
        target_priority_events,
        "operational_feedback.target_priority_overrides"
      ),
      branch(
        "derived_resource_margin_feedback",
        "Derived resource margin feedback",
        resource_margin_events,
        "operational_feedback.resource_margin_overrides"
      ),
      branch(
        "derived_resource_availability_feedback",
        "Derived resource availability feedback",
        resource_availability_events,
        "operational_feedback.resource_availability_overrides"
      )
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp branch(_id, _label, [], _derived_source), do: nil

  defp branch(id, label, events, derived_source) do
    %{
      "id" => id,
      "label" => label,
      "events" => events,
      "metadata" => %{"derived_source" => derived_source}
    }
  end

  defp planning_ground_station_ids(mission_state, prior_plan, callbacks) do
    callbacks
    |> Keyword.fetch!(:planning_ground_station_ids)
    |> then(& &1.(mission_state, prior_plan))
  end

  defp planning_target_ids(mission_state, prior_plan, callbacks) do
    callbacks
    |> Keyword.fetch!(:planning_target_ids)
    |> then(& &1.(mission_state, prior_plan))
  end

  defp planning_target_priorities(mission_state, prior_plan, callbacks) do
    callbacks
    |> Keyword.fetch!(:planning_target_priorities)
    |> then(& &1.(mission_state, prior_plan))
  end

  defp planning_maneuver_activities(prior_plan, callbacks) do
    callbacks
    |> Keyword.fetch!(:planning_maneuver_activities)
    |> then(& &1.(prior_plan))
  end

  defp planning_command_activities(prior_plan, callbacks) do
    callbacks
    |> Keyword.fetch!(:planning_command_activities)
    |> then(& &1.(prior_plan))
  end

  defp operational_feedback_trust_boundary_context(provenance, callbacks) do
    callbacks
    |> Keyword.fetch!(:operational_feedback_trust_boundary_context)
    |> then(& &1.(provenance))
  end

  defp low_station_throughput_feedback_events(
         factors,
         station_ids,
         threshold,
         horizon_end_s,
         trust_boundary,
         callbacks
       ) do
    callbacks
    |> Keyword.fetch!(:low_station_throughput_feedback_events)
    |> then(& &1.(factors, station_ids, threshold, horizon_end_s, trust_boundary))
  end

  defp low_contact_success_feedback_events(
         factors,
         station_ids,
         threshold,
         horizon_end_s,
         trust_boundary,
         callbacks
       ) do
    callbacks
    |> Keyword.fetch!(:low_contact_success_feedback_events)
    |> then(& &1.(factors, station_ids, threshold, horizon_end_s, trust_boundary))
  end

  defp low_observation_success_feedback_events(
         factors,
         target_ids,
         target_priorities,
         threshold,
         horizon_end_s,
         trust_boundary,
         callbacks
       ) do
    callbacks
    |> Keyword.fetch!(:low_observation_success_feedback_events)
    |> then(
      & &1.(factors, target_ids, target_priorities, threshold, horizon_end_s, trust_boundary)
    )
  end

  defp low_observation_quality_feedback_events(
         scores,
         statuses,
         sources,
         cloud_cover_fractions,
         blur_scores,
         target_ids,
         target_priorities,
         threshold,
         horizon_end_s,
         trust_boundary,
         callbacks
       ) do
    callbacks
    |> Keyword.fetch!(:low_observation_quality_feedback_events)
    |> then(
      & &1.(
        scores,
        statuses,
        sources,
        cloud_cover_fractions,
        blur_scores,
        target_ids,
        target_priorities,
        threshold,
        horizon_end_s,
        trust_boundary
      )
    )
  end

  defp low_maneuver_success_feedback_events(
         factors,
         maneuver_activities,
         threshold,
         horizon_end_s,
         trust_boundary,
         callbacks
       ) do
    callbacks
    |> Keyword.fetch!(:low_maneuver_success_feedback_events)
    |> then(& &1.(factors, maneuver_activities, threshold, horizon_end_s, trust_boundary))
  end

  defp maneuver_execution_uncertainty_feedback_events(
         feedback,
         maneuver_activities,
         policy,
         horizon_end_s,
         trust_boundary,
         callbacks
       ) do
    callbacks
    |> Keyword.fetch!(:maneuver_execution_uncertainty_feedback_events)
    |> then(& &1.(feedback, maneuver_activities, policy, horizon_end_s, trust_boundary))
  end

  defp low_command_success_feedback_events(
         factors,
         command_activities,
         threshold,
         horizon_end_s,
         trust_boundary,
         callbacks
       ) do
    callbacks
    |> Keyword.fetch!(:low_command_success_feedback_events)
    |> then(& &1.(factors, command_activities, threshold, horizon_end_s, trust_boundary))
  end

  defp downlink_demand_feedback_events(
         demands,
         demand_sources,
         station_ids,
         threshold_mb,
         horizon_end_s,
         trust_boundary,
         callbacks
       ) do
    callbacks
    |> Keyword.fetch!(:downlink_demand_feedback_events)
    |> then(
      & &1.(demands, demand_sources, station_ids, threshold_mb, horizon_end_s, trust_boundary)
    )
  end

  defp high_target_priority_feedback_events(
         priorities,
         target_ids,
         threshold,
         horizon_end_s,
         trust_boundary,
         callbacks
       ) do
    callbacks
    |> Keyword.fetch!(:high_target_priority_feedback_events)
    |> then(& &1.(priorities, target_ids, threshold, horizon_end_s, trust_boundary))
  end

  defp low_resource_margin_feedback_events(
         overrides,
         policy,
         horizon_end_s,
         trust_boundary,
         callbacks
       ) do
    callbacks
    |> Keyword.fetch!(:low_resource_margin_feedback_events)
    |> then(& &1.(overrides, policy, horizon_end_s, trust_boundary))
  end

  defp resource_availability_feedback_events(overrides, horizon_end_s, trust_boundary, callbacks) do
    callbacks
    |> Keyword.fetch!(:resource_availability_feedback_events)
    |> then(& &1.(overrides, horizon_end_s, trust_boundary))
  end

  defp default_callbacks do
    [
      downlink_demand_feedback_events: &downlink_demand_feedback_events/6,
      high_target_priority_feedback_events: &high_target_priority_feedback_events/5,
      low_command_success_feedback_events: &low_command_success_feedback_events/5,
      low_contact_success_feedback_events: &low_contact_success_feedback_events/5,
      low_maneuver_success_feedback_events: &low_maneuver_success_feedback_events/5,
      low_observation_quality_feedback_events: &low_observation_quality_feedback_events/10,
      low_observation_success_feedback_events: &low_observation_success_feedback_events/6,
      low_resource_margin_feedback_events: &low_resource_margin_feedback_events/4,
      low_station_throughput_feedback_events: &low_station_throughput_feedback_events/5,
      maneuver_execution_uncertainty_feedback_events:
        &maneuver_execution_uncertainty_feedback_events/5,
      operational_feedback_trust_boundary_context:
        &OperationalFeedbackSourceMetadata.trust_boundary_context/1,
      planning_command_activities: &OperationalFeedbackPlanningContext.command_activities/1,
      planning_ground_station_ids: &OperationalFeedbackPlanningContext.ground_station_ids/2,
      planning_maneuver_activities: &OperationalFeedbackPlanningContext.maneuver_activities/1,
      planning_target_ids: &OperationalFeedbackPlanningContext.target_ids/2,
      planning_target_priorities: &OperationalFeedbackPlanningContext.target_priorities/2,
      resource_availability_feedback_events: &resource_availability_feedback_events/3
    ]
  end

  defp low_station_throughput_feedback_events(
         factors,
         station_ids,
         threshold,
         horizon_end_s,
         trust_boundary
       ) do
    if is_map(factors) do
      StationFeedbackEvents.station_throughput(
        factors,
        station_ids,
        threshold,
        horizon_end_s,
        trust_boundary
      )
    else
      []
    end
  end

  defp low_contact_success_feedback_events(
         factors,
         station_ids,
         threshold,
         horizon_end_s,
         trust_boundary
       ) do
    if is_map(factors) do
      StationFeedbackEvents.contact_success(
        factors,
        station_ids,
        threshold,
        horizon_end_s,
        trust_boundary
      )
    else
      []
    end
  end

  defp low_observation_success_feedback_events(
         factors,
         target_ids,
         target_priorities,
         threshold,
         horizon_end_s,
         trust_boundary
       ) do
    if is_map(factors) do
      ObservationFeedbackEvents.success(
        factors,
        target_ids,
        target_priorities,
        threshold,
        horizon_end_s,
        trust_boundary
      )
    else
      []
    end
  end

  defp low_observation_quality_feedback_events(
         scores,
         statuses,
         sources,
         cloud_cover_fractions,
         blur_scores,
         target_ids,
         target_priorities,
         threshold,
         horizon_end_s,
         trust_boundary
       ) do
    if is_map(scores) do
      ObservationFeedbackEvents.quality(
        scores,
        statuses,
        sources,
        cloud_cover_fractions,
        blur_scores,
        target_ids,
        target_priorities,
        threshold,
        horizon_end_s,
        trust_boundary
      )
    else
      []
    end
  end

  defp low_maneuver_success_feedback_events(
         factors,
         maneuver_activities,
         threshold,
         horizon_end_s,
         trust_boundary
       ) do
    if is_map(factors) do
      ActivitySuccessFeedbackEvents.maneuver(
        factors,
        maneuver_activities,
        threshold,
        horizon_end_s,
        trust_boundary
      )
    else
      []
    end
  end

  defp maneuver_execution_uncertainty_feedback_events(
         feedback,
         maneuver_activities,
         policy,
         horizon_end_s,
         trust_boundary
       ) do
    if is_map(feedback) do
      ManeuverExecutionUncertaintyFeedbackEvents.events(
        feedback,
        maneuver_activities,
        policy,
        horizon_end_s,
        trust_boundary
      )
    else
      []
    end
  end

  defp low_command_success_feedback_events(
         factors,
         command_activities,
         threshold,
         horizon_end_s,
         trust_boundary
       ) do
    if is_map(factors) do
      ActivitySuccessFeedbackEvents.command(
        factors,
        command_activities,
        threshold,
        horizon_end_s,
        trust_boundary
      )
    else
      []
    end
  end

  defp downlink_demand_feedback_events(
         demands,
         demand_sources,
         station_ids,
         threshold_mb,
         horizon_end_s,
         trust_boundary
       ) do
    if is_map(demands) do
      DownlinkDemandFeedbackEvents.events(
        demands,
        demand_sources,
        station_ids,
        threshold_mb,
        horizon_end_s,
        trust_boundary
      )
    else
      []
    end
  end

  defp high_target_priority_feedback_events(
         priorities,
         target_ids,
         threshold,
         horizon_end_s,
         trust_boundary
       ) do
    if is_map(priorities) do
      TargetPriorityFeedbackEvents.events(
        priorities,
        target_ids,
        threshold,
        horizon_end_s,
        trust_boundary
      )
    else
      []
    end
  end

  defp low_resource_margin_feedback_events(overrides, policy, horizon_end_s, trust_boundary) do
    if is_map(overrides) do
      SpacecraftResourceFeedbackEvents.margin(
        overrides,
        policy,
        horizon_end_s,
        trust_boundary
      )
    else
      []
    end
  end

  defp resource_availability_feedback_events(overrides, horizon_end_s, trust_boundary) do
    if is_map(overrides) do
      SpacecraftResourceFeedbackEvents.availability(
        overrides,
        horizon_end_s,
        trust_boundary
      )
    else
      []
    end
  end
end
