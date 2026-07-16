defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.InvalidInputs.IdLists do
  @moduledoc false

  alias __MODULE__.NormalizedValues

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.InvalidInputs.InputIds

  def invalid_activity_input_ids(reports) do
    values(reports, &InputIds.invalid_activity_input_ids/1)
  end

  def invalid_resource_summary_input_ids(reports) do
    values(reports, &InputIds.invalid_resource_summary_input_ids/1)
  end

  defp values(reports, source_fun) do
    reports
    |> Enum.flat_map(source_fun)
    |> NormalizedValues.ids()
  end
end
