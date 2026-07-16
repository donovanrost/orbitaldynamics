defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.ReadinessSupport.ReadinessFields.ImportReadiness.IdFields do
  @moduledoc false

  def all do
    [
      "freshness_status_ids",
      "import_status_ids",
      "cadence_import_status_ids",
      "stale_or_unknown_freshness_quality_gate_row_ids",
      "import_preparation_quality_gate_row_ids",
      "blocked_import_quality_gate_row_ids",
      "import_readiness_gate_ids"
    ]
  end
end
