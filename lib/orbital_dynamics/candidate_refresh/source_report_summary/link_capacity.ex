defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.LinkCapacity do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      compact_map: 1,
      count_report_field_values: 2,
      merge_count_maps: 1,
      merge_numeric_maps: 1,
      merge_string_list_maps: 1,
      merge_string_lists: 1,
      sum_report_count: 2
    ]

  def report_input_summary([], _callbacks), do: nil

  def report_input_summary(sources, callbacks) do
    sources =
      callback!(callbacks, :deduplicate_shadowed_mission_state_result_artifact_sources).(sources)

    reports =
      Enum.map(sources, fn {_path, report} ->
        callback!(callbacks, :link_capacity_compact_summary_for_provenance).(report)
      end)

    directions = callback!(callbacks, :link_capacity_report_directions).(reports)

    %{
      "paths" => Enum.map(sources, fn {path, _report} -> path end),
      "contract" => callback!(callbacks, :link_capacity_input_summary_contract).(reports),
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
      "row_count" => count_sum(reports, callbacks, :link_capacity_report_row_count),
      "selected_shortfall_row_count" =>
        count_sum(reports, callbacks, :link_capacity_report_selected_shortfall_row_count),
      "actual_shortfall_row_count" =>
        count_sum(reports, callbacks, :link_capacity_report_actual_shortfall_row_count),
      "actual_throughput_row_count" =>
        count_sum(reports, callbacks, :link_capacity_report_actual_throughput_row_count),
      "capacity_adjusted_throughput_row_count" =>
        count_sum(
          reports,
          callbacks,
          :link_capacity_report_capacity_adjusted_throughput_row_count
        ),
      "capacity_adjusted_throughput_mb_total" =>
        numeric_total_sum(reports, callbacks, "capacity_adjusted_throughput_mb"),
      "selected_capacity_adjusted_throughput_mb_total" =>
        numeric_total_sum(reports, callbacks, "selected_capacity_adjusted_throughput_mb"),
      "unused_capacity_adjusted_throughput_mb_total" =>
        numeric_total_sum(reports, callbacks, "unused_capacity_adjusted_throughput_mb"),
      "ground_station_counts" =>
        count_map_merge(reports, callbacks, :link_capacity_report_ground_station_counts),
      "spacecraft_counts" =>
        count_map_merge(reports, callbacks, :link_capacity_report_spacecraft_counts),
      "capacity_adjusted_throughput_mb_by_ground_station" =>
        numeric_map_merge(
          reports,
          callbacks,
          :link_capacity_report_numeric_values_by_ground_station,
          "capacity_adjusted_throughput_mb"
        ),
      "selected_capacity_adjusted_throughput_mb_by_ground_station" =>
        numeric_map_merge(
          reports,
          callbacks,
          :link_capacity_report_numeric_values_by_ground_station,
          "selected_capacity_adjusted_throughput_mb"
        ),
      "unused_capacity_adjusted_throughput_mb_by_ground_station" =>
        numeric_map_merge(
          reports,
          callbacks,
          :link_capacity_report_numeric_values_by_ground_station,
          "unused_capacity_adjusted_throughput_mb"
        ),
      "capacity_adjusted_throughput_mb_by_direction" =>
        numeric_map_merge(
          reports,
          callbacks,
          :link_capacity_report_numeric_values_by_direction,
          "capacity_adjusted_throughput_mb"
        ),
      "selected_capacity_adjusted_throughput_mb_by_direction" =>
        numeric_map_merge(
          reports,
          callbacks,
          :link_capacity_report_numeric_values_by_direction,
          "selected_capacity_adjusted_throughput_mb"
        ),
      "unused_capacity_adjusted_throughput_mb_by_direction" =>
        numeric_map_merge(
          reports,
          callbacks,
          :link_capacity_report_numeric_values_by_direction,
          "unused_capacity_adjusted_throughput_mb"
        ),
      "direction_counts" =>
        count_map_merge(reports, callbacks, :link_capacity_report_direction_counts),
      "directions" => directions,
      "contact_ids_by_direction" =>
        string_list_map_merge(reports, callbacks, :link_capacity_report_contact_ids_by_direction),
      "source_window_ids_by_direction" =>
        string_list_map_merge(
          reports,
          callbacks,
          :link_capacity_report_source_window_ids_by_direction
        ),
      "station_calendar_entry_ids_by_direction" =>
        string_list_map_merge(
          reports,
          callbacks,
          :link_capacity_report_station_calendar_entry_ids_by_direction
        ),
      "station_calendar_provider_entry_ids_by_direction" =>
        string_list_map_merge(
          reports,
          callbacks,
          :link_capacity_report_station_calendar_provider_entry_ids_by_direction
        ),
      "direction_routing" =>
        callback!(callbacks, :link_capacity_report_direction_routing).(reports),
      "contact_ids_by_ground_station" =>
        string_list_map_merge(
          reports,
          callbacks,
          :link_capacity_report_contact_ids_by_ground_station
        ),
      "source_window_ids_by_ground_station" =>
        string_list_map_merge(
          reports,
          callbacks,
          :link_capacity_report_source_window_ids_by_ground_station
        ),
      "station_calendar_entry_ids_by_ground_station" =>
        string_list_map_merge(
          reports,
          callbacks,
          :link_capacity_report_station_calendar_entry_ids_by_ground_station
        ),
      "station_calendar_provider_entry_ids_by_ground_station" =>
        string_list_map_merge(
          reports,
          callbacks,
          :link_capacity_report_station_calendar_provider_entry_ids_by_ground_station
        ),
      "contact_ids_by_spacecraft" =>
        string_list_map_merge(reports, callbacks, :link_capacity_report_contact_ids_by_spacecraft),
      "source_window_ids_by_spacecraft" =>
        string_list_map_merge(
          reports,
          callbacks,
          :link_capacity_report_source_window_ids_by_spacecraft
        ),
      "station_calendar_entry_ids_by_spacecraft" =>
        string_list_map_merge(
          reports,
          callbacks,
          :link_capacity_report_station_calendar_entry_ids_by_spacecraft
        ),
      "station_calendar_provider_entry_ids_by_spacecraft" =>
        string_list_map_merge(
          reports,
          callbacks,
          :link_capacity_report_station_calendar_provider_entry_ids_by_spacecraft
        ),
      "selected_contact_ids" =>
        string_list_merge(reports, callbacks, :link_capacity_report_selected_contact_ids),
      "selected_source_window_ids" =>
        string_list_merge(reports, callbacks, :link_capacity_report_selected_source_window_ids),
      "selected_station_calendar_entry_ids" =>
        string_list_merge(
          reports,
          callbacks,
          :link_capacity_report_selected_station_calendar_entry_ids
        ),
      "selected_station_calendar_provider_entry_ids" =>
        string_list_merge(
          reports,
          callbacks,
          :link_capacity_report_selected_station_calendar_provider_entry_ids
        ),
      "selected_contact_id_counts" =>
        count_map_merge(reports, callbacks, :link_capacity_report_selected_contact_id_counts),
      "actual_throughput_contact_ids" =>
        string_list_merge(reports, callbacks, :link_capacity_report_actual_throughput_contact_ids),
      "actual_throughput_source_window_ids" =>
        string_list_merge(
          reports,
          callbacks,
          :link_capacity_report_actual_throughput_source_window_ids
        ),
      "actual_throughput_station_calendar_entry_ids" =>
        string_list_merge(
          reports,
          callbacks,
          :link_capacity_report_actual_throughput_station_calendar_entry_ids
        ),
      "actual_throughput_station_calendar_provider_entry_ids" =>
        string_list_merge(
          reports,
          callbacks,
          :link_capacity_report_actual_throughput_station_calendar_provider_entry_ids
        ),
      "actual_throughput_contact_id_counts" =>
        count_map_merge(
          reports,
          callbacks,
          :link_capacity_report_actual_throughput_contact_id_counts
        ),
      "downlink_requirement_status_counts" =>
        count_map_merge(reports, callbacks, :link_capacity_report_requirement_status_counts),
      "relay_route_count" =>
        reports
        |> count_sum(callbacks, :link_capacity_report_relay_route_count)
        |> non_zero_count(),
      "direct_downlink_route_count" =>
        reports
        |> count_sum(callbacks, :link_capacity_report_direct_downlink_route_count)
        |> non_zero_count(),
      "relay_route_ids" =>
        sorted_list_merge(reports, callbacks, :link_capacity_report_relay_route_ids),
      "source_spacecraft_ids" =>
        sorted_list_merge(reports, callbacks, :link_capacity_report_source_spacecraft_ids),
      "relay_spacecraft_ids" =>
        sorted_list_merge(reports, callbacks, :link_capacity_report_relay_spacecraft_ids),
      "ground_downlink_contact_ids" =>
        sorted_list_merge(reports, callbacks, :link_capacity_report_ground_downlink_contact_ids),
      "relay_custody_status_counts" =>
        count_map_merge(reports, callbacks, :link_capacity_report_relay_custody_status_counts),
      "relay_latency_status_counts" =>
        count_map_merge(reports, callbacks, :link_capacity_report_relay_latency_status_counts),
      "relay_risk_status_counts" =>
        count_map_merge(reports, callbacks, :link_capacity_report_relay_risk_status_counts),
      "relay_route_ids_by_custody_status" =>
        string_list_map_merge(
          reports,
          callbacks,
          :link_capacity_report_relay_route_ids_by_custody_status
        ),
      "relay_route_ids_by_latency_status" =>
        string_list_map_merge(
          reports,
          callbacks,
          :link_capacity_report_relay_route_ids_by_latency_status
        ),
      "relay_route_ids_by_risk_status" =>
        string_list_map_merge(
          reports,
          callbacks,
          :link_capacity_report_relay_route_ids_by_risk_status
        ),
      "relay_route_ids_by_ground_station" =>
        string_list_map_merge(
          reports,
          callbacks,
          :link_capacity_report_relay_route_ids_by_ground_station
        ),
      "contact_ids_by_requirement_status" =>
        string_list_map_merge(
          reports,
          callbacks,
          :link_capacity_report_contact_ids_by_requirement_status
        ),
      "source_window_ids_by_requirement_status" =>
        string_list_map_merge(
          reports,
          callbacks,
          :link_capacity_report_source_window_ids_by_requirement_status
        ),
      "station_calendar_entry_ids_by_requirement_status" =>
        string_list_map_merge(
          reports,
          callbacks,
          :link_capacity_report_station_calendar_entry_ids_by_requirement_status
        ),
      "station_calendar_provider_entry_ids_by_requirement_status" =>
        string_list_map_merge(
          reports,
          callbacks,
          :link_capacity_report_station_calendar_provider_entry_ids_by_requirement_status
        ),
      "trust_boundary_status" =>
        trust_boundary_status(
          reports,
          callback!(callbacks, :source_link_capacity_report_trust_boundaries)
        ),
      "trust_boundaries" =>
        callback!(callbacks, :source_link_capacity_report_trust_boundaries).(reports)
    }
    |> compact_map()
  end

  defp count_sum(reports, callbacks, key),
    do: sum_report_count(reports, callback!(callbacks, key))

  defp numeric_total_sum(reports, callbacks, field) do
    sum_report_numeric_values = callback!(callbacks, :sum_report_numeric_values)
    numeric_total = callback!(callbacks, :link_capacity_report_numeric_total)

    sum_report_numeric_values.(reports, &numeric_total.(&1, field))
  end

  defp numeric_map_merge(reports, callbacks, key, field) do
    extractor = callback!(callbacks, key)

    reports
    |> Enum.map(&extractor.(&1, field))
    |> merge_numeric_maps()
  end

  defp count_map_merge(reports, callbacks, key) do
    extractor = callback!(callbacks, key)

    reports
    |> Enum.map(extractor)
    |> merge_count_maps()
  end

  defp string_list_map_merge(reports, callbacks, key) do
    extractor = callback!(callbacks, key)

    reports
    |> Enum.map(extractor)
    |> merge_string_list_maps()
  end

  defp string_list_merge(reports, callbacks, key) do
    extractor = callback!(callbacks, key)

    reports
    |> Enum.map(extractor)
    |> merge_string_lists()
  end

  defp sorted_list_merge(reports, callbacks, key) do
    extractor = callback!(callbacks, key)

    reports
    |> Enum.flat_map(&(extractor.(&1) || []))
    |> sorted_non_empty_values()
  end

  defp trust_boundary_status(reports, trust_boundaries) when is_function(trust_boundaries, 1) do
    case trust_boundaries.(reports) do
      [] -> "missing"
      _trust_boundaries -> "declared"
    end
  end

  defp sorted_non_empty_values(values) do
    values
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      values -> values
    end
  end

  defp non_zero_count(count) when is_integer(count) and count > 0, do: count
  defp non_zero_count(_count), do: nil

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
