defmodule OrbitalDynamics.EventSearch.Source do
  @moduledoc "Finite, explicitly framed state source for opt-in event searches."
  alias OrbitalDynamics.{Epoch, Frame, StateVector, Trajectory, Vector3}
  alias OrbitalDynamics.MissionAnalysis.Input
  alias OrbitalDynamics.Schema.JsonSafety
  @enforce_keys [:sampler, :start, :stop, :frame, :provenance]
  defstruct @enforce_keys

  def new!(sampler, %Epoch{} = start, %Epoch{} = stop, %Frame{} = frame, provenance)
      when is_function(sampler, 1) and is_map(provenance) do
    Input.number!(start.seconds_since_j2000, "source start", -1.0e12, 1.0e12)
    Input.number!(stop.seconds_since_j2000, "source end", -1.0e12, 1.0e12)

    unless start.scale in [:utc, :tai, :tdb] and start.scale == stop.scale and
             stop.seconds_since_j2000 > start.seconds_since_j2000,
           do:
             raise(
               ArgumentError,
               "state source requires ordered finite coverage in one explicit scale"
             )

    %__MODULE__{
      sampler: sampler,
      start: start,
      stop: stop,
      frame: frame,
      provenance: JsonSafety.normalize_input!(provenance, "event source provenance")
    }
  end

  @doc "Explicit cubic-Hermite interpolation of sampled position/velocity; not dense propagation."
  def from_trajectory!(%Trajectory{states: states}, opts) do
    unless opts == [interpolation: :cubic_hermite],
      do: raise(ArgumentError, "explicit interpolation: :cubic_hermite required")

    unless is_list(states) and length(states) in 2..10000,
      do: raise(ArgumentError, "2..10000 state anchors required")

    first = hd(states)
    last = List.last(states)

    source =
      new!(fn _ -> {:error, :uninitialized} end, first.epoch, last.epoch, first.frame, %{
        "evaluation" => "cubic_hermite_sample_interpolant",
        "anchor_count" => length(states),
        "limits" =>
          "root timing is relative to interpolated states, not independently propagated truth"
      })

    Enum.reduce(states, nil, fn state, previous ->
      validate!(source, state, state.epoch.seconds_since_j2000)
      t = state.epoch.seconds_since_j2000

      if previous != nil and t <= previous,
        do: raise(ArgumentError, "event source anchors must strictly increase")

      t
    end)

    anchors = List.to_tuple(states)

    sampler = fn t ->
      i = index(anchors, t, 0, tuple_size(anchors) - 1)
      a = elem(anchors, i)
      b = elem(anchors, min(i + 1, tuple_size(anchors) - 1))

      state =
        cond do
          t == a.epoch.seconds_since_j2000 -> a
          t == b.epoch.seconds_since_j2000 -> b
          true -> interpolate(a, b, t)
        end

      {:ok, state}
    end

    %{source | sampler: sampler}
  end

  def at(%__MODULE__{} = s, t),
    do: OrbitalDynamics.EventSearch.Context.state(s, t, fn -> evaluate(s, t) end)

  defp evaluate(s, t) do
    if t < s.start.seconds_since_j2000 or t > s.stop.seconds_since_j2000 do
      {:unknown, :outside_state_source_coverage}
    else
      case s.sampler.(t) do
        {:ok, %StateVector{} = state} ->
          validate!(s, state, t)
          {:ok, state}

        {:unknown, _} = unknown ->
          unknown

        {:error, _} = error ->
          error

        _ ->
          raise ArgumentError, "invalid event state-source result"
      end
    end
  end

  def describe(s),
    do: %{
      "coverage" => %{
        "starts_at_s" => s.start.seconds_since_j2000,
        "ends_at_s" => s.stop.seconds_since_j2000
      },
      "time_scale" => Atom.to_string(s.start.scale),
      "frame" => %{
        "name" => Atom.to_string(s.frame.name),
        "center" => Atom.to_string(s.frame.center),
        "orientation" => Atom.to_string(s.frame.orientation)
      },
      "provenance" => s.provenance
    }

  defp validate!(s, state, t) do
    unless Frame.compatible?(s.frame, state.frame) and state.epoch.scale == s.start.scale and
             state.epoch.seconds_since_j2000 == t,
           do: raise(ArgumentError, "state source returned incompatible frame, scale or epoch")

    Input.vector!(state.position_km, "event state position")
    Input.vector!(state.velocity_km_s, "event state velocity")
  end

  defp index(_states, _t, lo, hi) when hi - lo <= 1, do: lo

  defp index(states, t, lo, hi) do
    mid = div(lo + hi, 2)

    if elem(states, mid).epoch.seconds_since_j2000 <= t,
      do: index(states, t, mid, hi),
      else: index(states, t, lo, mid)
  end

  defp interpolate(a, b, t) do
    dt = b.epoch.seconds_since_j2000 - a.epoch.seconds_since_j2000
    u = (t - a.epoch.seconds_since_j2000) / dt
    u2 = u * u
    u3 = u2 * u

    p =
      sum([
        {a.position_km, 2 * u3 - 3 * u2 + 1},
        {a.velocity_km_s, (u3 - 2 * u2 + u) * dt},
        {b.position_km, -2 * u3 + 3 * u2},
        {b.velocity_km_s, (u3 - u2) * dt}
      ])

    v =
      sum([
        {a.position_km, (6 * u2 - 6 * u) / dt},
        {a.velocity_km_s, 3 * u2 - 4 * u + 1},
        {b.position_km, (-6 * u2 + 6 * u) / dt},
        {b.velocity_km_s, 3 * u2 - 2 * u}
      ])

    StateVector.new!(p, v, Epoch.new!(t, a.epoch.scale), a.frame)
  end

  defp sum(terms),
    do:
      Enum.reduce(terms, {0.0, 0.0, 0.0}, fn {v, k}, acc ->
        Vector3.add(acc, Vector3.scale(v, k))
      end)
end
