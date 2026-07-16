defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.InvalidInputs do
  @moduledoc false

  alias __MODULE__.{Counts, FieldMap}

  def fields(reports) do
    FieldMap.fields(reports)
  end

  def invalid_activity_input_count(report) do
    Counts.invalid_activity_input_count(report)
  end

  def invalid_resource_summary_input_count(report) do
    Counts.invalid_resource_summary_input_count(report)
  end
end
