defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationReservation do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      compact_map: 1,
      count_report_field_values: 2,
      merge_count_maps: 1,
      merge_string_list_maps: 1,
      merge_string_lists: 1,
      sum_report_count: 2
    ]

  def report_input_summary([], _callbacks), do: nil

  def report_input_summary(sources, callbacks) do
    reports = Enum.map(sources, fn {_path, report} -> report end)

    reservation_hold_ids_by_direction =
      reports
      |> Enum.map(callback!(callbacks, :station_reservation_report_hold_ids_by_direction))
      |> merge_string_list_maps()

    reservation_hold_contact_ids_by_direction =
      reports
      |> Enum.map(callback!(callbacks, :station_reservation_report_hold_contact_ids_by_direction))
      |> merge_string_list_maps()

    direction_counts =
      reports
      |> Enum.map(callback!(callbacks, :station_reservation_report_direction_counts))
      |> merge_count_maps()

    contact_ids_by_direction =
      reports
      |> Enum.map(callback!(callbacks, :station_reservation_report_contact_ids_by_direction))
      |> merge_string_list_maps()

    %{
      "paths" => Enum.map(sources, fn {path, _report} -> path end),
      "contract" => "station_reservation_report.v1",
      "count" => length(sources),
      "row_count" =>
        sum_report_count(reports, callback!(callbacks, :station_reservation_report_row_count)),
      "source_summary_model_counts" =>
        reports
        |> count_report_field_values("source_summary_model"),
      "source_summary_schema_contract_counts" =>
        reports
        |> count_report_field_values("source_summary_schema_contract"),
      "source_artifact_type_counts" =>
        reports
        |> count_report_field_values("source_artifact_type"),
      "affected_contact_count" =>
        sum_report_count(
          reports,
          callback!(callbacks, :station_reservation_report_affected_contact_count)
        ),
      "provider_calendar_contention_group_count" =>
        sum_report_count(
          reports,
          callback!(
            callbacks,
            :station_reservation_report_provider_calendar_contention_group_count
          )
        ),
      "provider_calendar_contention_group_ids" =>
        callback!(callbacks, :station_calendar_report_provider_contention_group_ids).(reports),
      "provider_calendar_contention_source_entry_ids" =>
        callback!(callbacks, :station_calendar_report_provider_contention_source_entry_ids).(
          reports
        ),
      "provider_calendar_contention_provider_entry_ids" =>
        callback!(callbacks, :station_calendar_report_provider_contention_provider_entry_ids).(
          reports
        ),
      "provider_calendar_contention_provider_counts" =>
        reports
        |> Enum.map(
          callback!(callbacks, :station_calendar_report_provider_contention_provider_counts)
        )
        |> merge_count_maps(),
      "provider_calendar_contention_ground_station_counts" =>
        reports
        |> Enum.map(
          callback!(callbacks, :station_calendar_report_provider_contention_ground_station_counts)
        )
        |> merge_count_maps(),
      "provider_calendar_contention_provider_entry_ids_by_provider" =>
        reports
        |> Enum.map(
          callback!(
            callbacks,
            :station_calendar_report_provider_contention_provider_entry_ids_by_provider
          )
        )
        |> merge_string_list_maps(),
      "provider_calendar_contention_provider_entry_ids_by_ground_station" =>
        reports
        |> Enum.map(
          callback!(
            callbacks,
            :station_calendar_report_provider_contention_provider_entry_ids_by_ground_station
          )
        )
        |> merge_string_list_maps(),
      "provider_calendar_contention_provider_entry_ids_by_direction" =>
        reports
        |> Enum.map(
          callback!(
            callbacks,
            :station_calendar_report_provider_contention_provider_entry_ids_by_direction
          )
        )
        |> merge_string_list_maps(),
      "reservation_review_count" =>
        sum_report_count(reports, callback!(callbacks, :station_reservation_report_review_count)),
      "reservation_hold_count" =>
        callback!(callbacks, :station_reservation_report_optional_count_sum).(
          reports,
          "reservation_hold_count"
        ),
      "affected_contact_reservation_hold_count" =>
        callback!(callbacks, :station_reservation_report_optional_count_sum).(
          reports,
          "affected_contact_reservation_hold_count"
        ),
      "provider_calendar_contention_hold_count" =>
        callback!(callbacks, :station_reservation_report_optional_count_sum).(
          reports,
          "provider_calendar_contention_hold_count"
        ),
      "reservation_hold_review_status_counts" =>
        reports
        |> count_report_field_values("reservation_hold_review_status"),
      "reservation_hold_expiration_count" =>
        callback!(callbacks, :station_reservation_report_optional_count_sum).(
          reports,
          "reservation_hold_expiration_count"
        ),
      "earliest_reservation_hold_expires_at_s" =>
        reports
        |> Enum.map(&(Map.get(&1, "earliest_reservation_hold_expires_at_s") |> numeric_value()))
        |> Enum.reject(&is_nil/1)
        |> Enum.min(fn -> nil end),
      "reservation_hold_expiration_status_counts" =>
        reports
        |> Enum.map(&Map.get(&1, "reservation_hold_expiration_status_counts"))
        |> merge_count_maps(),
      "reservation_hold_status_counts" =>
        reports
        |> Enum.map(&Map.get(&1, "reservation_hold_status_counts"))
        |> merge_count_maps(),
      "reservation_hold_import_readiness_status_counts" =>
        reports
        |> Enum.map(
          callback!(callbacks, :station_reservation_report_import_readiness_status_counts)
        )
        |> merge_count_maps(),
      "reservation_hold_import_classification_counts" =>
        reports
        |> Enum.map(
          callback!(callbacks, :station_reservation_report_import_classification_counts)
        )
        |> merge_count_maps(),
      "reservation_hold_ready_for_import_count" =>
        callback!(callbacks, :station_reservation_report_optional_count_sum).(
          reports,
          "ready_for_import_count"
        ),
      "reservation_hold_review_required_before_import_count" =>
        callback!(callbacks, :station_reservation_report_optional_count_sum).(
          reports,
          "review_required_before_import_count"
        ),
      "reservation_hold_no_import_required_count" =>
        callback!(callbacks, :station_reservation_report_optional_count_sum).(
          reports,
          "no_import_required_count"
        ),
      "reservation_hold_import_status_counts" =>
        reports
        |> Enum.map(callback!(callbacks, :station_reservation_report_hold_import_status_counts))
        |> merge_count_maps(),
      "required_import_action_counts" =>
        reports
        |> Enum.map(
          callback!(callbacks, :station_reservation_report_hold_required_import_action_counts)
        )
        |> merge_count_maps(),
      "reservation_hold_ids" =>
        reports
        |> Enum.map(&Map.get(&1, "reservation_hold_ids"))
        |> merge_string_lists(),
      "reservation_hold_ids_by_import_status" =>
        reports
        |> Enum.map(callback!(callbacks, :station_reservation_report_hold_ids_by_import_status))
        |> merge_string_list_maps(),
      "reservation_hold_ids_by_expiration_status" =>
        reports
        |> Enum.map(&Map.get(&1, "reservation_hold_ids_by_expiration_status"))
        |> merge_string_list_maps(),
      "reservation_hold_ids_by_status" =>
        reports
        |> Enum.map(&Map.get(&1, "reservation_hold_ids_by_status"))
        |> merge_string_list_maps(),
      "reservation_hold_ids_by_reserved_by" =>
        reports
        |> Enum.map(&Map.get(&1, "reservation_hold_ids_by_reserved_by"))
        |> merge_string_list_maps(),
      "reservation_hold_ids_by_row_type" =>
        reports
        |> Enum.map(&Map.get(&1, "reservation_hold_ids_by_row_type"))
        |> merge_string_list_maps(),
      "reservation_hold_ids_by_required_import_action" =>
        reports
        |> Enum.map(
          callback!(callbacks, :station_reservation_report_hold_ids_by_required_import_action)
        )
        |> merge_string_list_maps(),
      "reservation_hold_ids_by_direction" => reservation_hold_ids_by_direction,
      "reservation_hold_contact_ids_by_import_status" =>
        reports
        |> Enum.map(
          callback!(callbacks, :station_reservation_report_hold_contact_ids_by_import_status)
        )
        |> merge_string_list_maps(),
      "reservation_hold_contact_ids_by_direction" => reservation_hold_contact_ids_by_direction,
      "reservation_hold_contact_ids_by_expiration_status" =>
        reports
        |> Enum.map(&Map.get(&1, "reservation_hold_contact_ids_by_expiration_status"))
        |> merge_string_list_maps(),
      "reservation_hold_review_contact_ids" =>
        reports
        |> Enum.map(&Map.get(&1, "review_contact_ids"))
        |> merge_string_lists(),
      "station_reservation_evidence_row_count" =>
        sum_report_count(
          reports,
          callback!(callbacks, :station_reservation_report_evidence_count)
        ),
      "station_reservation_expiration_evidence_row_count" =>
        sum_report_count(
          reports,
          callback!(callbacks, :station_reservation_report_expiration_evidence_count)
        ),
      "affected_contact_ids" =>
        callback!(callbacks, :station_reservation_report_affected_contact_ids).(reports),
      "contact_ids_by_match_status" =>
        reports
        |> Enum.map(callback!(callbacks, :station_reservation_report_contact_ids_by_match_status))
        |> merge_string_list_maps(),
      "contact_ids_by_status" =>
        reports
        |> Enum.map(callback!(callbacks, :station_reservation_report_contact_ids_by_status))
        |> merge_string_list_maps(),
      "direction_counts" => direction_counts,
      "contact_ids_by_direction" => contact_ids_by_direction,
      "direction_routing" =>
        callback!(callbacks, :station_reservation_direction_routing).(
          direction_counts,
          contact_ids_by_direction,
          reservation_hold_ids_by_direction,
          reservation_hold_contact_ids_by_direction
        ),
      "reservation_expires_at_s" =>
        callback!(callbacks, :station_reservation_report_expires_at_s).(reports),
      "earliest_reservation_expires_at_s" =>
        reports
        |> callback!(callbacks, :station_reservation_report_expires_at_s).()
        |> List.wrap()
        |> Enum.min(fn -> nil end),
      "station_reservation_match_status_counts" =>
        reports
        |> Enum.map(callback!(callbacks, :station_reservation_report_match_status_counts))
        |> merge_count_maps(),
      "reservation_status_counts" =>
        reports
        |> Enum.map(callback!(callbacks, :station_reservation_report_status_counts))
        |> merge_count_maps(),
      "reservation_ids" => callback!(callbacks, :station_reservation_report_ids).(reports),
      "reservation_ids_by_match_status" =>
        reports
        |> Enum.map(callback!(callbacks, :station_reservation_report_ids_by_match_status))
        |> merge_string_list_maps(),
      "reservation_ids_by_status" =>
        reports
        |> Enum.map(callback!(callbacks, :station_reservation_report_ids_by_status))
        |> merge_string_list_maps(),
      "reserved_by_counts" =>
        reports
        |> Enum.map(callback!(callbacks, :station_reservation_report_reserved_by_counts))
        |> merge_count_maps(),
      "contact_ids_by_reserved_by" =>
        reports
        |> Enum.map(callback!(callbacks, :station_reservation_report_contact_ids_by_reserved_by))
        |> merge_string_list_maps(),
      "reservation_ids_by_reserved_by" =>
        reports
        |> Enum.map(callback!(callbacks, :station_reservation_report_ids_by_reserved_by))
        |> merge_string_list_maps(),
      "trust_boundary_status" =>
        trust_boundary_status(
          reports,
          callback!(callbacks, :source_station_reservation_report_trust_boundaries)
        ),
      "trust_boundaries" =>
        callback!(callbacks, :source_station_reservation_report_trust_boundaries).(reports)
    }
    |> compact_map()
  end

  defp trust_boundary_status(reports, trust_boundaries) when is_function(trust_boundaries, 1) do
    case trust_boundaries.(reports) do
      [] -> "missing"
      _trust_boundaries -> "declared"
    end
  end

  defp numeric_value(value) when is_number(value), do: value * 1.0

  defp numeric_value(value) when is_binary(value) do
    case Float.parse(String.trim(value)) do
      {number, ""} -> number
      _error -> nil
    end
  end

  defp numeric_value(_value), do: nil

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
