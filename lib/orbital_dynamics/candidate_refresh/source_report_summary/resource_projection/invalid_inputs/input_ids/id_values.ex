defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.InvalidInputs.InputIds.IdValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.InvalidInputs.InputIds.NormalizedValues

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.InvalidInputs.InputIds.Values

  def from_report(report, ids_field, inputs_field, fallback_keys) do
    report
    |> Values.invalid_values(ids_field, inputs_field, fallback_keys)
    |> NormalizedValues.ids()
  end
end
