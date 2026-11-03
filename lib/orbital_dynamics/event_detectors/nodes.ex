defmodule OrbitalDynamics.EventDetectors.Nodes do
  @moduledoc "Directed crossings of an explicitly declared central plane; no inferred equator or frame transform."
  @behaviour OrbitalDynamics.EventDetector
  alias OrbitalDynamics.EventDetectors.Thresholds
  alias OrbitalDynamics.EventSearch.DetectorAdapter

  def capabilities,
    do: %{
      detector: :nodes,
      model: :declared_plane_crossing,
      validation_level: :analysis,
      timing_policy: :bounded_root_on_explicit_state_source,
      known_limits: [
        :finite_discovery_cadence,
        :state_source_dependent,
        :nonisolated_zeros_unknown
      ]
    }

  def function(id, normal, opts) do
    unless Keyword.keyword?(opts) and
             Enum.all?(Keyword.keys(opts), &(&1 in [:value_tolerance, :direction])),
           do: raise(ArgumentError, "invalid node options")

    f = Thresholds.plane(id, normal, 0, opts)

    %{
      f
      | labels: %{
          increasing: "ascending_node",
          decreasing: "descending_node",
          touching: "node_touch",
          boundary: "node_boundary"
        }
    }
  end

  def detect(trajectory, opts) do
    DetectorAdapter.fields!(opts, [:normal, :value_tolerance, :interpolation, :search])
    f = function("nodes", opts[:normal], value_tolerance: opts[:value_tolerance])

    DetectorAdapter.detect(trajectory, [f], opts, %{
      "ascending_node" => :ascending_node,
      "descending_node" => :descending_node,
      "node_touch" => :node_touch,
      "node_boundary" => :node_boundary
    })
  rescue
    e in [ArgumentError, KeyError] -> {:error, {:invalid_event_search, Exception.message(e)}}
  end
end
