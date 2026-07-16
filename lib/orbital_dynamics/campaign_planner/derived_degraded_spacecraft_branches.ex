defmodule OrbitalDynamics.CampaignPlanner.DerivedDegradedSpacecraftBranches do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    BranchOperationalFeedback,
    MissionStateResourceSources,
    OperationalFeedbackNormalization,
    RepairRealizedState,
    ScalarValues,
    ValueEncoding
  }

  def build(mission_state, callbacks \\ default_callbacks()) do
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

  def states(mission_state) do
    spacecraft_states =
      mission_state
      |> Map.get("spacecraft_states", [])
      |> Enum.map(&ValueEncoding.stringify_keys/1)
      |> Enum.map(&normalize_degraded_spacecraft_state/1)
      |> Enum.filter(fn state ->
        Map.get(state, "mode") in ["degraded", "degraded_mode", "safe"] or
          ScalarValues.truthy?(Map.get(state, "degraded")) or
          not is_nil(Map.get(state, "incompatible_activity_types"))
      end)

    degradation_states =
      mission_state
      |> Map.get("degradations", [])
      |> Enum.map(&ValueEncoding.stringify_keys/1)
      |> Enum.map(fn degradation ->
        %{
          "scenario_id" => degraded_state_identity(degradation),
          "mode" => degraded_state_mode(degradation, "degraded"),
          "incompatible_activity_types" =>
            degradation
            |> degradation_activity_types()
            |> BranchOperationalFeedback.normalize_incompatible_activity_types(),
          "source" => "mission_state.degradations"
        }
      end)

    resource_degradation_states = resource_summary_degradation_states(mission_state)

    (spacecraft_states ++ degradation_states ++ resource_degradation_states)
    |> Enum.reject(&(Map.get(&1, "scenario_id") in [nil, ""]))
  end

  def disambiguate(branches, callbacks \\ disambiguation_callbacks()) do
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

  defp normalize_degraded_spacecraft_state(state) do
    explicit =
      Map.get(state, "incompatible_activity_types") ||
        Map.get(state, "suppressed_activity_types")

    normalized =
      state
      |> OperationalFeedbackNormalization.normalize_resource_availability_aliases()
      |> OperationalFeedbackNormalization.copy_resource_availability_status_alias(
        "spacecraft_available",
        "status"
      )
      |> RepairRealizedState.spacecraft_state_booleans()
      |> normalize_degraded_spacecraft_state_identity()
      |> put_degraded_state_mode(state)

    normalized
    |> put_normalized_degraded_activity_types(
      explicit || inferred_degraded_state_activity_types(normalized)
    )
  end

  defp inferred_degraded_state_activity_types(state) do
    cond do
      Map.get(state, "spacecraft_available") == false or
          Map.get(state, "spacecraft_availability") == false ->
        ["downlink", "observe", "planned_contact"]

      Map.get(state, "payload_available") == false or Map.get(state, "antenna_available") == false ->
        []
        |> maybe_append_branch_event(Map.get(state, "payload_available") == false, "observe")
        |> maybe_append_branch_event(Map.get(state, "antenna_available") == false, "downlink")
        |> maybe_append_branch_event(
          Map.get(state, "antenna_available") == false,
          "planned_contact"
        )

      true ->
        nil
    end
  end

  defp normalize_degraded_spacecraft_state_identity(state) do
    ["scenario_id", "spacecraft_id", "id"]
    |> Enum.reduce(state, fn field, acc ->
      case ValueEncoding.encode_value(Map.get(acc, field)) do
        value when value in [nil, ""] -> acc
        value -> Map.put(acc, field, value)
      end
    end)
  end

  defp put_normalized_degraded_activity_types(state, explicit) when explicit in [nil, []],
    do: state

  defp put_normalized_degraded_activity_types(state, explicit) do
    Map.put(
      state,
      "incompatible_activity_types",
      BranchOperationalFeedback.normalize_incompatible_activity_types(explicit)
    )
  end

  defp put_degraded_state_mode(state, source_state) do
    case degraded_state_mode(source_state, Map.get(source_state, "mode")) do
      nil -> Map.delete(state, "mode")
      mode -> Map.put(state, "mode", mode)
    end
  end

  defp degraded_state_identity(state) do
    case ValueEncoding.encode_value(
           Map.get(state, "scenario_id") || Map.get(state, "spacecraft_id") ||
             Map.get(state, "id")
         ) do
      value when value in [nil, ""] -> nil
      value -> value
    end
  end

  defp degraded_state_mode(state, default) do
    case ValueEncoding.encode_value(Map.get(state, "mode", default)) do
      value when value in [nil, ""] -> default
      value -> value
    end
  end

  defp resource_summary_degradation_states(mission_state) do
    mission_state
    |> MissionStateResourceSources.summary_inputs()
    |> Enum.map(&ValueEncoding.stringify_keys/1)
    |> Enum.map(&OperationalFeedbackNormalization.normalize_resource_availability_aliases/1)
    |> Enum.map(&RepairRealizedState.spacecraft_state_booleans/1)
    |> Enum.filter(fn summary ->
      Map.get(summary, "mode") in ["degraded", "degraded_mode", "safe"] or
        ScalarValues.truthy?(Map.get(summary, "degraded")) or
        Map.get(summary, "spacecraft_available") == false or
        Map.get(summary, "spacecraft_availability") == false or
        not is_nil(Map.get(summary, "incompatible_activity_types"))
    end)
    |> Enum.map(fn summary ->
      %{
        "scenario_id" =>
          Map.get(summary, "scenario_id") || Map.get(summary, "spacecraft_id") ||
            Map.get(summary, "id"),
        "mode" => Map.get(summary, "mode", "degraded"),
        "degraded" => Map.get(summary, "degraded", true),
        "spacecraft_available" => Map.get(summary, "spacecraft_available"),
        "payload_available" => Map.get(summary, "payload_available"),
        "antenna_available" => Map.get(summary, "antenna_available"),
        "incompatible_activity_types" => degradation_incompatible_activity_types(summary),
        "source" => MissionStateResourceSources.source_path(mission_state, "degraded")
      }
    end)
  end

  defp degradation_activity_types(degradation) do
    explicit =
      Map.get(degradation, "incompatible_activity_types") ||
        Map.get(degradation, "suppressed_activity_types")

    cond do
      explicit not in [nil, []] ->
        explicit

      Map.get(degradation, "spacecraft_available") == false or
          Map.get(degradation, "spacecraft_availability") == false ->
        ["downlink", "observe", "planned_contact"]

      true ->
        ["observe"]
    end
  end

  defp degradation_incompatible_activity_types(state) do
    explicit =
      Map.get(state, "incompatible_activity_types") ||
        Map.get(state, "suppressed_activity_types")

    cond do
      explicit not in [nil, []] ->
        BranchOperationalFeedback.normalize_incompatible_activity_types(explicit)

      Map.get(state, "spacecraft_available") == false or
          Map.get(state, "spacecraft_availability") == false ->
        ["downlink", "observe", "planned_contact"]

      Map.get(state, "payload_available") == false or Map.get(state, "antenna_available") == false ->
        []
        |> maybe_append_branch_event(Map.get(state, "payload_available") == false, "observe")
        |> maybe_append_branch_event(Map.get(state, "antenna_available") == false, "downlink")
        |> maybe_append_branch_event(
          Map.get(state, "antenna_available") == false,
          "planned_contact"
        )
        |> Enum.reverse()

      true ->
        ["observe"]
    end
  end

  defp maybe_append_branch_event(events, true, event), do: [event | events]
  defp maybe_append_branch_event(events, false, _event), do: events

  defp default_callbacks do
    [
      branch_states: &__MODULE__.states/1,
      incompatible_activity_types: &degradation_incompatible_activity_types/1,
      compact_map: &ValueEncoding.compact_map/1
    ]
  end

  defp disambiguation_callbacks do
    [
      branch_id_fragment: &ValueEncoding.branch_id_fragment/1,
      encode_value: &ValueEncoding.encode_value/1
    ]
  end
end
