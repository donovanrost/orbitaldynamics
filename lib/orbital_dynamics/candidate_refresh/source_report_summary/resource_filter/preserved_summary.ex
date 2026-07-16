defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ResourceFilter.PreservedSummary do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  def report_from_summary(%{} = summary) do
    summary = EncodedValue.stringify_keys(summary)

    summary
    |> Map.put("suppressed_candidates", Map.get(summary, "review_rows", []))
    |> Map.put(
      "invalid_resource_summary_inputs",
      Map.get(summary, "invalid_resource_summary_inputs", [])
    )
    |> Map.put("source_summary_schema_contract", Map.get(summary, "schema_contract"))
    |> Map.put("source_summary_model", Map.get(summary, "model"))
    |> Map.put("source_artifact_type", Map.get(summary, "source_artifact_type"))
  end
end
