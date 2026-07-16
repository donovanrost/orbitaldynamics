defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineTransitionApplicationReviewImportContextRows do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineTransitionApplicationReviewImportRows

  def operator_review_rows(%{} = package) do
    package
    |> Map.get("rows", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.filter(&(&1["review_type"] == "timeline_diff_review"))
  end

  def cadence_import_rows(%{} = manifest) do
    manifest
    |> Map.get("rows", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.filter(fn row ->
      row["source_review_type"] == "timeline_diff_review" or
        row["import_action"] == "review_timeline_diff"
    end)
  end

  def applications_from_rows(rows) do
    rows
    |> Enum.map(
      &TimelineTransitionApplicationReviewImportRows.source_application_from_review_or_import_row/1
    )
    |> Enum.map(&stringify_keys/1)
    |> Enum.reject(&(map_size(&1) == 0))
  end

  defp stringify_keys(value),
    do: TimelineTransitionApplicationReviewImportRows.stringify_keys(value)
end
