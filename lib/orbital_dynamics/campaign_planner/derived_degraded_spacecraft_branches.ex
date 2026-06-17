defmodule OrbitalDynamics.CampaignPlanner.DerivedDegradedSpacecraftBranches do
  @moduledoc false

  def build(mission_state, callbacks) do
    branch_states = Keyword.fetch!(callbacks, :branch_states)
    incompatible_activity_types = Keyword.fetch!(callbacks, :incompatible_activity_types)
    compact_map = Keyword.fetch!(callbacks, :compact_map)

    mission_state
    |> branch_states.()
    |> Enum.map(fn state ->
      scenario_id =
        Map.get(state, "scenario_id") || Map.get(state, "spacecraft_id") || state["id"]

      %{
        "id" => "derived_degraded_#{scenario_id}",
        "label" => "Derived degraded spacecraft #{scenario_id}",
        "events" => [
          compact_map.(%{
            "type" => "degraded_spacecraft",
            "scenario_id" => scenario_id,
            "mode" => Map.get(state, "mode"),
            "incompatible_activity_types" => incompatible_activity_types.(state)
          })
        ],
        "metadata" => %{
          "derived_source" => Map.get(state, "source", "mission_state.spacecraft_states")
        }
      }
    end)
  end

  def disambiguate(branches, callbacks) do
    branch_id_fragment = Keyword.fetch!(callbacks, :branch_id_fragment)
    encode_value = Keyword.fetch!(callbacks, :encode_value)

    id_counts = Enum.frequencies_by(branches, & &1["id"])

    branches
    |> Enum.with_index(1)
    |> Enum.map(fn {branch, index} ->
      branch_id = branch["id"]

      if degraded_spacecraft_branch_id?(branch_id) and Map.get(id_counts, branch_id, 0) > 1 do
        suffix =
          branch
          |> degraded_spacecraft_branch_identity(index, encode_value)
          |> branch_id_fragment.()

        branch
        |> Map.put("id", "#{branch_id}_#{suffix}")
        |> Map.update("metadata", %{}, fn metadata ->
          metadata
          |> Map.put("degraded_spacecraft_branch_base_id", branch_id)
          |> Map.put("degraded_spacecraft_branch_identity", suffix)
        end)
      else
        branch
      end
    end)
    |> disambiguate_duplicate_degraded_spacecraft_suffixes()
  end

  defp degraded_spacecraft_branch_id?(id) when is_binary(id),
    do: String.starts_with?(id, "derived_degraded_")

  defp degraded_spacecraft_branch_id?(_id), do: false

  defp disambiguate_duplicate_degraded_spacecraft_suffixes(branches) do
    id_counts = Enum.frequencies_by(branches, & &1["id"])

    branches
    |> Enum.with_index(1)
    |> Enum.map(fn {branch, index} ->
      metadata = Map.get(branch, "metadata", %{})

      if Map.has_key?(metadata, "degraded_spacecraft_branch_base_id") and
           Map.get(id_counts, branch["id"], 0) > 1 do
        suffix = "#{metadata["degraded_spacecraft_branch_identity"]}_#{index}"

        branch
        |> Map.put("id", "#{metadata["degraded_spacecraft_branch_base_id"]}_#{suffix}")
        |> Map.update(
          "metadata",
          %{},
          &Map.put(&1, "degraded_spacecraft_branch_identity", suffix)
        )
      else
        branch
      end
    end)
  end

  defp degraded_spacecraft_branch_identity(branch, index, encode_value) do
    metadata = Map.get(branch, "metadata", %{})

    branch
    |> Map.get("events", [])
    |> List.wrap()
    |> Enum.flat_map(fn event ->
      [
        metadata["derived_source"],
        event["type"],
        event["scenario_id"],
        event["mode"],
        event["incompatible_activity_types"],
        event["trust_boundary"]
      ]
    end)
    |> List.flatten()
    |> Enum.map(fn value -> encode_value.(value) end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> case do
      [] -> index
      identifiers -> Enum.join(identifiers, "_")
    end
  end
end
