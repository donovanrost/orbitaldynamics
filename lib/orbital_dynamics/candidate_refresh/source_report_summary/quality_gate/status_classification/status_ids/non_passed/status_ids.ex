defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.StatusClassification.StatusIds.NonPassed.StatusIds do
  @moduledoc false

  alias __MODULE__.FallbackIds
  alias __MODULE__.StatusLists

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.StatusClassification.StatusIds.StatusValues

  def gate_ids(report) do
    case StatusValues.ids_by_status_map(report) do
      %{} ->
        StatusLists.gate_ids(report)

      _ids_by_status ->
        FallbackIds.gate_ids(report, &StatusLists.gate_ids/1)
    end
  end

  def row_ids(report) do
    case StatusValues.row_ids_by_status_map(report) do
      %{} ->
        StatusLists.row_ids(report)

      _row_ids_by_status ->
        FallbackIds.row_ids(report, &StatusLists.row_ids/1)
    end
  end
end
