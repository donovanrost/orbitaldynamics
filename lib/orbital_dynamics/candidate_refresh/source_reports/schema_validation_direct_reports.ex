defmodule OrbitalDynamics.CandidateRefresh.SourceReports.SchemaValidationDirectReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.SchemaValidation

  def reports(refresh) do
    [
      {"accepted_planning_state.source_schema_validation_report",
       get_in(refresh, ["accepted_planning_state", "source_schema_validation_report"])},
      {"accepted_planning_state.schema_validation_report",
       get_in(refresh, ["accepted_planning_state", "schema_validation_report"])},
      {"mission_state.source_schema_validation_report",
       get_in(refresh, ["mission_state", "source_schema_validation_report"])},
      {"mission_state.schema_validation_report",
       get_in(refresh, ["mission_state", "schema_validation_report"])},
      {"accepted_planning_state.source_schema_validation_batch_report",
       get_in(refresh, ["accepted_planning_state", "source_schema_validation_batch_report"])},
      {"accepted_planning_state.schema_validation_batch_report",
       get_in(refresh, ["accepted_planning_state", "schema_validation_batch_report"])},
      {"mission_state.source_schema_validation_batch_report",
       get_in(refresh, ["mission_state", "source_schema_validation_batch_report"])},
      {"mission_state.schema_validation_batch_report",
       get_in(refresh, ["mission_state", "schema_validation_batch_report"])},
      {"source_schema_validation_report", Map.get(refresh, "source_schema_validation_report")},
      {"schema_validation_report", Map.get(refresh, "schema_validation_report")},
      {"source_schema_validation_batch_report",
       Map.get(refresh, "source_schema_validation_batch_report")},
      {"schema_validation_batch_report", Map.get(refresh, "schema_validation_batch_report")}
    ]
    |> Enum.flat_map(fn {path, report_or_reports} ->
      SchemaValidation.entries(path, report_or_reports)
    end)
  end
end
