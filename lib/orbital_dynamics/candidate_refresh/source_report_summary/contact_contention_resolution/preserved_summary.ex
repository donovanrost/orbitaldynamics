defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContentionResolution.PreservedSummary do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  def report_from_summary(%{} = summary) do
    summary = EncodedValue.stringify_keys_with_keyword_maps(summary)

    summary
    |> Map.put_new("recommendations", [])
    |> Map.put_new("required_operator_action_counts", Map.get(summary, "action_counts"))
    |> Map.put("source_summary_schema_contract", Map.get(summary, "schema_contract"))
    |> Map.put("source_summary_model", Map.get(summary, "model"))
    |> Map.put("source_artifact_type", Map.get(summary, "source_artifact_type"))
    |> Map.put("trust_boundary", Map.get(summary, "trust_boundary"))
  end
end
