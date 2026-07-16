defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ModelAcceptance.SourceReportFields.Pressure do
  @moduledoc false

  def source_report_fields(pressure_fields) do
    %{
      "source_report_model_acceptance_branch_local_review_pressure" =>
        Map.get(pressure_fields, "branch_local_review_pressure"),
      "source_report_model_acceptance_branch_local_blocking_pressure" =>
        Map.get(pressure_fields, "branch_local_blocking_pressure"),
      "source_report_model_acceptance_branch_local_unknown_model_pressure" =>
        Map.get(pressure_fields, "branch_local_unknown_model_pressure")
    }
  end
end
