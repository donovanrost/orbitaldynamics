defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.StatusClassification.GateCounts.FieldSpecs do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.StatusClassification.GateCounts.RowValues

  def all do
    [
      {:scalar, "row_count", &RowValues.quality_gate_row_count/1},
      {:scalar, "gate_count", &RowValues.gate_count/1},
      {:status, "passed_gate_count", "passed"},
      {:status, "review_gate_count", "review_required"},
      {:status, "analysis_gate_count", "analysis_only"},
      {:count_map, "analysis_mode_counts", &RowValues.analysis_mode_counts/1},
      {:status, "blocked_gate_count", "blocked"},
      {:count_map, "gate_status_counts", &RowValues.gate_status_counts/1},
      {:count_map, "gate_classification_counts", &RowValues.gate_classification_counts/1}
    ]
  end
end
