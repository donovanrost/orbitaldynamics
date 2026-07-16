defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.SummaryNormalization.Rows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  def values(summary) do
    summary
    |> Map.get("rows", [])
    |> List.wrap()
    |> Enum.filter(&is_map/1)
    |> Enum.map(&EncodedValue.stringify_keys/1)
  end
end
