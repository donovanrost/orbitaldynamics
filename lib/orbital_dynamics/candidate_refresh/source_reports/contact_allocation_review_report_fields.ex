defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactAllocationReviewReportFields do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactAllocationReviewRows

  def from_embedded_rows(path, source, rows, artifact) do
    report =
      %{
        "schema_contract" => "contact_allocation_report.v1",
        "model" => "preserved_contact_allocation_rows",
        "source" => source,
        "rows" => rows,
        "row_count" => length(rows),
        "allocation_status_counts" =>
          ContactAllocationReviewRows.count_contact_allocation_rows(rows, "allocation_status"),
        "effective_allocation_status_counts" =>
          ContactAllocationReviewRows.count_contact_allocation_rows(
            rows,
            "effective_allocation_status"
          )
      }
      |> maybe_put("provenance", Map.get(artifact, "provenance"))
      |> maybe_put("trust_boundary", result_artifact_trust_boundary(artifact))
      |> compact_map()

    {path, report}
  end

  defp result_artifact_trust_boundary(artifact) do
    artifact = ContactAllocationReviewRows.stringify_keys(artifact)

    Map.get(artifact, "trust_boundary") ||
      get_in(artifact, ["provenance", "trust_boundary"]) ||
      get_in(artifact, ["metadata", "trust_boundary"]) ||
      get_in(artifact, ["assumptions", "trust_boundary"])
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
