defmodule OrbitalDynamics.Timeline.TransitionApplicationIntegrityPolicy do
  @moduledoc false

  def gate_single(
        %{"selected_activity" => %{} = selected_activity} = application,
        opts,
        annotate_transition_selected_activities,
        gate_selected_activity_integrity
      ) do
    [selected_activity]
    |> annotate_transition_selected_activities.(opts)
    |> case do
      [%{} = selected_with_integrity] ->
        application
        |> Map.put("selected_activity", selected_with_integrity)
        |> gate_selected_activity_integrity.(selected_with_integrity)

      _other ->
        application
    end
  end

  def gate_single(
        application,
        _opts,
        _annotate_transition_selected_activities,
        _gate_selected_activity_integrity
      ),
      do: application

  def put_batch(
        applications,
        selected_activities,
        gate_selected_activity_integrity
      ) do
    selected_by_timeline_id = Map.new(selected_activities, &{&1["timeline_id"], &1})

    Enum.map(applications, fn application ->
      case Map.get(application, "selected_activity") do
        %{} = selected ->
          case Map.get(selected_by_timeline_id, selected["timeline_id"]) do
            nil ->
              application

            selected_with_integrity ->
              application
              |> Map.put("selected_activity", selected_with_integrity)
              |> gate_selected_activity_integrity.(selected_with_integrity)
          end

        _other ->
          application
      end
    end)
  end
end
