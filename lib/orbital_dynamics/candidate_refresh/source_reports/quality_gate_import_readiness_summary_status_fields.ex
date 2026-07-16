defmodule OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateImportReadinessSummaryStatusFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateImportReadinessSummaryStatus
  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateStatusFields

  def row_ids(%{} = row_ids_by_status, _summary, status) do
    QualityGateStatusFields.list_values(row_ids_by_status, status)
  end

  def row_ids(_row_ids_by_status, summary, "passed") do
    list_value(summary["ready_quality_gate_row_ids"])
  end

  def row_ids(_row_ids_by_status, summary, "review_required") do
    list_value(summary["review_required_quality_gate_row_ids"])
  end

  def row_ids(_row_ids_by_status, summary, "analysis_only") do
    list_value(summary["analysis_only_quality_gate_row_ids"])
  end

  def row_ids(_row_ids_by_status, summary, "blocked") do
    list_value(summary["blocked_quality_gate_row_ids"])
  end

  def row_count(row_ids_by_status, summary) do
    QualityGateStatusFields.row_count(row_ids_by_status, summary["import_readiness_row_count"])
  end

  def status(%{} = summary), do: QualityGateImportReadinessSummaryStatus.status(summary)

  def classification(status), do: QualityGateStatusFields.import_classification(status)

  def readiness_level(classification), do: QualityGateStatusFields.readiness_level(classification)

  def status_counts(row_ids_by_status),
    do: QualityGateStatusFields.status_counts(row_ids_by_status)

  def classification_counts(row_ids_by_status) do
    QualityGateStatusFields.classification_counts(row_ids_by_status)
  end

  defp list_value(values) when is_list(values), do: values
  defp list_value(_values), do: []
end
