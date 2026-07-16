defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactAllocationReviewRowSources do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactAllocationReviewRowEncoding

  def embedded_allocation(%{} = row) do
    row
    |> embedded_source()
    |> stringify_allocation()
  end

  defp embedded_source(row) do
    cond do
      is_map(row["source_contact_allocation"]) ->
        row["source_contact_allocation"]

      is_map(get_in(row, ["source_review_row", "source_contact_allocation"])) ->
        get_in(row, ["source_review_row", "source_contact_allocation"])

      true ->
        %{}
    end
  end

  defp stringify_allocation(%{} = allocation_row) do
    ContactAllocationReviewRowEncoding.stringify_keys(allocation_row)
  end

  defp stringify_allocation(_allocation_row), do: %{}
end
