defmodule OrbitalDynamics.CampaignPlanner.ObjectivePressureBranchIds do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.ValueEncoding

  @families %{
    score_term: %{
      prefix: "derived_score_term_pressure_",
      base_key: "score_term_branch_base_id",
      identity_key: "score_term_branch_identity",
      event_fields: [
        "feedback_source",
        "ground_station_id",
        "target_id",
        "objective_id",
        "score_term_key",
        "source_activity_id",
        "source_activity_ids",
        "downlink_demand_source",
        "downlink_demand_sources",
        "downlink_completion_source",
        "downlink_completion_sources",
        "required_downlink_mb",
        "required_contacts",
        "required_observations",
        "starts_at_s",
        "ends_at_s",
        "trust_boundary"
      ]
    },
    objective_tradeoff: %{
      prefix: "derived_objective_tradeoff_pressure_",
      base_key: "objective_tradeoff_branch_base_id",
      identity_key: "objective_tradeoff_branch_identity",
      event_fields: [
        "feedback_source",
        "branch_id",
        "objective_id",
        "objective_type",
        "ground_station_id",
        "target_id",
        "source_activity_id",
        "source_activity_ids",
        "required_downlink_mb",
        "required_contacts",
        "required_observations",
        "starts_at_s",
        "ends_at_s",
        "trust_boundary"
      ]
    },
    objective_satisfaction: %{
      prefix: "derived_objective_satisfaction_",
      base_key: "objective_satisfaction_branch_base_id",
      identity_key: "objective_satisfaction_branch_identity",
      event_fields: [
        "feedback_source",
        "objective_id",
        "objective_type",
        "ground_station_id",
        "target_id",
        "source_activity_id",
        "source_activity_ids",
        "missed_downlink_activity_id",
        "missed_downlink_activity_ids",
        "required_downlink_mb",
        "required_contacts",
        "required_observations",
        "starts_at_s",
        "ends_at_s",
        "trust_boundary"
      ]
    },
    constraint: %{
      prefix: "derived_constraint_pressure_",
      base_key: "constraint_branch_base_id",
      identity_key: "constraint_branch_identity",
      event_fields: [
        "feedback_source",
        "constraint_id",
        "constraint_metric",
        "type",
        "spacecraft_id",
        "scenario_id",
        "resource_field",
        "activity_id",
        "source_activity_ids",
        "ground_station_id",
        "downlink_demand_sources",
        "downlink_completion_sources",
        "required_downlink_mb",
        "required_contacts",
        "starts_at_s",
        "ends_at_s",
        "trust_boundary"
      ]
    }
  }

  def disambiguate_score_term_pressure_branch_ids(branches),
    do: disambiguate(branches, Map.fetch!(@families, :score_term))

  def disambiguate_objective_tradeoff_pressure_branch_ids(branches),
    do: disambiguate(branches, Map.fetch!(@families, :objective_tradeoff))

  def disambiguate_objective_satisfaction_pressure_branch_ids(branches),
    do: disambiguate(branches, Map.fetch!(@families, :objective_satisfaction))

  def disambiguate_constraint_pressure_branch_ids(branches),
    do: disambiguate(branches, Map.fetch!(@families, :constraint))

  defp disambiguate(branches, family) do
    id_counts = Enum.frequencies_by(branches, & &1["id"])

    branches
    |> Enum.with_index(1)
    |> Enum.map(fn {branch, index} ->
      branch_id = branch["id"]

      if branch_id?(branch_id, family) and Map.get(id_counts, branch_id, 0) > 1 do
        disambiguate_branch(branch, branch_id, index, family)
      else
        branch
      end
    end)
    |> disambiguate_duplicate_suffixes(family)
  end

  defp branch_id?(id, family) when is_binary(id), do: String.starts_with?(id, family.prefix)
  defp branch_id?(_id, _family), do: false

  defp disambiguate_branch(branch, branch_id, index, family) do
    suffix =
      branch
      |> branch_identity(index, family)
      |> ValueEncoding.branch_id_fragment()

    branch
    |> Map.put("id", "#{branch_id}_#{suffix}")
    |> Map.update("metadata", %{}, fn metadata ->
      metadata
      |> Map.put(family.base_key, branch_id)
      |> Map.put(family.identity_key, suffix)
    end)
  end

  defp disambiguate_duplicate_suffixes(branches, family) do
    id_counts = Enum.frequencies_by(branches, & &1["id"])

    branches
    |> Enum.with_index(1)
    |> Enum.map(fn {branch, index} ->
      metadata = Map.get(branch, "metadata", %{})

      if Map.has_key?(metadata, family.base_key) and Map.get(id_counts, branch["id"], 0) > 1 do
        suffix = "#{metadata[family.identity_key]}_#{index}"

        branch
        |> Map.put("id", "#{metadata[family.base_key]}_#{suffix}")
        |> Map.update("metadata", %{}, &Map.put(&1, family.identity_key, suffix))
      else
        branch
      end
    end)
  end

  defp branch_identity(branch, index, family) do
    branch
    |> Map.get("events", [])
    |> List.wrap()
    |> Enum.flat_map(fn event ->
      Enum.map(family.event_fields, &event[&1])
    end)
    |> List.flatten()
    |> Enum.map(&ValueEncoding.encode_value/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> case do
      [] -> index
      identifiers -> Enum.join(identifiers, "_")
    end
  end
end
