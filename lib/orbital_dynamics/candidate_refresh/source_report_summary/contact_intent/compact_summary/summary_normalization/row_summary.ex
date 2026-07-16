defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.SummaryNormalization.RowSummary do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.SummaryNormalization.Rows
  alias OrbitalDynamics.Communications.ContactIntent, as: CommunicationsContactIntent

  def from_summary(summary) do
    case Rows.values(summary) do
      [] ->
        nil

      rows ->
        rows
        |> CommunicationsContactIntent.summary()
        |> Map.merge(Map.take(summary, ["provenance", "source"]))
    end
  end
end
