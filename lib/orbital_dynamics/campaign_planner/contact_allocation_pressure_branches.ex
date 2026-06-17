defmodule OrbitalDynamics.CampaignPlanner.ContactAllocationPressureBranches do
  @moduledoc false

  def build(row, source_path, callbacks) do
    event = pressure_event(row, source_path, callbacks)
    contact_id = Map.get(row, "contact_id")

    if is_nil(event) or contact_id in [nil, ""] do
      []
    else
      branch_id_fragment = Keyword.fetch!(callbacks, :branch_id_fragment)
      compact_map = Keyword.fetch!(callbacks, :compact_map)

      status =
        row
        |> effective_status()
        |> branch_id_fragment.()

      [
        %{
          "id" =>
            "derived_contact_allocation_pressure_#{status}_#{branch_id_fragment.(contact_id)}",
          "label" => "Derived contact allocation pressure #{contact_id}",
          "events" => [event],
          "metadata" =>
            %{
              "derived_source" => source_path,
              "contact_allocation_status" => row["allocation_status"],
              "contact_effective_allocation_status" => row["effective_allocation_status"],
              "contact_allocation_reason" => row["allocation_reason"],
              "contact_review_status" => row["review_status"],
              "contact_approval_status" => row["approval_status"],
              "capacity_pack_group_id" => row["capacity_pack_group_id"],
              "capacity_pack_status" => row["capacity_pack_status"],
              "capacity_pack_capacity_fraction" => row["capacity_pack_capacity_fraction"],
              "capacity_pack_used_fraction" => row["capacity_pack_used_fraction"],
              "contact_policy_classification" =>
                get_in(row, ["policy_decision", "classification"])
            }
            |> compact_map.()
        }
      ]
    end
  end

  def disambiguate(branches, callbacks) do
    id_counts = Enum.frequencies_by(branches, & &1["id"])

    branches
    |> Enum.with_index(1)
    |> Enum.map(fn {branch, index} ->
      branch_id = branch["id"]

      if pressure_branch_id?(branch_id) and Map.get(id_counts, branch_id, 0) > 1 do
        branch_id_fragment = Keyword.fetch!(callbacks, :branch_id_fragment)

        suffix =
          branch
          |> branch_identity(index, callbacks)
          |> branch_id_fragment.()

        branch
        |> Map.put("id", "#{branch_id}_#{suffix}")
        |> Map.update("metadata", %{}, fn metadata ->
          metadata
          |> Map.put("contact_allocation_branch_base_id", branch_id)
          |> Map.put("contact_allocation_branch_identity", suffix)
        end)
      else
        branch
      end
    end)
    |> disambiguate_duplicate_suffixes()
  end

  def contact_identity(contact) do
    Map.get(contact, "id") || Map.get(contact, "contact_id") ||
      Map.get(contact, "activity_id") || Map.get(contact, "source_activity_id") ||
      Map.get(contact, "downlink_activity_id")
  end

  defp pressure_branch_id?(id) when is_binary(id),
    do: String.starts_with?(id, "derived_contact_allocation_pressure_")

  defp pressure_branch_id?(_id), do: false

  defp disambiguate_duplicate_suffixes(branches) do
    id_counts = Enum.frequencies_by(branches, & &1["id"])

    branches
    |> Enum.with_index(1)
    |> Enum.map(fn {branch, index} ->
      metadata = Map.get(branch, "metadata", %{})

      if Map.has_key?(metadata, "contact_allocation_branch_base_id") and
           Map.get(id_counts, branch["id"], 0) > 1 do
        suffix = "#{metadata["contact_allocation_branch_identity"]}_#{index}"

        branch
        |> Map.put("id", "#{metadata["contact_allocation_branch_base_id"]}_#{suffix}")
        |> Map.update(
          "metadata",
          %{},
          &Map.put(&1, "contact_allocation_branch_identity", suffix)
        )
      else
        branch
      end
    end)
  end

  defp branch_identity(branch, index, callbacks) do
    encode_value = Keyword.fetch!(callbacks, :encode_value)

    branch
    |> Map.get("events", [])
    |> List.wrap()
    |> Enum.flat_map(fn event ->
      [
        event["source_window_id"],
        event["source_window_ids"],
        event["source_activity_id"],
        event["source_activity_ids"],
        event["downlink_completion_source"],
        event["downlink_completion_sources"],
        event["downlink_demand_source"],
        event["downlink_demand_sources"],
        event["ground_station_id"],
        event["station_reservation_id"],
        event["station_reserved_by"],
        event["station_reservation_status"],
        event["station_reservation_match_status"],
        event["station_calendar_entry_id"],
        event["station_calendar_entry_status"],
        event["feedback_source"],
        event["required_downlink_mb"],
        event["starts_at_s"],
        event["ends_at_s"]
      ]
    end)
    |> List.flatten()
    |> Enum.map(&encode_value.(&1))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> case do
      [] -> index
      identifiers -> Enum.join(identifiers, "_")
    end
  end

  defp pressure_event(row, source_path, callbacks) do
    status = effective_status(row)

    cond do
      status not in ["deferred", "blocked", "policy_blocked"] ->
        nil

      not downlink_allocation_row?(row, callbacks) ->
        nil

      true ->
        compact_map = Keyword.fetch!(callbacks, :compact_map)
        trust_boundary = Keyword.fetch!(callbacks, :trust_boundary)
        source_contact = source_contact(row, callbacks)
        required_downlink_mb = required_downlink_mb(row, source_contact, callbacks)
        contact_id = row["contact_id"]
        ground_station_id = ground_station_id(row, source_contact, callbacks)

        %{
          "type" => "downlink_completion_gap",
          "scenario_id" => row["scenario_id"] || row["spacecraft_id"],
          "spacecraft_id" => row["spacecraft_id"] || row["scenario_id"],
          "ground_station_id" => ground_station_id,
          "required_contacts" => 1,
          "planned_contacts" => 0,
          "required_downlink_mb" => required_downlink_mb,
          "planned_downlink_mb" => 0.0,
          "starts_at_s" => start_s(row, source_contact, callbacks),
          "ends_at_s" => end_s(row, source_contact, callbacks),
          "contact_id" => contact_id,
          "source_activity_id" => contact_id,
          "source_activity_ids" => List.wrap(contact_id),
          "source_window_id" => source_window_id(row, source_contact, callbacks),
          "realized_status" => status,
          "contact_result" => row["allocation_reason"],
          "allocation_status" => row["allocation_status"],
          "effective_allocation_status" => row["effective_allocation_status"],
          "allocation_reason" => row["allocation_reason"],
          "capacity_pack_group_id" => row["capacity_pack_group_id"],
          "capacity_pack_status" => row["capacity_pack_status"],
          "capacity_pack_capacity_fraction" => row["capacity_pack_capacity_fraction"],
          "capacity_pack_used_fraction" => row["capacity_pack_used_fraction"],
          "capacity_pack_unused_fraction" => row["capacity_pack_unused_fraction"],
          "required_capacity_fraction" => row["required_capacity_fraction"],
          "required_capacity_fraction_source" => row["required_capacity_fraction_source"],
          "capacity_pack_contact_ids_by_direction" => row["contact_ids_by_direction"],
          "capacity_pack_selected_contact_ids_by_direction" =>
            row["selected_contact_ids_by_direction"],
          "capacity_pack_deferred_contact_ids_by_direction" =>
            row["deferred_contact_ids_by_direction"],
          "capacity_pack_required_capacity_fraction_by_direction" =>
            row["required_capacity_fraction_by_direction"],
          "capacity_pack_selected_required_capacity_fraction_by_direction" =>
            row["selected_required_capacity_fraction_by_direction"],
          "capacity_pack_deferred_required_capacity_fraction_by_direction" =>
            row["deferred_required_capacity_fraction_by_direction"],
          "station_reservation_id" =>
            row["station_reservation_id"] || source_contact["station_reservation_id"],
          "station_reserved_by" =>
            row["station_reserved_by"] || source_contact["station_reserved_by"],
          "station_reservation_status" =>
            row["station_reservation_status"] || source_contact["station_reservation_status"],
          "station_reservation_match_status" =>
            row["station_reservation_match_status"] ||
              source_contact["station_reservation_match_status"],
          "station_calendar_entry_id" =>
            row["station_calendar_entry_id"] || source_contact["station_calendar_entry_id"],
          "station_calendar_entry_status" =>
            row["station_calendar_entry_status"] ||
              source_contact["station_calendar_entry_status"],
          "station_calendar_directions" =>
            row["station_calendar_directions"] || source_contact["station_calendar_directions"],
          "review_status" => row["review_status"],
          "approval_status" => row["approval_status"],
          "policy_decision" => row["policy_decision"],
          "policy_classification" => get_in(row, ["policy_decision", "classification"]),
          "policy_bundle_id" => get_in(row, ["policy_decision", "policy_bundle_id"]),
          "downlink_completion_source" =>
            row["downlink_completion_source"] ||
              source_contact["downlink_completion_source"] ||
              get_in(source_contact, ["throughput_model", "downlink_completion_source"]) ||
              get_in(source_contact, ["activity_context", "downlink_completion_source"]),
          "downlink_demand_sources" => downlink_demand_sources(row, source_contact, callbacks),
          "downlink_completion_sources" =>
            downlink_completion_sources(row, source_contact, callbacks),
          "derivation_reasons" => pressure_reasons(row, status),
          "feedback_source" => source_path,
          "feedback_scope" => "contact_allocation",
          "trust_boundary" => trust_boundary.(row)
        }
        |> compact_map.()
    end
  end

  defp ground_station_id(row, source_contact, callbacks) do
    nested_ground_station_id = Keyword.fetch!(callbacks, :nested_ground_station_id)
    stable_id_string? = Keyword.fetch!(callbacks, :stable_id_string?)

    [
      row["ground_station_id"],
      row["station_id"],
      nested_ground_station_id.(row),
      source_contact["ground_station_id"],
      source_contact["station_id"],
      nested_ground_station_id.(source_contact)
    ]
    |> Enum.find(&stable_id_string?.(&1))
  end

  defp start_s(row, source_contact, callbacks) do
    activity_raw_start = Keyword.fetch!(callbacks, :activity_raw_start)
    activity_raw_start.(row) || activity_raw_start.(source_contact)
  end

  defp end_s(row, source_contact, callbacks) do
    activity_raw_end = Keyword.fetch!(callbacks, :activity_raw_end)
    activity_raw_end.(row) || activity_raw_end.(source_contact)
  end

  defp source_window_id(row, source_contact, callbacks) do
    stable_id_string? = Keyword.fetch!(callbacks, :stable_id_string?)

    [
      row["source_window_id"],
      get_in(row, ["source_window", "id"]),
      get_in(row, ["activity_context", "source_window_id"]),
      source_contact["source_window_id"],
      get_in(source_contact, ["source_window", "id"]),
      get_in(source_contact, ["activity_context", "source_window_id"])
    ]
    |> Enum.find(&stable_id_string?.(&1))
  end

  defp effective_status(row) do
    Map.get(row, "effective_allocation_status") || Map.get(row, "allocation_status")
  end

  defp downlink_allocation_row?(row, callbacks) do
    downlink_activity? = Keyword.fetch!(callbacks, :downlink_activity?)
    downlink_activity?.(row) or downlink_activity?.(source_contact(row, callbacks))
  end

  defp source_contact(row, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    contact_id = row["contact_id"]

    cond do
      is_map(row["source_contact_candidate"]) ->
        stringify_keys.(row["source_contact_candidate"])

      source_contact = direct_source_contact(row, contact_id, callbacks) ->
        source_contact

      is_list(get_in(row, ["source_contention_recommendation", "source_contact_candidates"])) ->
        row
        |> get_in(["source_contention_recommendation", "source_contact_candidates"])
        |> Enum.map(&stringify_keys.(&1))
        |> Enum.find(%{}, &contact_match?(&1, contact_id))

      true ->
        %{}
    end
  end

  defp direct_source_contact(row, contact_id, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

    [
      row["source_contact"],
      row["contact_candidate"],
      row["contact"],
      row["source_contacts"],
      row["contact_candidates"],
      row["contacts"]
    ]
    |> List.flatten()
    |> Enum.filter(&is_map/1)
    |> Enum.map(&stringify_keys.(&1))
    |> Enum.find(&contact_match?(&1, contact_id))
  end

  defp contact_match?(contact, contact_id) do
    contact_id in [nil, ""] or contact_identity(contact) == contact_id
  end

  defp required_downlink_mb(row, source_contact, callbacks) do
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)

    [
      row["required_downlink_mb"],
      row["estimated_throughput_mb"],
      row["planned_throughput_mb"],
      get_in(row, ["throughput_model", "required_downlink_mb"]),
      get_in(row, ["throughput_model", "estimated_throughput_mb"]),
      get_in(row, ["throughput_model", "planned_throughput_mb"]),
      source_contact["required_downlink_mb"],
      source_contact["estimated_throughput_mb"],
      source_contact["planned_throughput_mb"],
      get_in(source_contact, ["throughput_model", "required_downlink_mb"]),
      get_in(source_contact, ["throughput_model", "estimated_throughput_mb"]),
      get_in(source_contact, ["throughput_model", "planned_throughput_mb"])
    ]
    |> Enum.map(&numeric_or_nil.(&1))
    |> Enum.find(fn value -> is_number(value) and value > 0.0 end)
  end

  defp downlink_demand_sources(row, source_contact, callbacks) do
    normalize_downlink_source_list = Keyword.fetch!(callbacks, :normalize_downlink_source_list)

    [
      row["downlink_demand_source"],
      row["downlink_demand_sources"],
      get_in(row, ["throughput_model", "downlink_demand_source"]),
      get_in(row, ["throughput_model", "downlink_demand_sources"]),
      get_in(row, ["activity_context", "downlink_demand_source"]),
      get_in(row, ["activity_context", "downlink_demand_sources"]),
      source_contact["downlink_demand_source"],
      source_contact["downlink_demand_sources"],
      get_in(source_contact, ["throughput_model", "downlink_demand_source"]),
      get_in(source_contact, ["throughput_model", "downlink_demand_sources"]),
      get_in(source_contact, ["activity_context", "downlink_demand_source"]),
      get_in(source_contact, ["activity_context", "downlink_demand_sources"])
    ]
    |> normalize_downlink_source_list.()
    |> case do
      [] -> downlink_completion_sources(row, source_contact, callbacks)
      sources -> sources
    end
  end

  defp downlink_completion_sources(row, source_contact, callbacks) do
    normalize_downlink_source_list = Keyword.fetch!(callbacks, :normalize_downlink_source_list)

    [
      row["downlink_completion_source"],
      row["downlink_completion_sources"],
      get_in(row, ["throughput_model", "downlink_completion_source"]),
      get_in(row, ["throughput_model", "downlink_completion_sources"]),
      get_in(row, ["activity_context", "downlink_completion_source"]),
      get_in(row, ["activity_context", "downlink_completion_sources"]),
      source_contact["downlink_completion_source"],
      source_contact["downlink_completion_sources"],
      get_in(source_contact, ["throughput_model", "downlink_completion_source"]),
      get_in(source_contact, ["throughput_model", "downlink_completion_sources"]),
      get_in(source_contact, ["activity_context", "downlink_completion_source"]),
      get_in(source_contact, ["activity_context", "downlink_completion_sources"])
    ]
    |> normalize_downlink_source_list.()
    |> case do
      [] -> nil
      sources -> sources
    end
  end

  defp pressure_reasons(row, status) do
    [
      "contact_allocation_#{status}",
      row["allocation_reason"],
      row["capacity_pack_status"],
      row["suppressed_reason"],
      row["station_reservation_match_status"],
      row["station_calendar_entry_status"]
    ]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end
end
