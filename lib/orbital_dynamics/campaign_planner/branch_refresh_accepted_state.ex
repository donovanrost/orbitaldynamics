defmodule OrbitalDynamics.CampaignPlanner.BranchRefreshAcceptedState do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{CandidateRefreshRequest, PriorActivityContext}

  @realized_failure_statuses ~w(missed failed canceled cancelled rejected)

  def from_mission_state(mission_state, prior_plan)

  def from_mission_state(
        %{"accepted_planning_state" => %{} = state} = mission_state,
        prior_plan
      ) do
    state
    |> CandidateRefreshRequest.ensure_accepted_planning_state_estimate_trust_boundaries()
    |> append_realized_maneuver_execution_deltas(mission_state, prior_plan)
  end

  def from_mission_state(mission_state, prior_plan) do
    spacecraft_states =
      mission_state
      |> Map.get("spacecraft_states", [])
      |> Enum.map(&stringify_keys/1)
      |> Enum.filter(&planning_state_estimate?/1)
      |> Enum.map(&complete_planning_state_estimate/1)

    if spacecraft_states == [] do
      nil
    else
      %{
        "schema_version" => 1,
        "artifact_type" => "accepted_planning_state",
        "snapshot_id" => Map.get(mission_state, "snapshot_id", "mission-state"),
        "accepted_at" =>
          Map.get(mission_state, "captured_at") || DateTime.to_iso8601(DateTime.utc_now()),
        "spacecraft_states" => spacecraft_states,
        "maneuver_execution_deltas" =>
          maneuver_execution_deltas_from_mission_state(mission_state, %{}, prior_plan),
        "source" => %{"system" => "mission_state"},
        "quality" => %{"level" => "planning_accepted"},
        "provenance" => %{
          "created_by" => "CampaignPlanner.strategy",
          "trust_boundary" => "strategy_candidate_refresh_input"
        }
      }
      |> CandidateRefreshRequest.ensure_accepted_planning_state_estimate_trust_boundaries()
    end
  end

  def for_branch(branch, mission_state, prior_plan) do
    case from_mission_state(mission_state, prior_plan) do
      %{} = accepted_state ->
        branch_deltas = branch_maneuver_execution_deltas(branch)

        if branch_deltas == [] do
          CandidateRefreshRequest.ensure_accepted_planning_state_estimate_trust_boundaries(
            accepted_state
          )
        else
          existing_deltas = Map.get(accepted_state, "maneuver_execution_deltas", [])

          accepted_state
          |> Map.put("maneuver_execution_deltas", existing_deltas ++ branch_deltas)
          |> CandidateRefreshRequest.ensure_accepted_planning_state_estimate_trust_boundaries()
        end

      missing ->
        missing
    end
  end

  defp append_realized_maneuver_execution_deltas(
         accepted_state,
         mission_state,
         prior_plan
       ) do
    Map.put(
      accepted_state,
      "maneuver_execution_deltas",
      maneuver_execution_deltas_from_mission_state(
        mission_state,
        accepted_state,
        prior_plan
      )
    )
  end

  defp maneuver_execution_deltas_from_mission_state(
         mission_state,
         accepted_state,
         prior_plan
       ) do
    existing =
      Map.get(accepted_state, "maneuver_execution_deltas") ||
        Map.get(mission_state, "maneuver_execution_deltas", [])

    (existing ++ realized_maneuver_execution_deltas(mission_state, prior_plan))
    |> Enum.map(&stringify_keys/1)
    |> Enum.map(&ensure_maneuver_execution_delta_trust_boundary(&1, accepted_state))
    |> unique_maneuver_execution_deltas()
  end

  defp realized_maneuver_execution_deltas(mission_state, prior_plan) do
    mission_state
    |> Map.get("realized_activities", [])
    |> Enum.map(&stringify_keys/1)
    |> PriorActivityContext.enrich(prior_plan)
    |> Enum.flat_map(&realized_maneuver_execution_delta/1)
  end

  defp realized_maneuver_execution_delta(%{"status" => status} = activity)
       when status in @realized_failure_statuses or status in ["delayed", "partial"] do
    type = Map.get(activity, "type") || Map.get(activity, "activity_type")
    activity_id = Map.get(activity, "id") || Map.get(activity, "activity_id")

    if type in ["maneuver", "impulsive_burn"] and activity_id not in [nil, ""] do
      [
        %{
          "activity_id" => activity_id,
          "status" => status,
          "source" => %{
            "system" => "mission_state.realized_activities",
            "source_id" => activity_id,
            "realized_status" => status
          },
          "quality" => %{"level" => "operator_reported"},
          "provenance" => %{
            "trust_boundary" => "mission_state_realized_activity",
            "source" => "mission_state.realized_activities"
          }
        }
        |> maybe_put_actual_epoch(activity)
        |> maybe_put_delta_epoch(activity)
      ]
    else
      []
    end
  end

  defp realized_maneuver_execution_delta(_activity), do: []

  defp maybe_put_delta_epoch(delta, %{"starts_at_s" => starts_at_s}) when is_number(starts_at_s),
    do: Map.put(delta, "epoch_s", starts_at_s * 1.0)

  defp maybe_put_delta_epoch(delta, %{"epoch_s" => epoch_s}) when is_number(epoch_s),
    do: Map.put(delta, "epoch_s", epoch_s * 1.0)

  defp maybe_put_delta_epoch(delta, _activity), do: delta

  defp unique_maneuver_execution_deltas(deltas) do
    deltas
    |> Enum.reduce({MapSet.new(), []}, fn delta, {seen, kept} ->
      key = {
        delta["activity_id"],
        delta["status"],
        get_in(delta, ["actual_epoch", "seconds_since_j2000"]),
        delta["epoch_s"],
        get_in(delta, ["source", "system"]),
        get_in(delta, ["source", "source_id"])
      }

      if MapSet.member?(seen, key) do
        {seen, kept}
      else
        {MapSet.put(seen, key), [delta | kept]}
      end
    end)
    |> elem(1)
    |> Enum.reverse()
  end

  defp branch_maneuver_execution_deltas(branch) do
    branch
    |> Map.get("events", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.flat_map(&branch_maneuver_execution_delta/1)
  end

  defp branch_maneuver_execution_delta(%{"type" => type, "activity_id" => activity_id} = event)
       when type in ["missed_maneuver", "delayed_maneuver"] and activity_id not in [nil, ""] do
    [
      %{
        "activity_id" => activity_id,
        "status" => maneuver_delta_status(type),
        "source" => %{
          "system" => "strategy_branch_event",
          "event_type" => type,
          "branch_event_id" => Map.get(event, "id")
        },
        "quality" => %{"level" => "branch_assumption"},
        "provenance" => %{
          "trust_boundary" => "strategy_branch_assumption",
          "source" => "strategy_branch.events"
        }
      }
      |> maybe_put_actual_epoch(event)
    ]
  end

  defp branch_maneuver_execution_delta(_event), do: []

  defp ensure_maneuver_execution_delta_trust_boundary(delta, accepted_state) do
    case Map.get(delta, "trust_boundary") || get_in(delta, ["provenance", "trust_boundary"]) do
      boundary when is_binary(boundary) and boundary != "" ->
        delta

      _missing ->
        provenance =
          delta
          |> Map.get("provenance", %{})
          |> Map.put("trust_boundary", inherited_maneuver_delta_trust_boundary(accepted_state))
          |> Map.put_new("source", "accepted_planning_state.maneuver_execution_deltas")

        Map.put(delta, "provenance", provenance)
    end
  end

  defp inherited_maneuver_delta_trust_boundary(%{"provenance" => %{"trust_boundary" => boundary}})
       when is_binary(boundary) and boundary != "" do
    boundary
  end

  defp inherited_maneuver_delta_trust_boundary(_accepted_state),
    do: "strategy_candidate_refresh_input"

  defp maneuver_delta_status("missed_maneuver"), do: "missed"
  defp maneuver_delta_status("delayed_maneuver"), do: "delayed"

  defp maybe_put_actual_epoch(delta, %{"actual_starts_at_s" => actual_starts_at_s})
       when is_number(actual_starts_at_s) do
    Map.put(delta, "actual_epoch", %{
      "seconds_since_j2000" => actual_starts_at_s * 1.0,
      "time_scale" => "tdb"
    })
  end

  defp maybe_put_actual_epoch(delta, _event), do: delta

  defp planning_state_estimate?(state) do
    is_map(Map.get(state, "epoch")) and is_map(Map.get(state, "state_vector")) and
      not is_nil(Map.get(state, "frame")) and
      not is_nil(Map.get(state, "spacecraft_id") || Map.get(state, "scenario_id"))
  end

  defp complete_planning_state_estimate(state) do
    state
    |> Map.put_new("spacecraft_id", Map.get(state, "scenario_id"))
    |> Map.put_new("scenario_id", Map.get(state, "spacecraft_id"))
    |> Map.put_new("source", %{"system" => "mission_state.spacecraft_states"})
    |> Map.put_new("quality", %{"level" => "planning_accepted"})
  end

  defp stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp encode_value(%_{} = struct), do: struct |> Map.from_struct() |> encode_value()

  defp encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values) do
    if Keyword.keyword?(values) do
      Map.new(values, fn {key, value} -> {encode_value(key), encode_value(value)} end)
    else
      Enum.map(values, &encode_value/1)
    end
  end

  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
