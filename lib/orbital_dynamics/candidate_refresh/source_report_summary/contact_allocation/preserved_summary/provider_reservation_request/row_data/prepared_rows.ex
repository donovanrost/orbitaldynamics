defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PreservedSummary.ProviderReservationRequest.RowData.PreparedRows do
  @moduledoc false

  alias __MODULE__.{RowSelection, RowSources}

  def prepare(%{} = summary) do
    row_sources = RowSources.from_summary(summary)
    selected_rows = RowSelection.from_summary(summary, row_sources)

    %{
      rows: row_sources.rows,
      derived_summary: selected_rows.derived_summary,
      source_summary_full_rows_present?: row_sources.source_summary_full_rows_present?,
      provider_reservation_request_rows: selected_rows.provider_reservation_request_rows,
      provider_reservation_review_rows: selected_rows.provider_reservation_review_rows
    }
  end
end
