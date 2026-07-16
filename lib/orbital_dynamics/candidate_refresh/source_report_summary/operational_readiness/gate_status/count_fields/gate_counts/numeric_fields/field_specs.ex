defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.GateStatus.CountFields.GateCounts.NumericFields.FieldSpecs do
  @moduledoc false

  @numeric_gate_count_fields [
    "passed_gate_count",
    "review_gate_count",
    "analysis_gate_count",
    "blocked_gate_count",
    "non_passed_gate_count"
  ]

  def numeric_gate_count_fields, do: @numeric_gate_count_fields
end
