defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities.StableEntityIds.StableValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.StableIds

  def id(value), do: StableIds.stable_id_or_nil(value)
end
