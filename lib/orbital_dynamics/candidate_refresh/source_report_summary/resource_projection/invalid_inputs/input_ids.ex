defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.InvalidInputs.InputIds do
  @moduledoc false

  alias __MODULE__.IdValues

  def invalid_activity_input_ids(report) do
    IdValues.from_report(report, "invalid_activity_input_ids", "invalid_activity_inputs", [
      "activity_id",
      "subject_id",
      "id"
    ])
  end

  def invalid_resource_summary_input_ids(report) do
    IdValues.from_report(
      report,
      "invalid_resource_summary_input_ids",
      "invalid_resource_summary_inputs",
      ["resource_summary_id", "subject_id", "spacecraft_id", "id"]
    )
  end
end
