defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelinePublicationHandoffRowSummaries do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelinePublicationHandoffEncoding
  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelinePublicationHandoffSummaryFields
  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelinePublicationReplayDetailSummaries

  def replay_detail_summary?(%{} = summary) do
    TimelinePublicationReplayDetailSummaries.replay_detail_summary?(summary)
  end

  def summary_from_review_or_import_row(%{} = row) do
    source_row =
      case Map.get(row, "source_review_row") do
        %{} = source_review_row -> source_review_row
        _source_review_row -> row
      end
      |> stringify_keys()

    source_row
    |> TimelinePublicationHandoffSummaryFields.from_source_row()
    |> compact_map()
    |> case do
      %{"publication_id" => _publication_id} = summary -> summary
      _summary -> nil
    end
  end

  defp stringify_keys(value), do: TimelinePublicationHandoffEncoding.stringify_keys(value)
end
