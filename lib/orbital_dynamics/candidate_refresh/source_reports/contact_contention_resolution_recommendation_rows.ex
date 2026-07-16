defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactContentionResolutionRecommendationRows do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactContentionResolutionRecommendationRowEncoding

  def from_review_or_import_row(%{} = row) do
    embedded =
      row
      |> embedded_recommendation()
      |> stringify_keys()

    row
    |> Map.drop(["source_review_row"])
    |> Map.merge(embedded)
    |> Map.put_new("group_id", row["subject_id"])
    |> Map.put_new("selected_contact_id", row["selected_contact_id"])
    |> Map.put_new("deferred_contact_ids", row["deferred_contact_ids"])
    |> Map.put_new("review_status", row["review_status"] || row["approval_status"])
    |> compact_map()
  end

  def stringify_keys(value) do
    ContactContentionResolutionRecommendationRowEncoding.stringify_keys(value)
  end

  defp embedded_recommendation(row) do
    cond do
      is_map(row["source_recommendation"]) ->
        row["source_recommendation"]

      is_map(get_in(row, ["source_review_row", "source_recommendation"])) ->
        get_in(row, ["source_review_row", "source_recommendation"])

      true ->
        %{}
    end
  end
end
