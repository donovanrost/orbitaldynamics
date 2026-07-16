defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PreservedSummary.ProviderReservationRequest.RowData.PreparedRows.RowSelection.Rows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PreservedSummary.ProviderReservationRequest.RowData.PreparedRows.NormalizedRows

  def selected(derived_summary, _fallback_rows, field, true) do
    NormalizedRows.values(derived_summary, field)
  end

  def selected(_derived_summary, fallback_rows, _field, false) do
    fallback_rows
  end
end
