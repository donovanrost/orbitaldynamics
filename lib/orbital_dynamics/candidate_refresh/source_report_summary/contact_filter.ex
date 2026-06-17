defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactFilter do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      compact_map: 1,
      merge_count_maps: 1,
      merge_string_list_maps: 1,
      sorted_string_values: 1,
      sum_report_count: 2
    ]

  def report_input_summary([], _callbacks), do: nil

  def report_input_summary(sources, callbacks) do
    reports = Enum.map(sources, fn {_path, report} -> report end)

    direction_counts =
      reports
      |> Enum.map(callback!(callbacks, :contact_filter_report_direction_counts))
      |> merge_count_maps()

    contact_ids_by_direction =
      reports
      |> Enum.map(callback!(callbacks, :contact_filter_report_contact_ids_by_direction))
      |> merge_string_list_maps()

    directions =
      callback!(callbacks, :contact_filter_report_direction_keys).(
        direction_counts,
        contact_ids_by_direction
      )

    %{
      "paths" => Enum.map(sources, fn {path, _report} -> path end),
      "contract" => "contact_filter_report.v1",
      "count" => length(sources),
      "row_count" =>
        sum_report_count(reports, callback!(callbacks, :contact_filter_report_row_count)),
      "suppressed_candidate_count" =>
        sum_report_count(
          reports,
          callback!(callbacks, :contact_filter_report_suppressed_candidate_count)
        ),
      "invalid_contact_input_count" =>
        sum_report_count(
          reports,
          callback!(callbacks, :contact_filter_report_invalid_contact_input_count)
        ),
      "invalid_contact_input_ids" =>
        reports
        |> Enum.flat_map(callback!(callbacks, :contact_filter_report_invalid_contact_input_ids))
        |> sorted_string_values()
        |> case do
          [] -> nil
          ids -> ids
        end,
      "suppressed_reason_counts" =>
        reports
        |> Enum.map(callback!(callbacks, :contact_filter_report_suppressed_reason_counts))
        |> merge_count_maps(),
      "contact_ids_by_suppressed_reason" =>
        reports
        |> Enum.map(callback!(callbacks, :contact_filter_report_contact_ids_by_suppressed_reason))
        |> merge_string_list_maps(),
      "direction_counts" => direction_counts,
      "directions" => directions,
      "contact_ids_by_direction" => contact_ids_by_direction,
      "direction_routing" =>
        callback!(callbacks, :contact_filter_direction_routing).(
          direction_counts,
          contact_ids_by_direction
        ),
      "station_suppression_count" =>
        sum_report_count(
          reports,
          callback!(callbacks, :contact_filter_report_station_suppression_count)
        ),
      "station_suppression_ground_station_counts" =>
        reports
        |> Enum.map(
          callback!(callbacks, :contact_filter_report_station_suppression_ground_station_counts)
        )
        |> merge_count_maps(),
      "station_suppression_availability_counts" =>
        reports
        |> Enum.map(
          callback!(callbacks, :contact_filter_report_station_suppression_availability_counts)
        )
        |> merge_count_maps(),
      "station_suppression_status_counts" =>
        reports
        |> Enum.map(
          callback!(callbacks, :contact_filter_report_station_suppression_status_counts)
        )
        |> merge_count_maps(),
      "station_suppression_contact_ids_by_ground_station" =>
        reports
        |> Enum.map(
          callback!(
            callbacks,
            :contact_filter_report_station_suppression_contact_ids_by_ground_station
          )
        )
        |> merge_string_list_maps(),
      "station_suppression_contact_ids_by_availability" =>
        reports
        |> Enum.map(
          callback!(
            callbacks,
            :contact_filter_report_station_suppression_contact_ids_by_availability
          )
        )
        |> merge_string_list_maps(),
      "station_suppression_contact_ids_by_status" =>
        reports
        |> Enum.map(
          callback!(callbacks, :contact_filter_report_station_suppression_contact_ids_by_status)
        )
        |> merge_string_list_maps(),
      "station_suppression_station_calendar_entry_ids_by_ground_station" =>
        reports
        |> Enum.map(
          callback!(
            callbacks,
            :contact_filter_report_station_suppression_station_calendar_entry_ids_by_ground_station
          )
        )
        |> merge_string_list_maps(),
      "station_suppression_station_calendar_entry_ids_by_availability" =>
        reports
        |> Enum.map(
          callback!(
            callbacks,
            :contact_filter_report_station_suppression_station_calendar_entry_ids_by_availability
          )
        )
        |> merge_string_list_maps(),
      "station_suppression_station_calendar_entry_ids_by_status" =>
        reports
        |> Enum.map(
          callback!(
            callbacks,
            :contact_filter_report_station_suppression_station_calendar_entry_ids_by_status
          )
        )
        |> merge_string_list_maps(),
      "station_suppression_station_calendar_provider_entry_ids_by_ground_station" =>
        reports
        |> Enum.map(
          callback!(
            callbacks,
            :contact_filter_report_station_suppression_station_calendar_provider_entry_ids_by_ground_station
          )
        )
        |> merge_string_list_maps(),
      "station_suppression_station_calendar_provider_entry_ids_by_availability" =>
        reports
        |> Enum.map(
          callback!(
            callbacks,
            :contact_filter_report_station_suppression_station_calendar_provider_entry_ids_by_availability
          )
        )
        |> merge_string_list_maps(),
      "station_suppression_station_calendar_provider_entry_ids_by_status" =>
        reports
        |> Enum.map(
          callback!(
            callbacks,
            :contact_filter_report_station_suppression_station_calendar_provider_entry_ids_by_status
          )
        )
        |> merge_string_list_maps(),
      "station_suppression_station_reservation_ids_by_ground_station" =>
        reports
        |> Enum.map(
          callback!(
            callbacks,
            :contact_filter_report_station_suppression_station_reservation_ids_by_ground_station
          )
        )
        |> merge_string_list_maps(),
      "station_suppression_station_reservation_ids_by_availability" =>
        reports
        |> Enum.map(
          callback!(
            callbacks,
            :contact_filter_report_station_suppression_station_reservation_ids_by_availability
          )
        )
        |> merge_string_list_maps(),
      "station_suppression_station_reservation_ids_by_status" =>
        reports
        |> Enum.map(
          callback!(
            callbacks,
            :contact_filter_report_station_suppression_station_reservation_ids_by_status
          )
        )
        |> merge_string_list_maps(),
      "trust_boundary_status" =>
        trust_boundary_status(
          reports,
          callback!(callbacks, :source_contact_filter_report_trust_boundaries)
        ),
      "trust_boundaries" =>
        callback!(callbacks, :source_contact_filter_report_trust_boundaries).(reports)
    }
    |> compact_map()
  end

  defp trust_boundary_status(reports, trust_boundaries) when is_function(trust_boundaries, 1) do
    case trust_boundaries.(reports) do
      [] -> "missing"
      _trust_boundaries -> "declared"
    end
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
