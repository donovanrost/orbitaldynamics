defmodule OrbitalDynamics.CampaignPlanner.CandidateRefreshRequest do
  @moduledoc false

  def manifest(refresh_request, study_id, metadata) do
    refresh_request = stringify_keys(refresh_request || %{})

    manifest =
      if Map.has_key?(refresh_request, "candidate_refresh") do
        refresh_request
      else
        %{"candidate_refresh" => refresh_request}
      end

    manifest
    |> ensure_trust_boundaries()
    |> Map.put_new("schema_version", 1)
    |> Map.put_new("study_id", study_id)
    |> Map.put_new("outputs", ["access_windows", "target_visibility", "eclipses"])
    |> Map.put_new("propagator", "two_body")
    |> put_in(["metadata"], Map.merge(Map.get(manifest, "metadata", %{}), metadata))
  end

  def run_id(study_id, %DateTime{} = generated_at) when is_binary(study_id) do
    "#{study_id}-#{DateTime.to_unix(generated_at, :microsecond)}"
  end

  def deterministic_run_opts(run_opts, study_id, %DateTime{} = generated_at)
      when is_list(run_opts) and is_binary(study_id) do
    run_opts
    |> Keyword.put(:run_id, run_id(study_id, generated_at))
    |> Keyword.put(:git_revision, nil)
  end

  defp ensure_trust_boundaries(manifest) do
    case get_in(manifest, ["candidate_refresh", "accepted_planning_state"]) do
      %{} = accepted_state ->
        put_in(
          manifest,
          ["candidate_refresh", "accepted_planning_state"],
          ensure_accepted_planning_state_estimate_trust_boundaries(accepted_state)
        )

      _missing ->
        manifest
    end
  end

  def ensure_accepted_planning_state_estimate_trust_boundaries(%{} = accepted_state) do
    states = Map.get(accepted_state, "spacecraft_states", [])
    boundary = inherited_state_estimate_trust_boundary(accepted_state)

    Map.put(
      accepted_state,
      "spacecraft_states",
      Enum.map(states, &ensure_spacecraft_state_estimate_trust_boundary(&1, boundary))
    )
  end

  defp ensure_spacecraft_state_estimate_trust_boundary(%{} = state, boundary) do
    case Map.get(state, "trust_boundary") || get_in(state, ["provenance", "trust_boundary"]) do
      value when is_binary(value) and value != "" ->
        state

      _missing ->
        provenance =
          state
          |> Map.get("provenance", %{})
          |> Map.put("trust_boundary", boundary)
          |> Map.put_new("source", "accepted_planning_state.provenance")

        Map.put(state, "provenance", provenance)
    end
  end

  defp ensure_spacecraft_state_estimate_trust_boundary(state, _boundary), do: state

  defp inherited_state_estimate_trust_boundary(%{"provenance" => %{"trust_boundary" => boundary}})
       when is_binary(boundary) and boundary != "" do
    boundary
  end

  defp inherited_state_estimate_trust_boundary(_accepted_state),
    do: "strategy_candidate_refresh_input"

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
    Enum.map(values, &encode_value/1)
  end

  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
