defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationCalendar do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      compact_map: 1,
      count_report_field_values: 2,
      merge_count_maps: 1,
      merge_numeric_list_maps: 1,
      merge_string_list_maps: 1,
      sorted_string_values: 1,
      sum_report_count: 2
    ]

  def report_input_summary([], _callbacks), do: nil

  def report_input_summary(sources, callbacks) do
    sources =
      callback!(callbacks, :deduplicate_shadowed_mission_state_result_artifact_sources).(sources)

    reports = Enum.map(sources, fn {_path, report} -> report end)

    %{
      "paths" => Enum.map(sources, fn {path, _report} -> path end),
      "contract" => callback!(callbacks, :station_calendar_input_summary_contract).(reports),
      "count" => length(sources),
      "source_summary_model_counts" =>
        reports
        |> count_report_field_values("source_summary_model"),
      "source_summary_schema_contract_counts" =>
        reports
        |> count_report_field_values("source_summary_schema_contract"),
      "source_artifact_type_counts" =>
        reports
        |> count_report_field_values("source_artifact_type"),
      "row_count" =>
        sum_report_count(reports, callback!(callbacks, :station_calendar_report_row_count)),
      "affected_contact_count" =>
        sum_report_count(
          reports,
          callback!(callbacks, :station_calendar_report_affected_contact_count)
        ),
      "provider_calendar_contention_group_count" =>
        sum_report_count(
          reports,
          callback!(callbacks, :station_calendar_report_provider_calendar_contention_group_count)
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
      "provider_calendar_contention_capacity_fractions" =>
        callback!(callbacks, :station_calendar_report_provider_contention_capacity_fractions).(
          reports
        ),
      "provider_calendar_contention_minimum_capacity_fraction" =>
        reports
        |> callback!(callbacks, :station_calendar_report_provider_contention_capacity_fractions).()
        |> min_list(),
      "provider_calendar_contention_capacity_fractions_by_provider" =>
        reports
        |> Enum.map(
          callback!(
            callbacks,
            :station_calendar_report_provider_contention_capacity_fractions_by_provider
          )
        )
        |> merge_numeric_list_maps(),
      "provider_calendar_contention_capacity_fractions_by_ground_station" =>
        reports
        |> Enum.map(
          callback!(
            callbacks,
            :station_calendar_report_provider_contention_capacity_fractions_by_ground_station
          )
        )
        |> merge_numeric_list_maps(),
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
      "provider_calendar_contention_provider_ids_by_direction" =>
        reports
        |> Enum.map(
          callback!(
            callbacks,
            :station_calendar_report_provider_contention_provider_ids_by_direction
          )
        )
        |> merge_string_list_maps(),
      "provider_calendar_contention_direction_counts" =>
        reports
        |> Enum.map(
          callback!(callbacks, :station_calendar_report_provider_contention_direction_counts)
        )
        |> merge_count_maps(),
      "provider_calendar_contention_group_ids_by_direction" =>
        reports
        |> Enum.map(
          callback!(
            callbacks,
            :station_calendar_report_provider_contention_group_ids_by_direction
          )
        )
        |> merge_string_list_maps(),
      "provider_calendar_contention_source_entry_ids_by_direction" =>
        reports
        |> Enum.map(
          callback!(
            callbacks,
            :station_calendar_report_provider_contention_source_entry_ids_by_direction
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
      "provider_calendar_contention_capacity_fractions_by_direction" =>
        reports
        |> Enum.map(
          callback!(
            callbacks,
            :station_calendar_report_provider_contention_capacity_fractions_by_direction
          )
        )
        |> merge_numeric_list_maps(),
      "affected_contact_ids" =>
        callback!(callbacks, :station_calendar_report_affected_contact_ids).(reports),
      "affected_station_calendar_entry_ids" =>
        callback!(callbacks, :station_calendar_report_affected_station_calendar_entry_ids).(
          reports
        ),
      "affected_station_reservation_ids" =>
        callback!(callbacks, :station_calendar_report_affected_station_reservation_ids).(reports),
      "direction_counts" =>
        reports
        |> Enum.map(callback!(callbacks, :station_calendar_report_direction_counts))
        |> merge_count_maps(),
      "contact_ids_by_direction" =>
        reports
        |> Enum.map(callback!(callbacks, :station_calendar_report_contact_ids_by_direction))
        |> merge_string_list_maps(),
      "station_calendar_entry_ids_by_direction" =>
        reports
        |> Enum.map(callback!(callbacks, :station_calendar_report_entry_ids_by_direction))
        |> merge_string_list_maps(),
      "station_reservation_ids_by_direction" =>
        reports
        |> Enum.map(callback!(callbacks, :station_calendar_report_reservation_ids_by_direction))
        |> merge_string_list_maps(),
      "station_capacity_fractions_by_direction" =>
        reports
        |> Enum.map(
          callback!(callbacks, :station_calendar_report_capacity_fractions_by_direction)
        )
        |> merge_numeric_list_maps(),
      "direction_routing" => callback!(callbacks, :station_calendar_direction_routing).(reports),
      "reserved_by_counts" =>
        reports
        |> Enum.map(callback!(callbacks, :station_calendar_report_reserved_by_counts))
        |> merge_count_maps(),
      "contact_ids_by_reserved_by" =>
        reports
        |> Enum.map(callback!(callbacks, :station_calendar_report_contact_ids_by_reserved_by))
        |> merge_string_list_maps(),
      "station_calendar_entry_ids_by_reserved_by" =>
        reports
        |> Enum.map(callback!(callbacks, :station_calendar_report_entry_ids_by_reserved_by))
        |> merge_string_list_maps(),
      "station_reservation_ids_by_reserved_by" =>
        reports
        |> Enum.map(callback!(callbacks, :station_calendar_report_reservation_ids_by_reserved_by))
        |> merge_string_list_maps(),
      "station_reservation_expires_at_s" =>
        callback!(callbacks, :station_calendar_report_reservation_expires_at_s).(reports),
      "earliest_station_reservation_expires_at_s" =>
        reports
        |> callback!(callbacks, :station_calendar_report_reservation_expires_at_s).()
        |> min_list(),
      "station_capacity_fractions" =>
        callback!(callbacks, :station_calendar_report_capacity_fractions).(reports),
      "minimum_station_capacity_fraction" =>
        reports
        |> callback!(callbacks, :station_calendar_report_capacity_fractions).()
        |> min_list(),
      "station_capacity_fractions_by_status" =>
        reports
        |> Enum.map(callback!(callbacks, :station_calendar_report_capacity_fractions_by_status))
        |> merge_numeric_list_maps(),
      "station_capacity_fractions_by_ground_station" =>
        reports
        |> Enum.map(
          callback!(callbacks, :station_calendar_report_capacity_fractions_by_ground_station)
        )
        |> merge_numeric_list_maps(),
      "station_capacity_fractions_by_availability" =>
        reports
        |> Enum.map(
          callback!(callbacks, :station_calendar_report_capacity_fractions_by_availability)
        )
        |> merge_numeric_list_maps(),
      "contact_ids_by_status" =>
        reports
        |> Enum.map(callback!(callbacks, :station_calendar_report_contact_ids_by_status))
        |> merge_string_list_maps(),
      "contact_ids_by_ground_station" =>
        reports
        |> Enum.map(callback!(callbacks, :station_calendar_report_contact_ids_by_ground_station))
        |> merge_string_list_maps(),
      "contact_ids_by_availability" =>
        reports
        |> Enum.map(callback!(callbacks, :station_calendar_report_contact_ids_by_availability))
        |> merge_string_list_maps(),
      "station_calendar_entry_ids_by_status" =>
        reports
        |> Enum.map(callback!(callbacks, :station_calendar_report_entry_ids_by_status))
        |> merge_string_list_maps(),
      "station_calendar_entry_ids_by_ground_station" =>
        reports
        |> Enum.map(callback!(callbacks, :station_calendar_report_entry_ids_by_ground_station))
        |> merge_string_list_maps(),
      "station_calendar_entry_ids_by_availability" =>
        reports
        |> Enum.map(callback!(callbacks, :station_calendar_report_entry_ids_by_availability))
        |> merge_string_list_maps(),
      "station_reservation_ids_by_status" =>
        reports
        |> Enum.map(callback!(callbacks, :station_calendar_report_reservation_ids_by_status))
        |> merge_string_list_maps(),
      "station_reservation_ids_by_ground_station" =>
        reports
        |> Enum.map(
          callback!(callbacks, :station_calendar_report_reservation_ids_by_ground_station)
        )
        |> merge_string_list_maps(),
      "station_reservation_ids_by_availability" =>
        reports
        |> Enum.map(
          callback!(callbacks, :station_calendar_report_reservation_ids_by_availability)
        )
        |> merge_string_list_maps(),
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
      "station_calendar_status_counts" =>
        reports
        |> Enum.map(callback!(callbacks, :station_calendar_report_status_counts))
        |> merge_count_maps(),
      "affected_contact_ground_station_counts" =>
        reports
        |> Enum.map(
          callback!(callbacks, :station_calendar_report_affected_contact_ground_station_counts)
        )
        |> merge_count_maps(),
      "affected_contact_availability_counts" =>
        reports
        |> Enum.map(
          callback!(callbacks, :station_calendar_report_affected_contact_availability_counts)
        )
        |> merge_count_maps(),
      "precedence_review_status_counts" =>
        reports
        |> count_report_field_values("precedence_review_status"),
      "applied_availability_counts" =>
        reports
        |> Enum.map(&Map.get(&1, "applied_availability_counts", %{}))
        |> merge_count_maps(),
      "overlap_availability_counts" =>
        reports
        |> Enum.map(&Map.get(&1, "overlap_availability_counts", %{}))
        |> merge_count_maps(),
      "affected_contact_ids_by_applied_availability" =>
        reports
        |> Enum.map(&Map.get(&1, "affected_contact_ids_by_applied_availability", %{}))
        |> merge_string_list_maps(),
      "affected_contact_ids_by_overlap_availability" =>
        reports
        |> Enum.map(&Map.get(&1, "affected_contact_ids_by_overlap_availability", %{}))
        |> merge_string_list_maps(),
      "reserved_under_higher_precedence_contact_count" =>
        sum_report_count(
          reports,
          &callback!(callbacks, :summary_integer).(
            &1,
            "reserved_under_higher_precedence_contact_count"
          )
        ),
      "reserved_under_higher_precedence_contact_ids" =>
        reports
        |> Enum.flat_map(&Map.get(&1, "reserved_under_higher_precedence_contact_ids", []))
        |> sorted_string_values(),
      "reserved_under_higher_precedence_contact_ids_by_applied_availability" =>
        reports
        |> Enum.map(
          &Map.get(
            &1,
            "reserved_under_higher_precedence_contact_ids_by_applied_availability",
            %{}
          )
        )
        |> merge_string_list_maps(),
      "reserved_under_higher_precedence_reservation_ids" =>
        reports
        |> Enum.flat_map(&Map.get(&1, "reserved_under_higher_precedence_reservation_ids", []))
        |> sorted_string_values(),
      "reserved_under_higher_precedence_reservation_ids_by_status" =>
        reports
        |> Enum.map(
          &Map.get(&1, "reserved_under_higher_precedence_reservation_ids_by_status", %{})
        )
        |> merge_string_list_maps(),
      "reserved_under_higher_precedence_reservation_ids_by_reserved_by" =>
        reports
        |> Enum.map(
          &Map.get(&1, "reserved_under_higher_precedence_reservation_ids_by_reserved_by", %{})
        )
        |> merge_string_list_maps(),
      "reserved_under_higher_precedence_contact_ids_by_reservation_status" =>
        reports
        |> Enum.map(
          &Map.get(
            &1,
            "reserved_under_higher_precedence_contact_ids_by_reservation_status",
            %{}
          )
        )
        |> merge_string_list_maps(),
      "reserved_under_higher_precedence_contact_ids_by_reserved_by" =>
        reports
        |> Enum.map(
          &Map.get(&1, "reserved_under_higher_precedence_contact_ids_by_reserved_by", %{})
        )
        |> merge_string_list_maps(),
      "trust_boundary_status" =>
        trust_boundary_status(
          reports,
          callback!(callbacks, :source_station_calendar_report_trust_boundaries)
        ),
      "trust_boundaries" =>
        callback!(callbacks, :source_station_calendar_report_trust_boundaries).(reports)
    }
    |> compact_map()
  end

  defp min_list(values) when is_list(values), do: Enum.min(values, fn -> nil end)
  defp min_list(_values), do: nil

  defp trust_boundary_status(reports, trust_boundaries) when is_function(trust_boundaries, 1) do
    case trust_boundaries.(reports) do
      [] -> "missing"
      _trust_boundaries -> "declared"
    end
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
