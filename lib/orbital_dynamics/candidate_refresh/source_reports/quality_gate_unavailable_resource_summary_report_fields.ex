defmodule OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateUnavailableResourceSummaryReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateSourceSummaryFields

  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateUnavailableResourceSummaryAvailabilityFields

  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateUnavailableResourceSummarySourceMetrics

  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateUnavailableResourceSummaryStatusFields

  def fields(%{} = summary) do
    row_ids_by_status = Map.get(summary, "quality_gate_row_ids_by_status")
    availability = availability_fields(summary, row_ids_by_status)
    source_metrics = QualityGateUnavailableResourceSummarySourceMetrics.fields(summary)

    summary
    |> QualityGateSourceSummaryFields.fields(
      "preserved_operational_quality_gate_unavailable_resource_summary"
    )
    |> Map.merge(
      QualityGateUnavailableResourceSummaryStatusFields.fields(
        summary,
        row_ids_by_status,
        availability
      )
    )
    |> Map.merge(source_metrics)
  end

  defp availability_fields(summary, row_ids_by_status) do
    QualityGateUnavailableResourceSummaryAvailabilityFields.fields(summary, row_ids_by_status)
  end
end
