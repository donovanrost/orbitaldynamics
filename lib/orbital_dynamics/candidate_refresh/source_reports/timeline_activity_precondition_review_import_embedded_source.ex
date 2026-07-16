defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityPreconditionReviewImportEmbeddedSource do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineActivityPreconditionReviewImportEncoding

  def summary(%{} = row) do
    row
    |> source_summary()
    |> TimelineActivityPreconditionReviewImportEncoding.stringify_keys()
  end

  defp source_summary(row) do
    cond do
      is_map(row["source_timeline_activity_precondition_summary"]) ->
        row["source_timeline_activity_precondition_summary"]

      is_map(get_in(row, ["source_review_row", "source_timeline_activity_precondition_summary"])) ->
        get_in(row, ["source_review_row", "source_timeline_activity_precondition_summary"])

      true ->
        %{}
    end
  end
end
