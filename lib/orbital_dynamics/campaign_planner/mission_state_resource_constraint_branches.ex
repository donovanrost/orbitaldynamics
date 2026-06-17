defmodule OrbitalDynamics.CampaignPlanner.MissionStateResourceConstraintBranches do
  @moduledoc false

  def power(mission_state, policy, callbacks) do
    resource_margin_sources = Keyword.fetch!(callbacks, :resource_margin_sources)
    resource_source_path = Keyword.fetch!(callbacks, :resource_source_path)
    compact_map = Keyword.fetch!(callbacks, :compact_map)

    mission_state
    |> resource_margin_sources.("power_margin")
    |> Enum.filter(fn source ->
      is_number(source["power_margin"]) and
        source["power_margin"] <= policy["power_margin_threshold"]
    end)
    |> Enum.map(fn source ->
      spacecraft_id = source["spacecraft_id"]

      %{
        "id" => "derived_power_constrained_#{spacecraft_id}",
        "label" => "Derived power constrained #{spacecraft_id}",
        "events" => [
          %{
            "type" => "resource_margin_pressure",
            "spacecraft_id" => spacecraft_id,
            "resource_field" => "power_margin",
            "power_margin" => source["power_margin"],
            "power_margin_threshold" => policy["power_margin_threshold"],
            "derivation_reasons" => ["power_margin_low"],
            "source_quality" => source["source_quality"]
          }
          |> compact_map.()
        ],
        "metadata" => %{
          "derived_source" => resource_source_path.(mission_state, "power_margin")
        }
      }
    end)
  end

  def thermal(mission_state, %{"thermal_margin_c_threshold" => threshold}, callbacks)
      when is_number(threshold) do
    resource_metric_sources = Keyword.fetch!(callbacks, :resource_metric_sources)
    resource_source_path = Keyword.fetch!(callbacks, :resource_source_path)
    compact_map = Keyword.fetch!(callbacks, :compact_map)

    mission_state
    |> resource_metric_sources.()
    |> Enum.filter(fn source ->
      is_number(source["thermal_margin_c"]) and source["thermal_margin_c"] <= threshold and
        source["spacecraft_id"] not in [nil, ""]
    end)
    |> Enum.sort_by(& &1["spacecraft_id"])
    |> Enum.map(fn source ->
      spacecraft_id = source["spacecraft_id"]

      %{
        "id" => "derived_thermal_constrained_#{spacecraft_id}",
        "label" => "Derived thermal constrained #{spacecraft_id}",
        "events" => [
          %{
            "type" => "resource_margin_pressure",
            "spacecraft_id" => spacecraft_id,
            "resource_field" => "thermal_margin_c",
            "thermal_margin_c" => source["thermal_margin_c"],
            "thermal_margin_c_threshold" => threshold,
            "derivation_reasons" => ["thermal_margin_low"],
            "source_quality" => source["source_quality"]
          }
          |> compact_map.()
        ],
        "metadata" => %{
          "derived_source" => resource_source_path.(mission_state, "thermal_margin_c")
        }
      }
    end)
  end

  def thermal(_mission_state, _policy, _callbacks), do: []

  def payload(mission_state, callbacks) do
    availability(
      mission_state,
      "payload_available",
      "payload_unavailable",
      "derived_payload_constrained",
      "Derived payload constrained",
      callbacks
    )
  end

  def antenna(mission_state, callbacks) do
    availability(
      mission_state,
      "antenna_available",
      "antenna_unavailable",
      "derived_antenna_constrained",
      "Derived antenna constrained",
      callbacks
    )
  end

  def disambiguate(branches, callbacks) do
    branch_id_fragment = Keyword.fetch!(callbacks, :branch_id_fragment)
    encode_value = Keyword.fetch!(callbacks, :encode_value)
    id_counts = Enum.frequencies_by(branches, & &1["id"])

    branches
    |> Enum.with_index(1)
    |> Enum.map(fn {branch, index} ->
      branch_id = branch["id"]

      if resource_branch_id?(branch_id) and Map.get(id_counts, branch_id, 0) > 1 do
        suffix =
          branch
          |> resource_branch_identity(index, encode_value)
          |> branch_id_fragment.()

        branch
        |> Map.put("id", "#{branch_id}_#{suffix}")
        |> Map.update("metadata", %{}, fn metadata ->
          metadata
          |> Map.put("mission_state_resource_branch_base_id", branch_id)
          |> Map.put("mission_state_resource_branch_identity", suffix)
        end)
      else
        branch
      end
    end)
    |> disambiguate_duplicate_suffixes()
  end

  defp availability(mission_state, field, reason, id_prefix, label_prefix, callbacks) do
    resource_unavailable_sources = Keyword.fetch!(callbacks, :resource_unavailable_sources)
    resource_source_path = Keyword.fetch!(callbacks, :resource_source_path)

    mission_state
    |> resource_unavailable_sources.(field)
    |> Enum.map(fn source ->
      spacecraft_id = source["spacecraft_id"]

      %{
        "id" => "#{id_prefix}_#{spacecraft_id}",
        "label" => "#{label_prefix} #{spacecraft_id}",
        "events" => [
          resource_availability_constraint_event(spacecraft_id, field, reason, source, callbacks)
        ],
        "metadata" => %{
          "derived_source" => resource_source_path.(mission_state, field)
        }
      }
    end)
  end

  defp resource_availability_constraint_event(spacecraft_id, field, reason, source, callbacks) do
    compact_map = Keyword.fetch!(callbacks, :compact_map)

    %{
      "type" => "resource_availability_constraint",
      "spacecraft_id" => spacecraft_id,
      "resource_field" => field,
      "available" => false,
      "derivation_reasons" => [reason],
      "source_quality" => source["source_quality"]
    }
    |> compact_map.()
  end

  defp resource_branch_id?(id) when is_binary(id) do
    Enum.any?(
      [
        "derived_power_constrained_",
        "derived_thermal_constrained_",
        "derived_payload_constrained_",
        "derived_antenna_constrained_"
      ],
      &String.starts_with?(id, &1)
    )
  end

  defp resource_branch_id?(_id), do: false

  defp disambiguate_duplicate_suffixes(branches) do
    id_counts = Enum.frequencies_by(branches, & &1["id"])

    branches
    |> Enum.with_index(1)
    |> Enum.map(fn {branch, index} ->
      metadata = Map.get(branch, "metadata", %{})

      if Map.has_key?(metadata, "mission_state_resource_branch_base_id") and
           Map.get(id_counts, branch["id"], 0) > 1 do
        suffix = "#{metadata["mission_state_resource_branch_identity"]}_#{index}"

        branch
        |> Map.put("id", "#{metadata["mission_state_resource_branch_base_id"]}_#{suffix}")
        |> Map.update(
          "metadata",
          %{},
          &Map.put(&1, "mission_state_resource_branch_identity", suffix)
        )
      else
        branch
      end
    end)
  end

  defp resource_branch_identity(branch, index, encode_value) do
    metadata = Map.get(branch, "metadata", %{})

    branch
    |> Map.get("events", [])
    |> List.wrap()
    |> Enum.flat_map(fn event ->
      [
        metadata["derived_source"],
        event["type"],
        event["spacecraft_id"],
        event["resource_field"],
        event["power_margin"],
        event["power_margin_threshold"],
        event["thermal_margin_c"],
        event["thermal_margin_c_threshold"],
        event["available"],
        event["derivation_reasons"],
        event["source_quality"],
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
