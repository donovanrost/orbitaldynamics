defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactContentionReviewReportFields do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      compact_map: 1
    ]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.EmbeddedRowFallbacks

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactContentionReviewReportValues,
    as: Values

  def report_from_embedded_rows(path, source, rows, artifact) do
    EmbeddedRowFallbacks.report_from_embedded_rows(
      path,
      source,
      rows,
      artifact,
      &report_from_rows/4
    )
  end

  defp report_from_rows(path, source, rows, artifact) do
    {invalid_inputs, conflict_groups} =
      Enum.split_with(rows, &Values.invalid_input_row?/1)

    report =
      %{
        "schema_contract" => "contact_contention_report.v1",
        "model" => "preserved_contact_contention_review_rows",
        "source" => source,
        "conflict_groups" => conflict_groups,
        "conflict_group_count" => length(conflict_groups),
        "invalid_contact_inputs" => invalid_inputs,
        "invalid_contact_input_count" => length(invalid_inputs),
        "invalid_contact_input_ids" => Values.invalid_input_ids(invalid_inputs)
      }
      |> maybe_put("provenance", Map.get(artifact, "provenance"))
      |> maybe_put("trust_boundary", Values.result_artifact_trust_boundary(artifact))
      |> compact_map()

    {path, report}
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
