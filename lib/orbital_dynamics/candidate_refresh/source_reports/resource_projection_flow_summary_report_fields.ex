defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ResourceProjectionFlowSummaryReportFields do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      compact_map: 1,
      numeric_report_count: 2
    ]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceProjectionFlowSummaryPressureFields,
    as: PressureFields

  def from_summary(
        summary,
        activity_resource_flow,
        projected_resources,
        invalid_activity_inputs,
        invalid_resource_summary_inputs
      ) do
    %{
      "schema_contract" => "resource_projection_report.v1",
      "source_artifact_type" => "resource_projection_flow_summary.v1",
      "source_flow_summary_model" => Map.get(summary, "model"),
      "projected_resources" => projected_resources,
      "invalid_activity_inputs" => invalid_activity_inputs,
      "invalid_resource_summary_inputs" => invalid_resource_summary_inputs,
      "projected_resource_count" =>
        flow_summary_count(summary, "projected_resource_count", projected_resources),
      "invalid_activity_input_count" =>
        flow_summary_count(summary, "invalid_activity_input_count", invalid_activity_inputs),
      "invalid_resource_summary_input_count" =>
        flow_summary_count(
          summary,
          "invalid_resource_summary_input_count",
          invalid_resource_summary_inputs
        ),
      "activity_resource_flow" => activity_resource_flow,
      "model_limits" => Map.get(summary, "model_limits"),
      "assumptions" => Map.get(summary, "assumptions"),
      "provenance" => Map.get(summary, "provenance"),
      "trust_boundary" => Map.get(summary, "trust_boundary")
    }
    |> Map.merge(PressureFields.from_summary(summary))
    |> compact_map()
  end

  defp flow_summary_count(summary, field, rows) when is_list(rows) do
    numeric_report_count(summary, field)
    |> case do
      0 -> length(rows)
      count -> count
    end
  end
end
