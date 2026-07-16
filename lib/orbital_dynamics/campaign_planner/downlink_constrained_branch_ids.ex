defmodule OrbitalDynamics.CampaignPlanner.DownlinkConstrainedBranchIds do
  @moduledoc false

  def objective_entries(objectives) when is_list(objectives) do
    multiple_objectives? = length(objectives) > 1

    objectives
    |> branch_objectives()
    |> Enum.with_index(1)
    |> Enum.map(fn {objective, index} ->
      {objective, multiple_objectives?, index}
    end)
  end

  def branch_id(_objective, false, _index, _callbacks),
    do: "derived_downlink_constrained"

  def branch_id(%{"id" => objective_id}, true, _index, _callbacks)
      when is_binary(objective_id) and objective_id != "" do
    "derived_downlink_constrained_#{objective_id}"
  end

  def branch_id(%{} = objective, true, index, callbacks) do
    objective_ground_station_id = Keyword.fetch!(callbacks, :objective_ground_station_id)

    [
      Map.get(objective, "scenario_id"),
      objective_ground_station_id.(objective),
      index
    ]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&encode_value/1)
    |> Enum.join("_")
    |> case do
      "" -> "derived_downlink_constrained_#{index}"
      suffix -> "derived_downlink_constrained_#{suffix}"
    end
  end

  def branch_id(_objective, true, index, _callbacks),
    do: "derived_downlink_constrained_#{index}"

  def branch_label(_objective, false, _index),
    do: "Derived downlink constrained"

  def branch_label(%{"id" => objective_id}, true, _index)
      when is_binary(objective_id) and objective_id != "" do
    "Derived downlink constrained #{objective_id}"
  end

  def branch_label(_objective, true, index),
    do: "Derived downlink constrained #{index}"

  def disambiguate(branches, _callbacks) do
    id_counts = Enum.frequencies_by(branches, & &1["id"])

    branches
    |> Enum.with_index(1)
    |> Enum.map(fn {branch, index} ->
      branch_id = branch["id"]

      if Map.get(id_counts, branch_id, 0) > 1 do
        suffix =
          branch
          |> branch_identity(index)
          |> branch_id_fragment()

        branch
        |> Map.put("id", "#{branch_id}_#{suffix}")
        |> Map.update("metadata", %{}, fn metadata ->
          metadata
          |> Map.put("downlink_constrained_branch_base_id", branch_id)
          |> Map.put("downlink_constrained_branch_identity", suffix)
        end)
      else
        branch
      end
    end)
    |> disambiguate_duplicate_suffixes()
  end

  defp branch_objectives([]), do: [nil]
  defp branch_objectives(objectives), do: objectives

  defp disambiguate_duplicate_suffixes(branches) do
    id_counts = Enum.frequencies_by(branches, & &1["id"])

    branches
    |> Enum.with_index(1)
    |> Enum.map(fn {branch, index} ->
      metadata = Map.get(branch, "metadata", %{})

      if Map.has_key?(metadata, "downlink_constrained_branch_base_id") and
           Map.get(id_counts, branch["id"], 0) > 1 do
        suffix = "#{metadata["downlink_constrained_branch_identity"]}_#{index}"

        branch
        |> Map.put("id", "#{metadata["downlink_constrained_branch_base_id"]}_#{suffix}")
        |> Map.update(
          "metadata",
          %{},
          &Map.put(&1, "downlink_constrained_branch_identity", suffix)
        )
      else
        branch
      end
    end)
  end

  defp branch_identity(branch, index) do
    events =
      branch
      |> Map.get("events", [])
      |> List.wrap()

    event =
      Enum.find(events, &(&1["type"] == "downlink_completion_gap")) ||
        List.first(events) || %{}

    [
      event["ground_station_id"],
      event["scenario_id"],
      event["collection_id"],
      event["collection_ids"],
      event["product_id"],
      event["product_ids"],
      event["payload_id"],
      event["payload_ids"],
      event["instrument_id"],
      event["instrument_ids"],
      event["starts_at_s"],
      event["ends_at_s"],
      event["source_activity_id"],
      event["source_activity_ids"],
      index
    ]
    |> List.flatten()
    |> Enum.map(&encode_value/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> case do
      [] -> index
      identifiers -> Enum.join(identifiers, "_")
    end
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
    map
    |> Enum.map(fn {key, value} -> {to_string(key), encode_value(value)} end)
    |> Map.new()
  end

  defp encode_value(values) when is_list(values) do
    Enum.map(values, &encode_value/1)
  end

  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
