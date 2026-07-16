defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineTransitionApplicationReviewImportRowSources do
  @moduledoc false

  def review_or_import_path(
        rows,
        source_timeline_application_path,
        source_timeline_transition_application_path
      ) do
    if Enum.any?(rows, &alias_row?/1) do
      source_timeline_transition_application_path
    else
      source_timeline_application_path
    end
  end

  def source_application_from_row(%{} = row) do
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

  defp alias_row?(row) do
    is_map(row["source_timeline_transition_application"]) or
      is_map(get_in(row, ["source_review_row", "source_timeline_transition_application"]))
  end
end
