defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalTimeline.RowFields.BaseFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalTimeline.RowFields.{
    RowValues,
    SourceContext
  }

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [sum_report_count: 2]

  def fields(reports) do
    %{
      "row_count" => sum_report_count(reports, &RowValues.row_count/1),
      "input_keys" => SourceContext.input_keys(reports),
      "trust_boundary_status" => SourceContext.trust_boundary_status(reports),
      "trust_boundaries" => SourceContext.trust_boundaries(reports)
    }
  end
end
