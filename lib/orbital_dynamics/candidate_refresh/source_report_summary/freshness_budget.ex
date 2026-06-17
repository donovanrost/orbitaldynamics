defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.FreshnessBudget do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      compact_map: 1,
      count_source_report_values: 1,
      count_values: 1,
      numeric_report_count: 2,
      sorted_string_values: 1,
      source_report_trust_boundaries: 1,
      source_report_trust_boundary_status: 1,
      sum_report_count: 2
    ]

  def freshness_report_input_summary([]), do: nil

  def freshness_report_input_summary(sources) do
    reports = Enum.map(sources, fn {_path, report} -> report end)
    stale_reasons = reports |> Enum.flat_map(&freshness_report_stale_reasons/1)
    unknown_reasons = reports |> Enum.flat_map(&freshness_report_unknown_reasons/1)

    %{
      "paths" => Enum.map(sources, fn {path, _report} -> path end),
      "contract" => "freshness_report.v1",
      "count" => length(sources),
      "row_count" => length(sources),
      "status_counts" =>
        reports
        |> Enum.map(&freshness_report_status/1)
        |> Enum.reject(&(&1 in [nil, ""]))
        |> Enum.frequencies(),
      "stale_reason_count" => sum_report_count(reports, &freshness_report_stale_reason_count/1),
      "stale_reasons" =>
        case sorted_string_values(stale_reasons) do
          [] -> nil
          reasons -> reasons
        end,
      "stale_reason_counts" => count_source_report_values(stale_reasons),
      "unknown_reason_count" =>
        sum_report_count(reports, &freshness_report_unknown_reason_count/1),
      "unknown_reasons" =>
        case sorted_string_values(unknown_reasons) do
          [] -> nil
          reasons -> reasons
        end,
      "unknown_reason_counts" => count_source_report_values(unknown_reasons),
      "trust_boundary_status" => source_report_trust_boundary_status(reports),
      "trust_boundaries" => source_report_trust_boundaries(reports)
    }
    |> compact_map()
  end

  def refresh_budget_report_input_summary([]), do: nil

  def refresh_budget_report_input_summary(sources) do
    reports = Enum.map(sources, fn {_path, report} -> report end)

    %{
      "paths" => Enum.map(sources, fn {path, _report} -> path end),
      "contract" => "refresh_budget_report.v1",
      "count" => length(sources),
      "row_count" => length(sources),
      "input_candidate_count" =>
        sum_report_count(reports, &numeric_report_count(&1, "input_candidate_count")),
      "kept_candidate_count" =>
        sum_report_count(reports, &numeric_report_count(&1, "kept_candidate_count")),
      "dropped_candidate_count" =>
        sum_report_count(reports, &numeric_report_count(&1, "dropped_candidate_count")),
      "invalid_candidate_limit_policy_count" =>
        Enum.count(reports, &(Map.get(&1, "invalid_candidate_limit_policy") == true)),
      "invalid_candidate_limit_policy_reason_counts" =>
        reports
        |> Enum.map(&Map.get(&1, "invalid_candidate_limit_policy_reason"))
        |> count_values(),
      "kept_candidate_ids" =>
        reports
        |> Enum.flat_map(&Map.get(&1, "kept_candidate_ids", []))
        |> sorted_string_values(),
      "dropped_candidate_ids" =>
        reports
        |> Enum.flat_map(&Map.get(&1, "dropped_candidate_ids", []))
        |> sorted_string_values(),
      "trust_boundary_status" => source_report_trust_boundary_status(reports),
      "trust_boundaries" => source_report_trust_boundaries(reports)
    }
    |> compact_map()
  end

  defp freshness_report_status(report) do
    Map.get(report, "status") || Map.get(report, "freshness_status")
  end

  defp freshness_report_stale_reasons(report) do
    list_value(Map.get(report, "stale_reasons")) ++
      Map.keys(Map.get(report, "stale_reason_counts") || %{})
  end

  defp freshness_report_unknown_reasons(report) do
    list_value(Map.get(report, "unknown_reasons")) ++
      Map.keys(Map.get(report, "unknown_reason_counts") || %{})
  end

  defp freshness_report_stale_reason_count(report),
    do: length(freshness_report_stale_reasons(report))

  defp freshness_report_unknown_reason_count(report),
    do: length(freshness_report_unknown_reasons(report))

  defp list_value(values) when is_list(values), do: values
  defp list_value(_values), do: []
end
