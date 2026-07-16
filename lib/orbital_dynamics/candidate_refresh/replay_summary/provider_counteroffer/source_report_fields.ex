defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ProviderCounteroffer.SourceReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ProviderCounteroffer
  alias __MODULE__.IdentityCore
  alias __MODULE__.PlanImpact
  alias __MODULE__.Pressure
  alias __MODULE__.ReviewImport

  def source_report_fields(source_reports) do
    summary =
      source_reports
      |> Map.get("provider_counteroffer_report", %{})
      |> ProviderCounteroffer.summary(
        "candidate_refresh.source_report_provenance.provider_counteroffer_report",
        "provider_counteroffer_source_report_provenance_only"
      )

    Pressure.source_report_fields(summary)
  end

  def source_report_summary_fields(source_reports) do
    source_reports
    |> source_report_fields()
    |> Map.merge(IdentityCore.fields(source_reports))
    |> Map.merge(ReviewImport.fields(source_reports))
    |> Map.merge(PlanImpact.fields(source_reports))
  end
end
