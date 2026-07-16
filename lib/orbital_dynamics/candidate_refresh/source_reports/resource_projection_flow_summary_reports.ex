defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ResourceProjectionFlowSummaryReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceProjectionFlowSummaryEncoding

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceProjectionFlowSummaryReportFields

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceProjectionFlowSummaryProjectedResources

  def flow_summary?(%{} = report) do
    rows = Map.get(report, "projected_resources") || Map.get(report, :projected_resources)
    schema_contract = Map.get(report, "schema_contract") || Map.get(report, :schema_contract)

    is_list(rows) and schema_contract == "resource_projection_flow_summary.v1"
  end

  def flow_summary?(_report), do: false

  def report_from_flow_summary(%{} = summary) do
    summary = ResourceProjectionFlowSummaryEncoding.stringify_keys(summary)
    activity_resource_flow = Map.get(summary, "activity_resource_flow", [])

    projected_resources =
      summary
      |> Map.get("projected_resources", [])
      |> ResourceProjectionFlowSummaryProjectedResources.enrich(activity_resource_flow)

    invalid_activity_inputs = Map.get(summary, "invalid_activity_inputs", [])
    invalid_resource_summary_inputs = Map.get(summary, "invalid_resource_summary_inputs", [])

    ResourceProjectionFlowSummaryReportFields.from_summary(
      summary,
      activity_resource_flow,
      projected_resources,
      invalid_activity_inputs,
      invalid_resource_summary_inputs
    )
  end
end
