defmodule OrbitalDynamics.OrbitDataTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{OrbitData, Schema}

  test "declares orbit-data adapter capabilities" do
    assert %{
             artifact_contract: "accepted_planning_state.v1",
             validation_level: :artifact_contract,
             import_formats: import_formats,
             export_formats: export_formats,
             supported_frames: ["earth_inertial_j2000"],
             supported_opm_reference_frames: supported_opm_reference_frames,
             supported_oem_reference_frames: supported_oem_reference_frames,
             metadata_formats: metadata_formats,
             supported_tle_metadata_fields: tle_metadata_fields,
             supported_omm_metadata_fields: omm_metadata_fields,
             supported_opm_metadata_fields: metadata_fields,
             supported_opm_spacecraft_metadata_fields: spacecraft_metadata_fields,
             supported_opm_covariance_fields: opm_covariance_fields,
             supported_oem_metadata_fields: oem_metadata_fields,
             supported_oem_covariance_fields: oem_covariance_fields,
             oem_interpolation: oem_interpolation,
             supported_covariance_component_order: covariance_component_order,
             supported_opm_maneuver_metadata_blocks: :multiple,
             exported_opm_maneuver_metadata_blocks: :multiple,
             known_limits: known_limits
           } = OrbitData.capabilities()

    assert :simple_json_state_estimate_batch in import_formats
    assert :ccsds_opm_kvn_single_object_cartesian in import_formats
    assert :ccsds_oem_kvn_single_object_cartesian_ephemeris in import_formats
    assert :tle_two_line_element in metadata_formats
    assert :ccsds_omm_kvn_mean_elements in metadata_formats
    assert :ccsds_opm_kvn_single_object_cartesian in export_formats
    assert :ccsds_oem_kvn_single_object_cartesian_ephemeris in export_formats
    assert "EME2000" in supported_opm_reference_frames
    assert "ICRF" in supported_opm_reference_frames
    assert "EME2000" in supported_oem_reference_frames
    assert "CCSDS_OPM_VERS" in metadata_fields
    assert "CREATION_DATE" in metadata_fields
    assert "ORIGINATOR" in metadata_fields
    assert "COV_REF_FRAME" in metadata_fields
    assert "MASS" in metadata_fields
    assert "DRAG_AREA" in metadata_fields
    assert "SOLAR_RAD_COEFF" in metadata_fields

    assert spacecraft_metadata_fields == [
             "DRAG_AREA",
             "DRAG_COEFF",
             "SOLAR_RAD_AREA",
             "SOLAR_RAD_COEFF"
           ]

    assert "MAN_EPOCH" in metadata_fields
    assert "CCSDS_OEM_VERS" in oem_metadata_fields
    assert "CREATION_DATE" in oem_metadata_fields
    assert "ORIGINATOR" in oem_metadata_fields
    assert "COV_REF_FRAME" in oem_metadata_fields
    assert "START_TIME" in oem_metadata_fields
    assert "STOP_TIME" in oem_metadata_fields
    assert "USEABLE_START_TIME" in oem_metadata_fields
    assert "USEABLE_STOP_TIME" in oem_metadata_fields
    assert "CX_X" in opm_covariance_fields
    assert "CZ_DOT_Z_DOT" in opm_covariance_fields
    assert "EPOCH" in oem_covariance_fields
    assert "CX_X" in oem_covariance_fields
    assert "CZ_DOT_Z_DOT" in oem_covariance_fields

    assert oem_interpolation == %{
             mode: :explicit_opt_in,
             request_option: :interpolate,
             strategy_epoch_option: :strategy_epoch,
             source_revision_option: :source_revision,
             optional_max_bracket_option: :max_bracket_s,
             interpolation_method: "cubic_hermite_position_velocity",
             interpolation_method_version: "1",
             exact_epoch_policy: :exact_sample,
             coverage_policy: :declared_oem_coverage_and_source_bracket,
             extrapolation: :rejected,
             covariance: :source_metadata_preserved_not_interpolated,
             assumptions: [
               "OEM samples are Cartesian kilometers and kilometers per second",
               "endpoint velocities are position derivatives in the declared frame",
               "the requested strategy epoch uses the OEM time scale without conversion"
             ],
             known_limits: [
               "single object and single OEM metadata segment only",
               "Earth-centered EME2000, J2000, or ICRF inertial states only",
               "no extrapolation beyond the source sample bracket or declared coverage",
               "no frame or time-scale conversion",
               "source covariance is preserved as metadata and is not interpolated or propagated",
               "SHA-256 content identity does not authenticate the source authority"
             ]
           }

    assert covariance_component_order == [
             "x_km",
             "y_km",
             "z_km",
             "x_dot_km_s",
             "y_dot_km_s",
             "z_dot_km_s"
           ]

    assert "MEAN_MOTION" in tle_metadata_fields
    assert "MEAN_MOTION_FIRST_DERIVATIVE" in tle_metadata_fields
    assert "MEAN_MOTION_SECOND_DERIVATIVE" in tle_metadata_fields
    assert "BSTAR" in tle_metadata_fields
    assert "ORBITAL_PERIOD" in tle_metadata_fields
    assert "SEMI_MAJOR_AXIS" in tle_metadata_fields
    assert "PERIGEE_ALTITUDE" in tle_metadata_fields
    assert "APOGEE_ALTITUDE" in tle_metadata_fields
    assert "ALTITUDE_REGIME" in tle_metadata_fields
    assert "CCSDS_OMM_VERS" in omm_metadata_fields
    assert "MEAN_ELEMENT_THEORY" in omm_metadata_fields
    assert "NORAD_CAT_ID" in omm_metadata_fields
    assert "BSTAR" in omm_metadata_fields
    assert "MEAN_MOTION_DOT" in omm_metadata_fields
    assert :no_tle_sgp4_import in known_limits
    assert :tle_metadata_only_no_sgp4_state_generation in known_limits
    assert :tle_mean_element_altitudes_are_preflight_estimates in known_limits
    assert :single_object_tle_metadata_preflight_only in known_limits
    assert :no_omm_sgp4_import in known_limits
    assert :omm_metadata_only_no_state_generation in known_limits
    assert :omm_mean_elements_are_preflight_estimates in known_limits
    assert :single_object_opm_only in known_limits
    assert :single_object_oem_only in known_limits
    assert :oem_import_selects_one_sample_without_interpolation in known_limits
    assert :oem_interpolation_is_explicit_opt_in in known_limits
    assert :oem_interpolation_requires_declared_coverage_and_source_revision in known_limits
    assert :oem_interpolation_rejects_extrapolation in known_limits
    assert :oem_interpolation_covariance_is_preserved_not_interpolated in known_limits
    assert :oem_export_single_sample_no_interpolation in known_limits
    assert :opm_covariance_metadata_only_no_propagation in known_limits
    assert :oem_covariance_metadata_only_no_propagation in known_limits
    assert :duplicate_single_value_kvn_fields_rejected in known_limits
    assert :opm_spacecraft_metadata_only_no_propagation in known_limits
    refute :single_opm_maneuver_metadata_block in known_limits
    assert :opm_maneuver_metadata_only_no_propagation in known_limits
  end

  test "normalizes simple state estimates into accepted planning state artifacts" do
    artifact =
      OrbitData.accepted_planning_state!([state_estimate()],
        snapshot_id: "ops-state-1",
        accepted_at: "2026-05-14T00:00:00Z",
        source: %{system: :operator_import, source_id: "batch-1"},
        quality: %{level: :planning_accepted},
        provenance: %{
          created_by: "orbit_data_test",
          trust_boundary: "operator_supplied"
        }
      )

    assert artifact["artifact_type"] == "accepted_planning_state"
    assert artifact["snapshot_id"] == "ops-state-1"

    assert [state] = artifact["spacecraft_states"]
    assert state["spacecraft_id"] == "sat_1"
    assert state["scenario_id"] == "leo_1"
    assert state["epoch"] == %{"seconds_since_j2000" => 120.0, "time_scale" => "utc"}
    assert state["state_vector"]["position_km"] == [7000.0, 0.0, 0.0]
    assert state["state_vector"]["velocity_km_s"] == [0.0, 7.5, 0.0]
    assert state["source"] == %{"system" => "od_tool", "source_id" => "estimate-1"}

    assert state["provenance"] == %{
             "source" => "accepted_planning_state.provenance",
             "trust_boundary" => "operator_supplied"
           }

    assert state["quality"] == %{
             "level" => "accepted",
             "position_sigma_km" => [0.1, 0.1, 0.2],
             "velocity_sigma_km_s" => [0.001, 0.001, 0.002]
           }

    assert {:ok, %{"schema_contract" => "accepted_planning_state.v1"}} =
             Schema.validate_artifact(artifact, schema_contract: "accepted_planning_state.v1")
  end

  test "imports and exports a simple JSON state-estimate batch" do
    source = %{
      "snapshot_id" => "ops-state-json",
      "accepted_at" => "2026-05-14T00:00:00Z",
      "source" => %{"system" => "json_drop", "source_id" => "drop-1"},
      "quality" => %{"level" => "planning_accepted"},
      "provenance" => %{"received_by" => "operator"},
      "state_estimates" => [state_estimate()],
      "maneuver_execution_deltas" => [
        %{
          "activity_id" => "burn_1",
          "status" => "completed",
          "source" => %{"system" => "ops_log"},
          "quality" => %{"level" => "operator_reported"}
        }
      ]
    }

    assert {:ok, artifact} =
             source
             |> :json.encode()
             |> IO.iodata_to_binary()
             |> OrbitData.import_simple_json()

    assert artifact["snapshot_id"] == "ops-state-json"

    assert artifact["provenance"] == %{
             "received_by" => "operator",
             "input_format" => "simple_json_state_estimate_batch",
             "import_adapter" => "OrbitalDynamics.OrbitData.import_simple_json/2",
             "trust_boundary" => "external_orbit_data_adapter",
             "network_access" => false,
             "state_estimate_count" => 1
           }

    assert [
             %{
               "provenance" => %{
                 "trust_boundary" => "external_orbit_data_adapter",
                 "source" => "accepted_planning_state.provenance"
               }
             }
           ] = artifact["spacecraft_states"]

    assert [
             %{
               "activity_id" => "burn_1",
               "provenance" => %{
                 "trust_boundary" => "external_orbit_data_adapter",
                 "source" => "accepted_planning_state.provenance"
               }
             }
           ] = artifact["maneuver_execution_deltas"]

    assert {:ok, json} = OrbitData.export_simple_json(artifact)

    assert %{"artifact_type" => "accepted_planning_state", "snapshot_id" => "ops-state-json"} =
             :json.decode(json)
  end

  test "adds deterministic provenance defaults to simple JSON imports" do
    source = %{
      "snapshot_id" => "ops-state-json-default-provenance",
      "accepted_at" => "2026-05-14T00:00:00Z",
      "source" => %{"system" => "json_drop", "source_id" => "drop-2"},
      "quality" => %{"level" => "planning_accepted"},
      "state_estimates" => [state_estimate()]
    }

    assert {:ok, artifact} = OrbitData.import_simple_json(source)

    assert artifact["provenance"] == %{
             "input_format" => "simple_json_state_estimate_batch",
             "import_adapter" => "OrbitalDynamics.OrbitData.import_simple_json/2",
             "trust_boundary" => "external_orbit_data_adapter",
             "network_access" => false,
             "state_estimate_count" => 1
           }

    assert {:ok, %{"schema_contract" => "accepted_planning_state.v1"}} =
             Schema.validate_artifact(artifact, schema_contract: "accepted_planning_state.v1")
  end

  test "adds adapter provenance to explicit simple JSON import opts" do
    source = %{
      "snapshot_id" => "ops-state-json-opt-provenance",
      "accepted_at" => "2026-05-14T00:00:00Z",
      "source" => %{"system" => "json_drop", "source_id" => "drop-3"},
      "quality" => %{"level" => "planning_accepted"},
      "state_estimates" => [state_estimate()]
    }

    assert {:ok, artifact} =
             OrbitData.import_simple_json(source,
               provenance: %{received_by: "operator", ingest_ticket: "od-42"}
             )

    assert artifact["provenance"] == %{
             "received_by" => "operator",
             "ingest_ticket" => "od-42",
             "input_format" => "simple_json_state_estimate_batch",
             "import_adapter" => "OrbitalDynamics.OrbitData.import_simple_json/2",
             "trust_boundary" => "external_orbit_data_adapter",
             "network_access" => false,
             "state_estimate_count" => 1
           }
  end

  test "imports CCSDS OPM KVN into accepted planning state" do
    assert {:ok, artifact} = OrbitData.import_ccsds_opm(opm_kvn())

    assert artifact["snapshot_id"] == "ccsds_opm:1998-067A:120.0"
    assert artifact["source"]["format"] == "ccsds_opm_kvn"
    assert artifact["source"]["center_name"] == "EARTH"
    assert artifact["source"]["ref_frame"] == "EME2000"
    assert artifact["provenance"]["ccsds_opm_version"] == "2.0"
    assert artifact["provenance"]["input_format"] == "ccsds_opm_kvn"

    assert artifact["provenance"]["import_adapter"] ==
             "OrbitalDynamics.OrbitData.import_ccsds_opm/2"

    assert artifact["provenance"]["trust_boundary"] == "external_orbit_data_adapter"
    assert artifact["provenance"]["network_access"] == false
    assert artifact["provenance"]["covariance_reference_frame"] == "EME2000"
    assert artifact["provenance"]["covariance_status"] == "reference_frame_only_no_matrix_import"

    assert [
             %{
               "spacecraft_id" => "1998-067A",
               "scenario_id" => "1998-067A",
               "epoch" => %{"seconds_since_j2000" => 120.0, "time_scale" => "utc"},
               "frame" => "earth_inertial_j2000",
               "state_vector" => %{
                 "position_km" => position_km,
                 "velocity_km_s" => velocity_km_s
               },
               "metadata" => %{
                 "ccsds_opm_version" => "2.0",
                 "creation_date" => "2026-05-14T00:00:00Z",
                 "originator" => "OrbitalDynamicsTest",
                 "object_name" => "ISS",
                 "object_id" => "1998-067A",
                 "center_name" => "EARTH",
                 "ref_frame" => "EME2000",
                 "time_system" => "UTC",
                 "covariance_reference_frame" => "EME2000"
               },
               "quality" => %{
                 "level" => "accepted",
                 "covariance_reference_frame" => "EME2000",
                 "covariance_status" => "reference_frame_only_no_matrix_import"
               }
             }
           ] = artifact["spacecraft_states"]

    assert position_km == [7000.0, 0.0, 0.0]
    assert velocity_km_s == [0.0, 7.5, 0.0]

    assert {:ok, %{"schema_contract" => "accepted_planning_state.v1"}} =
             Schema.validate_artifact(artifact, schema_contract: "accepted_planning_state.v1")
  end

  test "imports OPM spacecraft mass metadata into accepted planning state" do
    assert {:ok, artifact} = OrbitData.import_ccsds_opm(opm_mass_kvn())

    assert [
             %{
               "dry_mass_kg" => 419_725.0,
               "metadata" => %{
                 "spacecraft_mass_kg" => 419_725.0
               }
             }
           ] = artifact["spacecraft_states"]

    assert {:ok, %{"schema_contract" => "accepted_planning_state.v1"}} =
             Schema.validate_artifact(artifact, schema_contract: "accepted_planning_state.v1")
  end

  test "exports single-state accepted planning state to deterministic CCSDS OPM KVN" do
    artifact =
      OrbitData.accepted_planning_state!([state_estimate()],
        snapshot_id: "ops-state-opm",
        accepted_at: "2026-05-14T00:00:00Z",
        source: %{system: :operator_import, source_id: "batch-1"},
        quality: %{level: :planning_accepted},
        provenance: %{
          created_by: "orbit_data_test",
          trust_boundary: "operator_supplied"
        }
      )

    assert {:ok, kvn} =
             OrbitData.export_ccsds_opm(artifact,
               creation_date: "2026-05-14T00:00:00Z",
               originator: "OrbitalDynamicsTest",
               object_id: "SAT-1"
             )

    assert kvn =~ "CCSDS_OPM_VERS = 2.0"
    assert kvn =~ "OBJECT_ID = SAT-1"
    assert kvn =~ "REF_FRAME = EME2000"
    assert kvn =~ "EPOCH = 2000-01-01T12:02:00.000000Z"

    assert {:ok, imported} = OrbitData.import_ccsds_opm(kvn)
    assert [state] = imported["spacecraft_states"]
    assert state["state_vector"]["position_km"] == [7000.0, 0.0, 0.0]
    assert state["state_vector"]["velocity_km_s"] == [0.0, 7.5, 0.0]
  end

  test "exports OPM KVN mass metadata from accepted planning state" do
    artifact =
      OrbitData.accepted_planning_state!([Map.put(state_estimate(), :dry_mass_kg, 420.5)],
        snapshot_id: "ops-state-opm-mass",
        accepted_at: "2026-05-14T00:00:00Z",
        source: %{system: :operator_import, source_id: "batch-1"},
        quality: %{level: :planning_accepted},
        provenance: %{
          created_by: "orbit_data_test",
          trust_boundary: "operator_supplied"
        }
      )

    assert {:ok, kvn} =
             OrbitData.export_ccsds_opm(artifact,
               creation_date: "2026-05-14T00:00:00Z",
               originator: "OrbitalDynamicsTest",
               object_id: "SAT-1"
             )

    assert kvn =~ "MASS = 420.5 [kg]"

    assert {:ok, imported} = OrbitData.import_ccsds_opm(kvn)

    assert [%{"dry_mass_kg" => 420.5, "metadata" => %{"spacecraft_mass_kg" => 420.5}}] =
             imported["spacecraft_states"]

    assert {:ok, %{"schema_contract" => "accepted_planning_state.v1"}} =
             Schema.validate_artifact(imported, schema_contract: "accepted_planning_state.v1")
  end

  test "imports and exports OPM spacecraft physical metadata without propagation" do
    assert {:ok, artifact} = OrbitData.import_ccsds_opm(opm_spacecraft_metadata_kvn())

    assert artifact["provenance"]["opm_spacecraft_metadata_status"] ==
             "metadata_only_no_propagation"

    assert [
             %{
               "metadata" => %{
                 "drag_area_m2" => 18.5,
                 "drag_coefficient" => 2.2,
                 "solar_radiation_pressure_area_m2" => 12.25,
                 "solar_radiation_pressure_coefficient" => 1.3,
                 "opm_spacecraft_metadata_status" => "metadata_only_no_propagation"
               }
             }
           ] = artifact["spacecraft_states"]

    assert {:ok, kvn} =
             OrbitData.export_ccsds_opm(artifact,
               creation_date: "2026-05-14T00:00:00Z",
               originator: "OrbitalDynamicsTest"
             )

    assert kvn =~ "DRAG_AREA = 18.5 [m**2]"
    assert kvn =~ "DRAG_COEFF = 2.2"
    assert kvn =~ "SOLAR_RAD_AREA = 12.25 [m**2]"
    assert kvn =~ "SOLAR_RAD_COEFF = 1.3"

    assert {:ok, round_trip} = OrbitData.import_ccsds_opm(kvn)

    assert get_in(round_trip, ["spacecraft_states", Access.at(0), "metadata", "drag_area_m2"]) ==
             18.5

    assert {:ok, %{"schema_contract" => "accepted_planning_state.v1"}} =
             Schema.validate_artifact(round_trip, schema_contract: "accepted_planning_state.v1")
  end

  test "exports OPM KVN covariance reference frame provenance without covariance matrix" do
    estimate =
      state_estimate()
      |> put_in([:quality, :covariance_reference_frame], "EME2000")

    artifact =
      OrbitData.accepted_planning_state!([estimate],
        snapshot_id: "ops-state-opm-cov-ref",
        accepted_at: "2026-05-14T00:00:00Z",
        source: %{system: :operator_import, source_id: "batch-1"},
        quality: %{level: :planning_accepted},
        provenance: %{
          created_by: "orbit_data_test",
          trust_boundary: "operator_supplied"
        }
      )

    assert {:ok, kvn} =
             OrbitData.export_ccsds_opm(artifact,
               creation_date: "2026-05-14T00:00:00Z",
               originator: "OrbitalDynamicsTest",
               object_id: "SAT-1"
             )

    assert kvn =~ "COV_REF_FRAME = EME2000"
    refute kvn =~ "CX_X"

    assert {:ok, imported} = OrbitData.import_ccsds_opm(kvn)

    assert [
             %{
               "quality" => %{
                 "covariance_reference_frame" => "EME2000",
                 "covariance_status" => "reference_frame_only_no_matrix_import"
               }
             }
           ] = imported["spacecraft_states"]

    assert {:ok, %{"schema_contract" => "accepted_planning_state.v1"}} =
             Schema.validate_artifact(imported, schema_contract: "accepted_planning_state.v1")
  end

  test "imports and exports OPM KVN covariance matrix metadata without propagation" do
    assert {:ok, artifact} = OrbitData.import_ccsds_opm(opm_covariance_kvn())

    assert artifact["provenance"]["covariance_status"] ==
             "matrix_imported_metadata_only_no_propagation"

    assert artifact["provenance"]["covariance_component_order"] == [
             "x_km",
             "y_km",
             "z_km",
             "x_dot_km_s",
             "y_dot_km_s",
             "z_dot_km_s"
           ]

    assert [
             %{
               "quality" => %{
                 "covariance_reference_frame" => "EME2000",
                 "covariance_status" => "matrix_imported_metadata_only_no_propagation",
                 "covariance_component_order" => [
                   "x_km",
                   "y_km",
                   "z_km",
                   "x_dot_km_s",
                   "y_dot_km_s",
                   "z_dot_km_s"
                 ],
                 "covariance_matrix_6x6" => covariance
               }
             }
           ] = artifact["spacecraft_states"]

    assert covariance |> Enum.at(0) |> Enum.at(0) == 1.0e-4
    assert covariance |> Enum.at(3) |> Enum.at(0) == 4.0e-7
    assert covariance |> Enum.at(0) |> Enum.at(3) == 4.0e-7
    assert covariance |> Enum.at(5) |> Enum.at(5) == 2.1e-8

    assert {:ok, kvn} =
             OrbitData.export_ccsds_opm(artifact,
               creation_date: "2026-05-14T00:00:00Z",
               originator: "OrbitalDynamicsTest"
             )

    assert kvn =~ "CX_X = 0.0001"
    assert kvn =~ "CX_DOT_X = 0.0000004"
    assert kvn =~ "CZ_DOT_Z_DOT = 0.000000021"

    assert {:ok, round_trip} = OrbitData.import_ccsds_opm(kvn)

    assert get_in(round_trip, ["spacecraft_states", Access.at(0), "quality"])[
             "covariance_matrix_6x6"
           ] == covariance

    assert {:ok, %{"schema_contract" => "accepted_planning_state.v1"}} =
             Schema.validate_artifact(artifact, schema_contract: "accepted_planning_state.v1")
  end

  test "exports OPM KVN using preserved object metadata" do
    assert {:ok, artifact} = OrbitData.import_ccsds_opm(opm_kvn())

    assert {:ok, kvn} = OrbitData.export_ccsds_opm(artifact)

    assert kvn =~ "CREATION_DATE = 2026-05-14T00:00:00Z"
    assert kvn =~ "ORIGINATOR = OrbitalDynamicsTest"
    assert kvn =~ "OBJECT_NAME = ISS"
    assert kvn =~ "OBJECT_ID = 1998-067A"
    assert kvn =~ "CENTER_NAME = EARTH"
    assert kvn =~ "REF_FRAME = EME2000"
  end

  test "exports OEM KVN using preserved object metadata" do
    assert {:ok, artifact} = OrbitData.import_ccsds_oem(oem_kvn())

    assert {:ok, kvn} = OrbitData.export_ccsds_oem(artifact)

    assert kvn =~ "CREATION_DATE = 2026-05-14T00:00:00Z"
    assert kvn =~ "ORIGINATOR = OrbitalDynamicsTest"
    assert kvn =~ "OBJECT_NAME = ISS"
    assert kvn =~ "OBJECT_ID = 1998-067A"
    assert kvn =~ "CENTER_NAME = EARTH"
    assert kvn =~ "REF_FRAME = EME2000"
  end

  test "top-level facades export accepted planning state interchange formats" do
    artifact =
      OrbitData.accepted_planning_state!([Map.put(state_estimate(), :dry_mass_kg, 420.5)],
        snapshot_id: "ops-state-facade-export",
        accepted_at: "2026-05-14T00:00:00Z",
        source: %{system: :operator_import, source_id: "batch-1"},
        quality: %{level: :planning_accepted},
        provenance: %{
          created_by: "orbit_data_test",
          trust_boundary: "operator_supplied"
        }
      )

    assert {:ok, json} = OrbitalDynamics.export_orbit_data_json(artifact)
    assert %{"snapshot_id" => "ops-state-facade-export"} = :json.decode(json)

    assert {:ok, opm} =
             OrbitalDynamics.export_ccsds_opm(artifact,
               creation_date: "2026-05-14T00:00:00Z",
               object_id: "SAT-1"
             )

    assert opm =~ "CCSDS_OPM_VERS = 2.0"
    assert opm =~ "MASS = 420.5 [kg]"

    assert {:ok, oem} =
             OrbitalDynamics.export_ccsds_oem(artifact,
               creation_date: "2026-05-14T00:00:00Z",
               object_id: "SAT-1"
             )

    assert oem =~ "CCSDS_OEM_VERS = 2.0"
    assert oem =~ "INTERPOLATION = NONE"
  end

  test "preserves single CCSDS OPM maneuver metadata as execution delta evidence" do
    assert {:ok, artifact} = OrbitData.import_ccsds_opm(opm_maneuver_kvn())

    assert artifact["provenance"]["opm_maneuver_metadata_count"] == 1

    assert artifact["provenance"]["opm_maneuver_metadata_status"] ==
             "metadata_only_no_propagation"

    assert [
             %{
               "metadata" => %{
                 "opm_maneuver_metadata_count" => 1,
                 "opm_maneuver_metadata_status" => "metadata_only_no_propagation"
               }
             }
           ] = artifact["spacecraft_states"]

    assert [
             %{
               "activity_id" => "ccsds_opm_maneuver:1998-067A:240.0",
               "status" => "reported",
               "epoch_s" => 240.0,
               "delta_v_km_s" => delta_v_km_s,
               "source" => %{
                 "format" => "ccsds_opm_kvn",
                 "object_id" => "1998-067A",
                 "maneuver_source" => "opm_man_fields",
                 "maneuver_reference_frame" => "EME2000"
               },
               "quality" => %{
                 "level" => "metadata_only",
                 "maneuver_status" => "declared_no_execution_confirmation"
               },
               "provenance" => %{
                 "trust_boundary" => "external_orbit_data_adapter",
                 "source" => "accepted_planning_state.provenance"
               },
               "metadata" => %{
                 "man_duration_s" => 12.0,
                 "man_delta_mass_kg" => -0.05,
                 "man_ref_frame" => "EME2000",
                 "model_limit" => "maneuver_metadata_preserved_without_propagation"
               }
             }
           ] = artifact["maneuver_execution_deltas"]

    assert delta_v_km_s == [0.0, 0.001, 0.0]

    assert {:ok, %{"schema_contract" => "accepted_planning_state.v1"}} =
             Schema.validate_artifact(artifact, schema_contract: "accepted_planning_state.v1")
  end

  test "preserves multiple CCSDS OPM maneuver metadata blocks as execution delta evidence" do
    assert {:ok, artifact} = OrbitData.import_ccsds_opm(opm_multiple_maneuver_kvn())

    assert artifact["provenance"]["opm_maneuver_metadata_count"] == 2

    assert artifact["provenance"]["opm_maneuver_metadata_status"] ==
             "metadata_only_no_propagation"

    assert [
             %{
               "metadata" => %{
                 "opm_maneuver_metadata_count" => 2,
                 "opm_maneuver_metadata_status" => "metadata_only_no_propagation"
               }
             }
           ] = artifact["spacecraft_states"]

    assert [
             %{
               "activity_id" => "ccsds_opm_maneuver:1998-067A:240.0",
               "epoch_s" => 240.0,
               "delta_v_km_s" => first_delta_v_km_s,
               "metadata" => %{
                 "man_epoch" => "2000-01-01T12:04:00.000",
                 "man_duration_s" => 12.0,
                 "man_delta_mass_kg" => -0.05
               }
             },
             %{
               "activity_id" => "ccsds_opm_maneuver:1998-067A:390.0",
               "epoch_s" => 390.0,
               "delta_v_km_s" => second_delta_v_km_s,
               "source" => %{
                 "maneuver_reference_frame" => "EME2000"
               },
               "provenance" => %{
                 "trust_boundary" => "external_orbit_data_adapter",
                 "source" => "accepted_planning_state.provenance"
               },
               "metadata" => %{
                 "man_epoch" => "2000-01-01T12:06:30.000",
                 "man_duration_s" => 20.0,
                 "man_delta_mass_kg" => -0.03,
                 "model_limit" => "maneuver_metadata_preserved_without_propagation"
               }
             }
           ] = artifact["maneuver_execution_deltas"]

    assert first_delta_v_km_s == [0.0, 0.001, 0.0]
    assert second_delta_v_km_s == [0.0005, 0.0, 0.0]

    assert {:ok, kvn} =
             OrbitData.export_ccsds_opm(artifact,
               creation_date: "2026-05-14T00:00:00Z",
               originator: "OrbitalDynamicsTest"
             )

    assert kvn =~ "MAN_EPOCH = 2000-01-01T12:04:00.000"
    assert kvn =~ "MAN_DURATION = 12.0 [s]"
    assert kvn =~ "MAN_DELTA_MASS = -0.05 [kg]"
    assert kvn =~ "MAN_DV_2 = 0.001 [km/s]"
    assert kvn =~ "MAN_EPOCH = 2000-01-01T12:06:30.000"
    assert kvn =~ "MAN_DURATION = 20.0 [s]"
    assert kvn =~ "MAN_DV_1 = 0.0005 [km/s]"

    assert {:ok, round_trip} = OrbitData.import_ccsds_opm(kvn)

    assert [
             %{
               "epoch_s" => first_round_trip_epoch_s,
               "delta_v_km_s" => first_round_trip_delta_v_km_s,
               "metadata" => %{
                 "man_duration_s" => first_round_trip_duration_s,
                 "man_delta_mass_kg" => first_round_trip_delta_mass_kg
               }
             },
             %{
               "epoch_s" => second_round_trip_epoch_s,
               "delta_v_km_s" => second_round_trip_delta_v_km_s,
               "metadata" => %{
                 "man_duration_s" => second_round_trip_duration_s,
                 "man_delta_mass_kg" => second_round_trip_delta_mass_kg
               }
             }
           ] = round_trip["maneuver_execution_deltas"]

    assert first_round_trip_epoch_s == 240.0
    assert first_round_trip_delta_v_km_s == [0.0, 0.001, 0.0]
    assert first_round_trip_duration_s == 12.0
    assert first_round_trip_delta_mass_kg == -0.05
    assert second_round_trip_epoch_s == 390.0
    assert second_round_trip_delta_v_km_s == [0.0005, 0.0, 0.0]
    assert second_round_trip_duration_s == 20.0
    assert second_round_trip_delta_mass_kg == -0.03

    assert {:ok, %{"schema_contract" => "accepted_planning_state.v1"}} =
             Schema.validate_artifact(artifact, schema_contract: "accepted_planning_state.v1")
  end

  test "imports CCSDS OEM KVN by selecting one ephemeris sample" do
    assert {:ok, artifact} = OrbitData.import_ccsds_oem(oem_kvn(), sample: :last)

    assert artifact["snapshot_id"] == "ccsds_oem:1998-067A:180.0"
    assert artifact["source"]["format"] == "ccsds_oem_kvn"
    assert artifact["provenance"]["ccsds_oem_version"] == "2.0"
    assert artifact["provenance"]["input_format"] == "ccsds_oem_kvn"

    assert artifact["provenance"]["import_adapter"] ==
             "OrbitalDynamics.OrbitData.import_ccsds_oem/2"

    assert artifact["provenance"]["trust_boundary"] == "external_orbit_data_adapter"
    assert artifact["provenance"]["network_access"] == false

    assert artifact["provenance"]["sample_selection"] ==
             "single_ephemeris_sample_no_interpolation"

    assert artifact["provenance"]["sample_index"] == 1
    assert artifact["provenance"]["sample_epoch"] == "2000-01-01T12:03:00.000"

    assert [
             %{
               "spacecraft_id" => "1998-067A",
               "scenario_id" => "1998-067A",
               "epoch" => %{"seconds_since_j2000" => 180.0, "time_scale" => "utc"},
               "frame" => "earth_inertial_j2000",
               "state_vector" => %{
                 "position_km" => position_km,
                 "velocity_km_s" => velocity_km_s
               },
               "metadata" => %{
                 "input_format" => "ccsds_oem_kvn",
                 "ccsds_oem_version" => "2.0",
                 "creation_date" => "2026-05-14T00:00:00Z",
                 "originator" => "OrbitalDynamicsTest",
                 "object_name" => "ISS",
                 "object_id" => "1998-067A",
                 "interpolation" => "LAGRANGE",
                 "interpolation_degree" => "1",
                 "sample_index" => 1
               }
             }
           ] = artifact["spacecraft_states"]

    assert position_km == [6990.0, 450.0, 0.0]
    assert velocity_km_s == [-0.5, 7.49, 0.0]

    assert {:ok, %{"schema_contract" => "accepted_planning_state.v1"}} =
             Schema.validate_artifact(artifact, schema_contract: "accepted_planning_state.v1")
  end

  test "imports OEM covariance matrix metadata without propagation" do
    assert {:ok, artifact} = OrbitData.import_ccsds_oem(oem_covariance_kvn(), sample: :last)

    assert artifact["provenance"]["covariance_status"] ==
             "matrix_imported_metadata_only_no_propagation"

    assert artifact["provenance"]["covariance_reference_frame"] == "EME2000"
    assert artifact["provenance"]["covariance_epoch"] == "2000-01-01T12:03:00.000"

    assert artifact["provenance"]["covariance_component_order"] == [
             "x_km",
             "y_km",
             "z_km",
             "x_dot_km_s",
             "y_dot_km_s",
             "z_dot_km_s"
           ]

    assert [
             %{
               "metadata" => %{
                 "covariance_reference_frame" => "EME2000",
                 "covariance_epoch" => "2000-01-01T12:03:00.000",
                 "covariance_status" => "matrix_imported_metadata_only_no_propagation"
               },
               "quality" => %{
                 "covariance_reference_frame" => "EME2000",
                 "covariance_status" => "matrix_imported_metadata_only_no_propagation",
                 "covariance_epoch" => "2000-01-01T12:03:00.000",
                 "covariance_component_order" => [
                   "x_km",
                   "y_km",
                   "z_km",
                   "x_dot_km_s",
                   "y_dot_km_s",
                   "z_dot_km_s"
                 ],
                 "covariance_matrix_6x6" => covariance
               }
             }
           ] = artifact["spacecraft_states"]

    assert covariance |> Enum.at(0) |> Enum.at(0) == 1.0e-4
    assert covariance |> Enum.at(3) |> Enum.at(0) == 4.0e-7
    assert covariance |> Enum.at(0) |> Enum.at(3) == 4.0e-7
    assert covariance |> Enum.at(5) |> Enum.at(5) == 2.1e-8

    assert {:ok, kvn} =
             OrbitData.export_ccsds_oem(artifact,
               creation_date: "2026-05-14T00:00:00Z",
               originator: "OrbitalDynamicsTest"
             )

    assert kvn =~ "COVARIANCE_START"
    assert kvn =~ "EPOCH = 2000-01-01T12:03:00.000"
    assert kvn =~ "COV_REF_FRAME = EME2000"
    assert kvn =~ "CX_DOT_X = 0.0000004"
    assert kvn =~ "COVARIANCE_STOP"

    assert {:ok, round_trip} = OrbitData.import_ccsds_oem(kvn)

    assert get_in(round_trip, ["spacecraft_states", Access.at(0), "quality"])[
             "covariance_matrix_6x6"
           ] == covariance

    assert {:ok, %{"schema_contract" => "accepted_planning_state.v1"}} =
             Schema.validate_artifact(artifact, schema_contract: "accepted_planning_state.v1")
  end

  test "exports single-state accepted planning state to single-sample CCSDS OEM KVN" do
    artifact =
      OrbitData.accepted_planning_state!([state_estimate()],
        snapshot_id: "ops-state-oem",
        accepted_at: "2026-05-14T00:00:00Z",
        source: %{system: :operator_import, source_id: "batch-1"},
        quality: %{level: :planning_accepted},
        provenance: %{
          created_by: "orbit_data_test",
          trust_boundary: "operator_supplied"
        }
      )

    assert {:ok, kvn} =
             OrbitData.export_ccsds_oem(artifact,
               creation_date: "2026-05-14T00:00:00Z",
               originator: "OrbitalDynamicsTest",
               object_id: "SAT-1"
             )

    assert kvn =~ "CCSDS_OEM_VERS = 2.0"
    assert kvn =~ "OBJECT_ID = SAT-1"
    assert kvn =~ "INTERPOLATION = NONE"
    assert kvn =~ "INTERPOLATION_DEGREE = 0"
    assert kvn =~ "2000-01-01T12:02:00.000000Z 7000.0 0.0 0.0 0.0 7.5 0.0"

    assert {:ok, imported} = OrbitData.import_ccsds_oem(kvn)
    assert [state] = imported["spacecraft_states"]
    assert state["state_vector"]["position_km"] == [7000.0, 0.0, 0.0]
    assert state["state_vector"]["velocity_km_s"] == [0.0, 7.5, 0.0]
    assert state["metadata"]["interpolation"] == "NONE"
    assert state["metadata"]["interpolation_degree"] == "0"
  end

  test "imports orbit-data wrapper formats" do
    assert {:ok, artifact} =
             OrbitData.import_orbit_data(%{
               "format" => "ccsds_oem_kvn",
               "content" => oem_kvn(),
               "sample" => "first",
               "snapshot_id" => "ops-oem-wrapper",
               "quality" => %{"level" => "planning_accepted"},
               "provenance" => %{"received_by" => "operator"}
             })

    assert artifact["snapshot_id"] == "ops-oem-wrapper"
    assert artifact["quality"] == %{"level" => "planning_accepted"}
    assert artifact["provenance"]["received_by"] == "operator"
    assert artifact["provenance"]["input_format"] == "ccsds_oem_kvn"

    assert artifact["provenance"]["import_adapter"] ==
             "OrbitalDynamics.OrbitData.import_ccsds_oem/2"

    assert artifact["provenance"]["trust_boundary"] == "external_orbit_data_adapter"
    assert artifact["provenance"]["sample_index"] == 0
  end

  test "top-level orbit-data facade imports wrapper formats" do
    assert {:ok, artifact} =
             OrbitalDynamics.import_orbit_data(%{
               "format" => "ccsds_oem_kvn",
               "content" => oem_kvn(),
               "sample" => "last",
               "snapshot_id" => "ops-oem-facade",
               "quality" => %{"level" => "planning_accepted"}
             })

    assert artifact["snapshot_id"] == "ops-oem-facade"

    assert [
             %{
               "state_vector" => %{
                 "position_km" => position_km,
                 "velocity_km_s" => velocity_km_s
               }
             }
           ] = artifact["spacecraft_states"]

    assert position_km == [6990.0, 450.0, 0.0]
    assert velocity_km_s == [-0.5, 7.49, 0.0]
  end

  test "top-level facades import direct OPM and OEM KVN formats" do
    assert {:ok, opm_artifact} = OrbitalDynamics.import_ccsds_opm(opm_kvn())
    assert opm_artifact["snapshot_id"] == "ccsds_opm:1998-067A:120.0"
    assert opm_artifact["provenance"]["input_format"] == "ccsds_opm_kvn"

    assert {:ok, oem_artifact} = OrbitalDynamics.import_ccsds_oem(oem_kvn(), sample: :last)
    assert oem_artifact["snapshot_id"] == "ccsds_oem:1998-067A:180.0"
    assert oem_artifact["provenance"]["sample_index"] == 1

    assert {:ok, %{"schema_contract" => "accepted_planning_state.v1"}} =
             Schema.validate_artifact(opm_artifact, schema_contract: "accepted_planning_state.v1")

    assert {:ok, %{"schema_contract" => "accepted_planning_state.v1"}} =
             Schema.validate_artifact(oem_artifact, schema_contract: "accepted_planning_state.v1")
  end

  test "inspects TLE metadata without generating accepted Cartesian state" do
    assert {:ok, metadata} =
             OrbitData.inspect_tle(tle(),
               source: %{"system" => "space_track_drop"},
               provenance: %{"received_by" => "operator"}
             )

    assert metadata["format"] == "tle_two_line_element"
    assert metadata["object_name"] == "ISS (ZARYA)"
    assert metadata["satellite_catalog_number"] == "25544"
    assert metadata["international_designator"] == "98067A"
    assert metadata["epoch"]["year"] == 2020
    assert_in_delta metadata["epoch"]["day_of_year"], 29.54791435, 1.0e-10
    assert metadata["inclination_deg"] == 51.6432
    assert metadata["raan_deg"] == 23.4361
    assert metadata["eccentricity"] == 0.0007417
    assert metadata["mean_motion_first_derivative"] == 0.00000726
    assert metadata["mean_motion_second_derivative"] == 0.0
    assert metadata["bstar"] == 0.000020456
    assert metadata["mean_motion_rev_per_day"] == 15.49147121
    assert_in_delta metadata["orbital_period_min"], 92.954, 0.001
    assert_in_delta metadata["semi_major_axis_km"], 6797.36, 0.1
    assert_in_delta metadata["perigee_altitude_km"], 414.0, 0.5
    assert_in_delta metadata["apogee_altitude_km"], 424.1, 0.5
    assert metadata["altitude_regime"] == "leo"
    assert metadata["mean_element_analysis_status"] == "preflight_estimate_not_sgp4_state"
    assert metadata["accepted_planning_state_compatible"] == false
    assert metadata["required_propagation_regime"] == "sgp4"
    assert metadata["state_vector_status"] == "not_generated"
    assert "tle_mean_element_altitudes_are_preflight_estimates" in metadata["known_limits"]
    assert metadata["source"] == %{"system" => "space_track_drop"}

    assert metadata["provenance"] == %{
             "received_by" => "operator",
             "input_format" => "tle_two_line_element",
             "import_adapter" => "OrbitalDynamics.OrbitData.inspect_tle/2",
             "trust_boundary" => "external_orbit_data_adapter",
             "network_access" => false
           }
  end

  test "rejects TLE wrappers as accepted planning-state imports" do
    assert {:error, {:unsupported_field, "format", "tle_requires_separate_sgp4_regime", metadata}} =
             OrbitData.import_orbit_data(%{"format" => "tle", "content" => tle()})

    assert metadata["satellite_catalog_number"] == "25544"
    assert metadata["accepted_planning_state_compatible"] == false
    assert metadata["altitude_regime"] == "leo"
    assert metadata["state_vector_status"] == "not_generated"
  end

  test "inspects CCSDS OMM metadata without generating accepted Cartesian state" do
    assert {:ok, metadata} =
             OrbitalDynamics.inspect_ccsds_omm(omm_kvn(),
               source: %{"system" => "catalog_drop"},
               provenance: %{"received_by" => "operator"}
             )

    assert metadata["format"] == "ccsds_omm_kvn"
    assert metadata["ccsds_omm_version"] == "2.0"
    assert metadata["object_name"] == "ISS"
    assert metadata["object_id"] == "1998-067A"
    assert metadata["norad_catalog_id"] == "25544"
    assert metadata["center_name"] == "EARTH"
    assert metadata["ref_frame"] == "TEME"
    assert metadata["time_system"] == "utc"
    assert metadata["mean_element_theory"] == "SGP4"
    assert metadata["epoch"]["iso8601"] == "2020-01-29T13:08:59.800000Z"
    assert metadata["inclination_deg"] == 51.6432
    assert metadata["raan_deg"] == 23.4361
    assert metadata["eccentricity"] == 0.0007417
    assert metadata["argument_of_pericenter_deg"] == 66.369
    assert metadata["mean_anomaly_deg"] == 60.5128
    assert metadata["mean_motion_rev_per_day"] == 15.49147121
    assert metadata["mean_motion_first_derivative"] == 0.00000726
    assert metadata["mean_motion_second_derivative"] == 0.0
    assert metadata["bstar"] == 0.000020456
    assert_in_delta metadata["orbital_period_min"], 92.954, 0.001
    assert_in_delta metadata["semi_major_axis_km"], 6797.36, 0.1
    assert_in_delta metadata["perigee_altitude_km"], 414.0, 0.5
    assert_in_delta metadata["apogee_altitude_km"], 424.1, 0.5
    assert metadata["altitude_regime"] == "leo"
    assert metadata["mean_element_analysis_status"] == "preflight_estimate_not_cartesian_state"
    assert metadata["accepted_planning_state_compatible"] == false
    assert metadata["required_propagation_regime"] == "sgp4"
    assert metadata["state_vector_status"] == "not_generated"
    assert "omm_mean_element_altitudes_are_preflight_estimates" in metadata["known_limits"]
    assert metadata["source"] == %{"system" => "catalog_drop"}

    assert metadata["provenance"] == %{
             "received_by" => "operator",
             "input_format" => "ccsds_omm_kvn",
             "import_adapter" => "OrbitalDynamics.OrbitData.inspect_ccsds_omm/2",
             "trust_boundary" => "external_orbit_data_adapter",
             "network_access" => false
           }
  end

  test "rejects CCSDS OMM wrappers as accepted planning-state imports" do
    assert {:error,
            {:unsupported_field, "format", "omm_requires_separate_propagation_regime", metadata}} =
             OrbitData.import_orbit_data(%{"format" => "ccsds_omm_kvn", "content" => omm_kvn()})

    assert metadata["object_id"] == "1998-067A"
    assert metadata["accepted_planning_state_compatible"] == false
    assert metadata["altitude_regime"] == "leo"
    assert metadata["state_vector_status"] == "not_generated"
  end

  test "rejects malformed CCSDS OMM metadata input" do
    assert {:error, {:missing_field, "MEAN_ELEMENT_THEORY"}} =
             OrbitData.inspect_ccsds_omm("""
             CCSDS_OMM_VERS = 2.0
             OBJECT_NAME = ISS
             EPOCH = 2020-01-29T13:08:59.800000Z
             INCLINATION = 51.6432 [deg]
             RA_OF_ASC_NODE = 23.4361 [deg]
             ECCENTRICITY = 0.0007417
             ARG_OF_PERICENTER = 66.3690 [deg]
             MEAN_ANOMALY = 60.5128 [deg]
             MEAN_MOTION = 15.49147121 [rev/day]
             """)

    assert {:error, {:unsupported_field, "ccsds_omm.duplicate_single_value_field", "OBJECT_ID"}} =
             OrbitData.inspect_ccsds_omm("""
             #{omm_kvn()}
             OBJECT_ID = 1998-067B
             """)
  end

  test "rejects malformed TLE metadata input" do
    assert {:error, {:invalid_field, "tle.checksum"}} =
             OrbitData.inspect_tle("""
             ISS (ZARYA)
             1 25544U 98067A   20029.54791435  .00000726  00000-0  20456-4 0  9990
             2 25544  51.6432  23.4361 0007417  66.3690  60.5128 15.49147121210618
             """)

    assert {:error, {:invalid_field, "tle.satellite_catalog_number"}} =
             OrbitData.inspect_tle("""
             1 25544U 98067A   20029.54791435  .00000726  00000-0  20456-4 0  9997
             2 25545  51.6432  23.4361 0007417  66.3690  60.5128 15.49147121210618
             """)
  end

  test "rejects ambiguous multi-object TLE metadata preflight input" do
    assert {:error, {:unsupported_field, "tle.multiple_objects"}} =
             OrbitData.inspect_tle("""
             ISS (ZARYA)
             1 25544U 98067A   20029.54791435  .00000726  00000-0  20456-4 0  9997
             2 25544  51.6432  23.4361 0007417  66.3690  60.5128 15.49147121210618
             NOAA 15
             1 25338U 98030A   20029.46326556  .00000072  00000-0  64152-4 0  9997
             2 25338  98.7260  44.0125 0011180  57.0101 303.2165 14.25902222129844
             """)
  end

  test "rejects incomplete CCSDS OPM KVN input" do
    assert {:error, {:invalid_field, "position_km"}} =
             OrbitData.import_ccsds_opm("""
             CCSDS_OPM_VERS = 2.0
             OBJECT_NAME = SAT-1
             EPOCH = 2000-01-01T12:02:00.000
             X = 7000 [km]
             """)
  end

  test "rejects unsupported OPM centers and incomplete covariance matrices" do
    assert {:error, {:unsupported_field, "CENTER_NAME"}} =
             OrbitData.import_ccsds_opm("""
             CCSDS_OPM_VERS = 2.0
             CREATION_DATE = 2026-05-14T00:00:00Z
             ORIGINATOR = OrbitalDynamicsTest
             OBJECT_NAME = MARS-SAT
             CENTER_NAME = MARS
             REF_FRAME = EME2000
             TIME_SYSTEM = UTC
             EPOCH = 2000-01-01T12:02:00.000
             X = 7000 [km]
             Y = 0 [km]
             Z = 0 [km]
             X_DOT = 0 [km/s]
             Y_DOT = 7.5 [km/s]
             Z_DOT = 0 [km/s]
             """)

    assert {:error, {:missing_field, "covariance_matrix.CY_X"}} =
             OrbitData.import_ccsds_opm("""
             #{opm_kvn()}
             CX_X = 1.0 [km**2]
             """)
  end

  test "rejects duplicate OPM single-value fields instead of using last write wins" do
    assert {:error, {:unsupported_field, "ccsds_opm.duplicate_single_value_field", "OBJECT_ID"}} =
             OrbitData.import_ccsds_opm("""
             #{opm_kvn()}
             OBJECT_ID = SECOND-OBJECT
             """)
  end

  test "rejects unsupported CCSDS OEM shapes" do
    assert {:error, {:missing_field, "ephemeris_data"}} =
             OrbitData.import_ccsds_oem("""
             CCSDS_OEM_VERS = 2.0
             OBJECT_NAME = ISS
             OBJECT_ID = 1998-067A
             CENTER_NAME = EARTH
             REF_FRAME = EME2000
             TIME_SYSTEM = UTC
             """)

    assert {:error, {:missing_field, "covariance_matrix.CY_X"}} =
             OrbitData.import_ccsds_oem("""
             #{oem_kvn()}
             COVARIANCE_START
             CX_X = 1.0e-4 [km**2]
             COVARIANCE_STOP
             """)

    assert {:error, {:invalid_field, "sample"}} =
             OrbitData.import_ccsds_oem(oem_kvn(), sample: :middle)
  end

  test "rejects duplicate OEM single-value fields instead of using last write wins" do
    assert {:error, {:unsupported_field, "ccsds_oem.duplicate_single_value_field", "OBJECT_ID"}} =
             OrbitData.import_ccsds_oem("""
             #{oem_kvn()}
             OBJECT_ID = SECOND-OBJECT
             """)
  end

  test "rejects invalid state vector estimates" do
    bad_estimate =
      state_estimate()
      |> put_in([:position_km], [7000.0, 0.0])

    assert {:error, {:invalid_field, "state_estimates[0].position_km"}} =
             OrbitData.accepted_planning_state([bad_estimate],
               snapshot_id: "ops-state-1",
               accepted_at: "2026-05-14T00:00:00Z",
               source: %{system: "operator_import"},
               quality: %{level: "planning_accepted"}
             )
  end

  test "rejects non-object simple JSON input" do
    assert {:error, :invalid_json_object} = OrbitData.import_simple_json("[1,2,3]")
  end

  defp state_estimate do
    %{
      spacecraft_id: :sat_1,
      scenario_id: :leo_1,
      seconds_since_j2000: 120.0,
      time_scale: :utc,
      frame: :earth_inertial_j2000,
      position_km: [7000, 0, 0],
      velocity_km_s: [0, 7.5, 0],
      position_sigma_km: [0.1, 0.1, 0.2],
      velocity_sigma_km_s: [0.001, 0.001, 0.002],
      source: %{system: :od_tool, source_id: "estimate-1"},
      quality: %{level: :accepted}
    }
  end

  defp opm_kvn do
    """
    CCSDS_OPM_VERS = 2.0
    CREATION_DATE = 2026-05-14T00:00:00Z
    ORIGINATOR = OrbitalDynamicsTest
    OBJECT_NAME = ISS
    OBJECT_ID = 1998-067A
    CENTER_NAME = EARTH
    REF_FRAME = EME2000
    TIME_SYSTEM = UTC
    EPOCH = 2000-01-01T12:02:00.000
    COV_REF_FRAME = EME2000
    X = 7000 [km]
    Y = 0 [km]
    Z = 0 [km]
    X_DOT = 0 [km/s]
    Y_DOT = 7.5 [km/s]
    Z_DOT = 0 [km/s]
    """
  end

  defp opm_mass_kvn do
    """
    #{opm_kvn()}
    MASS = 419725 [kg]
    """
  end

  defp opm_spacecraft_metadata_kvn do
    """
    #{opm_kvn()}
    DRAG_AREA = 18.5 [m**2]
    DRAG_COEFF = 2.2
    SOLAR_RAD_AREA = 12.25 [m**2]
    SOLAR_RAD_COEFF = 1.3
    """
  end

  defp opm_covariance_kvn do
    """
    #{opm_kvn()}
    CX_X = 1.0e-4 [km**2]
    CY_X = 1.0e-5 [km**2]
    CY_Y = 2.0e-4 [km**2]
    CZ_X = 2.0e-5 [km**2]
    CZ_Y = 3.0e-5 [km**2]
    CZ_Z = 3.0e-4 [km**2]
    CX_DOT_X = 4.0e-7 [km**2/s]
    CX_DOT_Y = 5.0e-7 [km**2/s]
    CX_DOT_Z = 6.0e-7 [km**2/s]
    CX_DOT_X_DOT = 7.0e-8 [km**2/s**2]
    CY_DOT_X = 8.0e-7 [km**2/s]
    CY_DOT_Y = 9.0e-7 [km**2/s]
    CY_DOT_Z = 1.0e-6 [km**2/s]
    CY_DOT_X_DOT = 1.1e-8 [km**2/s**2]
    CY_DOT_Y_DOT = 1.2e-8 [km**2/s**2]
    CZ_DOT_X = 1.3e-6 [km**2/s]
    CZ_DOT_Y = 1.4e-6 [km**2/s]
    CZ_DOT_Z = 1.5e-6 [km**2/s]
    CZ_DOT_X_DOT = 1.9e-8 [km**2/s**2]
    CZ_DOT_Y_DOT = 2.0e-8 [km**2/s**2]
    CZ_DOT_Z_DOT = 2.1e-8 [km**2/s**2]
    """
  end

  defp opm_maneuver_kvn do
    """
    #{opm_kvn()}
    MAN_EPOCH = 2000-01-01T12:04:00.000
    MAN_DURATION = 12 [s]
    MAN_DELTA_MASS = -0.05 [kg]
    MAN_REF_FRAME = EME2000
    MAN_DV_1 = 0 [km/s]
    MAN_DV_2 = 0.001 [km/s]
    MAN_DV_3 = 0 [km/s]
    """
  end

  defp opm_multiple_maneuver_kvn do
    """
    #{opm_kvn()}
    MAN_EPOCH = 2000-01-01T12:04:00.000
    MAN_DURATION = 12 [s]
    MAN_DELTA_MASS = -0.05 [kg]
    MAN_REF_FRAME = EME2000
    MAN_DV_1 = 0 [km/s]
    MAN_DV_2 = 0.001 [km/s]
    MAN_DV_3 = 0 [km/s]
    MAN_EPOCH = 2000-01-01T12:06:30.000
    MAN_DURATION = 20 [s]
    MAN_DELTA_MASS = -0.03 [kg]
    MAN_REF_FRAME = EME2000
    MAN_DV_1 = 0.0005 [km/s]
    MAN_DV_2 = 0 [km/s]
    MAN_DV_3 = 0 [km/s]
    """
  end

  defp oem_kvn do
    """
    CCSDS_OEM_VERS = 2.0
    CREATION_DATE = 2026-05-14T00:00:00Z
    ORIGINATOR = OrbitalDynamicsTest
    META_START
    OBJECT_NAME = ISS
    OBJECT_ID = 1998-067A
    CENTER_NAME = EARTH
    REF_FRAME = EME2000
    TIME_SYSTEM = UTC
    INTERPOLATION = LAGRANGE
    INTERPOLATION_DEGREE = 1
    META_STOP
    2000-01-01T12:02:00.000 7000 0 0 0 7.5 0
    2000-01-01T12:03:00.000 6990 450 0 -0.5 7.49 0
    """
  end

  defp oem_covariance_kvn do
    """
    #{oem_kvn()}
    COVARIANCE_START
    EPOCH = 2000-01-01T12:03:00.000
    COV_REF_FRAME = EME2000
    CX_X = 1.0e-4 [km**2]
    CY_X = 1.0e-5 [km**2]
    CY_Y = 2.0e-4 [km**2]
    CZ_X = 2.0e-5 [km**2]
    CZ_Y = 3.0e-5 [km**2]
    CZ_Z = 3.0e-4 [km**2]
    CX_DOT_X = 4.0e-7 [km**2/s]
    CX_DOT_Y = 5.0e-7 [km**2/s]
    CX_DOT_Z = 6.0e-7 [km**2/s]
    CX_DOT_X_DOT = 7.0e-8 [km**2/s**2]
    CY_DOT_X = 8.0e-7 [km**2/s]
    CY_DOT_Y = 9.0e-7 [km**2/s]
    CY_DOT_Z = 1.0e-6 [km**2/s]
    CY_DOT_X_DOT = 1.1e-8 [km**2/s**2]
    CY_DOT_Y_DOT = 1.2e-8 [km**2/s**2]
    CZ_DOT_X = 1.3e-6 [km**2/s]
    CZ_DOT_Y = 1.4e-6 [km**2/s]
    CZ_DOT_Z = 1.5e-6 [km**2/s]
    CZ_DOT_X_DOT = 1.9e-8 [km**2/s**2]
    CZ_DOT_Y_DOT = 2.0e-8 [km**2/s**2]
    CZ_DOT_Z_DOT = 2.1e-8 [km**2/s**2]
    COVARIANCE_STOP
    """
  end

  defp tle do
    """
    ISS (ZARYA)
    1 25544U 98067A   20029.54791435  .00000726  00000-0  20456-4 0  9997
    2 25544  51.6432  23.4361 0007417  66.3690  60.5128 15.49147121210618
    """
  end

  defp omm_kvn do
    """
    CCSDS_OMM_VERS = 2.0
    CREATION_DATE = 2026-05-14T00:00:00Z
    ORIGINATOR = OrbitalDynamicsTest
    OBJECT_NAME = ISS
    OBJECT_ID = 1998-067A
    CENTER_NAME = EARTH
    REF_FRAME = TEME
    TIME_SYSTEM = UTC
    MEAN_ELEMENT_THEORY = SGP4
    EPOCH = 2020-01-29T13:08:59.800000Z
    SEMI_MAJOR_AXIS = 6797.36 [km]
    INCLINATION = 51.6432 [deg]
    RA_OF_ASC_NODE = 23.4361 [deg]
    ECCENTRICITY = 0.0007417
    ARG_OF_PERICENTER = 66.3690 [deg]
    MEAN_ANOMALY = 60.5128 [deg]
    MEAN_MOTION = 15.49147121 [rev/day]
    MEAN_MOTION_DOT = 0.00000726
    MEAN_MOTION_DDOT = 0.0
    BSTAR = 0.000020456
    EPHEMERIS_TYPE = 0
    CLASSIFICATION_TYPE = U
    NORAD_CAT_ID = 25544
    ELEMENT_SET_NO = 999
    REV_AT_EPOCH = 21061
    """
  end
end
