defmodule OrbitalDynamics.Validation.Registry do
  @moduledoc false

  alias OrbitalDynamics.ForceModels.AtmosphericDrag

  alias OrbitalDynamics.Propagators.{
    J2,
    J2ExlaCpu,
    TwoBody,
    TwoBodyDrag,
    TwoBodyExlaCpu,
    TwoBodyNx,
    TwoBodyNxCompiled
  }

  @records %{
    "force_model.atmospheric_drag" => %{
      "id" => "force_model.atmospheric_drag",
      "model" => "co_rotating_reference_atmosphere_drag",
      "implementation" => "OrbitalDynamics.ForceModels.AtmosphericDrag",
      "validation_level" => "educational",
      "covered_regime" =>
        "single-state Earth/J2000 LEO drag acceleration with constant co-rotation and a validated atmosphere-density provider",
      "tolerances" => %{
        "density_kg_m3" => 1.0e-18,
        "atmosphere_velocity_km_s" => 1.0e-12,
        "relative_velocity_km_s" => 1.0e-12,
        "relative_speed_km_s" => 1.0e-12,
        "acceleration_km_s2" => 1.0e-15,
        "acceleration_magnitude_km_s2" => 1.0e-15
      },
      "evidence" => [
        "unit tests check atmosphere-relative direction, SI conversion, provider identity, and invalid-input boundaries",
        "curated 400 km reference fixture is evaluated through OrbitalDynamics.atmospheric_drag_acceleration/4"
      ],
      "known_limits" => AtmosphericDrag.model_limits()
    },
    "propagator.two_body_drag" => %{
      "id" => "propagator.two_body_drag",
      "model" => "fixed_step_point_mass_with_co_rotating_reference_atmosphere_drag",
      "implementation" => "OrbitalDynamics.Propagators.TwoBodyDrag",
      "validation_level" => "educational",
      "covered_regime" =>
        "Earth/J2000 LEO fixed-step RK4 with point-mass gravity, explicit spacecraft ballistic properties, and a validated atmosphere-density provider",
      "tolerances" => %{
        "final_position_km" => 1.0e-8,
        "final_velocity_km_s" => 1.0e-11,
        "final_specific_energy_km2_s2" => 1.0e-10,
        "specific_energy_change_km2_s2" => 1.0e-10
      },
      "evidence" => [
        "zero-density provider parameters recover scalar fixed-step two-body states exactly",
        "curated 600 second LEO fixture is evaluated through the public programmatic Study path"
      ],
      "known_limits" => TwoBodyDrag.model_limits()
    },
    "propagator.two_body" => %{
      "id" => "propagator.two_body",
      "model" => "point_mass_two_body",
      "implementation" => "OrbitalDynamics.Propagators.TwoBody",
      "validation_level" => "educational",
      "covered_regime" =>
        "near-circular LEO demo and trade-study cases using fixed-step or explicit adaptive step-doubling RK4",
      "tolerances" => %{
        "position_km" => 1.0e-6,
        "velocity_km_s" => 1.0e-9,
        "energy_relative" => 1.0e-9
      },
      "evidence" => [
        "unit tests compare conserved orbital energy and angular momentum",
        "unit tests cover deterministic adaptive step-doubling assumptions",
        "backend comparison tests check Nx/EXLA variants against scalar two-body output"
      ],
      "known_limits" => [
        "fixed-step RK4 is the default; adaptive step-doubling is explicit and educational",
        "point-mass gravity only",
        "not flight-certified"
      ]
    },
    "propagator.j2" => %{
      "id" => "propagator.j2",
      "model" => "j2_perturbed_earth",
      "implementation" => "OrbitalDynamics.Propagators.J2",
      "validation_level" => "educational",
      "covered_regime" => "LEO planning examples using fixed-step RK4",
      "tolerances" => %{
        "position_km" => 1.0e-5,
        "velocity_km_s" => 1.0e-8
      },
      "evidence" => [
        "unit tests compare deterministic scalar and EXLA J2 propagation",
        "scenario fixtures exercise repeated LEO propagation"
      ],
      "known_limits" => [
        "J2 is the only perturbation",
        "no drag, third-body, or adaptive integration",
        "not flight-certified"
      ]
    },
    "propagator.two_body_nx" => %{
      "id" => "propagator.two_body_nx",
      "model" => "point_mass_two_body",
      "implementation" => "OrbitalDynamics.Propagators.TwoBodyNx",
      "validation_level" => "educational",
      "covered_regime" => "homogeneous small-batch LEO comparison cases",
      "tolerances" => %{"position_km" => 1.0e-5, "velocity_km_s" => 1.0e-8},
      "evidence" => ["backend comparison tests against scalar two-body propagation"],
      "known_limits" => ["experimental accelerator path", "not a default performance win"]
    },
    "event.access_windows" => %{
      "id" => "event.access_windows",
      "model" => "sampled_ground_station_access",
      "implementation" => "OrbitalDynamics.EventDetectors.AccessWindows",
      "validation_level" => "analysis",
      "covered_regime" => "spherical Earth LEO visibility examples",
      "tolerances" => %{"event_time_s" => "bounded by output step with linear interpolation"},
      "evidence" => ["unit tests cover visibility grouping and boundary interpolation"],
      "known_limits" => ["no terrain mask", "no refraction model beyond assumption metadata"]
    },
    "event.access_windows.bracketed_bisection" => %{
      "id" => "event.access_windows.bracketed_bisection",
      "model" => "cubic_hermite_bracketed_ground_station_access",
      "implementation" => "OrbitalDynamics.EventDetectors.AccessWindows",
      "validation_level" => "analysis",
      "covered_regime" =>
        "spherical Earth LEO visibility examples with one crossing per sampled bracket",
      "tolerances" => %{
        "event_time_s" => "bounded by the final cubic-Hermite interpolated-state root bracket"
      },
      "evidence" => [
        "unit tests compare opt-in bracketed bisection against an analytical spherical-geometry crossing and verify deterministic local bounds",
        "unit tests cover incompatible state metadata, invalid solver options, and bounded non-convergence"
      ],
      "known_limits" => [
        "no terrain mask",
        "no refraction model beyond assumption metadata",
        "opt-in roots solve elevation on cubic-Hermite interpolation between samples, not dense propagator output",
        "one sign-changing root is selected per bracket; multiple crossings inside one sample interval are not resolved",
        "internal analytical comparison only; no external validation or flight-fidelity claim"
      ]
    },
    "event.eclipses" => %{
      "id" => "event.eclipses",
      "model" => "cylindrical_central_body_shadow",
      "implementation" => "OrbitalDynamics.EventDetectors.Eclipses",
      "validation_level" => "analysis",
      "covered_regime" => "Earth-shadow LEO examples with fixed Sun direction",
      "tolerances" => %{"event_time_s" => "bounded by output step with linear interpolation"},
      "evidence" => ["unit tests cover shadow intervals and boundary interpolation"],
      "known_limits" => ["fixed Sun direction", "cylindrical shadow approximation"]
    },
    "event.target_visibility" => %{
      "id" => "event.target_visibility",
      "model" => "sampled_target_visibility",
      "implementation" => "OrbitalDynamics.EventDetectors.TargetVisibility",
      "validation_level" => "analysis",
      "covered_regime" => "spherical Earth target visibility examples",
      "tolerances" => %{"event_time_s" => "bounded by output step with linear interpolation"},
      "evidence" => ["unit tests cover target visibility windows and interpolation"],
      "known_limits" => ["no lighting categories", "no terrain or sensor-specific model"]
    },
    "event.ground_track_crossings" => %{
      "id" => "event.ground_track_crossings",
      "model" => "sampled_geocentric_ground_track_crossing",
      "implementation" => "OrbitalDynamics.EventDetectors.GroundTrackCrossings",
      "validation_level" => "analysis",
      "covered_regime" =>
        "manual geocentric latitude/longitude crossing examples with inertial and declared constant-rotation body-fixed frames",
      "tolerances" => %{"event_time_s" => "bounded by output step with linear interpolation"},
      "evidence" => [
        "unit tests cover latitude, longitude, antimeridian, and configured constant-rotation crossings"
      ],
      "known_limits" => [
        "geocentric spherical coordinates",
        "body-fixed mode uses declared constant rotation assumptions",
        "no Earth orientation parameters or time-system conversion"
      ]
    },
    "orbit_data.simple_json" => %{
      "id" => "orbit_data.simple_json",
      "model" => "simple_json_cartesian_state_estimate_batch",
      "implementation" => "OrbitalDynamics.OrbitData.import_simple_json",
      "validation_level" => "artifact_contract",
      "covered_regime" =>
        "operator-supplied Cartesian state estimates already expressed in project units and frames",
      "tolerances" => %{
        "position_km" => "input-preserving adapter, no numerical transformation",
        "velocity_km_s" => "input-preserving adapter, no numerical transformation"
      },
      "evidence" => [
        "unit tests cover normalization, provenance defaults, and invalid state-vector rejection",
        "accepted_planning_state.v1 schema lint checks exported fixture artifacts"
      ],
      "known_limits" => [
        "no hidden unit conversion",
        "no covariance propagation",
        "caller must provide accepted source and quality metadata"
      ]
    },
    "orbit_data.ccsds_opm_kvn" => %{
      "id" => "orbit_data.ccsds_opm_kvn",
      "model" => "ccsds_opm_kvn_single_object_cartesian_handoff",
      "implementation" => "OrbitalDynamics.OrbitData.import_ccsds_opm",
      "validation_level" => "artifact_contract",
      "covered_regime" => "single-object Earth-centered OPM KVN Cartesian state handoff",
      "tolerances" => %{
        "position_km" => "input-preserving adapter, no numerical transformation",
        "velocity_km_s" => "input-preserving adapter, no numerical transformation",
        "epoch_s" => "ISO-8601 parse to seconds since J2000"
      },
      "evidence" => [
        "unit tests cover OPM import/export round trip and unsupported center rejection",
        "unit tests reject duplicate OPM single-value fields instead of silently overwriting them",
        "unit tests preserve OPM spacecraft physical metadata as metadata-only evidence",
        "unit tests import and export complete OPM covariance matrix components as metadata-only evidence",
        "unit tests preserve one OPM MAN_* maneuver metadata block as maneuver_execution_delta evidence",
        "unit tests export and re-import multiple OPM MAN_* maneuver metadata blocks from maneuver_execution_delta evidence"
      ],
      "known_limits" => [
        "single object only",
        "Earth center only",
        "duplicate single-value KVN fields are rejected",
        "EME2000/J2000/ICRF are mapped to earth_inertial_j2000 metadata",
        "OPM spacecraft physical metadata is preserved as metadata-only evidence and is not propagated",
        "OPM covariance matrices are preserved as metadata-only evidence and are not propagated",
        "OPM maneuver metadata is preserved as metadata-only evidence and is not propagated"
      ]
    },
    "orbit_data.ccsds_oem_kvn" => %{
      "id" => "orbit_data.ccsds_oem_kvn",
      "model" => "ccsds_oem_kvn_single_sample_cartesian_handoff",
      "implementation" => "OrbitalDynamics.OrbitData.import_ccsds_oem",
      "validation_level" => "artifact_contract",
      "covered_regime" =>
        "single-object Earth-centered OEM KVN Cartesian ephemeris handoff using one selected sample",
      "tolerances" => %{
        "position_km" => "selected sample is preserved, no interpolation",
        "velocity_km_s" => "selected sample is preserved, no interpolation",
        "epoch_s" => "selected sample ISO-8601 parse to seconds since J2000"
      },
      "evidence" => [
        "unit tests cover first/last sample selection and single-sample OEM export",
        "unit tests reject duplicate OEM single-value fields instead of silently overwriting them",
        "unit tests import and export one OEM covariance block as metadata-only evidence",
        "unit tests reject invalid sample selectors"
      ],
      "known_limits" => [
        "single object only",
        "single selected sample only",
        "duplicate single-value KVN fields are rejected",
        "no interpolation despite OEM interpolation metadata",
        "OEM covariance blocks are preserved as metadata-only evidence and are not propagated"
      ]
    },
    "orbit_data.tle_metadata" => %{
      "id" => "orbit_data.tle_metadata",
      "model" => "tle_two_line_element_metadata_preflight",
      "implementation" => "OrbitalDynamics.OrbitData.inspect_tle",
      "validation_level" => "artifact_contract",
      "covered_regime" => "TLE metadata parsing and preflight validation only",
      "tolerances" => %{
        "checksum" => "exact modulo-10 TLE checksum match",
        "catalog_number" => "line 1 and line 2 catalog numbers must match"
      },
      "evidence" => [
        "unit tests cover checksum validation, catalog-number consistency, and metadata extraction",
        "unit tests preserve TLE mean-motion derivatives and BSTAR drag metadata as metadata-only preflight evidence",
        "unit tests derive TLE mean-element period, altitude, and coarse regime metadata without generating a Cartesian state",
        "unit tests reject multi-object TLE drops as ambiguous metadata preflight input",
        "import_orbit_data/2 tests verify TLE wrappers are rejected as accepted planning-state inputs"
      ],
      "known_limits" => [
        "metadata only",
        "mean-element altitude and regime values are preflight estimates, not SGP4 state outputs",
        "single-object metadata preflight only",
        "requires a separate SGP4 propagation regime before state generation",
        "not interchangeable with accepted_planning_state.v1 Cartesian handoff"
      ]
    }
  }

  @propagator_ids %{
    TwoBody => "propagator.two_body",
    TwoBodyDrag => "propagator.two_body_drag",
    TwoBodyExlaCpu => "propagator.two_body",
    TwoBodyNxCompiled => "propagator.two_body_nx",
    TwoBodyNx => "propagator.two_body_nx",
    J2 => "propagator.j2",
    J2ExlaCpu => "propagator.j2"
  }

  @implementation_ids Map.put(
                        @propagator_ids,
                        AtmosphericDrag,
                        "force_model.atmospheric_drag"
                      )

  @output_ids %{
    :access_windows => "event.access_windows",
    "access_windows" => "event.access_windows",
    :eclipses => "event.eclipses",
    "eclipses" => "event.eclipses",
    :target_visibility => "event.target_visibility",
    "target_visibility" => "event.target_visibility",
    :ground_track_crossings => "event.ground_track_crossings",
    "ground_track_crossings" => "event.ground_track_crossings"
  }

  def all, do: @records

  def fetch(id) when is_binary(id), do: Map.fetch(@records, id)

  def fetch(module) when is_atom(module) do
    with {:ok, id} <- Map.fetch(@implementation_ids, module) do
      fetch(id)
    end
  end

  def propagator_ids, do: @propagator_ids

  def output_ids, do: @output_ids
end
