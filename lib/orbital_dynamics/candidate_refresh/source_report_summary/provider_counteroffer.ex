defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ProviderCounteroffer do
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
    sources =
      callback!(callbacks, :deduplicate_shadowed_mission_state_result_artifact_sources).(sources)

    reports = Enum.map(sources, fn {_path, report} -> report end)

    %{
      "paths" => Enum.map(sources, fn {path, _report} -> path end),
      "contract" => callback!(callbacks, :provider_counteroffer_input_summary_contract).(reports),
      "count" => length(sources),
      "row_count" => count_sum(reports, callbacks, :provider_counteroffer_report_row_count),
      "reviewable_count" =>
        count_sum(reports, callbacks, :provider_counteroffer_report_reviewable_count),
      "counteroffer_cost_delta_count" =>
        count_sum(reports, callbacks, :provider_counteroffer_report_cost_delta_count),
      "counteroffer_cost_delta_total" =>
        reports
        |> Enum.map(callback!(callbacks, :provider_counteroffer_report_cost_delta_total))
        |> Enum.sum(),
      "counteroffer_timing_shift_count" =>
        count_sum(reports, callbacks, :provider_counteroffer_report_timing_shift_count),
      "counteroffer_start_delta_count" =>
        timing_delta_count(reports, callbacks, "provider_counteroffer_start_delta_s"),
      "counteroffer_end_delta_count" =>
        timing_delta_count(reports, callbacks, "provider_counteroffer_end_delta_s"),
      "counteroffer_duration_delta_count" =>
        timing_delta_count(reports, callbacks, "provider_counteroffer_duration_delta_s"),
      "counteroffer_lock_deadline_count" =>
        count_sum(reports, callbacks, :provider_counteroffer_report_lock_deadline_count),
      "earliest_counteroffer_lock_deadline_s" =>
        callback!(callbacks, :provider_counteroffer_report_earliest_lock_deadline_s).(reports),
      "counteroffer_status_counts" =>
        count_map_merge(reports, callbacks, :provider_counteroffer_report_status_counts),
      "required_operator_action_counts" =>
        count_map_merge(reports, callbacks, :provider_counteroffer_report_required_action_counts),
      "counteroffer_lock_deadline_status_counts" =>
        reports
        |> Enum.map(&lock_deadline_status_counts(&1, callbacks))
        |> merge_count_maps(),
      "counteroffer_ids_by_lock_deadline_status" =>
        reports
        |> Enum.map(&ids_by_lock_deadline_status(&1, callbacks))
        |> merge_string_list_maps(),
      "review_counteroffer_ids" =>
        reports
        |> Enum.flat_map(&Map.get(&1, "review_counteroffer_ids", []))
        |> sorted_string_values(),
      "trust_boundary_status" =>
        trust_boundary_status(
          reports,
          callback!(callbacks, :source_provider_counteroffer_report_trust_boundaries)
        ),
      "trust_boundaries" =>
        callback!(callbacks, :source_provider_counteroffer_report_trust_boundaries).(reports)
    }
    |> Map.merge(
      callback!(callbacks, :source_provider_counteroffer_import_readiness_summary_fields).(
        reports
      )
    )
    |> Map.merge(
      callback!(callbacks, :source_provider_counteroffer_plan_impact_summary_fields).(reports)
    )
    |> Map.merge(
      callback!(callbacks, :source_provider_counteroffer_review_summary_fields).(reports)
    )
    |> compact_map()
  end

  defp count_sum(reports, callbacks, key),
    do: sum_report_count(reports, callback!(callbacks, key))

  defp count_map_merge(reports, callbacks, key) do
    extractor = callback!(callbacks, key)

    reports
    |> Enum.map(extractor)
    |> merge_count_maps()
  end

  defp timing_delta_count(reports, callbacks, field) do
    timing_delta_count = callback!(callbacks, :provider_counteroffer_report_timing_delta_count)

    sum_report_count(reports, &timing_delta_count.(&1, field))
  end

  defp lock_deadline_status_counts(report, callbacks) do
    Map.get(report, "counteroffer_lock_deadline_status_counts") ||
      callback!(callbacks, :provider_counteroffer_report_row_counts).(
        report,
        "counteroffer_lock_deadline_status_counts",
        "provider_counteroffer_lock_deadline_status"
      )
  end

  defp ids_by_lock_deadline_status(report, callbacks) do
    Map.get(report, "counteroffer_ids_by_lock_deadline_status") ||
      callback!(callbacks, :provider_counteroffer_report_ids_by_row_field).(
        report,
        "provider_counteroffer_lock_deadline_status"
      )
  end

  defp trust_boundary_status(reports, trust_boundaries) when is_function(trust_boundaries, 1) do
    case trust_boundaries.(reports) do
      [] -> "missing"
      _trust_boundaries -> "declared"
    end
  end

  defp callback!(callbacks, key), do: Keyword.fetch!(callbacks, key)
end
