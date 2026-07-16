defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferReviewRowReports do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      compact_map: 1
    ]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferReviewRowReportValues,
    as: RowReportValues

  alias OrbitalDynamics.CandidateRefresh.SourceReports.EmbeddedRowFallbacks

  def from_embedded_rows(path, source, rows, artifact) do
    EmbeddedRowFallbacks.from_embedded_rows(
      path,
      source,
      rows,
      artifact,
      &report_from_embedded_rows/4
    )
  end

  defp report_from_embedded_rows(path, source, rows, artifact) do
    report =
      %{
        "schema_contract" => "provider_counteroffer_report.v1",
        "model" => "preserved_provider_counteroffer_rows",
        "source" => source,
        "rows" => rows,
        "counteroffer_count" => length(rows),
        "reviewable_count" => Enum.count(rows, & &1["reviewable"]),
        "counteroffer_cost_delta_count" =>
          Enum.count(rows, &is_number(&1["provider_counteroffer_cost_delta"])),
        "counteroffer_cost_delta_total" =>
          rows
          |> Enum.map(& &1["provider_counteroffer_cost_delta"])
          |> Enum.filter(&is_number/1)
          |> Enum.sum(),
        "counteroffer_lock_deadline_count" =>
          Enum.count(rows, &is_number(&1["provider_counteroffer_lock_deadline_s"])),
        "earliest_counteroffer_lock_deadline_s" =>
          rows
          |> Enum.map(&RowReportValues.numeric_value(&1["provider_counteroffer_lock_deadline_s"]))
          |> Enum.reject(&is_nil/1)
          |> Enum.min(fn -> nil end),
        "counteroffer_status_counts" =>
          RowReportValues.count_rows(rows, "provider_counteroffer_status"),
        "required_operator_action_counts" =>
          RowReportValues.count_rows(rows, "required_operator_action")
      }
      |> RowReportValues.maybe_put("provenance", Map.get(artifact, "provenance"))
      |> RowReportValues.maybe_put(
        "trust_boundary",
        RowReportValues.result_artifact_trust_boundary(artifact)
      )
      |> compact_map()

    {path, report}
  end
end
