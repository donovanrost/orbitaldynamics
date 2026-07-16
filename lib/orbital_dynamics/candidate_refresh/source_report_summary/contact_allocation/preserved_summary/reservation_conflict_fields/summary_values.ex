defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PreservedSummary.ReservationConflictFields.SummaryValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PreservedSummary.ReservationConflictFields.ContactIds

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      numeric_report_count: 2,
      sorted_string_values: 1
    ]

  def contact_count(summary) do
    case ContactIds.count(summary) do
      nil -> numeric_report_count(summary, "reservation_conflict_contact_count")
      count -> count
    end
  end

  def sorted_strings(summary, field) do
    summary
    |> Map.get(field, [])
    |> sorted_string_values()
  end
end
