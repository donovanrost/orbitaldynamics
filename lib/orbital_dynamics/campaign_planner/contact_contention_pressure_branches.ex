defmodule OrbitalDynamics.CampaignPlanner.ContactContentionPressureBranches do
  @moduledoc false

  @contention_report_contract "contact_contention_report.v1"
  @resolution_report_contract "contact_contention_resolution_report.v1"

  alias OrbitalDynamics.CampaignPlanner.{
    ActivityTiming,
    ContactAllocationPressureBranches,
    DownlinkActivityNormalization,
    ScalarValues,
    ValueEncoding
  }

  def resolutions_from_reports(reports, callbacks \\ default_callbacks()) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

    Enum.flat_map(reports, fn {report, source_path} ->
      if report["schema_contract"] == @resolution_report_contract do
        trust_boundary =
          Map.get(report, "trust_boundary") || get_in(report, ["provenance", "trust_boundary"])

        report
        |> Map.get("recommendations", [])
        |> Enum.map(&stringify_keys.(&1))
        |> Enum.flat_map(fn recommendation ->
          recommendation
          |> Map.put("_source_report_trust_boundary", trust_boundary)
          |> resolution(source_path, callbacks)
        end)
      else
        []
      end
    end)
  end

  def conflicts_from_reports(reports, callbacks \\ default_callbacks()) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

    Enum.flat_map(reports, fn {report, source_path} ->
      if report["schema_contract"] == @contention_report_contract do
        trust_boundary =
          Map.get(report, "trust_boundary") || get_in(report, ["provenance", "trust_boundary"])

        report
        |> Map.get("conflict_groups", [])
        |> List.wrap()
        |> Enum.map(&stringify_keys.(&1))
        |> Enum.flat_map(fn group ->
          group
          |> Map.put("_source_report_trust_boundary", trust_boundary)
          |> conflict("#{source_path}.conflict_groups", callbacks)
        end)
      else
        []
      end
    end)
  end

  def resolution(recommendation, source_path, callbacks \\ default_callbacks()) do
    if recommendation_identity_correlated?(recommendation, callbacks) do
      encode_value = Keyword.fetch!(callbacks, :encode_value)

      recommendation
      |> Map.get("deferred_contact_ids", [])
      |> List.wrap()
      |> Enum.map(&encode_value.(&1))
      |> Enum.reject(&(&1 in [nil, ""]))
      |> Enum.flat_map(fn contact_id ->
        case resolution_pressure_event(recommendation, contact_id, source_path, callbacks) do
          nil ->
            []

          event ->
            branch_id_fragment = Keyword.fetch!(callbacks, :branch_id_fragment)
            compact_map = Keyword.fetch!(callbacks, :compact_map)

            [
              %{
                "id" =>
                  "derived_contact_contention_pressure_deferred_#{branch_id_fragment.(contact_id)}",
                "label" => "Derived contact contention pressure #{contact_id}",
                "events" => [event],
                "metadata" =>
                  %{
                    "derived_source" => source_path,
                    "contention_group_id" => recommendation["group_id"],
                    "selected_contact_id" => recommendation["selected_contact_id"],
                    "selection_reason" => recommendation["selection_reason"],
                    "resolution_selection_rule" => recommendation["resolution_selection_rule"],
                    "selected_priority_source" => recommendation["selected_priority_source"]
                  }
                  |> compact_map.()
              }
            ]
        end
      end)
    else
      []
    end
  end

  def conflict(group, source_path, callbacks \\ default_callbacks()) do
    group
    |> conflict_contacts(callbacks)
    |> Enum.flat_map(fn source_contact ->
      case conflict_pressure_event(group, source_contact, source_path, callbacks) do
        nil ->
          []

        event ->
          branch_id_fragment = Keyword.fetch!(callbacks, :branch_id_fragment)
          compact_map = Keyword.fetch!(callbacks, :compact_map)
          contact_id = event["contact_id"]
          group_id = event["contention_group_id"] || "conflict"

          [
            %{
              "id" =>
                "derived_contact_contention_pressure_conflict_#{branch_id_fragment.(group_id)}_#{branch_id_fragment.(contact_id)}",
              "label" => "Derived contact contention conflict #{contact_id}",
              "events" => [event],
              "metadata" =>
                %{
                  "derived_source" => source_path,
                  "contention_group_id" => group["id"],
                  "resource_scope" => group["resource_scope"],
                  "operator_action_reason" => group["operator_action_reason"]
                }
                |> compact_map.()
            }
          ]
      end
    end)
  end

  def disambiguate(branches, callbacks \\ default_callbacks()) do
    branch_id_fragment = Keyword.fetch!(callbacks, :branch_id_fragment)
    id_counts = Enum.frequencies_by(branches, & &1["id"])

    branches
    |> Enum.with_index(1)
    |> Enum.map(fn {branch, index} ->
      branch_id = branch["id"]

      if branch_id?(branch_id) and Map.get(id_counts, branch_id, 0) > 1 do
        suffix =
          branch
          |> branch_identity(index, callbacks)
          |> branch_id_fragment.()

        branch
        |> Map.put("id", "#{branch_id}_#{suffix}")
        |> Map.update("metadata", %{}, fn metadata ->
          metadata
          |> Map.put("contact_contention_branch_base_id", branch_id)
          |> Map.put("contact_contention_branch_identity", suffix)
        end)
      else
        branch
      end
    end)
    |> disambiguate_duplicate_suffixes()
  end

  defp conflict_pressure_event(group, source_contact, source_path, callbacks) do
    contact_identity = Keyword.fetch!(callbacks, :contact_identity)
    stable_id_string? = Keyword.fetch!(callbacks, :stable_id_string?)
    contact_id = contact_identity.(source_contact)

    if stable_id_string?.(contact_id) and
         deferred_downlink?(group, source_contact, callbacks) do
      compact_map = Keyword.fetch!(callbacks, :compact_map)
      activity_raw_start = Keyword.fetch!(callbacks, :activity_raw_start)
      activity_raw_end = Keyword.fetch!(callbacks, :activity_raw_end)

      %{
        "type" => "downlink_completion_gap",
        "scenario_id" =>
          source_contact["scenario_id"] || first_stable_id(group["scenario_ids"], callbacks),
        "spacecraft_id" =>
          source_contact["spacecraft_id"] || source_contact["scenario_id"] ||
            group["spacecraft_id"] || first_stable_id(group["spacecraft_ids"], callbacks),
        "ground_station_id" => ground_station_id(group, source_contact, callbacks),
        "required_contacts" => 1,
        "planned_contacts" => 0,
        "required_downlink_mb" => required_downlink_mb(source_contact, callbacks),
        "planned_downlink_mb" => 0.0,
        "starts_at_s" => activity_raw_start.(source_contact) || group["starts_at_s"],
        "ends_at_s" => activity_raw_end.(source_contact) || group["ends_at_s"],
        "contact_id" => contact_id,
        "source_activity_id" => contact_id,
        "source_activity_ids" => [contact_id],
        "source_window_id" => source_window_id(source_contact, callbacks),
        "source_window_ids" => group["source_window_ids"],
        "contention_group_id" => group["id"],
        "contention_resource_scope" => group["resource_scope"],
        "contention_contact_count" => group["contact_count"],
        "contention_contact_ids" => group["contact_ids"],
        "contention_duplicate_contact_ids" => group["duplicate_contact_ids"],
        "contention_duplicate_contact_id_count" => group["duplicate_contact_id_count"],
        "required_operator_action" => group["required_operator_action"],
        "approval_status" => group["approval_status"],
        "policy_classification" => group["policy_classification"],
        "review_status" => group["review_status"] || group["approval_status"],
        "operator_action_reason" => group["operator_action_reason"],
        "station_calendar_entry_ids" => group["station_calendar_entry_ids"],
        "station_calendar_provider_ids" => group["station_calendar_provider_ids"],
        "station_calendar_provider_entry_ids" => group["station_calendar_provider_entry_ids"],
        "station_calendar_overlap_entry_ids" => group["station_calendar_overlap_entry_ids"],
        "station_calendar_directions" => group["station_calendar_directions"],
        "station_calendar_reservation_ids" => group["station_calendar_reservation_ids"],
        "station_calendar_reserved_by" => group["station_calendar_reserved_by"],
        "station_calendar_reservation_statuses" => group["station_calendar_reservation_statuses"],
        "station_calendar_trust_boundary_statuses" =>
          group["station_calendar_trust_boundary_statuses"],
        "downlink_completion_sources" => downlink_completion_sources(source_contact, callbacks),
        "downlink_demand_sources" => downlink_demand_sources(source_contact, callbacks),
        "derivation_reasons" => conflict_pressure_reasons(group),
        "feedback_source" => source_path,
        "feedback_scope" => "contact_contention",
        "trust_boundary" => trust_boundary(group, source_contact),
        "source_contact_candidate" => source_contact
      }
      |> compact_map.()
    end
  end

  defp resolution_pressure_event(recommendation, contact_id, source_path, callbacks) do
    source_contact = source_contact(recommendation, contact_id, callbacks)
    capacity_requirement = capacity_requirement(recommendation, contact_id, callbacks)
    stable_id_string? = Keyword.fetch!(callbacks, :stable_id_string?)

    if stable_id_string?.(contact_id) and
         deferred_downlink?(recommendation, source_contact, callbacks) do
      compact_map = Keyword.fetch!(callbacks, :compact_map)
      activity_raw_start = Keyword.fetch!(callbacks, :activity_raw_start)
      activity_raw_end = Keyword.fetch!(callbacks, :activity_raw_end)

      %{
        "type" => "downlink_completion_gap",
        "scenario_id" => source_contact["scenario_id"] || recommendation["selected_scenario_id"],
        "spacecraft_id" => source_contact["spacecraft_id"] || source_contact["scenario_id"],
        "ground_station_id" => ground_station_id(recommendation, source_contact, callbacks),
        "required_contacts" => 1,
        "planned_contacts" => 0,
        "required_downlink_mb" => required_downlink_mb(source_contact, callbacks),
        "planned_downlink_mb" => 0.0,
        "starts_at_s" => activity_raw_start.(source_contact) || recommendation["starts_at_s"],
        "ends_at_s" => activity_raw_end.(source_contact) || recommendation["ends_at_s"],
        "contact_id" => contact_id,
        "source_activity_id" => contact_id,
        "source_activity_ids" => [contact_id],
        "source_window_id" => source_window_id(source_contact, callbacks),
        "contention_group_id" => recommendation["group_id"],
        "selected_contact_id" => recommendation["selected_contact_id"],
        "selected_priority" => recommendation["selected_priority"],
        "selected_priority_source" => recommendation["selected_priority_source"],
        "selection_reason" => recommendation["selection_reason"],
        "resolution_selection_rule" => recommendation["resolution_selection_rule"],
        "resolution_priority_override_count" =>
          recommendation["resolution_priority_override_count"],
        "resolution_priority_override_contact_ids" =>
          recommendation["resolution_priority_override_contact_ids"],
        "capacity_pack_group_id" => recommendation["capacity_pack_group_id"],
        "capacity_pack_status" => recommendation["capacity_pack_status"],
        "capacity_pack_capacity_fraction" => recommendation["capacity_pack_capacity_fraction"],
        "capacity_pack_used_fraction" => recommendation["capacity_pack_used_fraction"],
        "capacity_pack_unused_fraction" => recommendation["capacity_pack_unused_fraction"],
        "required_capacity_fraction" => capacity_requirement["required_capacity_fraction"],
        "required_capacity_fraction_source" =>
          capacity_requirement["required_capacity_fraction_source"],
        "capacity_pack_contact_ids_by_direction" =>
          recommendation["capacity_pack_contact_ids_by_direction"],
        "capacity_pack_selected_contact_ids_by_direction" =>
          recommendation["capacity_pack_selected_contact_ids_by_direction"],
        "capacity_pack_deferred_contact_ids_by_direction" =>
          recommendation["capacity_pack_deferred_contact_ids_by_direction"],
        "capacity_pack_required_capacity_fraction_by_direction" =>
          recommendation["capacity_pack_required_capacity_fraction_by_direction"],
        "capacity_pack_selected_required_capacity_fraction_by_direction" =>
          recommendation["capacity_pack_selected_required_capacity_fraction_by_direction"],
        "capacity_pack_deferred_required_capacity_fraction_by_direction" =>
          recommendation["capacity_pack_deferred_required_capacity_fraction_by_direction"],
        "review_status" => recommendation["review_status"],
        "approval_status" => recommendation["approval_status"],
        "policy_classification" => recommendation["policy_classification"],
        "required_operator_action" => recommendation["required_operator_action"],
        "downlink_completion_sources" => downlink_completion_sources(source_contact, callbacks),
        "downlink_demand_sources" => downlink_demand_sources(source_contact, callbacks),
        "derivation_reasons" => pressure_reasons(recommendation),
        "feedback_source" => source_path,
        "feedback_scope" => "contact_contention_resolution",
        "trust_boundary" => trust_boundary(recommendation, source_contact)
      }
      |> compact_map.()
    end
  end

  defp conflict_contacts(group, callbacks) do
    source_contacts =
      group
      |> Map.get("source_contact_candidates", [])
      |> List.wrap()
      |> Enum.filter(&is_map/1)
      |> Enum.map(&stringify_keys(&1, callbacks))

    case source_contacts do
      [] ->
        encode_value = Keyword.fetch!(callbacks, :encode_value)
        stable_id_string? = Keyword.fetch!(callbacks, :stable_id_string?)
        compact_map = Keyword.fetch!(callbacks, :compact_map)

        group
        |> Map.get("contact_ids", [])
        |> List.wrap()
        |> Enum.map(&encode_value.(&1))
        |> Enum.filter(&stable_id_string?.(&1))
        |> Enum.map(fn contact_id ->
          %{
            "id" => contact_id,
            "contact_id" => contact_id,
            "type" => group_activity_type(group),
            "direction" => group["direction"],
            "scenario_id" => first_stable_id(group["scenario_ids"], callbacks),
            "spacecraft_id" =>
              group["spacecraft_id"] || first_stable_id(group["spacecraft_ids"], callbacks),
            "ground_station_id" => group["ground_station_id"],
            "starts_at_s" => group["starts_at_s"],
            "ends_at_s" => group["ends_at_s"]
          }
          |> compact_map.()
        end)

      contacts ->
        contacts
    end
  end

  defp group_activity_type(group) do
    cond do
      group["direction"] == "downlink" -> "downlink"
      "downlink" in List.wrap(group["directions"]) -> "downlink"
      true -> "planned_contact"
    end
  end

  defp first_stable_id(values, callbacks) do
    stable_id_string? = Keyword.fetch!(callbacks, :stable_id_string?)

    values
    |> List.wrap()
    |> Enum.find(&stable_id_string?.(&1))
  end

  defp conflict_pressure_reasons(group) do
    [
      "contact_contention_conflict",
      group["operator_action_reason"],
      group["resource_scope"],
      group["approval_status"]
    ]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  defp branch_id?(id) when is_binary(id),
    do: String.starts_with?(id, "derived_contact_contention_pressure_")

  defp branch_id?(_id), do: false

  defp disambiguate_duplicate_suffixes(branches) do
    id_counts = Enum.frequencies_by(branches, & &1["id"])

    branches
    |> Enum.with_index(1)
    |> Enum.map(fn {branch, index} ->
      metadata = Map.get(branch, "metadata", %{})

      if Map.has_key?(metadata, "contact_contention_branch_base_id") and
           Map.get(id_counts, branch["id"], 0) > 1 do
        suffix = "#{metadata["contact_contention_branch_identity"]}_#{index}"

        branch
        |> Map.put("id", "#{metadata["contact_contention_branch_base_id"]}_#{suffix}")
        |> Map.update(
          "metadata",
          %{},
          &Map.put(&1, "contact_contention_branch_identity", suffix)
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
        event["feedback_source"],
        event["contention_group_id"],
        event["selected_contact_id"],
        event["source_activity_id"],
        event["source_activity_ids"],
        event["ground_station_id"],
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

  defp capacity_requirement(recommendation, contact_id, callbacks) do
    contact_identity = Keyword.fetch!(callbacks, :contact_identity)

    recommendation
    |> Map.get("capacity_requirement_rows", [])
    |> List.wrap()
    |> Enum.filter(&is_map/1)
    |> Enum.map(&stringify_keys(&1, callbacks))
    |> Enum.find(%{}, &(contact_identity.(&1) == contact_id))
  end

  defp source_contact(recommendation, contact_id, callbacks) do
    contact_identity = Keyword.fetch!(callbacks, :contact_identity)

    recommendation
    |> Map.get("source_contact_candidates", [])
    |> List.wrap()
    |> Enum.filter(&is_map/1)
    |> Enum.map(&stringify_keys(&1, callbacks))
    |> Enum.find(%{}, &(contact_identity.(&1) == contact_id))
  end

  defp recommendation_identity_correlated?(recommendation, callbacks) do
    encode_value = Keyword.fetch!(callbacks, :encode_value)
    contact_identity = Keyword.fetch!(callbacks, :contact_identity)
    stable_id_string? = Keyword.fetch!(callbacks, :stable_id_string?)

    decision_ids =
      [recommendation["selected_contact_id"] | List.wrap(recommendation["deferred_contact_ids"])]
      |> Enum.map(&encode_value.(&1))

    candidate_ids =
      recommendation
      |> Map.get("source_contact_candidates", [])
      |> List.wrap()
      |> Enum.filter(&is_map/1)
      |> Enum.map(&stringify_keys(&1, callbacks))
      |> Enum.map(&(contact_identity.(&1) |> encode_value.()))

    decision_ids != [] and Enum.all?(decision_ids, stable_id_string?) and
      length(Enum.uniq(decision_ids)) == length(decision_ids) and
      Enum.sort(decision_ids) == Enum.sort(candidate_ids)
  end

  defp deferred_downlink?(recommendation, source_contact, callbacks) do
    downlink_activity? = Keyword.fetch!(callbacks, :downlink_activity?)

    downlink_activity?.(source_contact) or recommendation["direction"] == "downlink" or
      "downlink" in List.wrap(recommendation["directions"])
  end

  defp ground_station_id(recommendation, source_contact, callbacks) do
    nested_ground_station_id = Keyword.fetch!(callbacks, :nested_ground_station_id)
    stable_id_string? = Keyword.fetch!(callbacks, :stable_id_string?)

    [
      source_contact["ground_station_id"],
      source_contact["station_id"],
      nested_ground_station_id.(source_contact),
      recommendation["ground_station_id"]
    ]
    |> Enum.find(&stable_id_string?.(&1))
  end

  defp required_downlink_mb(source_contact, callbacks) do
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)

    [
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

  defp source_window_id(source_contact, callbacks) do
    stable_id_string? = Keyword.fetch!(callbacks, :stable_id_string?)

    [
      source_contact["source_window_id"],
      get_in(source_contact, ["source_window", "id"]),
      get_in(source_contact, ["activity_context", "source_window_id"])
    ]
    |> Enum.find(&stable_id_string?.(&1))
  end

  defp downlink_demand_sources(source_contact, callbacks) do
    [
      source_contact["downlink_demand_source"],
      source_contact["downlink_demand_sources"],
      get_in(source_contact, ["throughput_model", "downlink_demand_source"]),
      get_in(source_contact, ["throughput_model", "downlink_demand_sources"]),
      get_in(source_contact, ["activity_context", "downlink_demand_source"]),
      get_in(source_contact, ["activity_context", "downlink_demand_sources"])
    ]
    |> normalize_downlink_source_list(callbacks)
    |> case do
      [] -> downlink_completion_sources(source_contact, callbacks)
      sources -> sources
    end
  end

  defp downlink_completion_sources(source_contact, callbacks) do
    [
      source_contact["downlink_completion_source"],
      source_contact["downlink_completion_sources"],
      get_in(source_contact, ["throughput_model", "downlink_completion_source"]),
      get_in(source_contact, ["throughput_model", "downlink_completion_sources"]),
      get_in(source_contact, ["activity_context", "downlink_completion_source"]),
      get_in(source_contact, ["activity_context", "downlink_completion_sources"])
    ]
    |> normalize_downlink_source_list(callbacks)
    |> case do
      [] -> nil
      sources -> sources
    end
  end

  defp normalize_downlink_source_list(values, callbacks) do
    normalize_downlink_source_list = Keyword.fetch!(callbacks, :normalize_downlink_source_list)

    normalize_downlink_source_list.(values)
  end

  defp pressure_reasons(recommendation) do
    [
      "contact_contention_deferred",
      recommendation["selection_reason"],
      recommendation["resolution_selection_rule"],
      recommendation["capacity_pack_status"]
    ]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  defp trust_boundary(recommendation, source_contact) do
    Map.get(recommendation, "trust_boundary") ||
      get_in(recommendation, ["provenance", "trust_boundary"]) ||
      Map.get(source_contact, "trust_boundary") ||
      get_in(source_contact, ["provenance", "trust_boundary"]) ||
      recommendation["_source_report_trust_boundary"]
  end

  defp stringify_keys(value, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

    stringify_keys.(value)
  end

  defp default_callbacks do
    [
      activity_raw_end: &ActivityTiming.activity_raw_end/1,
      activity_raw_start: &ActivityTiming.activity_raw_start/1,
      branch_id_fragment: &ValueEncoding.branch_id_fragment/1,
      compact_map: &ValueEncoding.compact_map/1,
      contact_identity: &ContactAllocationPressureBranches.contact_identity/1,
      downlink_activity?: &DownlinkActivityNormalization.downlink?/1,
      encode_value: &ValueEncoding.encode_value/1,
      nested_ground_station_id: &DownlinkActivityNormalization.nested_ground_station_id/1,
      normalize_downlink_source_list: &normalize_downlink_source_values/1,
      numeric_or_nil: &ScalarValues.numeric_or_nil/1,
      stable_id_string?: &ScalarValues.stable_id_string?/1,
      stringify_keys: &ValueEncoding.stringify_keys/1
    ]
  end

  defp normalize_downlink_source_values(values) do
    values
    |> List.flatten()
    |> Enum.map(&ValueEncoding.encode_value/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end
end
