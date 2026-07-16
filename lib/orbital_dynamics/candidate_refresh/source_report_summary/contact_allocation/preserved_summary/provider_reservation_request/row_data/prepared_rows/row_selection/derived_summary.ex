defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PreservedSummary.ProviderReservationRequest.RowData.PreparedRows.RowSelection.DerivedSummary do
  @moduledoc false

  alias OrbitalDynamics.Communications.ContactAllocation, as: CommunicationsContactAllocation

  def from_source_rows(summary, rows, true) do
    CommunicationsContactAllocation.provider_reservation_request_summary(%{
      "schema_contract" => "contact_allocation_report.v1",
      "source" => Map.get(summary, "source"),
      "rows" => rows
    })
  end

  def from_source_rows(summary, _rows, false), do: summary
end
