defmodule OrbitalDynamics.CadenceImport.ProposedContactManifestRow do
  @moduledoc false

  def build(contact, rank, callbacks) when is_list(callbacks) do
    raw_cadence_import = Map.get(contact, "cadence_import")
    cadence_import = if is_map(raw_cadence_import), do: raw_cadence_import, else: %{}
    has_import? = is_map(raw_cadence_import)
    invalid_import? = Map.has_key?(contact, "cadence_import") and not has_import?
    cadence_import_status = proposed_contact_cadence_import_status(has_import?, invalid_import?)

    %{
      "id" => "cadence_import:proposed_contact:#{contact["id"] || rank}",
      "rank" => rank,
      "import_action" => "import_proposed_contact",
      "import_status" => proposed_contact_import_status(cadence_import_status),
      "import_side" => "source",
      "source_review_row_id" => "proposed_contact:#{contact["id"] || rank}",
      "source_review_type" => "proposed_contact",
      "source_review_action" => "import_proposed_contact",
      "subject_id" => contact["id"],
      "activity_id" => contact["id"],
      "activity_type" => contact["type"] || "downlink",
      "direction" => contact["direction"],
      "ground_station_id" => contact["ground_station_id"],
      "scenario_id" => contact["scenario_id"],
      "source_window_id" => contact["source_window_id"],
      "starts_at_s" => contact["starts_at_s"],
      "ends_at_s" => contact["ends_at_s"],
      "estimated_throughput_mb" => contact["estimated_throughput_mb"],
      "capacity_adjusted_throughput_mb" => contact["capacity_adjusted_throughput_mb"],
      "station_availability" => contact["station_availability"],
      "station_contention_status" => contact["station_contention_status"],
      "station_calendar_entry_id" => contact["station_calendar_entry_id"],
      "station_calendar_status" => contact["station_calendar_status"],
      "station_calendar_overlap_count" => contact["station_calendar_overlap_count"],
      "station_calendar_overlap_entry_ids" => contact["station_calendar_overlap_entry_ids"],
      "station_calendar_overlap_availabilities" =>
        contact["station_calendar_overlap_availabilities"],
      "station_calendar_entry_ambiguous" => contact["station_calendar_entry_ambiguous"],
      "station_calendar_ambiguous_entry_count" =>
        contact["station_calendar_ambiguous_entry_count"],
      "station_calendar_ambiguous_entry_ids" => contact["station_calendar_ambiguous_entry_ids"],
      "station_calendar_reservation_overlap_count" =>
        contact["station_calendar_reservation_overlap_count"],
      "station_calendar_reservation_ids" => contact["station_calendar_reservation_ids"],
      "station_calendar_reserved_by" => contact["station_calendar_reserved_by"],
      "station_calendar_reservation_statuses" => contact["station_calendar_reservation_statuses"],
      "station_calendar_reservation_expires_at_s" =>
        contact["station_calendar_reservation_expires_at_s"],
      "station_calendar_trust_boundary_status" =>
        contact["station_calendar_trust_boundary_status"],
      "trust_boundary" => contact["trust_boundary"],
      "provenance" => contact["provenance"],
      "source_station_calendar_entry" => contact["source_station_calendar_entry"],
      "source_station_calendar_overlaps" => contact["source_station_calendar_overlaps"],
      "cadence_import_status" => cadence_import_status,
      "cadence_import_type" => Map.get(cadence_import, "activity_type"),
      "cadence_import_id" => Map.get(cadence_import, "external_id"),
      "cadence_import_contract" => Map.get(cadence_import, "schema_contract"),
      "cadence_import_provider" => Map.get(cadence_import, "provider"),
      "cadence_import_adapter" => Map.get(cadence_import, "adapter"),
      "cadence_import_adapter_version" => Map.get(cadence_import, "adapter_version"),
      "cadence_import_trust_boundary" =>
        Map.get(cadence_import, "trust_boundary") ||
          get_in(cadence_import, ["provenance", "trust_boundary"]),
      "cadence_import_provenance" => Map.get(cadence_import, "provenance"),
      "invalid_cadence_import" => if(invalid_import?, do: true),
      "invalid_cadence_import_reason" => if(invalid_import?, do: "cadence_import_must_be_object"),
      "source_cadence_import" =>
        if(invalid_import?,
          do: %{"invalid_import_shape" => encode_json_value(callbacks, raw_cadence_import)}
        ),
      "has_cadence_import" => has_import?,
      "import_activity_context" =>
        contact
        |> proposed_contact_import_activity_context(
          raw_cadence_import,
          invalid_import?,
          callbacks
        )
        |> normalize_provider_result_artifact_fields(callbacks)
    }
    |> compact_map(callbacks)
  end

  defp proposed_contact_cadence_import_status(true, _invalid_import?), do: "present"
  defp proposed_contact_cadence_import_status(_has_import?, true), do: "invalid"
  defp proposed_contact_cadence_import_status(_has_import?, _invalid_import?), do: "missing"

  defp proposed_contact_import_status("present"), do: "ready_for_import"
  defp proposed_contact_import_status("invalid"), do: "review_required_before_import"
  defp proposed_contact_import_status(_status), do: "blocked_missing_cadence_import"

  defp proposed_contact_import_activity_context(
         contact,
         raw_cadence_import,
         true,
         callbacks
       ) do
    contact
    |> Map.delete("cadence_import")
    |> Map.merge(%{
      "invalid_cadence_import" => true,
      "invalid_cadence_import_reason" => "cadence_import_must_be_object",
      "source_cadence_import" => %{
        "invalid_import_shape" => encode_json_value(callbacks, raw_cadence_import)
      }
    })
  end

  defp proposed_contact_import_activity_context(
         contact,
         _raw_cadence_import,
         _invalid_import?,
         _callbacks
       ),
       do: contact

  defp encode_json_value(callbacks, value),
    do: invoke(callbacks, :encode_json_value, [value])

  defp normalize_provider_result_artifact_fields(value, callbacks),
    do: invoke(callbacks, :normalize_provider_result_artifact_fields, [value])

  defp compact_map(value, callbacks), do: invoke(callbacks, :compact_map, [value])

  defp invoke(callbacks, name, args), do: apply(Keyword.fetch!(callbacks, name), args)
end
