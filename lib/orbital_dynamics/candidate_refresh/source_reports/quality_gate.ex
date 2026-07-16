defmodule OrbitalDynamics.CandidateRefresh.SourceReports.QualityGate do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.EntryFallbacks
  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateEncoding
  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateReportRecognition
  alias OrbitalDynamics.CandidateRefresh.SourceReports.QualityGateSummaryReports

  def entries(path, value) do
    EntryFallbacks.entries(path, value, fn entry_path, entry_value ->
      report = QualityGateEncoding.stringify_keys(entry_value)

      cond do
        report?(report) ->
          {entry_path, report}

        QualityGateSummaryReports.summary?(report) ->
          {entry_path, QualityGateSummaryReports.report_from_summary(report)}

        QualityGateSummaryReports.unavailable_resource_summary?(report) ->
          {entry_path, QualityGateSummaryReports.report_from_unavailable_resource_summary(report)}

        QualityGateSummaryReports.operator_training_summary?(report) ->
          {entry_path, QualityGateSummaryReports.report_from_operator_training_summary(report)}

        QualityGateSummaryReports.schema_validation_summary?(report) ->
          {entry_path, QualityGateSummaryReports.report_from_schema_validation_summary(report)}

        QualityGateSummaryReports.import_readiness_summary?(report) ->
          {entry_path, QualityGateSummaryReports.report_from_import_readiness_summary(report)}

        true ->
          nil
      end
    end)
  end

  def report?(report), do: QualityGateReportRecognition.report?(report)
end
