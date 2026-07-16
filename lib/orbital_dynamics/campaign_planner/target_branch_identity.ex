defmodule OrbitalDynamics.CampaignPlanner.TargetBranchIdentity do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.ObjectiveWindowBounds

  def branch_id("target_revisit", target_id), do: "derived_target_revisit_#{target_id}"

  def branch_id("target_observation", target_id),
    do: "derived_target_observation_#{target_id}"

  def branch_id("target_coverage", target_id), do: "derived_target_coverage_#{target_id}"

  def branch_id(_objective_type, target_id), do: "derived_urgent_target_#{target_id}"

  def branch_label("target_revisit", target_id), do: "Derived target revisit #{target_id}"

  def branch_label("target_observation", target_id),
    do: "Derived target observation #{target_id}"

  def branch_label("target_coverage", target_id), do: "Derived target coverage #{target_id}"

  def branch_label(_objective_type, target_id), do: "Derived urgent target #{target_id}"

  def disambiguate(branches) do
    id_counts = Enum.frequencies_by(branches, & &1["id"])

    branches
    |> Enum.map_reduce(%{}, fn branch, seen ->
      branch_id = branch["id"]

      if Map.get(id_counts, branch_id, 0) <= 1 do
        {delete_suffix(branch), seen}
      else
        suffix = get_in(branch, ["metadata", "target_objective_branch_suffix"]) || "duplicate"
        candidate_id = "#{branch_id}_#{suffix}"
        occurrence = Map.get(seen, candidate_id, 0) + 1
        next_seen = Map.put(seen, candidate_id, occurrence)

        disambiguated_id =
          if occurrence == 1 do
            candidate_id
          else
            "#{candidate_id}_#{occurrence}"
          end

        {
          branch
          |> Map.put("id", disambiguated_id)
          |> Map.put("label", "#{branch["label"]} #{suffix}")
          |> Map.update("metadata", %{}, fn metadata ->
            metadata
            |> Map.put("target_branch_base_id", branch_id)
            |> Map.put("target_branch_identity", suffix)
            |> Map.delete("target_objective_branch_suffix")
          end),
          next_seen
        }
      end
    end)
    |> elem(0)
  end

  def suffix(objective, target_id) do
    stable_identity =
      [
        Map.get(objective, "objective_id"),
        Map.get(objective, "id"),
        Map.get(objective, "commitment_id"),
        Map.get(objective, "coverage_objective_id"),
        Map.get(objective, "source_activity_id")
      ]
      |> Enum.find(&(&1 not in [nil, ""]))

    case stable_identity do
      value when value not in [nil, ""] ->
        branch_id_fragment(value)

      _missing ->
        [
          Map.get(objective, "scenario_id"),
          ObjectiveWindowBounds.start(objective, nil),
          ObjectiveWindowBounds.finish(objective, nil),
          target_id
        ]
        |> Enum.reject(&(&1 in [nil, ""]))
        |> Enum.map(&branch_id_fragment/1)
        |> Enum.join("_")
    end
  end

  defp delete_suffix(branch) do
    Map.update(branch, "metadata", %{}, &Map.delete(&1, "target_objective_branch_suffix"))
  end

  defp branch_id_fragment(value) do
    value
    |> encode_value()
    |> to_string()
    |> String.replace(~r/[^A-Za-z0-9._:@-]+/, "_")
    |> String.trim("_")
    |> case do
      "" -> "unnamed"
      fragment -> fragment
    end
  end

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
