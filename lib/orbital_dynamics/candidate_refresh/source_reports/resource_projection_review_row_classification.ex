defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ResourceProjectionReviewRowClassification do
  @moduledoc false

  def split_embedded_rows(rows, stringify_keys) do
    rows
    |> Enum.map(stringify_keys)
    |> Enum.reduce({[], [], []}, fn row, {projected, invalid_activities, invalid_summaries} ->
      cond do
        invalid_activity_row?(row) ->
          {projected, [row | invalid_activities], invalid_summaries}

        invalid_summary_row?(row) ->
          {projected, invalid_activities, [row | invalid_summaries]}

        true ->
          {[row | projected], invalid_activities, invalid_summaries}
      end
    end)
    |> then(fn {projected, invalid_activities, invalid_summaries} ->
      {Enum.reverse(projected), Enum.reverse(invalid_activities), Enum.reverse(invalid_summaries)}
    end)
  end

  defp invalid_activity_row?(row) do
    row["invalid_activity_input"] == true or
      row["required_operator_action"] == "review_invalid_resource_projection_input" or
      row["action"] == "review_invalid_resource_projection_input"
  end

  defp invalid_summary_row?(row) do
    row["invalid_resource_summary_input"] == true or
      row["required_operator_action"] == "review_invalid_resource_projection_summary" or
      row["action"] == "review_invalid_resource_projection_summary"
  end
end
