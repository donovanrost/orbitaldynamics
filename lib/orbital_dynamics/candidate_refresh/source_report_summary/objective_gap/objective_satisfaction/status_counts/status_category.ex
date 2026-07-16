defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ObjectiveGap.ObjectiveSatisfaction.StatusCounts.StatusCategory do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.NormalizedToken
  alias __MODULE__.Groups

  def value(status) when is_boolean(status), do: if(status, do: "met", else: "unmet")

  def value(status) do
    status
    |> NormalizedToken.value()
    |> Groups.value()
  end
end
