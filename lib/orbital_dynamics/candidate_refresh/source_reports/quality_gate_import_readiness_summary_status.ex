defmodule OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateImportReadinessSummaryStatus do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [numeric_report_count: 2]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateStatusFields

  def status(%{} = summary) do
    case status_from_row_ids(summary["quality_gate_row_ids_by_status"]) do
      nil -> status_from_summary(summary)
      status -> status
    end
  end

  defp status_from_summary(%{} = summary) do
    cond do
      list_value(summary["blocked_quality_gate_row_ids"]) != [] or
        positive_summary_count?(summary, "blocked_import_count") or
          positive_summary_count?(summary, "invalid_cadence_import_count") ->
        "blocked"

      list_value(summary["analysis_only_quality_gate_row_ids"]) != [] ->
        "analysis_only"

      list_value(summary["review_required_quality_gate_row_ids"]) != [] or
        list_value(summary["stale_or_unknown_freshness_quality_gate_row_ids"]) != [] or
        list_value(summary["import_preparation_quality_gate_row_ids"]) != [] or
        positive_summary_count?(summary, "manifest_review_required_count") or
        positive_summary_count?(summary, "stale_freshness_count") or
          positive_summary_count?(summary, "unknown_freshness_count") ->
        "review_required"

      true ->
        "passed"
    end
  end

  defp status_from_row_ids(%{} = row_ids_by_status) do
    QualityGateStatusFields.status_from_row_ids(row_ids_by_status)
  end

  defp status_from_row_ids(_row_ids_by_status), do: nil

  defp positive_summary_count?(summary, field), do: numeric_report_count(summary, field) > 0

  defp list_value(values) when is_list(values), do: values
  defp list_value(_values), do: []
end
