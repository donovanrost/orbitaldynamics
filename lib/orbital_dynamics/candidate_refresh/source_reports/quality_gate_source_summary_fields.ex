defmodule OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateSourceSummaryFields do
  @moduledoc false

  def fields(summary, model) do
    %{
      "schema_contract" => "quality_gate_report.v1",
      "model" => model,
      "source" => summary["source"],
      "source_summary_model" => summary["model"],
      "source_summary_schema_contract" => summary["schema_contract"],
      "source_artifact_type" => summary["source_artifact_type"],
      "source_artifact_id" => summary["source_artifact_id"],
      "source_quality_gate_report_id" => summary["source_quality_gate_report_id"],
      "source_readiness_report_id" => summary["source_readiness_report_id"]
    }
  end
end
