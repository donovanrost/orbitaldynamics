defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.ReadinessSupport.AdapterBoundaryFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.RowFallbackValues

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1,
      sum_report_count: 2
    ]

  def fields(reports) do
    %{
      "adapter_context_count" =>
        sum_report_count(reports, &RowFallbackValues.count(&1, "adapter_context_count")),
      "adapter_trust_boundary_declared_count" =>
        sum_report_count(
          reports,
          &RowFallbackValues.count(&1, "adapter_trust_boundary_declared_count")
        ),
      "adapter_trust_boundary_missing_count" =>
        sum_report_count(
          reports,
          &RowFallbackValues.count(&1, "adapter_trust_boundary_missing_count")
        ),
      "adapter_trust_boundary_untrusted_count" =>
        sum_report_count(
          reports,
          &RowFallbackValues.count(&1, "adapter_trust_boundary_untrusted_count")
        ),
      "adapter_boundary_status_counts" =>
        reports
        |> Enum.map(&RowFallbackValues.count_map(&1, "adapter_boundary_status_counts"))
        |> merge_count_maps()
    }
  end
end
