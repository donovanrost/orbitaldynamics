defmodule OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateSummaryReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateSourceSummaryFields
  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateSummaryReportDerivedFields

  def fields(%{} = summary) do
    derived_fields = QualityGateSummaryReportDerivedFields.fields(summary)

    summary
    |> QualityGateSourceSummaryFields.fields("preserved_operational_quality_gate_summary")
    |> Map.merge(%{
      "non_passed_quality_gate_row_ids" => summary["non_passed_quality_gate_row_ids"],
      "non_passed_gate_ids" => summary["non_passed_gate_ids"],
      "non_passed_gate_count" => summary["non_passed_gate_count"],
      "non_passed_rows" => summary["non_passed_rows"],
      "rows" => summary["rows"],
      "trust_boundary" => summary["trust_boundary"],
      "trust_boundaries" => summary["trust_boundaries"],
      "assumptions" => summary["assumptions"]
    })
    |> Map.merge(derived_fields)
  end
end
