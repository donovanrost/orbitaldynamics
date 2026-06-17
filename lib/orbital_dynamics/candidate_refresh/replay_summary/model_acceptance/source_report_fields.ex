defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ModelAcceptance.SourceReportFields do
  @moduledoc false

  alias __MODULE__.Flattened

  def source_report_fields(source_reports, pressure_fields) do
    %{
      "source_report_model_acceptance_branch_local_review_pressure" =>
        Map.get(pressure_fields, "branch_local_review_pressure"),
      "source_report_model_acceptance_branch_local_blocking_pressure" =>
        Map.get(pressure_fields, "branch_local_blocking_pressure"),
      "source_report_model_acceptance_branch_local_unknown_model_pressure" =>
        Map.get(pressure_fields, "branch_local_unknown_model_pressure")
    }
    |> Map.merge(Flattened.fields(source_reports))
  end
end
