defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.DirectionRouting.DirectionTokens do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue
  alias __MODULE__.{CandidateValues, NormalizedValues}

  def direction_token(row) do
    row
    |> EncodedValue.stringify_keys()
    |> CandidateValues.values()
    |> Enum.map(&NormalizedValues.normalize/1)
    |> Enum.find(&(&1 not in [nil, ""]))
  end
end
