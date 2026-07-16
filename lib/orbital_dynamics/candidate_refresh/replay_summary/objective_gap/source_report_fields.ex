defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ObjectiveGap.SourceReportFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ObjectiveGap.Summary
  alias __MODULE__.Flattened
  alias __MODULE__.Pressure

  def source_report_fields(source_reports) do
    Summary.summary(
      Map.get(source_reports, "objective_satisfaction_report", %{}),
      Map.get(source_reports, "objective_tradeoff_report", %{}),
      Map.get(source_reports, "score_term_report", %{})
    )
    |> Pressure.source_report_fields()
    |> Map.merge(Flattened.fields(source_reports))
  end
end
