defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ModelValidationDirectReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ModelAcceptance
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ValidationSafetyCase

  def model_acceptance_reports(refresh) do
    [
      {"accepted_planning_state.source_model_acceptance_report",
       get_in(refresh, ["accepted_planning_state", "source_model_acceptance_report"])},
      {"accepted_planning_state.model_acceptance_report",
       get_in(refresh, ["accepted_planning_state", "model_acceptance_report"])},
      {"mission_state.source_model_acceptance_report",
       get_in(refresh, ["mission_state", "source_model_acceptance_report"])},
      {"mission_state.model_acceptance_report",
       get_in(refresh, ["mission_state", "model_acceptance_report"])},
      {"source_model_acceptance_report", Map.get(refresh, "source_model_acceptance_report")},
      {"model_acceptance_report", Map.get(refresh, "model_acceptance_report")}
    ]
    |> Enum.flat_map(fn {path, report_or_reports} ->
      ModelAcceptance.entries(path, report_or_reports)
    end)
  end

  def validation_safety_case_summaries(refresh) do
    [
      {"accepted_planning_state.source_validation_safety_case_summary",
       get_in(refresh, ["accepted_planning_state", "source_validation_safety_case_summary"])},
      {"accepted_planning_state.validation_safety_case_summary",
       get_in(refresh, ["accepted_planning_state", "validation_safety_case_summary"])},
      {"mission_state.source_validation_safety_case_summary",
       get_in(refresh, ["mission_state", "source_validation_safety_case_summary"])},
      {"mission_state.validation_safety_case_summary",
       get_in(refresh, ["mission_state", "validation_safety_case_summary"])},
      {"source_validation_safety_case_summary",
       Map.get(refresh, "source_validation_safety_case_summary")},
      {"validation_safety_case_summary", Map.get(refresh, "validation_safety_case_summary")}
    ]
    |> Enum.flat_map(fn {path, report_or_reports} ->
      ValidationSafetyCase.entries(path, report_or_reports)
    end)
  end
end
