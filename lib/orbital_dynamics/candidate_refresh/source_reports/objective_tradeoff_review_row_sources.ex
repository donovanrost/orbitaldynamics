defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveTradeoffReviewRowSources do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveTradeoffReviewRowEncoding

  def embedded_tradeoff(row) do
    row
    |> embedded_source()
    |> case do
      %{} = tradeoff -> ObjectiveTradeoffReviewRowEncoding.stringify_keys(tradeoff)
      _tradeoff -> %{}
    end
  end

  defp embedded_source(row) do
    cond do
      is_map(row["source_objective_tradeoff"]) ->
        row["source_objective_tradeoff"]

      is_map(get_in(row, ["source_review_row", "source_objective_tradeoff"])) ->
        get_in(row, ["source_review_row", "source_objective_tradeoff"])

      true ->
        %{}
    end
  end
end
