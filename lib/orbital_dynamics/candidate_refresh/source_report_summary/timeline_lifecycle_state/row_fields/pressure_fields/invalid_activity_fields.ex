defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineLifecycleState.RowFields.PressureFields.InvalidActivityFields do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineLifecycleState.RowFields.PressureFields.RowValues

  def fields(rows) do
    invalid_rows = Enum.filter(rows, &(&1["invalid_activity_input"] == true))

    %{
      "invalid_activity_input_count" => length(invalid_rows),
      "invalid_activity_input_ids" => invalid_activity_ids(invalid_rows)
    }
  end

  defp invalid_activity_ids(rows) do
    rows
    |> Enum.flat_map(&RowValues.activity_ids/1)
    |> RowValues.sorted_values()
  end
end
