defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PreservedSummary.ProviderReservationRequest.RowData.PreparedRows.RowSelection do
  @moduledoc false

  alias __MODULE__.DerivedSummary
  alias __MODULE__.Rows

  def from_summary(summary, row_sources) do
    derived_summary =
      DerivedSummary.from_source_rows(
        summary,
        row_sources.rows,
        row_sources.source_summary_full_rows_present?
      )

    %{
      derived_summary: derived_summary,
      provider_reservation_request_rows:
        Rows.selected(
          derived_summary,
          row_sources.request_rows,
          "provider_reservation_request_rows",
          row_sources.source_summary_full_rows_present?
        ),
      provider_reservation_review_rows:
        Rows.selected(
          derived_summary,
          row_sources.review_rows,
          "provider_reservation_review_rows",
          row_sources.source_summary_full_rows_present?
        )
    }
  end
end
