defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.StatusClassification.StatusIds.StatusValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.RowFallbackValues
  alias __MODULE__.StatusMaps

  def gate_ids(report, status, fallback_field) do
    case ids_by_status_map(report) do
      %{} = ids_by_status ->
        StatusMaps.values(ids_by_status, status)

      _ids_by_status ->
        RowFallbackValues.string_list(report, fallback_field)
    end
  end

  def row_ids(report, status, fallback_field) do
    case row_ids_by_status_map(report) do
      %{} = row_ids_by_status ->
        StatusMaps.values(row_ids_by_status, status)

      _row_ids_by_status ->
        RowFallbackValues.string_list(report, fallback_field)
    end
  end

  def ids_by_status_map(report) do
    StatusMaps.gate_ids_by_status(report)
  end

  def row_ids_by_status_map(report) do
    StatusMaps.row_ids_by_status(report)
  end
end
