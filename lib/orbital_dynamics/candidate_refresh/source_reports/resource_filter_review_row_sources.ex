defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ResourceFilterReviewRowSources do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceFilterReviewRowEncoding

  def embedded_suppression(%{} = row) do
    row
    |> embedded_source()
    |> stringify_suppression()
  end

  defp embedded_source(row) do
    cond do
      is_map(row["source_resource_suppression"]) ->
        row["source_resource_suppression"]

      is_map(get_in(row, ["source_review_row", "source_resource_suppression"])) ->
        get_in(row, ["source_review_row", "source_resource_suppression"])

      true ->
        %{}
    end
  end

  defp stringify_suppression(%{} = suppression_row) do
    ResourceFilterReviewRowEncoding.stringify_keys(suppression_row)
  end

  defp stringify_suppression(_suppression_row), do: %{}
end
