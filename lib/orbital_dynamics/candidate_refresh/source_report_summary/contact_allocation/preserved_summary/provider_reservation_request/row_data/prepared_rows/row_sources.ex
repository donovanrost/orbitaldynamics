defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PreservedSummary.ProviderReservationRequest.RowData.PreparedRows.RowSources do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PreservedSummary.ProviderReservationRequest.RowData.PreparedRows.NormalizedRows

  def from_summary(summary) do
    source_rows = NormalizedRows.values(summary, "rows")
    request_rows = NormalizedRows.values(summary, "provider_reservation_request_rows")
    review_rows = NormalizedRows.values(summary, "provider_reservation_review_rows")

    %{
      rows: rows(source_rows, request_rows, review_rows),
      request_rows: request_rows,
      review_rows: review_rows,
      source_summary_full_rows_present?: source_rows != []
    }
  end

  defp rows([], request_rows, review_rows), do: request_rows ++ review_rows
  defp rows(source_rows, _request_rows, _review_rows), do: source_rows
end
