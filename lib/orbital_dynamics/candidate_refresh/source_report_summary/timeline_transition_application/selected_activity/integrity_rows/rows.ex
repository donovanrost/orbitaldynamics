defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineTransitionApplication.SelectedActivity.IntegrityRows.Rows do
  @moduledoc false

  alias __MODULE__.ApplicationRows
  alias __MODULE__.SummaryInteger
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  def rows(report) do
    selected_activities =
      report
      |> Map.get("selected_activities", [])
      |> Enum.map(&EncodedValue.stringify_keys/1)

    if selected_activities == [] do
      ApplicationRows.rows(report)
    else
      selected_activities
    end
  end

  def summary_integer(%{} = summary, field) do
    SummaryInteger.value(summary, field)
  end

  def summary_integer(_summary, _field), do: 0
end
