defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.BaseFields.CompactSourceCounts do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.ContactCounts

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [report_count: 1]

  def row_count(summaries) do
    summaries
    |> Enum.map(&ContactCounts.contact_count/1)
    |> Enum.sum()
    |> report_count()
  end

  def capacity_pack_required_contact_count(summaries) do
    summaries
    |> Enum.map(&ContactCounts.capacity_pack_contact_count/1)
    |> Enum.sum()
    |> report_count()
  end
end
