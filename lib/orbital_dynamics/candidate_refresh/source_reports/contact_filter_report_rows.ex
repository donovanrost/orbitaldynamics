defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactFilterReportRows do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactFilterReportRowValues,
    as: RowValues

  def from_rows(path, source, rows, artifact) do
    report =
      %{
        "schema_contract" => "contact_filter_report.v1",
        "model" => "preserved_contact_suppression_rows",
        "source" => source,
        "suppressed_candidates" => rows,
        "suppressed_candidate_count" => length(rows),
        "invalid_contact_input_count" => Enum.count(rows, &invalid_input_row?/1),
        "invalid_contact_input_ids" =>
          rows
          |> Enum.map(&stringify_keys/1)
          |> Enum.filter(&invalid_input_row?/1)
          |> Enum.map(& &1["id"]),
        "suppressed_reason_counts" => count_rows(rows, "suppressed_reason")
      }
      |> RowValues.maybe_put("provenance", Map.get(artifact, "provenance"))
      |> RowValues.maybe_put("trust_boundary", RowValues.result_artifact_trust_boundary(artifact))
      |> compact_map()

    {path, report}
  end

  defp invalid_input_row?(row), do: RowValues.invalid_input_row?(row)
  defp count_rows(rows, field), do: RowValues.count_rows(rows, field)
  defp stringify_keys(value), do: RowValues.stringify_keys(value)
end
