defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineLifecycleState.ReviewFields.RouteMap do
  @moduledoc false

  alias __MODULE__.Fields
  alias __MODULE__.Inputs

  def build(summaries) do
    route_inputs = Inputs.build(summaries)

    route_inputs.actions
    |> Map.new(fn action ->
      {action, Fields.for_action(action, route_inputs)}
    end)
    |> non_empty_map()
  end

  defp non_empty_map(map) do
    case map do
      %{} when map_size(map) == 0 -> nil
      _map -> map
    end
  end
end
