defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.InvalidInputs.InputIds.NormalizedValues do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [sorted_string_values: 1]

  def ids(values), do: sorted_string_values(values)
end
