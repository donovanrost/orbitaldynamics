defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.DirectionRouting.DirectionTokens.Aliases.FallbackValues do
  @moduledoc false

  def normalized("nil"), do: nil
  def normalized(""), do: nil
  def normalized(value), do: value
end
