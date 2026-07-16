defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.InvalidInputs.FieldMap.CountFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceProjection.InvalidInputs

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [sum_report_count: 2]

  def fields(reports) do
    %{
      "invalid_activity_input_count" =>
        sum_report_count(
          reports,
          &InvalidInputs.invalid_activity_input_count/1
        ),
      "invalid_resource_summary_input_count" =>
        sum_report_count(
          reports,
          &InvalidInputs.invalid_resource_summary_input_count/1
        )
    }
  end
end
