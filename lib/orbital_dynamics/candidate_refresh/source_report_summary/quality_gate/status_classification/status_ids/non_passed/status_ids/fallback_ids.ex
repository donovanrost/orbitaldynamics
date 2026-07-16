defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.StatusClassification.StatusIds.NonPassed.StatusIds.FallbackIds do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.RowFallbackValues

  def gate_ids(report, status_ids) do
    ids_or_status_ids(report, "non_passed_gate_ids", status_ids)
  end

  def row_ids(report, status_ids) do
    ids_or_status_ids(report, "non_passed_quality_gate_row_ids", status_ids)
  end

  defp ids_or_status_ids(report, aggregate_field, status_ids) do
    case RowFallbackValues.string_list(report, aggregate_field) do
      [] -> status_ids.(report)
      ids -> ids
    end
  end
end
