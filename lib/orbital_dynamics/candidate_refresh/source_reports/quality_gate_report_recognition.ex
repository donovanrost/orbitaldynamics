defmodule OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateReportRecognition do
  @moduledoc false

  @gate_count_fields [
    "gate_count",
    "passed_gate_count",
    "review_gate_count",
    "analysis_gate_count",
    "blocked_gate_count",
    "gate_status_counts",
    "gate_classification_counts"
  ]

  def report?(%{} = report) do
    schema_contract = Map.get(report, "schema_contract") || Map.get(report, :schema_contract)
    readiness_level = Map.get(report, "readiness_level") || Map.get(report, :readiness_level)

    import_classification =
      Map.get(report, "import_classification") || Map.get(report, :import_classification)

    schema_contract in [nil, "quality_gate_report.v1"] and
      (readiness_level not in [nil, ""] or import_classification not in [nil, ""] or
         has_gate_counts?(report))
  end

  def report?(_report), do: false

  defp has_gate_counts?(report) do
    Enum.any?(@gate_count_fields, &Map.has_key?(report, &1))
  end
end
