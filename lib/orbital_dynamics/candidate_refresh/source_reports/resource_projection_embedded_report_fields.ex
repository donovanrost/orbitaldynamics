defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ResourceProjectionEmbeddedReportFields do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceProjectionEmbeddedReportValues
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceProjectionReviewRows

  def report(
        source,
        rows,
        {projected_resources, invalid_activity_inputs, invalid_resource_summary_inputs},
        artifact
      ) do
    %{
      "schema_contract" => "resource_projection_report.v1",
      "model" => "preserved_resource_projection_rows",
      "source" => source,
      "projected_resources" => projected_resources,
      "invalid_activity_inputs" => invalid_activity_inputs,
      "invalid_resource_summary_inputs" => invalid_resource_summary_inputs,
      "row_count" => length(rows),
      "projected_resource_count" => length(projected_resources),
      "invalid_activity_input_count" => length(invalid_activity_inputs),
      "invalid_resource_summary_input_count" => length(invalid_resource_summary_inputs),
      "invalid_activity_input_ids" =>
        ResourceProjectionEmbeddedReportValues.invalid_input_ids(
          invalid_activity_inputs,
          "activity_id"
        ),
      "invalid_resource_summary_input_ids" =>
        ResourceProjectionEmbeddedReportValues.invalid_input_ids(
          invalid_resource_summary_inputs,
          "resource_summary_id"
        ),
      "resource_pressure_status_counts" =>
        ResourceProjectionReviewRows.count_resource_projection_rows(
          projected_resources,
          "resource_pressure_status"
        )
    }
    |> maybe_put("provenance", Map.get(artifact, "provenance"))
    |> maybe_put(
      "trust_boundary",
      ResourceProjectionEmbeddedReportValues.result_artifact_trust_boundary(artifact)
    )
    |> compact_map()
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
