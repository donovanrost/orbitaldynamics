defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiffReviewImportRowSources do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDiffReviewImportRowEncoding

  def source_application_from_review_or_import_row(%{} = row) do
    row
    |> source_application()
    |> TimelineDiffReviewImportRowEncoding.stringify_keys()
  end

  def embedded_timeline_diff(row, source_application) do
    cond do
      is_map(row["source_timeline_diff"]) ->
        row["source_timeline_diff"]

      is_map(get_in(row, ["source_review_row", "source_timeline_diff"])) ->
        get_in(row, ["source_review_row", "source_timeline_diff"])

      is_map(source_application["source_timeline_diff"]) ->
        source_application["source_timeline_diff"]

      true ->
        %{}
    end
    |> case do
      %{} = diff -> TimelineDiffReviewImportRowEncoding.stringify_keys(diff)
      _diff -> %{}
    end
  end

  defp source_application(%{} = row) do
    cond do
      is_map(row["source_timeline_application"]) ->
        row["source_timeline_application"]

      is_map(row["source_timeline_transition_application"]) ->
        row["source_timeline_transition_application"]

      is_map(get_in(row, ["source_review_row", "source_timeline_application"])) ->
        get_in(row, ["source_review_row", "source_timeline_application"])

      is_map(get_in(row, ["source_review_row", "source_timeline_transition_application"])) ->
        get_in(row, ["source_review_row", "source_timeline_transition_application"])

      true ->
        %{}
    end
  end
end
