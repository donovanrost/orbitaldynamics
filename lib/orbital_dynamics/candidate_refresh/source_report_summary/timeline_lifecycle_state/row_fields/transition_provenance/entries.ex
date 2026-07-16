defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineLifecycleState.RowFields.TransitionProvenance.Entries do
  @moduledoc false

  alias __MODULE__.LifecycleRows

  def transition_application_provenances(%{} = summary) do
    summary
    |> LifecycleRows.values()
    |> Enum.flat_map(&row_transition_application_provenances/1)
  end

  defp row_transition_application_provenances(%{} = row) do
    [
      Map.get(row, "transition_application_provenance"),
      get_in(row, ["activity_context", "transition_application_provenance"]),
      get_in(row, ["planned_activity_context", "transition_application_provenance"]),
      get_in(row, ["realized_activity_context", "transition_application_provenance"])
    ]
    |> Enum.filter(&is_map/1)
    |> Enum.uniq()
  end

  defp row_transition_application_provenances(_row), do: []
end
