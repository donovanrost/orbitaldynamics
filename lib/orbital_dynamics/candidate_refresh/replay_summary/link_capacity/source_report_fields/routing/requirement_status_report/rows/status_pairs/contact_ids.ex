defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.LinkCapacity.SourceReportFields.Routing.RequirementStatusReport.Rows.StatusPairs.ContactIds do
  @moduledoc false

  alias __MODULE__.RowContactIds

  @selected_contact_fields [
    "selected_contact_ids",
    "selected_contact_id",
    "selected_contacts",
    "selected_contact"
  ]

  @actual_throughput_contact_fields [
    "actual_throughput_contact_ids",
    "actual_throughput_contact_id",
    "actual_throughput_contacts",
    "actual_throughput_contact"
  ]

  def selected_contact_ids(row) do
    RowContactIds.row_contact_ids(row, @selected_contact_fields)
  end

  def actual_throughput_contact_ids(row) do
    RowContactIds.row_contact_ids(row, @actual_throughput_contact_fields)
  end
end
