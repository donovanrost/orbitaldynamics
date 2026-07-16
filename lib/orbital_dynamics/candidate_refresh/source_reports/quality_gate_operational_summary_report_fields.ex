defmodule OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateOperationalSummaryReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateOperatorTrainingSummaryReportFields

  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateUnavailableResourceSummaryReportFields

  def unavailable_resource_fields(%{} = summary) do
    QualityGateUnavailableResourceSummaryReportFields.fields(summary)
  end

  def operator_training_fields(%{} = summary) do
    QualityGateOperatorTrainingSummaryReportFields.fields(summary)
  end
end
