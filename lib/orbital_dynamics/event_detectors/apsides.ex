defmodule OrbitalDynamics.EventDetectors.Apsides do
  @moduledoc "Reference-center radial extrema from r·v: periapsis on increasing crossings, apoapsis on decreasing crossings."
  @behaviour OrbitalDynamics.EventDetector
  alias OrbitalDynamics.Vector3, as: V
  alias OrbitalDynamics.EventSearch.{Function, DetectorAdapter}

  def capabilities,
    do: %{
      detector: :apsides,
      model: :radial_extrema,
      validation_level: :analysis,
      timing_policy: :bounded_root_on_explicit_state_source,
      known_limits: [
        :finite_discovery_cadence,
        :state_source_dependent,
        :circular_or_nonisolated_apsides_unknown
      ]
    }

  def function(id, opts) do
    unless Keyword.keyword?(opts) and
             Enum.all?(Keyword.keys(opts), &(&1 in [:value_tolerance, :direction])),
           do: raise(ArgumentError, "invalid apsis options")

    Function.new!(
      id,
      fn state ->
        if V.norm(state.position_km) == 0,
          do: {:unknown, :apsis_undefined_at_reference_center},
          else:
            {:ok, V.dot(state.position_km, state.velocity_km_s), nil,
             %{"radius_km" => V.norm(state.position_km)}}
      end,
      [
        units: "km2/s",
        labels: %{
          increasing: "periapsis",
          decreasing: "apoapsis",
          touching: "apsis_touch",
          boundary: "apsis_boundary"
        },
        assumptions: %{
          "geometry" => "radial_extrema_about_declared_frame_center",
          "velocity_semantics" => "time derivative of position in declared source axes",
          "limits" => "zero radial rate throughout an interval does not define isolated apsides"
        }
      ] ++ opts
    )
  end

  def detect(trajectory, opts) do
    DetectorAdapter.fields!(opts, [:value_tolerance, :interpolation, :search])

    DetectorAdapter.detect(
      trajectory,
      [function("apsides", value_tolerance: opts[:value_tolerance])],
      opts,
      %{
        "periapsis" => :periapsis,
        "apoapsis" => :apoapsis,
        "apsis_touch" => :apsis_touch,
        "apsis_boundary" => :apsis_boundary
      }
    )
  rescue
    e in [ArgumentError, KeyError] -> {:error, {:invalid_event_search, Exception.message(e)}}
  end
end
