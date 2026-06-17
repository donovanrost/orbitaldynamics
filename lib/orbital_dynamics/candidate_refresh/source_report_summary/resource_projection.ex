defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      compact_map: 1,
      count_report_field_values: 2,
      merge_count_maps: 1,
      merge_string_list_maps: 1,
      sorted_string_values: 1,
      sum_report_count: 2
    ]

  def report_input_summary([], _callbacks), do: nil

  def report_input_summary(sources, callbacks) do
    sources =
      callback!(callbacks, :deduplicate_shadowed_mission_state_result_artifact_sources).(sources)

    reports = Enum.map(sources, fn {_path, report} -> report end)

    resource_pressure_direction_counts =
      reports
      |> Enum.map(callback!(callbacks, :resource_projection_report_pressure_direction_counts))
      |> merge_count_maps()

    resource_pressure_activity_ids_by_direction =
      reports
      |> Enum.map(
        callback!(callbacks, :resource_projection_report_pressure_activity_ids_by_direction)
      )
      |> merge_string_list_maps()

    resource_pressure_directions =
      callback!(callbacks, :resource_projection_pressure_direction_keys).(
        resource_pressure_direction_counts,
        resource_pressure_activity_ids_by_direction
      )

    %{
      "paths" => Enum.map(sources, fn {path, _report} -> path end),
      "contract" => "resource_projection_report.v1",
      "count" => length(sources),
      "row_count" =>
        sum_report_count(reports, callback!(callbacks, :resource_projection_report_row_count)),
      "projected_resource_count" =>
        sum_report_count(
          reports,
          callback!(callbacks, :resource_projection_report_projected_resource_count)
        ),
      "source_artifact_type_counts" =>
        reports
        |> count_report_field_values("source_artifact_type"),
      "source_flow_summary_model_counts" =>
        reports
        |> count_report_field_values("source_flow_summary_model"),
      "invalid_activity_input_count" =>
        sum_report_count(
          reports,
          callback!(callbacks, :resource_projection_report_invalid_activity_input_count)
        ),
      "invalid_resource_summary_input_count" =>
        sum_report_count(
          reports,
          callback!(callbacks, :resource_projection_report_invalid_resource_summary_input_count)
        ),
      "invalid_activity_input_ids" =>
        reports
        |> Enum.flat_map(
          callback!(callbacks, :resource_projection_report_invalid_activity_input_ids)
        )
        |> sorted_string_values()
        |> non_empty_list(),
      "invalid_resource_summary_input_ids" =>
        reports
        |> Enum.flat_map(
          callback!(callbacks, :resource_projection_report_invalid_resource_summary_input_ids)
        )
        |> sorted_string_values()
        |> non_empty_list(),
      "resource_pressure_status_counts" =>
        reports
        |> Enum.map(callback!(callbacks, :resource_projection_report_pressure_status_counts))
        |> merge_count_maps(),
      "ground_station_counts" =>
        reports
        |> Enum.map(callback!(callbacks, :resource_projection_report_ground_station_counts))
        |> merge_count_maps(),
      "resource_projection_spacecraft_counts" =>
        reports
        |> Enum.map(callback!(callbacks, :resource_projection_report_spacecraft_counts))
        |> merge_count_maps(),
      "resource_pressure_type_counts" =>
        reports
        |> Enum.map(callback!(callbacks, :resource_projection_report_pressure_type_counts))
        |> merge_count_maps(),
      "resource_pressure_activity_id_counts" =>
        reports
        |> Enum.map(callback!(callbacks, :resource_projection_report_pressure_activity_id_counts))
        |> merge_count_maps(),
      "resource_pressure_activity_ids_by_status" =>
        reports
        |> Enum.map(
          callback!(callbacks, :resource_projection_report_pressure_activity_ids_by_status)
        )
        |> merge_string_list_maps(),
      "resource_pressure_activity_ids_by_type" =>
        reports
        |> Enum.map(
          callback!(callbacks, :resource_projection_report_pressure_activity_ids_by_type)
        )
        |> merge_string_list_maps(),
      "resource_pressure_activity_ids_by_ground_station" =>
        reports
        |> Enum.map(
          callback!(
            callbacks,
            :resource_projection_report_pressure_activity_ids_by_ground_station
          )
        )
        |> merge_string_list_maps(),
      "resource_pressure_activity_ids_by_spacecraft" =>
        reports
        |> Enum.map(
          callback!(callbacks, :resource_projection_report_pressure_activity_ids_by_spacecraft)
        )
        |> merge_string_list_maps(),
      "resource_pressure_direction_counts" => resource_pressure_direction_counts,
      "resource_pressure_directions" => resource_pressure_directions,
      "resource_pressure_activity_ids_by_direction" =>
        resource_pressure_activity_ids_by_direction,
      "resource_pressure_direction_routing" =>
        callback!(callbacks, :resource_projection_pressure_direction_routing).(
          resource_pressure_direction_counts,
          resource_pressure_activity_ids_by_direction
        ),
      "resource_pressure_ground_station_ids_by_type" =>
        reports
        |> Enum.map(
          callback!(callbacks, :resource_projection_report_pressure_ground_station_ids_by_type)
        )
        |> merge_string_list_maps(),
      "resource_pressure_source_window_ids_by_status" =>
        reports
        |> Enum.map(
          callback!(callbacks, :resource_projection_report_pressure_source_window_ids_by_status)
        )
        |> merge_string_list_maps(),
      "resource_pressure_source_window_ids_by_type" =>
        reports
        |> Enum.map(
          callback!(callbacks, :resource_projection_report_pressure_source_window_ids_by_type)
        )
        |> merge_string_list_maps(),
      "resource_pressure_station_calendar_entry_ids_by_status" =>
        reports
        |> Enum.map(
          callback!(
            callbacks,
            :resource_projection_report_pressure_station_calendar_entry_ids_by_status
          )
        )
        |> merge_string_list_maps(),
      "resource_pressure_station_calendar_entry_ids_by_type" =>
        reports
        |> Enum.map(
          callback!(
            callbacks,
            :resource_projection_report_pressure_station_calendar_entry_ids_by_type
          )
        )
        |> merge_string_list_maps(),
      "resource_pressure_station_calendar_provider_ids_by_status" =>
        reports
        |> Enum.map(
          callback!(
            callbacks,
            :resource_projection_report_pressure_station_calendar_provider_ids_by_status
          )
        )
        |> merge_string_list_maps(),
      "resource_pressure_station_calendar_provider_ids_by_type" =>
        reports
        |> Enum.map(
          callback!(
            callbacks,
            :resource_projection_report_pressure_station_calendar_provider_ids_by_type
          )
        )
        |> merge_string_list_maps(),
      "resource_pressure_station_calendar_provider_entry_ids_by_status" =>
        reports
        |> Enum.map(
          callback!(
            callbacks,
            :resource_projection_report_pressure_station_calendar_provider_entry_ids_by_status
          )
        )
        |> merge_string_list_maps(),
      "resource_pressure_station_calendar_provider_entry_ids_by_type" =>
        reports
        |> Enum.map(
          callback!(
            callbacks,
            :resource_projection_report_pressure_station_calendar_provider_entry_ids_by_type
          )
        )
        |> merge_string_list_maps(),
      "trust_boundary_status" =>
        trust_boundary_status(
          reports,
          callback!(callbacks, :source_resource_projection_report_trust_boundaries)
        ),
      "trust_boundaries" =>
        callback!(callbacks, :source_resource_projection_report_trust_boundaries).(reports)
    }
    |> compact_map()
  end

  defp trust_boundary_status(reports, trust_boundaries) when is_function(trust_boundaries, 1) do
    case trust_boundaries.(reports) do
      [] -> "missing"
      _trust_boundaries -> "declared"
    end
  end

  defp non_empty_list([]), do: nil
  defp non_empty_list(values), do: values

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
