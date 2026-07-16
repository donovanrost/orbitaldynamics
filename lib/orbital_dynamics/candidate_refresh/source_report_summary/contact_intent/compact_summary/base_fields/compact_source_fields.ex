defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.BaseFields.CompactSourceFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactIntent.CompactSummary.BaseFields.{
    CompactSourceCounts,
    CompactSourceFields.SourceSummaryCounts,
    SourceMetadata
  }

  def fields(sources, summaries) do
    %{
      "paths" => Enum.map(sources, fn {path, _summary} -> path end),
      "contract" => SourceMetadata.contract(summaries),
      "count" => length(sources),
      "row_count" => CompactSourceCounts.row_count(summaries),
      "station_feedback_count" => 0,
      "capacity_pack_required_contact_count" =>
        CompactSourceCounts.capacity_pack_required_contact_count(summaries)
    }
    |> Map.merge(SourceSummaryCounts.fields(summaries))
  end
end
