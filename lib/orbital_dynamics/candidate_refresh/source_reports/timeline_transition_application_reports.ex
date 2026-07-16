defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineTransitionApplicationReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineTransitionApplicationReviewImportEncoding

  def report?(%{} = report) do
    applications = Map.get(report, "applications") || Map.get(report, :applications)
    schema_contract = Map.get(report, "schema_contract") || Map.get(report, :schema_contract)

    source_summary_schema_contract =
      Map.get(report, "source_summary_schema_contract") ||
        Map.get(report, :source_summary_schema_contract)

    is_list(applications) and
      (schema_contract in [
         nil,
         "timeline_transition_application_report.v1",
         "timeline_transition_application_summary.v1"
       ] or source_summary_schema_contract == "timeline_transition_application_summary.v1")
  end

  def report?(_report), do: false

  def summary?(%{} = summary) do
    review_applications =
      Map.get(summary, "review_applications") || Map.get(summary, :review_applications)

    model = Map.get(summary, "model") || Map.get(summary, :model)
    schema_contract = Map.get(summary, "schema_contract") || Map.get(summary, :schema_contract)

    is_list(review_applications) and
      (model == "artifact_only_timeline_transition_application_summary" or
         schema_contract in [nil, "timeline_transition_application_summary.v1"])
  end

  def summary?(_summary), do: false

  def report_from_summary(%{} = summary) do
    summary = stringify_keys(summary)

    summary
    |> Map.put("applications", Map.get(summary, "review_applications", []))
    |> Map.put("source_summary_schema_contract", Map.get(summary, "schema_contract"))
    |> Map.put("source_summary_model", Map.get(summary, "model"))
    |> Map.put("source_artifact_type", Map.get(summary, "source_artifact_type"))
  end

  def stringify_keys(value),
    do: TimelineTransitionApplicationReviewImportEncoding.stringify_keys(value)
end
