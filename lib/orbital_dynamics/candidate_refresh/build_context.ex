defmodule OrbitalDynamics.CandidateRefresh.BuildContext do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.AcceptedStateEvidenceAuthority
  alias OrbitalDynamics.CandidateRefresh.FreshnessReport

  @accepted_planning_state_alias_collision %{
    "spacecraft_states" => [],
    "maneuver_execution_deltas" => []
  }

  def accepted_planning_state_ref(refresh, evidence_authority \\ nil) do
    accepted_state = accepted_planning_state(refresh)

    evidence_authority =
      case evidence_authority do
        nil -> accepted_state_evidence_authority(refresh)
        summary -> summary
      end

    accepted_state
    |> accepted_planning_state_identity()
    |> Map.merge(%{
      "spacecraft_state_count" => accepted_state_list_count(accepted_state, "spacecraft_states"),
      "maneuver_execution_delta_count" =>
        accepted_state_list_count(accepted_state, "maneuver_execution_deltas"),
      "evidence_authority" => evidence_authority
    })
  end

  def accepted_planning_state_provenance(refresh, evidence_authority \\ nil) do
    accepted_state = accepted_planning_state(refresh)

    evidence_authority =
      case evidence_authority do
        nil -> accepted_state_evidence_authority(refresh)
        summary -> summary
      end

    accepted_state
    |> accepted_planning_state_identity()
    |> Map.merge(%{
      "source" => Map.get(accepted_state, "source", %{}),
      "quality" => Map.get(accepted_state, "quality", %{}),
      "provenance" => Map.get(accepted_state, "provenance", %{}),
      "evidence_authority" => evidence_authority
    })
  end

  def accepted_planning_state(refresh) do
    case accepted_planning_state_field(refresh) do
      {:ok, nil} -> %{}
      {:ok, false} -> %{}
      {:ok, %{} = accepted_state} -> accepted_state
      {:ok, _accepted_state} -> %{}
      :missing -> %{}
      :alias_collision -> @accepted_planning_state_alias_collision
    end
  end

  def accepted_state_evidence_authority(refresh) do
    refresh
    |> AcceptedStateEvidenceAuthority.analyze_refresh_wrapper()
    |> Map.fetch!(:evidence_authority)
  end

  def prepare_refresh_for_build(refresh) do
    AcceptedStateEvidenceAuthority.analyze_refresh_wrapper(refresh)
  end

  def refresh_for_build_encoding(refresh, _evidence_authority) do
    refresh
    |> prepare_refresh_for_build()
    |> Map.fetch!(:refresh)
  end

  def freshness_report(refresh, generated_at, model_limits, numeric_value) do
    FreshnessReport.build(%{
      accepted_state: accepted_planning_state(refresh),
      current_epoch_s: current_epoch_s(refresh, numeric_value),
      generated_at: generated_at,
      horizon: remaining_horizon(refresh, numeric_value),
      model_limits: model_limits.(),
      refresh: refresh
    })
  end

  def snapshot_id(refresh), do: Map.get(accepted_planning_state(refresh), "snapshot_id")

  def current_epoch_s(refresh, numeric_value) do
    [
      Map.get(refresh, "current_epoch_s"),
      get_in(refresh, ["current_epoch", "seconds_since_j2000"]),
      get_in(refresh, ["mission_state", "current_epoch_s"]),
      get_in(refresh, ["mission_state", "current_epoch", "seconds_since_j2000"]),
      get_in(refresh, ["accepted_planning_state", "current_epoch_s"]),
      get_in(refresh, ["accepted_planning_state", "current_epoch", "seconds_since_j2000"]),
      accepted_state_spacecraft_epoch_s(refresh, numeric_value)
    ]
    |> Enum.find_value(numeric_value)
  end

  def remaining_horizon(refresh, numeric_value) do
    [
      Map.get(refresh, "remaining_horizon"),
      get_in(refresh, ["mission_state", "remaining_horizon"]),
      get_in(refresh, ["accepted_planning_state", "remaining_horizon"])
    ]
    |> Enum.find(&is_map/1)
    |> case do
      %{} = horizon -> normalize_remaining_horizon(horizon, numeric_value)
      _horizon -> %{}
    end
  end

  defp accepted_state_spacecraft_epoch_s(refresh, numeric_value) do
    with %{} = accepted_state <- accepted_planning_state(refresh),
         {:ok, spacecraft_states} <- fetch_encoding_field(accepted_state, "spacecraft_states"),
         {:ok, [%{} = state | _rest]} <-
           bounded_list_items(
             spacecraft_states,
             AcceptedStateEvidenceAuthority.max_encoding_projection_list_entries()
           ) do
      state
      |> get_in(["epoch", "seconds_since_j2000"])
      |> then(numeric_value)
    else
      _result -> nil
    end
  end

  defp accepted_planning_state_identity(accepted_state) do
    %{
      "snapshot_id" => Map.get(accepted_state, "snapshot_id"),
      "accepted_at" => Map.get(accepted_state, "accepted_at")
    }
  end

  defp accepted_state_list_count(%{} = accepted_state, key) do
    case fetch_encoding_field(accepted_state, key) do
      {:ok, values} when is_list(values) ->
        case bounded_list_items(
               values,
               AcceptedStateEvidenceAuthority.max_encoding_projection_list_entries()
             ) do
          {:ok, items} -> length_bounded(items)
          _result -> 0
        end

      _result ->
        0
    end
  end

  defp accepted_state_list_count(_accepted_state, _key), do: 0

  defp normalize_remaining_horizon(horizon, numeric_value) do
    horizon
    |> Map.take(["starts_at_s", "ends_at_s", "duration_s", "output_step_s"])
    |> Map.new(fn {key, value} ->
      case numeric_value.(value) do
        number when is_number(number) -> {key, number}
        nil -> {key, value}
      end
    end)
  end

  defp accepted_planning_state_field(%{} = refresh) do
    string_value = Map.fetch(refresh, "accepted_planning_state")
    atom_value = Map.fetch(refresh, :accepted_planning_state)

    case {string_value, atom_value} do
      {:error, :error} -> :missing
      {{:ok, value}, :error} -> {:ok, value}
      {:error, {:ok, value}} -> {:ok, value}
      {{:ok, _string_value}, {:ok, _atom_value}} -> :alias_collision
    end
  end

  defp accepted_planning_state_field(_refresh), do: :missing

  defp fetch_encoding_field(%{} = map, key) do
    string_value = Map.fetch(map, key)

    atom_value =
      case AcceptedStateEvidenceAuthority.encoding_projection_atom_for_key(key) do
        nil -> :error
        atom_key -> Map.fetch(map, atom_key)
      end

    case {string_value, atom_value} do
      {:error, :error} -> :missing
      {{:ok, value}, :error} -> {:ok, value}
      {:error, {:ok, value}} -> {:ok, value}
      {{:ok, _string_value}, {:ok, _atom_value}} -> {:alias_collision, key}
    end
  end

  defp fetch_encoding_field(_map, _key), do: :missing

  defp bounded_list_items(values, max_items) when is_list(values),
    do: bounded_list_items(values, max_items, [])

  defp bounded_list_items(_values, _max_items), do: {:improper, []}

  defp bounded_list_items([], _remaining, acc), do: {:ok, Enum.reverse(acc)}

  defp bounded_list_items(_values, 0, acc), do: {:oversize, Enum.reverse(acc)}

  defp bounded_list_items([head | tail], remaining, acc),
    do: bounded_list_items(tail, remaining - 1, [head | acc])

  defp bounded_list_items(_improper_tail, _remaining, acc), do: {:improper, Enum.reverse(acc)}

  defp length_bounded(values), do: length_bounded(values, 0)
  defp length_bounded([], count), do: count
  defp length_bounded([_head | tail], count), do: length_bounded(tail, count + 1)
end
