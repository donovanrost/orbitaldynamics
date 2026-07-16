defmodule OrbitalDynamics.CandidateRefresh.SourceReports.OperationalReadinessReportPredicate do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.OperationalReadinessSummaryReports

  def report?(%{} = report) do
    schema_contract = Map.get(report, "schema_contract") || Map.get(report, :schema_contract)
    readiness_level = Map.get(report, "readiness_level") || Map.get(report, :readiness_level)

    import_classification =
      Map.get(report, "import_classification") || Map.get(report, :import_classification)

    source_summary_schema_contract =
      Map.get(report, "source_summary_schema_contract") ||
        Map.get(report, :source_summary_schema_contract)

    (schema_contract in [nil, "operational_readiness_report.v1"] and
       (readiness_level not in [nil, ""] or import_classification not in [nil, ""])) or
      OperationalReadinessSummaryReports.summary_contract?(source_summary_schema_contract)
  end

  def report?(_report), do: false
end
