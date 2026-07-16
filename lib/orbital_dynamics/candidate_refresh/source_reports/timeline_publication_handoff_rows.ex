defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelinePublicationHandoffRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelinePublicationHandoffEncoding
  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelinePublicationHandoffRowSummaries
  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelinePublicationHandoffTrustBoundary

  def summary_from_handoff_rows(path, %{} = artifact, row_type) do
    artifact
    |> Map.get("rows", [])
    |> List.wrap()
    |> Enum.map(&stringify_keys/1)
    |> Enum.find_value(fn row ->
      if handoff_row?(row, row_type) do
        row
        |> TimelinePublicationHandoffRowSummaries.summary_from_review_or_import_row()
        |> case do
          %{} = summary ->
            if TimelinePublicationHandoffRowSummaries.replay_detail_summary?(summary) do
              {path, TimelinePublicationHandoffTrustBoundary.inherit(summary, artifact)}
            else
              embedded_handoff_summary(path, row, artifact)
            end

          _summary ->
            embedded_handoff_summary(path, row, artifact)
        end
      end
    end)
  end

  defdelegate stringify_keys(value), to: TimelinePublicationHandoffEncoding

  defp embedded_handoff_summary(path, row, artifact) do
    case Map.get(row, "source_timeline_publication_summary") do
      %{} = summary ->
        {path, TimelinePublicationHandoffTrustBoundary.inherit(summary, artifact)}

      _summary ->
        nil
    end
  end

  defp handoff_row?(%{"review_type" => row_type}, row_type), do: true
  defp handoff_row?(%{"import_type" => row_type}, row_type), do: true
  defp handoff_row?(%{"row_type" => row_type}, row_type), do: true
  defp handoff_row?(%{"action" => row_type}, row_type), do: true
  defp handoff_row?(%{"import_action" => row_type}, row_type), do: true
  defp handoff_row?(_row, _row_type), do: false
end
