defmodule OrbitalDynamics.CampaignPlanner.TargetObjectiveBranches do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.TargetBranchIdentity
  alias OrbitalDynamics.CampaignPlanner.TargetObjectiveRealizedObservations
  alias OrbitalDynamics.CampaignPlanner.TargetObjectiveRequirements
  alias OrbitalDynamics.CampaignPlanner.TargetObjectiveSchedule
  alias OrbitalDynamics.CampaignPlanner.TargetObjectiveSelectors

  def build(mission_state, prior_plan, policy), do: build(mission_state, prior_plan, policy, [])

  def build(mission_state, prior_plan, policy, callbacks) do
    scheduled_counts = scheduled_target_counts(prior_plan, mission_state, callbacks)

    mission_state
    |> objectives(prior_plan, callbacks)
    |> Enum.map(fn objective ->
      planned_count =
        scheduled_target_count(objective, prior_plan, mission_state, scheduled_counts, callbacks)

      {objective, planned_count}
    end)
    |> Enum.filter(fn {objective, planned_count} ->
      target_id = Map.get(objective, "target_id") || Map.get(objective, "id")

      target_id not in [nil, ""] and
        TargetObjectiveRequirements.needs_branch?(objective, planned_count, policy)
    end)
    |> Enum.map(fn {objective, planned_count} ->
      branch(objective, planned_count, policy)
    end)
    |> TargetBranchIdentity.disambiguate()
  end

  defp objectives(mission_state, prior_plan, callbacks) do
    mission_state
    |> Map.get("objectives", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.reject(&TargetObjectiveSelectors.coverage_objective?/1)
    |> Enum.flat_map(&expand_target_selector_objective/1)
    |> Kernel.++(TargetObjectiveSelectors.coverage_objectives(mission_state))
    |> Kernel.++(realized_observation_revisit_objectives(mission_state, prior_plan, callbacks))
  end

  defp realized_observation_revisit_objectives(mission_state, prior_plan, []) do
    TargetObjectiveRealizedObservations.revisit_objectives(mission_state, prior_plan)
  end

  defp realized_observation_revisit_objectives(mission_state, prior_plan, callbacks) do
    TargetObjectiveRealizedObservations.revisit_objectives(
      mission_state,
      prior_plan,
      realized_observation_callbacks(callbacks)
    )
  end

  defp expand_target_selector_objective(%{"type" => type} = objective)
       when type in ["priority_commitment", "target_revisit", "target_observation"] do
    TargetObjectiveSelectors.expand(objective)
  end

  defp expand_target_selector_objective(objective), do: [objective]

  defp branch(objective, planned_count, policy) do
    target_id = Map.get(objective, "target_id") || Map.get(objective, "id")
    objective_type = objective["type"]

    event =
      objective
      |> Map.take([
        "objective_id",
        "target_id",
        "scenario_id",
        "priority",
        "latitude_deg",
        "longitude_deg",
        "minimum_elevation_deg",
        "starts_at_s",
        "ends_at_s",
        "candidate_windows",
        "spacecraft_constraints",
        "commitment_id",
        "coverage_objective_id",
        "required_count",
        "required_observations",
        "required_revisits",
        "source_activity_id",
        "source_activity_ids",
        "realized_status",
        "derivation_reason"
      ])
      |> Map.put("type", "urgent_target")
      |> Map.put("target_id", target_id)
      |> Map.put("objective_type", objective_type)
      |> Map.put("planned_observations", planned_count)
      |> TargetObjectiveRequirements.put_required_observations(objective)
      |> Map.put("allow_placeholder", policy["allow_urgent_placeholder"])

    %{
      "id" => TargetBranchIdentity.branch_id(objective_type, target_id),
      "label" => TargetBranchIdentity.branch_label(objective_type, target_id),
      "events" => [event],
      "metadata" =>
        %{
          "derived_source" => "mission_state.objectives",
          "target_objective_branch_suffix" => TargetBranchIdentity.suffix(objective, target_id)
        }
        |> compact_map()
    }
  end

  defp scheduled_target_counts(prior_plan, mission_state, _callbacks) do
    TargetObjectiveSchedule.scheduled_counts(prior_plan, mission_state)
  end

  defp scheduled_target_count(
         objective,
         prior_plan,
         mission_state,
         scheduled_counts,
         _callbacks
       ) do
    TargetObjectiveSchedule.scheduled_count(
      objective,
      prior_plan,
      mission_state,
      scheduled_counts
    )
  end

  defp realized_observation_callbacks(callbacks),
    do: Keyword.fetch!(callbacks, :target_objective_realized_observation_callbacks)

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp encode_value(%_{} = struct), do: struct |> Map.from_struct() |> encode_value()

  defp encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values) do
    if Keyword.keyword?(values) do
      Map.new(values, fn {key, value} -> {encode_value(key), encode_value(value)} end)
    else
      Enum.map(values, &encode_value/1)
    end
  end

  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
