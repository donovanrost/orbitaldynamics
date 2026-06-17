defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContentionResolution do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      compact_map: 1,
      count_report_field_values: 2,
      merge_count_maps: 1,
      merge_numeric_maps: 1,
      merge_string_list_maps: 1,
      merge_string_lists: 1,
      numeric_report_count: 2,
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
      "contract" =>
        callback!(callbacks, :contact_contention_resolution_input_summary_contract).(reports),
      "count" => length(sources),
      "source_summary_model_counts" => count_report_field_values(reports, "source_summary_model"),
      "source_summary_schema_contract_counts" =>
        count_report_field_values(reports, "source_summary_schema_contract"),
      "source_artifact_type_counts" => count_report_field_values(reports, "source_artifact_type"),
      "row_count" =>
        count_sum(reports, callbacks, :contact_contention_resolution_report_row_count),
      "conflict_group_count" =>
        sum_report_count(reports, &numeric_report_count(&1, "conflict_group_count")),
      "recommendation_count" =>
        count_sum(reports, callbacks, :contact_contention_resolution_report_recommendation_count),
      "review_recommendation_count" =>
        sum_report_count(reports, &numeric_report_count(&1, "review_recommendation_count")),
      "recommendation_group_ids" => sorted_field_values(reports, "recommendation_group_ids"),
      "review_group_ids" => sorted_field_values(reports, "review_group_ids"),
      "ambiguous_group_ids" => sorted_field_values(reports, "ambiguous_group_ids"),
      "ambiguous_duplicate_contact_ids" =>
        sorted_field_values(reports, "ambiguous_duplicate_contact_ids"),
      "ambiguous_duplicate_contact_ids_by_group_id" =>
        string_list_map_field_merge(reports, "ambiguous_duplicate_contact_ids_by_group_id"),
      "deferred_contact_count" =>
        count_sum(
          reports,
          callbacks,
          :contact_contention_resolution_report_deferred_contact_count
        ),
      "resolution_status_counts" =>
        count_map_merge(reports, callbacks, :contact_contention_resolution_report_status_counts),
      "selection_reason_counts" =>
        count_map_merge(
          reports,
          callbacks,
          :contact_contention_resolution_report_selection_reason_counts
        ),
      "capacity_pack_required_capacity_fraction" =>
        numeric_sum(
          reports,
          callbacks,
          :contact_contention_resolution_report_capacity_pack_required_fraction
        ),
      "capacity_pack_selected_required_capacity_fraction" =>
        numeric_sum(
          reports,
          callbacks,
          :contact_contention_resolution_report_capacity_pack_selected_required_fraction
        ),
      "capacity_pack_deferred_required_capacity_fraction" =>
        numeric_sum(
          reports,
          callbacks,
          :contact_contention_resolution_report_capacity_pack_deferred_required_fraction
        ),
      "capacity_pack_required_capacity_fraction_by_ground_station" =>
        numeric_map_merge(
          reports,
          callbacks,
          :contact_contention_resolution_report_capacity_pack_required_by_station
        ),
      "capacity_pack_selected_required_capacity_fraction_by_ground_station" =>
        numeric_map_merge(
          reports,
          callbacks,
          :contact_contention_resolution_report_capacity_pack_selected_by_station
        ),
      "capacity_pack_deferred_required_capacity_fraction_by_ground_station" =>
        numeric_map_merge(
          reports,
          callbacks,
          :contact_contention_resolution_report_capacity_pack_deferred_by_station
        ),
      "capacity_pack_required_capacity_fraction_by_status" =>
        numeric_map_field_merge(reports, "capacity_pack_required_capacity_fraction_by_status"),
      "required_capacity_fraction_source_counts" =>
        count_map_field_merge(reports, "required_capacity_fraction_source_counts"),
      "required_capacity_fraction_contact_ids_by_source" =>
        string_list_map_field_merge(reports, "required_capacity_fraction_contact_ids_by_source"),
      "selected_contact_ids" =>
        string_list_merge(
          reports,
          callbacks,
          :contact_contention_resolution_report_selected_contact_ids
        ),
      "selected_contact_ids_by_group_id" =>
        string_list_map_field_merge(reports, "selected_contact_ids_by_group_id"),
      "deferred_contact_ids" =>
        string_list_merge(
          reports,
          callbacks,
          :contact_contention_resolution_report_deferred_contact_ids
        ),
      "deferred_contact_ids_by_group_id" =>
        string_list_map_field_merge(reports, "deferred_contact_ids_by_group_id"),
      "review_contact_ids" => sorted_field_values(reports, "review_contact_ids"),
      "review_contact_ids_by_group_id" =>
        string_list_map_field_merge(reports, "review_contact_ids_by_group_id"),
      "selected_contact_ids_by_selection_reason" =>
        string_list_map_field_merge(reports, "selected_contact_ids_by_selection_reason"),
      "selected_contact_ids_by_ground_station" =>
        string_list_map_merge(
          reports,
          callbacks,
          :contact_contention_resolution_report_selected_contact_ids_by_station
        ),
      "deferred_contact_ids_by_ground_station" =>
        string_list_map_merge(
          reports,
          callbacks,
          :contact_contention_resolution_report_deferred_contact_ids_by_station
        ),
      "resource_scope_counts" => count_map_field_merge(reports, "resource_scope_counts"),
      "selected_contact_ids_by_resource_scope" =>
        string_list_map_field_merge(reports, "selected_contact_ids_by_resource_scope"),
      "deferred_contact_ids_by_resource_scope" =>
        string_list_map_field_merge(reports, "deferred_contact_ids_by_resource_scope"),
      "review_contact_ids_by_resource_scope" =>
        string_list_map_field_merge(reports, "review_contact_ids_by_resource_scope"),
      "direction_counts" =>
        count_map_merge(
          reports,
          callbacks,
          :contact_contention_resolution_report_direction_counts
        ),
      "contact_ids_by_direction" =>
        string_list_map_merge(
          reports,
          callbacks,
          :contact_contention_resolution_report_contact_ids_by_direction
        ),
      "direction_routing" =>
        callback!(callbacks, :contact_contention_resolution_direction_routing).(reports),
      "required_operator_action_counts" =>
        count_map_merge(
          reports,
          callbacks,
          :contact_contention_resolution_report_required_action_counts
        ),
      "review_contact_ids_by_action" =>
        string_list_map_field_merge(reports, "review_contact_ids_by_action"),
      "trust_boundary_status" =>
        trust_boundary_status(
          reports,
          callback!(callbacks, :source_contact_contention_resolution_report_trust_boundaries)
        ),
      "trust_boundaries" =>
        callback!(
          callbacks,
          :source_contact_contention_resolution_report_trust_boundaries
        ).(reports)
    }
    |> compact_map()
  end

  defp count_sum(reports, callbacks, key),
    do: sum_report_count(reports, callback!(callbacks, key))

  defp numeric_sum(reports, callbacks, key) do
    callback!(callbacks, :sum_report_numeric_values).(reports, callback!(callbacks, key))
  end

  defp count_map_merge(reports, callbacks, key) do
    extractor = callback!(callbacks, key)

    reports
    |> Enum.map(extractor)
    |> merge_count_maps()
  end

  defp count_map_field_merge(reports, field) do
    reports
    |> Enum.map(&Map.get(&1, field, %{}))
    |> merge_count_maps()
  end

  defp numeric_map_merge(reports, callbacks, key) do
    extractor = callback!(callbacks, key)

    reports
    |> Enum.map(extractor)
    |> merge_numeric_maps()
  end

  defp numeric_map_field_merge(reports, field) do
    reports
    |> Enum.map(&Map.get(&1, field, %{}))
    |> merge_numeric_maps()
  end

  defp string_list_map_merge(reports, callbacks, key) do
    extractor = callback!(callbacks, key)

    reports
    |> Enum.map(extractor)
    |> merge_string_list_maps()
  end

  defp string_list_map_field_merge(reports, field) do
    reports
    |> Enum.map(&Map.get(&1, field, %{}))
    |> merge_string_list_maps()
  end

  defp string_list_merge(reports, callbacks, key) do
    extractor = callback!(callbacks, key)

    reports
    |> Enum.map(extractor)
    |> merge_string_lists()
  end

  defp sorted_field_values(reports, field) do
    reports
    |> Enum.flat_map(&Map.get(&1, field, []))
    |> sorted_string_values()
    |> non_empty_list()
  end

  defp trust_boundary_status(reports, trust_boundaries) when is_function(trust_boundaries, 1) do
    case trust_boundaries.(reports) do
      [] -> "missing"
      _trust_boundaries -> "declared"
    end
  end

  defp non_empty_list([]), do: nil
  defp non_empty_list(list), do: list

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
