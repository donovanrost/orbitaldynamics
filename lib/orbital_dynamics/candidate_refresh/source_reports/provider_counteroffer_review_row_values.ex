defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferReviewRowValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferReviewRowEncoding
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferReviewRowExtraction

  def operator_review_rows(%{} = package) do
    package
    |> Map.get("rows", [])
    |> Enum.map(&ProviderCounterofferReviewRowEncoding.stringify_keys/1)
    |> Enum.filter(&(&1["review_type"] == "provider_counteroffer_review"))
    |> Enum.map(&ProviderCounterofferReviewRowExtraction.row_from_review_or_import_row/1)
    |> Enum.reject(&is_nil/1)
  end

  def cadence_import_rows(%{} = manifest) do
    manifest
    |> Map.get("rows", [])
    |> Enum.map(&ProviderCounterofferReviewRowEncoding.stringify_keys/1)
    |> Enum.filter(fn row ->
      row["source_review_type"] == "provider_counteroffer_review" or
        row["import_action"] == "review_provider_counteroffer"
    end)
    |> Enum.map(&ProviderCounterofferReviewRowExtraction.row_from_review_or_import_row/1)
    |> Enum.reject(&is_nil/1)
  end
end
