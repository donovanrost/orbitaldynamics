defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.ContactCounts.SourceFirstCount do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.ContactCounts.FallbackCount

  def value(summary, nil, fallback_field), do: FallbackCount.value(summary, fallback_field)
  def value(_summary, count, _fallback_field), do: count
end
