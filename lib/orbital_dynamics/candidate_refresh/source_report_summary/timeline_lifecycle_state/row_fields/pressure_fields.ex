defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineLifecycleState.RowFields.PressureFields do
  @moduledoc false

  alias __MODULE__.BaseFields
  alias __MODULE__.InvalidActivityFields
  alias __MODULE__.RowValues

  def fields(rows) do
    rows
    |> BaseFields.fields()
    |> Map.merge(InvalidActivityFields.fields(rows))
  end

  def activity_ids(row), do: RowValues.activity_ids(row)

  def timeline_ids(rows, predicate), do: RowValues.timeline_ids(rows, predicate)

  def sorted_values(values), do: RowValues.sorted_values(values)
end
