defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.RowIdentities.ActivityIds.StableValues do
  @moduledoc false

  alias __MODULE__.ResultValues

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.StableIds

  def ids(values) do
    values
    |> List.flatten()
    |> Enum.map(&StableIds.stable_id_or_nil/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
    |> ResultValues.non_empty()
  end
end
