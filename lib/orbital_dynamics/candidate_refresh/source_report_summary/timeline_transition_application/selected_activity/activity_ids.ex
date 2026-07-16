defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.SelectedActivity.ActivityIds do
  @moduledoc false

  alias __MODULE__.IdValues

  def selected_row?(row) do
    value_present?(row["selected_activity"]) or row["application_status"] == "selected"
  end

  def selected_ids(row) do
    IdValues.selected(row)
  end

  def review_ids(row) do
    IdValues.review(row)
  end

  defp value_present?(%{} = value), do: map_size(value) > 0
  defp value_present?(values) when is_list(values), do: values != []
  defp value_present?(value), do: value not in [nil, "", false]
end
