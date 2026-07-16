defmodule OrbitalDynamics.CandidateRefresh.SourceReports.StationCalendarReviewRowReports do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.EmbeddedRowFallbacks

  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationCalendarReviewProviderContentionGroups

  alias OrbitalDynamics.CandidateRefresh.SourceReports.StationCalendarReviewValueEncoding

  def from_rows(path, source, rows, artifact) do
    EmbeddedRowFallbacks.from_rows(path, source, rows, artifact, &report_from_rows/4)
  end

  defp report_from_rows(path, source, rows, artifact) do
    {provider_contention_rows, affected_contact_rows} =
      Enum.split_with(
        rows,
        &StationCalendarReviewProviderContentionGroups.provider_contention_row?/1
      )

    provider_contention_groups =
      provider_contention_rows
      |> Enum.map(&StationCalendarReviewProviderContentionGroups.from_row/1)
      |> Enum.reject(&is_nil/1)

    artifact = StationCalendarReviewValueEncoding.stringify_keys(artifact)

    report =
      %{
        "schema_contract" => "station_calendar_report.v1",
        "model" => "preserved_station_calendar_review_rows",
        "source" => source,
        "affected_contacts" => affected_contact_rows,
        "affected_contact_count" => length(affected_contact_rows),
        "provider_calendar_contention_groups" => provider_contention_groups,
        "provider_calendar_contention_group_count" => length(provider_contention_groups)
      }
      |> maybe_put("provenance", Map.get(artifact, "provenance"))
      |> maybe_put(
        "trust_boundary",
        StationCalendarReviewValueEncoding.result_artifact_trust_boundary(artifact)
      )
      |> compact_map()

    {path, report}
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
