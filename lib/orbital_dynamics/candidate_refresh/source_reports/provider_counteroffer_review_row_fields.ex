defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferReviewRowFields do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      compact_map: 1
    ]

  def from_row(%{} = row, %{} = embedded) do
    row
    |> Map.drop(["source_review_row"])
    |> Map.merge(embedded)
    |> Map.put_new(
      "provider_counteroffer_id",
      row["provider_counteroffer_id"] || row["subject_id"]
    )
    |> Map.put_new(
      "provider_counteroffer_status",
      row["provider_counteroffer_status"] || row["status"]
    )
    |> Map.put_new("required_operator_action", required_action(row))
    |> Map.put_new("reviewable", reviewable?(row))
    |> compact_map()
    |> eligible_row()
  end

  defp eligible_row(counteroffer_row) when is_map(counteroffer_row) do
    if nonempty_binary?(counteroffer_row["provider_counteroffer_id"]) or
         counteroffer_row["required_operator_action"] == "review_provider_counteroffer" do
      counteroffer_row
    end
  end

  defp eligible_row(_counteroffer_row), do: nil

  defp required_action(row) do
    row["required_operator_action"] ||
      row["import_action"] ||
      row["source_review_action"] ||
      "review_provider_counteroffer"
  end

  defp reviewable?(%{"reviewable" => reviewable}) when is_boolean(reviewable), do: reviewable

  defp reviewable?(row) do
    row["review_type"] == "provider_counteroffer_review" or
      row["source_review_type"] == "provider_counteroffer_review" or
      required_action(row) == "review_provider_counteroffer"
  end

  defp nonempty_binary?(value), do: is_binary(value) and value != ""
end
