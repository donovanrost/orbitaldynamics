defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.GateStatus.CountFields.GateCounts.NumericFields do
  @moduledoc false

  alias __MODULE__.FieldSpecs

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      numeric_report_count: 2,
      sum_report_count: 2
    ]

  def fields(reports) do
    Map.new(FieldSpecs.numeric_gate_count_fields(), fn field ->
      {field, sum_report_count(reports, &numeric_report_count(&1, field))}
    end)
  end
end
