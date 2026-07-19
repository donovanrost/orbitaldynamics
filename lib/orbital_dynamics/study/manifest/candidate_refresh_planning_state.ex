defmodule OrbitalDynamics.Study.Manifest.CandidateRefreshPlanningState do
  @moduledoc false

  alias OrbitalDynamics.{OrbitData, Schema}

  def resolve(refresh) do
    case Map.fetch(refresh, "accepted_planning_state") do
      {:ok, %{} = accepted_state} ->
        validate(accepted_state)

      {:ok, _accepted_state} ->
        {:error, {:invalid_field, "candidate_refresh.accepted_planning_state"}}

      :error ->
        resolve_fallback(refresh)
    end
  end

  defp resolve_fallback(%{"orbit_data" => _orbit_data} = refresh),
    do: resolve_orbit_data(refresh)

  defp resolve_fallback(%{"mission_state" => %{} = mission_state}) do
    accepted_state =
      case Map.get(mission_state, "accepted_planning_state") do
        %{} = accepted_state ->
          accepted_state

        _accepted_state ->
          from_mission_state(mission_state)
      end

    case accepted_state do
      %{} = accepted_state ->
        validate(accepted_state)

      :invalid ->
        {:error, {:invalid_field, "candidate_refresh.mission_state.spacecraft_states"}}

      nil ->
        {:error, {:missing_field, "candidate_refresh.accepted_planning_state"}}
    end
  end

  defp resolve_fallback(_refresh),
    do: {:error, {:missing_field, "candidate_refresh.accepted_planning_state"}}

  defp from_mission_state(%{"spacecraft_states" => spacecraft_states} = mission_state)
       when is_list(spacecraft_states) do
    spacecraft_states =
      Enum.map(spacecraft_states, &complete_spacecraft_state/1)

    if spacecraft_states == [] or Enum.any?(spacecraft_states, &(&1 == :invalid)) do
      :invalid
    else
      %{
        "schema_version" => 1,
        "artifact_type" => "accepted_planning_state",
        "snapshot_id" => Map.get(mission_state, "snapshot_id", "mission-state"),
        "accepted_at" =>
          Map.get(mission_state, "accepted_at") ||
            Map.get(mission_state, "captured_at") ||
            "1970-01-01T00:00:00Z",
        "spacecraft_states" => spacecraft_states,
        "maneuver_execution_deltas" => [],
        "source" =>
          Map.get(mission_state, "source", %{"system" => "candidate_refresh.mission_state"}),
        "quality" => Map.get(mission_state, "quality", %{"level" => "planning_accepted"}),
        "provenance" =>
          Map.get(mission_state, "provenance", %{
            "created_by" => "OrbitalDynamics.Study.Manifest",
            "trust_boundary" => "candidate_refresh.mission_state"
          })
      }
    end
  end

  defp from_mission_state(%{"spacecraft_states" => _spacecraft_states}), do: :invalid
  defp from_mission_state(_mission_state), do: nil

  defp complete_spacecraft_state(%{} = state) do
    state
    |> Map.put_new("spacecraft_id", Map.get(state, "scenario_id"))
    |> Map.put_new("scenario_id", Map.get(state, "spacecraft_id"))
    |> Map.put_new("source", %{"system" => "candidate_refresh.mission_state.spacecraft_states"})
    |> Map.put_new("quality", %{"level" => "planning_accepted"})
    |> Map.put_new("provenance", %{"trust_boundary" => "candidate_refresh.mission_state"})
  end

  defp complete_spacecraft_state(_state), do: :invalid

  defp resolve_orbit_data(%{"orbit_data" => orbit_data}) do
    case OrbitData.import_orbit_data(orbit_data) do
      {:ok, accepted_state} -> {:ok, accepted_state}
      {:error, reason} -> {:error, {:invalid_field, "candidate_refresh.orbit_data", reason}}
    end
  end

  defp resolve_orbit_data(_refresh),
    do: {:error, {:missing_field, "candidate_refresh.accepted_planning_state"}}

  defp validate(accepted_state) do
    case Schema.validate_artifact(accepted_state,
           schema_contract: "accepted_planning_state.v1"
         ) do
      {:ok, _report} -> {:ok, accepted_state}
      {:error, report} -> {:error, {:invalid_accepted_planning_state, report}}
    end
  end
end
