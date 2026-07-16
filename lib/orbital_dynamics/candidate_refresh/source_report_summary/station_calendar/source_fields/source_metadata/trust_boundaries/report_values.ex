defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationCalendar.SourceFields.SourceMetadata.TrustBoundaries.ReportValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [source_report_trust_boundaries: 1]

  def trust_boundaries(%{} = report) do
    report
    |> report_rows()
    |> Enum.map(&EncodedValue.stringify_keys/1)
    |> Enum.map(&row_trust_boundary/1)
    |> Kernel.++(source_report_trust_boundaries([report]))
  end

  defp report_rows(report) do
    Map.get(report, "affected_contacts", []) ++
      Map.get(report, "provider_calendar_contention_groups", [])
  end

  defp row_trust_boundary(row) do
    row["trust_boundary"] ||
      row["station_calendar_trust_boundary"] ||
      get_in(row, ["provenance", "trust_boundary"]) ||
      get_in(row, ["source_station_calendar_entry", "provenance", "trust_boundary"])
  end
end
