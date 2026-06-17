defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.TimelineActivityPrecondition.Summary.Pressure do
  @moduledoc false

  def fields(context) do
    dependency_pressure = dependency_pressure?(context)
    exclusivity_pressure = exclusivity_pressure?(context)
    review_pressure = review_pressure?(context)
    invalid_input_pressure = invalid_input_pressure?(context)
    routing_pressure = routing_pressure?(context)

    %{
      "branch_local_timeline_activity_precondition_pressure" =>
        timeline_activity_precondition_pressure?(
          context,
          review_pressure,
          dependency_pressure,
          exclusivity_pressure,
          invalid_input_pressure,
          routing_pressure
        ),
      "branch_local_activity_precondition_review_pressure" => review_pressure,
      "branch_local_activity_precondition_dependency_pressure" => dependency_pressure,
      "branch_local_activity_precondition_exclusivity_pressure" => exclusivity_pressure,
      "branch_local_activity_precondition_invalid_input_pressure" => invalid_input_pressure,
      "branch_local_activity_precondition_routing_pressure" => routing_pressure
    }
  end

  defp timeline_activity_precondition_pressure?(
         context,
         review_pressure,
         dependency_pressure,
         exclusivity_pressure,
         invalid_input_pressure,
         routing_pressure
       ) do
    Map.fetch!(context, :row_count) > 0 or
      Map.fetch!(context, :blocked_precondition_count) > 0 or
      Map.fetch!(context, :review_precondition_count) > 0 or
      map_size(Map.fetch!(context, :precondition_status_counts)) > 0 or
      map_size(Map.fetch!(context, :blocked_precondition_type_counts)) > 0 or
      review_pressure or dependency_pressure or exclusivity_pressure or invalid_input_pressure or
      routing_pressure
  end

  defp dependency_pressure?(context) do
    map_size(Map.fetch!(context, :dependency_activity_id_counts)) > 0 or
      map_size(Map.fetch!(context, :dependency_timeline_id_counts)) > 0 or
      map_size(Map.fetch!(context, :duplicate_dependency_activity_id_counts)) > 0 or
      map_size(Map.fetch!(context, :duplicate_dependency_timeline_id_counts)) > 0
  end

  defp exclusivity_pressure?(context) do
    map_size(Map.fetch!(context, :exclusive_with_activity_id_counts)) > 0 or
      map_size(Map.fetch!(context, :exclusive_with_timeline_id_counts)) > 0 or
      map_size(Map.fetch!(context, :duplicate_exclusivity_activity_id_counts)) > 0 or
      map_size(Map.fetch!(context, :duplicate_exclusivity_timeline_id_counts)) > 0 or
      map_size(Map.fetch!(context, :allow_overlap_counts)) > 0
  end

  defp review_pressure?(context) do
    Map.fetch!(context, :review_precondition_count) > 0 or
      summary_integer(Map.fetch!(context, :precondition_status_counts), "review_required") > 0 or
      map_size(Map.fetch!(context, :review_precondition_type_counts)) > 0
  end

  defp invalid_input_pressure?(context) do
    Map.fetch!(context, :invalid_activity_input_count) > 0 or
      map_size(Map.fetch!(context, :invalid_activity_input_reason_counts)) > 0
  end

  defp routing_pressure?(context) do
    map_size(Map.fetch!(context, :activity_id_counts)) > 0 or
      map_size(Map.fetch!(context, :timeline_id_counts)) > 0
  end

  defp summary_integer(%{} = summary, field) do
    case Map.get(summary, field) do
      value when is_integer(value) ->
        value

      value when is_float(value) ->
        trunc(value)

      value when is_binary(value) ->
        case Integer.parse(String.trim(value)) do
          {integer, ""} -> integer
          _parse -> 0
        end

      _value ->
        0
    end
  end

  defp summary_integer(_summary, _field), do: 0
end
