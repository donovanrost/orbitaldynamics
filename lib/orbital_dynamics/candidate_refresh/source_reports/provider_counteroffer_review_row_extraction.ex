defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferReviewRowExtraction do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferReviewRowEncoding
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ProviderCounterofferReviewRowFields

  def row_from_review_or_import_row(%{} = row) do
    embedded =
      cond do
        is_map(row["source_provider_counteroffer"]) ->
          row["source_provider_counteroffer"]

        is_map(get_in(row, ["source_review_row", "source_provider_counteroffer"])) ->
          get_in(row, ["source_review_row", "source_provider_counteroffer"])

        true ->
          %{}
      end

    embedded =
      case embedded do
        %{} = provider_counteroffer ->
          ProviderCounterofferReviewRowEncoding.stringify_keys(provider_counteroffer)

        _provider_counteroffer ->
          %{}
      end

    ProviderCounterofferReviewRowFields.from_row(row, embedded)
  end
end
