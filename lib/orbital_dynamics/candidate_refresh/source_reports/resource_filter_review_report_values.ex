defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ResourceFilterReviewReportValues do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      compact_map: 1
    ]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceFilterReviewReportDerivedValues,
    as: DerivedValues

  def build(source, suppressed_candidates, invalid_resource_summary_inputs, artifact) do
    %{
      "schema_contract" => "resource_filter_report.v1",
      "model" => "preserved_resource_suppression_rows",
      "source" => source,
      "suppressed_candidates" => suppressed_candidates,
      "invalid_resource_summary_inputs" => invalid_resource_summary_inputs,
      "suppressed_candidate_count" => length(suppressed_candidates),
      "invalid_resource_summary_input_count" => length(invalid_resource_summary_inputs),
      "invalid_resource_summary_input_ids" =>
        DerivedValues.invalid_resource_summary_input_ids(invalid_resource_summary_inputs),
      "suppressed_reason_counts" =>
        DerivedValues.count_rows(suppressed_candidates, "suppressed_reason")
    }
    |> maybe_put("provenance", Map.get(artifact, "provenance"))
    |> maybe_put("trust_boundary", DerivedValues.result_artifact_trust_boundary(artifact))
    |> compact_map()
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
