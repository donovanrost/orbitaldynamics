defmodule OrbitalDynamics.CampaignPlanner.ContactIntentPressureBranches do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ActivityTiming,
    DownlinkActivityNormalization,
    RealizedFeedbackContext,
    ReviewRowSources,
    ScalarValues,
    ValueEncoding
  }

  def from_rows_with_source(rows_with_source, callbacks \\ default_callbacks()) do
    normalize_pressure_row = Keyword.fetch!(callbacks, :normalize_pressure_row)

    Enum.flat_map(rows_with_source, fn {row, source_path} ->
      row
      |> normalize_pressure_row.()
      |> build(source_path, callbacks)
    end)
  end

  def identity_set(rows_with_source, callbacks \\ default_callbacks()) do
    normalize_pressure_row = Keyword.fetch!(callbacks, :normalize_pressure_row)

    rows_with_source
    |> Enum.map(fn {row, _source_path} ->
      row
      |> normalize_pressure_row.()
      |> identity(callbacks)
    end)
    |> Enum.reject(&is_nil/1)
    |> MapSet.new()
  end

  def pressure_statuses_by_contact_id(rows_with_source, callbacks \\ default_callbacks()) do
    rows_with_source
    |> identity_set(callbacks)
    |> Enum.group_by(&elem(&1, 1), &elem(&1, 0))
    |> Map.new(fn {contact_id, statuses} ->
      {contact_id, statuses |> Enum.uniq() |> Enum.sort()}
    end)
  end

  def summaries_from_sources(
        summaries_with_source,
        excluded_identities,
        callbacks \\ default_callbacks()
      ) do
    summaries_with_source
    |> Enum.reduce({excluded_identities, []}, fn summary_with_source, {seen, branches} ->
      {seen, summary_branches} =
        summary_with_source
        |> summary_pressure_rows(callbacks)
        |> Enum.reduce({seen, []}, fn {row, source_path}, {seen, kept} ->
          row_identity = identity(row, callbacks)

          cond do
            is_nil(row_identity) ->
              {seen, kept}

            MapSet.member?(seen, row_identity) ->
              {seen, kept}

            true ->
              {MapSet.put(seen, row_identity), kept ++ build(row, source_path, callbacks)}
          end
        end)

      {seen, branches ++ summary_branches}
    end)
    |> elem(1)
  end

  defp summary_pressure_rows({summary, source_path}, callbacks) do
    normalize_pressure_row = Keyword.fetch!(callbacks, :normalize_pressure_row)
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

    summary = stringify_keys.(summary)

    trust_boundary =
      Map.get(summary, "trust_boundary") || get_in(summary, ["provenance", "trust_boundary"])

    summary
    |> Map.get("rows", [])
    |> List.wrap()
    |> Enum.filter(&is_map/1)
    |> Enum.map(fn row ->
      row
      |> stringify_keys.()
      |> put_default_if_present("_source_report_trust_boundary", trust_boundary)
    end)
    |> Enum.map(fn row ->
      row
      |> normalize_pressure_row.()
      |> then(&{&1, source_path})
    end)
  end

  def build(row, source_path, callbacks \\ default_callbacks()) do
    branch_id_fragment = Keyword.fetch!(callbacks, :branch_id_fragment)
    compact_map = Keyword.fetch!(callbacks, :compact_map)

    event = event(row, source_path, callbacks)
    contact_id = contact_id(row)

    if is_nil(event) or contact_id in [nil, ""] do
      []
    else
      [
        %{
          "id" =>
            "derived_contact_intent_pressure_#{branch_id_fragment.(status(row, callbacks))}_#{branch_id_fragment.(contact_id)}",
          "label" => "Derived contact-intent pressure #{contact_id}",
          "events" => [event],
          "metadata" =>
            %{
              "derived_source" => source_path,
              "contact_intent_gate_status" => status(row, callbacks),
              "cadence_import_status" => row["cadence_import_status"],
              "contact_approval_status" => row["approval_status"]
            }
            |> compact_map.()
        }
      ]
    end
  end

  def status(row, callbacks \\ default_callbacks()) do
    normalized_optional_status = Keyword.fetch!(callbacks, :normalized_optional_status)

    approval_status = normalized_optional_status.(row["approval_status"])
    cadence_import_status = normalized_optional_status.(row["cadence_import_status"])

    cond do
      approval_status == "blocked_by_policy" ->
        "blocked_by_policy"

      cadence_import_status in ["missing", "invalid"] ->
        "cadence_import_#{cadence_import_status}"

      row["invalid_activity_input"] == true ->
        "invalid_activity_input"

      true ->
        nil
    end
  end

  def event(row, source_path, callbacks \\ default_callbacks()) do
    pressure_event(row, source_path, callbacks)
  end

  def identity(row, callbacks \\ default_callbacks()) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)
    downlink_activity? = Keyword.fetch!(callbacks, :downlink_activity?)

    row = stringify_keys.(row)
    contact_id = contact_id(row)
    pressure_status = status(row, callbacks)

    cond do
      contact_id in [nil, ""] -> nil
      pressure_status in [nil, ""] -> nil
      not downlink_activity?.(row) -> nil
      true -> {pressure_status, contact_id}
    end
  end

  defp pressure_event(row, source_path, callbacks) do
    downlink_activity? = Keyword.fetch!(callbacks, :downlink_activity?)

    pressure_status = status(row, callbacks)

    cond do
      is_nil(pressure_status) ->
        nil

      not downlink_activity?.(row) ->
        nil

      true ->
        contact_id = contact_id(row)
        compact_map = Keyword.fetch!(callbacks, :compact_map)
        activity_raw_start = Keyword.fetch!(callbacks, :activity_raw_start)
        activity_raw_end = Keyword.fetch!(callbacks, :activity_raw_end)
        explicit_timeline_id = Keyword.fetch!(callbacks, :explicit_timeline_id)
        normalized_optional_status = Keyword.fetch!(callbacks, :normalized_optional_status)

        %{
          "type" => "downlink_completion_gap",
          "scenario_id" => row["scenario_id"] || row["spacecraft_id"],
          "spacecraft_id" => row["spacecraft_id"] || row["scenario_id"],
          "ground_station_id" => ground_station_id(row, callbacks),
          "required_contacts" => 1,
          "planned_contacts" => 0,
          "required_downlink_mb" => required_downlink_mb(row, callbacks),
          "planned_downlink_mb" => 0.0,
          "starts_at_s" => activity_raw_start.(row),
          "ends_at_s" => activity_raw_end.(row),
          "contact_id" => contact_id,
          "source_activity_id" => contact_id,
          "source_activity_ids" => List.wrap(contact_id),
          "source_window_id" => row["source_window_id"] || get_in(row, ["source_window", "id"]),
          "timeline_id" => explicit_timeline_id.(row),
          "approval_status" => normalized_optional_status.(row["approval_status"]),
          "required_operator_action" => row["required_operator_action"],
          "cadence_import_status" => normalized_optional_status.(row["cadence_import_status"]),
          "invalid_cadence_import" => row["invalid_cadence_import"],
          "invalid_cadence_import_reason" => row["invalid_cadence_import_reason"],
          "invalid_activity_input" => row["invalid_activity_input"],
          "invalid_activity_input_reason" => row["invalid_activity_input_reason"],
          "contact_intent_gate_status" => pressure_status,
          "policy_classification" => get_in(row, ["source_policy_decision", "classification"]),
          "policy_bundle_id" => get_in(row, ["source_policy_decision", "policy_bundle_id"]),
          "station_availability" => row["station_availability"],
          "station_contention_status" => row["station_contention_status"],
          "station_calendar_entry_id" => row["station_calendar_entry_id"],
          "station_calendar_provider_id" => row["station_calendar_provider_id"],
          "station_calendar_provider_entry_id" => row["station_calendar_provider_entry_id"],
          "station_calendar_directions" => row["station_calendar_directions"],
          "station_calendar_status" => row["station_calendar_status"],
          "station_calendar_trust_boundary_status" =>
            row["station_calendar_trust_boundary_status"],
          "station_reservation_id" => row["station_reservation_id"],
          "station_reserved_by" => row["station_reserved_by"],
          "station_reservation_status" => row["station_reservation_status"],
          "station_reservation_match_status" => row["station_reservation_match_status"],
          "derivation_reasons" => pressure_reasons(row, pressure_status),
          "feedback_source" => source_path,
          "feedback_scope" => "contact_intent",
          "trust_boundary" => trust_boundary(row)
        }
        |> compact_map.()
    end
  end

  defp contact_id(row) do
    row["contact_id"] || row["activity_id"] || row["id"]
  end

  defp ground_station_id(row, callbacks) do
    nested_ground_station_id = Keyword.fetch!(callbacks, :nested_ground_station_id)
    stable_id_string? = Keyword.fetch!(callbacks, :stable_id_string?)

    [
      row["ground_station_id"],
      row["station_id"],
      nested_ground_station_id.(row)
    ]
    |> Enum.find(&stable_id_string?.(&1))
  end

  defp required_downlink_mb(row, callbacks) do
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)

    [
      row["required_downlink_mb"],
      row["estimated_throughput_mb"],
      row["planned_throughput_mb"],
      get_in(row, ["activity_context", "required_downlink_mb"]),
      get_in(row, ["activity_context", "estimated_throughput_mb"]),
      get_in(row, ["activity_context", "planned_throughput_mb"]),
      get_in(row, ["throughput_model", "required_downlink_mb"]),
      get_in(row, ["throughput_model", "estimated_throughput_mb"])
    ]
    |> Enum.map(fn value -> numeric_or_nil.(value) end)
    |> Enum.find(fn value -> is_number(value) and value > 0.0 end)
  end

  defp pressure_reasons(row, pressure_status) do
    [
      "contact_intent_#{pressure_status}",
      row["required_operator_action"],
      row["invalid_cadence_import_reason"],
      row["invalid_activity_input_reason"],
      row["station_availability"],
      row["station_calendar_status"],
      row["station_reservation_match_status"],
      get_in(row, ["source_policy_decision", "classification"])
    ]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  defp trust_boundary(row) do
    Map.get(row, "trust_boundary") ||
      get_in(row, ["provenance", "trust_boundary"]) ||
      get_in(row, ["source_contact_intent", "trust_boundary"]) ||
      get_in(row, ["source_contact_intent", "provenance", "trust_boundary"]) ||
      row["_source_report_trust_boundary"]
  end

  defp put_default_if_present(map, _field, value) when value in [nil, "", [], %{}], do: map

  defp put_default_if_present(map, field, value) do
    case Map.get(map, field) do
      existing when existing in [nil, "", [], %{}] -> Map.put(map, field, value)
      _existing -> map
    end
  end

  defp default_callbacks do
    [
      activity_raw_end: &ActivityTiming.activity_raw_end/1,
      activity_raw_start: &ActivityTiming.activity_raw_start/1,
      branch_id_fragment: &ValueEncoding.branch_id_fragment/1,
      compact_map: &ValueEncoding.compact_map/1,
      downlink_activity?: &DownlinkActivityNormalization.downlink?/1,
      explicit_timeline_id: &RealizedFeedbackContext.explicit_timeline_id/1,
      nested_ground_station_id: &DownlinkActivityNormalization.nested_ground_station_id/1,
      normalize_pressure_row: &normalize_pressure_row/1,
      normalized_optional_status: &ScalarValues.normalized_optional_status/1,
      numeric_or_nil: &ScalarValues.numeric_or_nil/1,
      stable_id_string?: &ScalarValues.stable_id_string?/1,
      stringify_keys: &ValueEncoding.stringify_keys/1
    ]
  end

  defp normalize_pressure_row(row) do
    row = ValueEncoding.stringify_keys(row)

    row
    |> ReviewRowSources.contact_intent_row(row)
    |> put_default_if_present("source_policy_decision", row["policy_decision"])
    |> put_default_if_present("cadence_import_status", nested_cadence_import_status(row))
  end

  defp nested_cadence_import_status(row) do
    case Map.get(row, "cadence_import") do
      %{} = cadence_import ->
        cadence_import
        |> ValueEncoding.stringify_keys()
        |> Map.get("status")
        |> ScalarValues.normalized_optional_status()

      _cadence_import ->
        nil
    end
  end
end
