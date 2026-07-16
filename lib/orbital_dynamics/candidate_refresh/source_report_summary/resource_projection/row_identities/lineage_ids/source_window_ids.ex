defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities.LineageIds.SourceWindowIds do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue
  alias __MODULE__.NormalizedValues
  alias __MODULE__.RawValues

  def values(row) do
    row = EncodedValue.stringify_keys(row)

    row
    |> RawValues.values()
    |> NormalizedValues.ids()
  end
end
