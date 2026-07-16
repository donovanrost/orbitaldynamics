defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.Assembly.ReadinessValidationFields.ValidationFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.Validation.Freshness,
    as: FreshnessFields

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.Validation.RefreshBudget,
    as: RefreshBudgetFields

  alias __MODULE__.ValidationReportFields

  def fields(refresh_or_artifact, source_reports) do
    FreshnessFields.source_report_fields(
      refresh_or_artifact,
      source_reports
    )
    |> Map.merge(
      RefreshBudgetFields.source_report_fields(
        refresh_or_artifact,
        source_reports
      )
    )
    |> Map.merge(ValidationReportFields.fields(refresh_or_artifact, source_reports))
  end
end
