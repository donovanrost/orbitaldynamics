defmodule OrbitalDynamics.CampaignPlanner.MissionStateResourceConstraintBranches do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    MissionStateResourceSources,
    OperationalFeedbackNormalization
  }

  @resource_availability_true_tokens ~w(true 1 yes y available nominal operational enabled)
  @resource_availability_false_tokens ~w(false 0 no n unavailable offline down outage maintenance disabled)

  def power(mission_state, policy) do
    mission_state
    |> mission_state_resource_margin_sources("power_margin")
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
          |> compact_map()
        ],
        "metadata" => %{
          "derived_source" => mission_state_resource_source_path(mission_state, "power_margin")
        }
      }
    end)
  end

  def thermal(mission_state, %{"thermal_margin_c_threshold" => threshold})
      when is_number(threshold) do
    mission_state
    |> mission_state_resource_metric_sources()
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
          |> compact_map()
        ],
        "metadata" => %{
          "derived_source" =>
            mission_state_resource_source_path(mission_state, "thermal_margin_c")
        }
      }
    end)
  end

  def thermal(_mission_state, _policy), do: []

  def payload(mission_state) do
    availability(
      mission_state,
      "payload_available",
      "payload_unavailable",
      "derived_payload_constrained",
      "Derived payload constrained"
    )
  end

  def antenna(mission_state) do
    availability(
      mission_state,
      "antenna_available",
      "antenna_unavailable",
      "derived_antenna_constrained",
      "Derived antenna constrained"
    )
  end

  def disambiguate(branches) do
    id_counts = Enum.frequencies_by(branches, & &1["id"])

    branches
    |> Enum.with_index(1)
    |> Enum.map(fn {branch, index} ->
      branch_id = branch["id"]

      if resource_branch_id?(branch_id) and Map.get(id_counts, branch_id, 0) > 1 do
        suffix =
          branch
          |> resource_branch_identity(index)
          |> branch_id_fragment()

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

  defp availability(mission_state, field, reason, id_prefix, label_prefix) do
    mission_state
    |> mission_state_resource_unavailable_sources(field)
    |> Enum.map(fn source ->
      spacecraft_id = source["spacecraft_id"]

      %{
        "id" => "#{id_prefix}_#{spacecraft_id}",
        "label" => "#{label_prefix} #{spacecraft_id}",
        "events" => [
          resource_availability_constraint_event(spacecraft_id, field, reason, source)
        ],
        "metadata" => %{
          "derived_source" => mission_state_resource_source_path(mission_state, field)
        }
      }
    end)
  end

  defp resource_availability_constraint_event(spacecraft_id, field, reason, source) do
    %{
      "type" => "resource_availability_constraint",
      "spacecraft_id" => spacecraft_id,
      "resource_field" => field,
      "available" => false,
      "derivation_reasons" => [reason],
      "source_quality" => source["source_quality"]
    }
    |> compact_map()
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

  defp resource_branch_identity(branch, index) do
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
    |> Enum.map(&encode_value/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> case do
      [] -> index
      identifiers -> Enum.join(identifiers, "_")
    end
  end

  defp mission_state_resource_margin_sources(mission_state, field) do
    MissionStateResourceSources.margin_sources(
      mission_state,
      field,
      mission_state_resource_source_callbacks()
    )
  end

  defp mission_state_resource_metric_sources(mission_state) do
    MissionStateResourceSources.metric_sources(
      mission_state,
      mission_state_resource_source_callbacks()
    )
  end

  defp mission_state_resource_unavailable_sources(mission_state, field) do
    MissionStateResourceSources.unavailable_sources(
      mission_state,
      field,
      mission_state_resource_source_callbacks()
    )
  end

  defp mission_state_resource_source_path(mission_state, field) do
    MissionStateResourceSources.source_path(mission_state, field)
  end

  defp mission_state_resource_source_callbacks,
    do: [
      stringify_keys: &stringify_keys/1,
      normalize_resource_margin_aliases: &normalize_resource_margin_aliases/1,
      normalize_resource_availability_aliases: &normalize_resource_availability_aliases/1,
      numeric_or_nil: &numeric_or_nil/1
    ]

  defp normalize_resource_margin_aliases(value) do
    OperationalFeedbackNormalization.normalize_resource_margin_aliases(
      value,
      resource_normalization_callbacks()
    )
  end

  defp normalize_resource_availability_aliases(value) do
    OperationalFeedbackNormalization.normalize_resource_availability_aliases(
      value,
      resource_normalization_callbacks()
    )
  end

  defp resource_normalization_callbacks,
    do: [
      stringify_keys: &stringify_keys/1,
      numeric_or_nil: &numeric_or_nil/1,
      resource_availability_boolean_value: &resource_availability_boolean_value/1,
      resource_availability_true_tokens: @resource_availability_true_tokens,
      resource_availability_false_tokens: @resource_availability_false_tokens
    ]

  defp resource_availability_boolean_value(value) do
    OperationalFeedbackNormalization.resource_availability_boolean_value(
      value,
      resource_normalization_callbacks()
    )
  end

  defp numeric_or_nil(nil), do: nil
  defp numeric_or_nil(value) when is_integer(value) or is_float(value), do: value

  defp numeric_or_nil(value) when is_binary(value) do
    case Float.parse(value) do
      {number, ""} -> number
      _error -> nil
    end
  end

  defp numeric_or_nil(_value), do: nil

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
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

  defp stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp encode_value(%_struct{} = struct), do: struct |> Map.from_struct() |> encode_value()

  defp encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values), do: Enum.map(values, &encode_value/1)
  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
