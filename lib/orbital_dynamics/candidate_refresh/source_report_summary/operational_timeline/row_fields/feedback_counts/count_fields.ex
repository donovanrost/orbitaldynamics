defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalTimeline.RowFields.FeedbackCounts.CountFields do
  @moduledoc false

  alias __MODULE__.FieldSpecs

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [sum_report_count: 2]

  def fields(reports, counts_module) do
    Map.new(FieldSpecs.count_fields(), fn {field, count_function} ->
      {field, sum_report_count(reports, &apply(counts_module, count_function, [&1]))}
    end)
  end
end
