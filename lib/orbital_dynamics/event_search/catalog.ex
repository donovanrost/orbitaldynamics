defmodule OrbitalDynamics.EventSearch.Catalog do
  @moduledoc "Versioned, bounded event-family inventory; implementation is distinct from physical validation."
  alias OrbitalDynamics.EventDetectors.{
    Nodes,
    Apsides,
    Thresholds,
    Geometry,
    Extrema,
    Occultations
  }

  @entries [
    {"nodes", "orbital_landmarks", Nodes, :function, 3,
     "declared reference plane; equatorial/nonisolated cases unresolved"},
    {"apsides", "orbital_landmarks", Apsides, :function, 2,
     "reference-center radial extrema; circular degeneracy unresolved"},
    {"plane_crossings", "thresholds", Thresholds, :plane, 4,
     "explicit coordinate plane and offset"},
    {"radius", "thresholds", Thresholds, :radius, 3, "reference-center distance"},
    {"altitude", "thresholds", Thresholds, :altitude, 4, "explicit spherical radius"},
    {"scalar_thresholds", "thresholds", Thresholds, :scalar, 4,
     "caller-defined continuous quantity and explicit units"},
    {"true_anomaly", "coordinates", Thresholds, :true_anomaly, 5,
     "osculating inertial elements; circular/radial cases undefined"},
    {"latitude", "coordinates", Geometry, :latitude, 4, "geocentric spherical latitude"},
    {"longitude", "coordinates", Geometry, :longitude, 4,
     "explicit z-axis rotation; meridian antipode filtered"},
    {"ground_access", "ground_geometry", Geometry, :access, 5,
     "spherical ground point, constant elevation limit"},
    {"ground_lighting", "ground_geometry", Geometry, :ground_night, 5,
     "explicit target solar-elevation threshold including twilight"},
    {"quantity_extrema", "extrema", Extrema, :function, 5,
     "explicit finite differences and padded matching state source"},
    {"region_crossings", "geographic_regions", Geometry, :region, 6,
     "geocentric spherical caps; no polygon/terrain model"},
    {"field_of_view", "instrument_geometry", Geometry, :field_of_view, 6,
     "circular cone and target center; no target extent"},
    {"limb_clearance", "instrument_geometry", Geometry, :limb_clearance, 5,
     "pointing-axis clearance from a spherical body"},
    {"angular_separation", "angular_geometry", Geometry, :angular_separation, 5,
     "two geometric target directions"},
    {"beta_angle", "angular_geometry", Geometry, :beta_angle, 4,
     "instantaneous inertial orbit-plane/Sun angle"},
    {"relative_distance", "relative_geometry", Geometry, :relative_distance, 4,
     "simultaneous relative range"},
    {"closest_approach", "relative_geometry", Geometry, :closest_approach, 3,
     "geometric miss distance, no collision probability"},
    {"intersatellite_visibility", "relative_geometry", Geometry, :intersatellite_visibility, 4,
     "sphere at common origin, finite line segment"},
    {"finite_source_occultations", "occultations", Occultations, :functions, 6,
     "partial, umbra, antumbra; spherical contacts and uniform angular-disk fraction"},
    {"condition_composition", "composition", OrbitalDynamics.EventSearch.Function, :combine, 4,
     "explicit child conditions and unit normalization; closed margins"}
  ]
  def describe do
    %{
      "format" => "orbital_event_catalog.v1",
      "implementation_scope" => "standalone_analysis_with_explicit_models",
      "families" =>
        Enum.map(@entries, fn {id, family, module, function, arity, scope} ->
          unless Code.ensure_loaded?(module) and function_exported?(module, function, arity),
            do: raise(ArgumentError, "unavailable catalog builder #{id}")

          %{
            "id" => id,
            "family" => family,
            "module" => Atom.to_string(module),
            "function" => Atom.to_string(function),
            "arity" => arity,
            "status" => "implemented_analysis",
            "scope" => scope,
            "validation_level" => "analytic_and_regression_cases_only"
          }
        end),
      "extensions_not_claimed" => [
        "arbitrary terrain/polygon or extended-target footprint events",
        "light-time/aberration corrected apparent events",
        "ellipsoidal/atmospheric eclipse boundaries",
        "magnetic/radiation regions without providers",
        "collision probability and covariance propagation",
        "continuous event-discovery completeness for arbitrary callbacks"
      ],
      "limits" =>
        "Finite supported catalog, not a claim to implement every possible mission event or independently validate every physical model."
    }
  end
end
