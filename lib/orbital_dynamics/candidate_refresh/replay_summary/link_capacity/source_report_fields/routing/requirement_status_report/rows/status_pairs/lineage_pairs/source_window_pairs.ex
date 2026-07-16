defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.RequirementStatusReport.Rows.StatusPairs.LineagePairs.SourceWindowPairs do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.RequirementStatusReport.Rows.StatusPairs.LineagePairs.PairRows

  alias __MODULE__.SourceWindowIds
  alias __MODULE__.SourceWindowIds.ContactIds

  def requirement_status_source_window_pairs(row) do
    PairRows.requirement_status_lineage_pairs(
      row,
      &selected_contact_source_window_ids/1,
      &actual_throughput_source_window_ids/1
    )
  end

  defp selected_contact_source_window_ids(row) do
    ContactIds.selected_contact_ids(row) || SourceWindowIds.row_source_window_ids(row)
  end

  defp actual_throughput_source_window_ids(row) do
    ContactIds.actual_throughput_contact_ids(row) ||
      SourceWindowIds.row_source_window_ids(row)
  end
end
