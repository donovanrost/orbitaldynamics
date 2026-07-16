defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.StatusClassification.StatusIds.IdMaps.FieldSpecs do
  @moduledoc false

  def all do
    [
      {"quality_gate_row_ids_by_classification", nil},
      {"quality_gate_ids_by_classification", "gate_ids_by_classification"},
      {"quality_gate_row_ids_by_status", nil},
      {"quality_gate_ids_by_status", nil}
    ]
  end
end
