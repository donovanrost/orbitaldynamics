defmodule OrbitalDynamics.CampaignPlanner.StationCalendarPressureBranches do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ActivityTiming,
    DownlinkActivityNormalization,
    MissionStateNormalization,
    ScalarValues,
    ValueEncoding
  }

  @unavailable_station_tokens ~w(unavailable maintenance outage offline down)

  def from_reports(reports), do: from_reports(reports, default_callbacks(), [])

  def pressure?(row), do: pressure?(row, default_callbacks())

  def pressure?(row, callbacks) when is_list(callbacks) do
    not is_nil(event(row, "station_calendar.pressure", callbacks))
  end

  def reduced_capacity_pressure?(row),
    do: reduced_capacity_pressure?(row, default_callbacks())

  def reduced_capacity_pressure?(row, callbacks) when is_list(callbacks) do
    match?(
      %{"type" => "reduced_downlink_capacity"},
      event(row, "station_calendar.pressure", callbacks)
    )
  end

  def from_reports(reports, callbacks_or_opts) do
    if callback_keywords?(callbacks_or_opts) do
      from_reports(reports, callbacks_or_opts, [])
    else
      from_reports(reports, default_callbacks(), callbacks_or_opts)
    end
  end

  def from_reports(reports, callbacks, opts) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

    Enum.flat_map(reports, fn {report, source_path} ->
      trust_boundary =
        Map.get(report, "trust_boundary") || get_in(report, ["provenance", "trust_boundary"])

      affected_contact_branches =
        report
        |> Map.get("affected_contacts", [])
        |> Enum.map(&stringify_keys.(&1))
        |> Enum.map(&Map.put_new(&1, "_source_report_trust_boundary", trust_boundary))
        |> Enum.flat_map(&branch(&1, source_path, callbacks))

      provider_contention_branches =
        report
        |> Map.get("provider_calendar_contention_groups", [])
        |> Enum.map(&stringify_keys.(&1))
        |> Enum.map(&Map.put_new(&1, "_source_report_trust_boundary", trust_boundary))
        |> Enum.flat_map(
          &provider_contention_branch(
            &1,
            provider_contention_source_path(report, source_path, opts),
            callbacks
          )
        )

      affected_contact_branches ++ provider_contention_branches
    end)
  end

  defp provider_contention_source_path(report, source_path, opts) do
    source_path_fun =
      Keyword.get(opts, :provider_contention_source_path, fn _report, path ->
        "#{path}.provider_calendar_contention_groups"
      end)

    source_path_fun.(report, source_path)
  end

  def branch(row, source_path, callbacks \\ default_callbacks()) do
    branch_id_fragment = Keyword.fetch!(callbacks, :branch_id_fragment)
    compact_map = Keyword.fetch!(callbacks, :compact_map)
    event_ground_station_id = Keyword.fetch!(callbacks, :event_ground_station_id)

    event = event(row, source_path, callbacks)
    station_id = event && event_ground_station_id.(event)

    if is_nil(event) or station_id in [nil, ""] do
      []
    else
      station_availability =
        Map.get(event, "station_availability") || Map.get(event, "availability")

      contact_id =
        Map.get(row, "contact_id") || Map.get(row, "activity_id") ||
          Map.get(row, "id") || station_id

      [
        %{
          "id" =>
            "derived_station_calendar_pressure_#{branch_id_fragment.(station_availability || event["type"])}_#{branch_id_fragment.(contact_id)}",
          "label" => "Derived station-calendar pressure #{contact_id}",
          "events" => [event],
          "metadata" =>
            %{
              "derived_source" => source_path,
              "station_calendar_entry_id" => row["station_calendar_entry_id"],
              "station_calendar_availability" => station_availability,
              "station_calendar_trust_boundary_status" =>
                row["station_calendar_trust_boundary_status"]
            }
            |> compact_map.()
        }
      ]
    end
  end

  def provider_contention_branch(group, source_path, callbacks \\ default_callbacks()) do
    branch_id_fragment = Keyword.fetch!(callbacks, :branch_id_fragment)
    compact_map = Keyword.fetch!(callbacks, :compact_map)
    event_ground_station_id = Keyword.fetch!(callbacks, :event_ground_station_id)
    events = station_calendar_provider_contention_pressure_events(group, source_path, callbacks)

    station_id =
      group["ground_station_id"] ||
        Enum.find_value(events, fn event -> event_ground_station_id.(event) end)

    if events == [] or station_id in [nil, ""] do
      []
    else
      [
        %{
          "id" =>
            "derived_station_calendar_provider_contention_#{branch_id_fragment.(group["id"] || station_id)}",
          "label" => "Derived station-calendar provider contention #{group["id"] || station_id}",
          "events" => events,
          "metadata" =>
            %{
              "derived_source" => source_path,
              "provider_calendar_contention_group_id" => group["id"],
              "provider_calendar_contention_entry_ids" => group["entry_ids"],
              "provider_calendar_contention_status" =>
                group["provider_calendar_contention_status"],
              "station_calendar_trust_boundary_statuses" => group["trust_boundary_statuses"]
            }
            |> compact_map.()
        }
      ]
    end
  end

  def event(row, source_path, callbacks \\ default_callbacks()) do
    compact_map = Keyword.fetch!(callbacks, :compact_map)
    activity_raw_start = Keyword.fetch!(callbacks, :activity_raw_start)
    activity_raw_end = Keyword.fetch!(callbacks, :activity_raw_end)
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)
    normalize_availability_token = Keyword.fetch!(callbacks, :normalize_availability_token)

    row
    |> station_calendar_pressure_event_type(callbacks)
    |> case do
      nil ->
        nil

      type ->
        row
        |> Map.take([
          "scenario_id",
          "station_calendar_entry_id",
          "station_calendar_provider_id",
          "station_calendar_provider_entry_id",
          "station_calendar_directions",
          "station_calendar_status",
          "station_calendar_overlap_count",
          "station_calendar_overlap_entry_ids",
          "station_calendar_overlap_availabilities",
          "station_calendar_entry_ambiguous",
          "station_calendar_ambiguous_entry_count",
          "station_calendar_ambiguous_entry_ids",
          "station_calendar_reservation_overlap_count",
          "station_calendar_reservation_ids",
          "station_calendar_reserved_by",
          "station_calendar_reservation_statuses",
          "station_calendar_trust_boundary_status",
          "station_contention_status",
          "station_reservation_match_status",
          "station_reservation_id",
          "station_reserved_by",
          "station_reservation_status",
          "station_reservation_expires_at_s",
          "station_reservation_expiration_status",
          "required_operator_action",
          "station_reservation_hold_summary_model",
          "station_reservation_hold_summary_source",
          "station_reservation_hold_summary_source_artifact_type",
          "station_reservation_hold_review_status",
          "station_reservation_hold_import_status",
          "station_reservation_hold_import_readiness_summary_model",
          "station_reservation_hold_import_readiness_source",
          "station_reservation_hold_import_readiness_source_artifact_type",
          "station_reservation_hold_import_readiness_status",
          "station_reservation_hold_import_classification",
          "station_reservation_hold_count",
          "station_reservation_hold_ids",
          "station_reservation_hold_ids_by_import_status",
          "station_reservation_hold_ids_by_required_import_action",
          "station_reservation_hold_ids_by_direction",
          "station_reservation_hold_ids_by_direction_and_ground_station_id",
          "station_reservation_hold_contact_ids_by_import_status",
          "station_reservation_hold_contact_ids_by_expiration_status",
          "station_reservation_hold_contact_ids_by_direction",
          "station_reservation_hold_contact_ids_by_direction_and_ground_station_id",
          "station_reservation_hold_import_status_counts",
          "station_reservation_hold_required_import_action_counts",
          "station_reservation_hold_import_execution_boundary",
          "station_reservation_hold_provider_write",
          "station_reservation_hold_cadence_write",
          "station_reservation_hold_reservation_acceptance",
          "source_station_reservation_hold_summary",
          "source_station_reservation_hold_import_readiness_summary",
          "trust_boundary",
          "source_station_reservation_review",
          "source_station_calendar_entry",
          "source_station_calendar_overlaps",
          "source_station_calendar_provider_contention",
          "provider_calendar_contention_group_id",
          "provider_calendar_contention_status",
          "provider_calendar_contention_entry_ids",
          "provider_calendar_contention_provider_ids",
          "provider_calendar_contention_provider_entry_ids",
          "provider_calendar_contention_availabilities",
          "provider_calendar_contention_directions",
          "provider_calendar_contention_reservation_ids",
          "provider_calendar_contention_reserved_by",
          "provider_calendar_contention_reservation_statuses",
          "provider_calendar_contention_trust_boundary_statuses",
          "provider_calendar_contention_overlap_pairs"
        ])
        |> Map.merge(%{
          "type" => type,
          "ground_station_id" => station_calendar_pressure_station_id(row),
          "starts_at_s" =>
            activity_raw_start.(row) ||
              numeric_or_nil.(row["overlap_starts_at_s"]) ||
              numeric_or_nil.(get_in(row, ["source_station_calendar_entry", "starts_at_s"])),
          "ends_at_s" =>
            activity_raw_end.(row) ||
              numeric_or_nil.(row["overlap_ends_at_s"]) ||
              numeric_or_nil.(get_in(row, ["source_station_calendar_entry", "ends_at_s"])),
          "capacity_fraction" => station_calendar_pressure_capacity_fraction(row, callbacks),
          "reservation_id" => row["station_reservation_id"],
          "reserved_by" => row["station_reserved_by"],
          "reservation_status" => row["station_reservation_status"],
          "station_reservation_expires_at_s" => row["station_reservation_expires_at_s"],
          "station_reservation_expiration_status" => row["station_reservation_expiration_status"],
          "required_operator_action" => row["required_operator_action"],
          "station_calendar_status" =>
            normalize_availability_token.(
              Map.get(row, "station_calendar_status") || Map.get(row, "status")
            ),
          "station_availability" => station_calendar_pressure_availability(row, callbacks),
          "feedback_source" => source_path,
          "feedback_scope" => "station_calendar",
          "derivation_reasons" => station_calendar_pressure_reasons(row, type, callbacks),
          "trust_boundary" => station_calendar_pressure_trust_boundary(row)
        })
        |> compact_map.()
    end
  end

  defp station_calendar_provider_contention_pressure_events(group, source_path, callbacks) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

    group
    |> Map.get("source_station_calendar_entries", [])
    |> Enum.map(fn entry -> stringify_keys.(entry) end)
    |> Enum.map(&station_calendar_provider_contention_pressure_row(group, &1, callbacks))
    |> Enum.map(&event(&1, source_path, callbacks))
    |> Enum.reject(&is_nil/1)
  end

  defp station_calendar_provider_contention_pressure_row(group, entry, callbacks) do
    compact_map = Keyword.fetch!(callbacks, :compact_map)
    entry_id = entry["id"] || entry["station_calendar_entry_id"]

    %{
      "ground_station_id" =>
        group["ground_station_id"] || station_calendar_pressure_station_id(entry),
      "starts_at_s" => group["starts_at_s"] || entry["starts_at_s"],
      "ends_at_s" => group["ends_at_s"] || entry["ends_at_s"],
      "station_calendar_entry_id" => entry_id,
      "station_calendar_provider_id" =>
        entry["provider_id"] || entry["station_calendar_provider_id"] ||
          first_string(group["provider_ids"]),
      "station_calendar_provider_entry_id" =>
        entry["provider_entry_id"] || entry["station_calendar_provider_entry_id"] || entry_id,
      "station_calendar_directions" => entry["directions"] || group["directions"],
      "station_calendar_status" => entry["status"] || entry["availability"],
      "station_availability" => entry["availability"] || entry["status"],
      "capacity_fraction" => entry["capacity_fraction"],
      "station_reservation_id" => entry["reservation_id"],
      "station_reserved_by" => entry["reserved_by"],
      "station_reservation_status" => entry["reservation_status"],
      "station_reservation_expiration_status" => group["station_reservation_expiration_status"],
      "required_operator_action" => group["required_operator_action"],
      "station_reservation_hold_summary_model" => group["station_reservation_hold_summary_model"],
      "station_reservation_hold_summary_source" =>
        group["station_reservation_hold_summary_source"],
      "station_reservation_hold_summary_source_artifact_type" =>
        group["station_reservation_hold_summary_source_artifact_type"],
      "station_reservation_hold_review_status" => group["station_reservation_hold_review_status"],
      "station_reservation_hold_import_status" => group["station_reservation_hold_import_status"],
      "station_reservation_hold_import_readiness_summary_model" =>
        group["station_reservation_hold_import_readiness_summary_model"],
      "station_reservation_hold_import_readiness_source" =>
        group["station_reservation_hold_import_readiness_source"],
      "station_reservation_hold_import_readiness_source_artifact_type" =>
        group["station_reservation_hold_import_readiness_source_artifact_type"],
      "station_reservation_hold_import_readiness_status" =>
        group["station_reservation_hold_import_readiness_status"],
      "station_reservation_hold_import_classification" =>
        group["station_reservation_hold_import_classification"],
      "station_reservation_hold_count" => group["station_reservation_hold_count"],
      "station_reservation_hold_ids" => group["station_reservation_hold_ids"],
      "station_reservation_hold_ids_by_import_status" =>
        group["station_reservation_hold_ids_by_import_status"],
      "station_reservation_hold_ids_by_required_import_action" =>
        group["station_reservation_hold_ids_by_required_import_action"],
      "station_reservation_hold_ids_by_direction" =>
        group["station_reservation_hold_ids_by_direction"],
      "station_reservation_hold_ids_by_direction_and_ground_station_id" =>
        group["station_reservation_hold_ids_by_direction_and_ground_station_id"],
      "station_reservation_hold_contact_ids_by_import_status" =>
        group["station_reservation_hold_contact_ids_by_import_status"],
      "station_reservation_hold_contact_ids_by_expiration_status" =>
        group["station_reservation_hold_contact_ids_by_expiration_status"],
      "station_reservation_hold_contact_ids_by_direction" =>
        group["station_reservation_hold_contact_ids_by_direction"],
      "station_reservation_hold_contact_ids_by_direction_and_ground_station_id" =>
        group["station_reservation_hold_contact_ids_by_direction_and_ground_station_id"],
      "station_reservation_hold_import_status_counts" =>
        group["station_reservation_hold_import_status_counts"],
      "station_reservation_hold_required_import_action_counts" =>
        group["station_reservation_hold_required_import_action_counts"],
      "station_reservation_hold_import_execution_boundary" =>
        group["station_reservation_hold_import_execution_boundary"],
      "station_reservation_hold_provider_write" =>
        group["station_reservation_hold_provider_write"],
      "station_reservation_hold_cadence_write" => group["station_reservation_hold_cadence_write"],
      "station_reservation_hold_reservation_acceptance" =>
        group["station_reservation_hold_reservation_acceptance"],
      "source_station_reservation_hold_summary" =>
        group["source_station_reservation_hold_summary"],
      "source_station_reservation_hold_import_readiness_summary" =>
        group["source_station_reservation_hold_import_readiness_summary"],
      "station_calendar_trust_boundary_status" =>
        station_calendar_provider_contention_trust_boundary_status(group, entry),
      "trust_boundary" =>
        station_calendar_pressure_trust_boundary(entry) || group["trust_boundary"] ||
          group["_source_report_trust_boundary"],
      "source_station_calendar_entry" => entry,
      "source_station_calendar_provider_contention" => group,
      "provider_calendar_contention_group_id" => group["id"],
      "provider_calendar_contention_status" => group["provider_calendar_contention_status"],
      "provider_calendar_contention_entry_ids" => group["entry_ids"],
      "provider_calendar_contention_provider_ids" => group["provider_ids"],
      "provider_calendar_contention_provider_entry_ids" => group["provider_entry_ids"],
      "provider_calendar_contention_availabilities" => group["availabilities"],
      "provider_calendar_contention_directions" => group["directions"],
      "provider_calendar_contention_reservation_ids" => group["reservation_ids"],
      "provider_calendar_contention_reserved_by" => group["reserved_by"],
      "provider_calendar_contention_reservation_statuses" => group["reservation_statuses"],
      "provider_calendar_contention_trust_boundary_statuses" => group["trust_boundary_statuses"],
      "provider_calendar_contention_overlap_pairs" => group["overlap_pairs"]
    }
    |> compact_map.()
  end

  defp station_calendar_provider_contention_trust_boundary_status(group, entry) do
    if station_calendar_pressure_trust_boundary(entry) in [nil, ""] do
      single_string(group["trust_boundary_statuses"])
    else
      "declared"
    end
  end

  defp station_calendar_pressure_event_type(row, callbacks) do
    normalize_availability_token = Keyword.fetch!(callbacks, :normalize_availability_token)
    unavailable_station_tokens = Keyword.fetch!(callbacks, :unavailable_station_tokens)
    availability = station_calendar_pressure_availability(row, callbacks)

    status =
      normalize_availability_token.(
        Map.get(row, "station_calendar_status") || Map.get(row, "status")
      )

    capacity_fraction = station_calendar_pressure_capacity_fraction(row, callbacks)

    cond do
      Map.get(row, "station_contention_status") == "reserved_overlap" or
          availability == "reserved" ->
        "ground_station_reserved"

      availability in unavailable_station_tokens or status in unavailable_station_tokens ->
        "ground_station_outage"

      availability == "reduced_capacity" or
          (is_number(capacity_fraction) and capacity_fraction < 1.0) ->
        "reduced_downlink_capacity"

      true ->
        nil
    end
  end

  defp station_calendar_pressure_availability(row, callbacks) do
    normalize_availability_token = Keyword.fetch!(callbacks, :normalize_availability_token)

    [
      Map.get(row, "station_availability"),
      Map.get(row, "availability"),
      get_in(row, ["source_station_calendar_entry", "availability"])
    ]
    |> Enum.map(fn value -> normalize_availability_token.(value) end)
    |> Enum.find(&(&1 not in [nil, ""]))
  end

  defp station_calendar_pressure_station_id(row) do
    Map.get(row, "ground_station_id") ||
      Map.get(row, "station_id") ||
      get_in(row, ["source_station_calendar_entry", "ground_station_id"]) ||
      get_in(row, ["source_station_calendar_entry", "station_id"])
  end

  defp station_calendar_pressure_capacity_fraction(row, callbacks) do
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)

    numeric_or_nil.(Map.get(row, "capacity_fraction")) ||
      numeric_or_nil.(Map.get(row, "station_availability")) ||
      numeric_or_nil.(Map.get(row, "availability")) ||
      numeric_or_nil.(get_in(row, ["source_station_calendar_entry", "capacity_fraction"]))
  end

  defp station_calendar_pressure_trust_boundary(row) do
    row["trust_boundary"] ||
      get_in(row, ["provenance", "trust_boundary"]) ||
      get_in(row, ["source_station_calendar_entry", "trust_boundary"]) ||
      get_in(row, ["source_station_calendar_entry", "provenance", "trust_boundary"]) ||
      row["_source_report_trust_boundary"]
  end

  defp station_calendar_pressure_reasons(row, type, callbacks) do
    encode_value = Keyword.fetch!(callbacks, :encode_value)

    [
      "station_calendar_#{station_calendar_pressure_availability(row, callbacks) || type}",
      row["station_contention_status"],
      row["provider_calendar_contention_status"],
      row["station_reservation_expiration_status"],
      row["required_operator_action"],
      if(row["station_calendar_entry_ambiguous"], do: "ambiguous_station_calendar_entry")
    ]
    |> Enum.map(fn reason -> encode_value.(reason) end)
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.uniq()
  end

  defp first_string(values) do
    values
    |> List.wrap()
    |> List.flatten()
    |> Enum.find(&(is_binary(&1) and &1 != ""))
  end

  defp single_string(values) do
    case values |> List.wrap() |> Enum.filter(&(is_binary(&1) and &1 != "")) |> Enum.uniq() do
      [value] -> value
      _values -> nil
    end
  end

  defp callback_keywords?(callbacks_or_opts) when is_list(callbacks_or_opts) do
    Keyword.has_key?(callbacks_or_opts, :stringify_keys) or
      Keyword.has_key?(callbacks_or_opts, :branch_id_fragment) or
      Keyword.has_key?(callbacks_or_opts, :event_ground_station_id)
  end

  defp callback_keywords?(_callbacks_or_opts), do: false

  defp default_callbacks do
    [
      unavailable_station_tokens: @unavailable_station_tokens,
      activity_raw_start: &ActivityTiming.activity_raw_start/1,
      activity_raw_end: &ActivityTiming.activity_raw_end/1,
      branch_id_fragment: &ValueEncoding.branch_id_fragment/1,
      compact_map: &ValueEncoding.compact_map/1,
      encode_value: &ValueEncoding.encode_value/1,
      event_ground_station_id: &event_ground_station_id/1,
      normalize_availability_token: &MissionStateNormalization.availability_token/1,
      numeric_or_nil: &ScalarValues.numeric_or_nil/1,
      stringify_keys: &ValueEncoding.stringify_keys/1
    ]
  end

  defp event_ground_station_id(event) do
    case ValueEncoding.encode_value(
           Map.get(event, "ground_station_id") || Map.get(event, "station_id") ||
             DownlinkActivityNormalization.nested_ground_station_id(event)
         ) do
      value when is_binary(value) and value != "" -> value
      _value -> nil
    end
  end
end
