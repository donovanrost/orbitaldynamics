defmodule OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateImportReadinessSummaryRowContextFields do
  @moduledoc false

  def fields(summary, ready_row_ids, review_row_ids, analysis_row_ids, blocked_row_ids) do
    %{
      "review_required_quality_gate_row_ids" => review_row_ids,
      "blocked_quality_gate_row_ids" => blocked_row_ids,
      "ready_quality_gate_row_ids" => ready_row_ids,
      "analysis_only_quality_gate_row_ids" => analysis_row_ids,
      "stale_or_unknown_freshness_quality_gate_row_ids" =>
        summary["stale_or_unknown_freshness_quality_gate_row_ids"],
      "import_preparation_quality_gate_row_ids" =>
        summary["import_preparation_quality_gate_row_ids"],
      "blocked_import_quality_gate_row_ids" => summary["blocked_import_quality_gate_row_ids"],
      "import_readiness_gate_ids" => summary["import_readiness_gate_ids"],
      "trust_boundary" => summary["trust_boundary"],
      "trust_boundaries" => summary["trust_boundaries"],
      "assumptions" => summary["assumptions"]
    }
  end
end
