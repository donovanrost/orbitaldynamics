defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineDiffIntegrity.TimelineDiffFields.ChangeCounts.ChangedCounts.FieldDefinitions do
  @moduledoc false

  alias __MODULE__.FieldSpecs

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [sum_report_count: 2]

  def aggregate_fields(reports) do
    Map.new(FieldSpecs.all(), fn {field, _source_field, row_count} ->
      {field, sum_report_count(reports, row_count)}
    end)
  end

  def source_fields(report) do
    Map.new(FieldSpecs.all(), fn {_field, source_field, row_count} ->
      {source_field, row_count.(report)}
    end)
  end
end
