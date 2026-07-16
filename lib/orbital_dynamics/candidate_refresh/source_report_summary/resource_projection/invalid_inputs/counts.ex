defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.InvalidInputs.Counts do
  @moduledoc false

  alias __MODULE__.CountValues

  def invalid_activity_input_count(report) do
    CountValues.count(report, "invalid_activity_input_count", "invalid_activity_inputs")
  end

  def invalid_resource_summary_input_count(report) do
    CountValues.count(
      report,
      "invalid_resource_summary_input_count",
      "invalid_resource_summary_inputs"
    )
  end
end
