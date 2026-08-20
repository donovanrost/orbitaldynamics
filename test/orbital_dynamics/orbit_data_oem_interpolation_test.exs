defmodule OrbitalDynamics.OrbitDataOemInterpolationTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{Epoch, OrbitData, Schema}

  @revision "linear-oem-fixture.v1"

  test "interpolates analytical linear motion with bounded cubic Hermite evidence" do
    kvn = linear_oem()

    assert {:ok, artifact} =
             OrbitData.import_ccsds_oem(kvn,
               interpolate: true,
               strategy_epoch: Epoch.new!(90.0, :utc),
               source_revision: @revision,
               max_bracket_s: 60.0
             )

    assert artifact["snapshot_id"] == "ccsds_oem:LINEAR-1:90.0"
    assert [state] = artifact["spacecraft_states"]
    assert state["epoch"] == %{"seconds_since_j2000" => 90.0, "time_scale" => "utc"}
    assert state["state_vector"]["position_km"] == [7090.0, 180.0, 270.0]
    assert state["state_vector"]["velocity_km_s"] == [1.0, 2.0, 3.0]
    assert state["quality"]["covariance_status"] == "not_present"

    evidence = artifact["provenance"]["oem_interpolation"]
    assert evidence["id"] =~ ~r/^oem_interpolation:sha256:[0-9a-f]{64}$/

    assert evidence["requested_epoch"] == %{
             "seconds_since_j2000" => 90.0,
             "time_scale" => "utc"
           }

    assert evidence["interpolation"] == %{
             "fraction" => 0.5,
             "method" => "cubic_hermite_position_velocity",
             "selection" => "interpolated",
             "source_declared_degree" => "3",
             "source_declared_method" => "HERMITE",
             "version" => "1"
           }

    assert %{
             "before" => %{
               "sample_index" => 1,
               "epoch" => "2000-01-01T12:01:00.000",
               "seconds_since_j2000" => 60.0,
               "position_km" => [7060.0, 120.0, 180.0],
               "velocity_km_s" => [1.0, 2.0, 3.0]
             },
             "after" => %{
               "sample_index" => 2,
               "epoch" => "2000-01-01T12:02:00.000",
               "seconds_since_j2000" => 120.0,
               "position_km" => [7120.0, 240.0, 360.0],
               "velocity_km_s" => [1.0, 2.0, 3.0]
             },
             "span_s" => 60.0,
             "max_bracket_s" => 60.0,
             "bounded" => true
           } = evidence["source_bracket"]

    assert evidence["coverage"] == %{
             "declared_start_epoch" => "2000-01-01T12:00:00.000",
             "declared_stop_epoch" => "2000-01-01T12:02:00.000",
             "declared_starts_at_s" => 0.0,
             "declared_ends_at_s" => 120.0,
             "effective_start_epoch" => "2000-01-01T12:00:10.000",
             "effective_stop_epoch" => "2000-01-01T12:01:50.000",
             "effective_starts_at_s" => 10.0,
             "effective_ends_at_s" => 110.0,
             "policy" => "OEM_USEABLE_START_TIME_USEABLE_STOP_TIME"
           }

    assert evidence["object"] == %{
             "object_name" => "LINEAR",
             "object_id" => "LINEAR-1",
             "center_name" => "EARTH"
           }

    assert evidence["frame"] == %{
             "source_ref_frame" => "EME2000",
             "accepted_state_frame" => "earth_inertial_j2000",
             "conversion_applied" => false
           }

    assert evidence["time"] == %{
             "source_time_system" => "UTC",
             "requested_time_scale" => "utc",
             "conversion_applied" => false
           }

    assert evidence["source"]["source_revision"] == @revision
    assert evidence["source"]["source_id"] == state["source"]["source_id"]
    assert evidence["source"]["content_identity"]["sha256"] == sha256(kvn)
    assert artifact["source"]["source_revision"] == @revision

    assert evidence["covariance"] == %{
             "present" => false,
             "matrix_present" => false,
             "status" => "not_present"
           }

    assert evidence["assumptions"] != []
    assert evidence["known_limits"] != []
    assert state["metadata"]["oem_interpolation_evidence_id"] == evidence["id"]
    assert state["metadata"]["interpolation_method"] == "cubic_hermite_position_velocity"
    assert state["metadata"]["interpolation_version"] == "1"

    assert {:ok, %{"schema_contract" => "accepted_planning_state.v1"}} =
             Schema.validate_artifact(artifact, schema_contract: "accepted_planning_state.v1")
  end

  test "selects the exact source sample at an exact strategy epoch" do
    assert {:ok, artifact} = interpolate(linear_oem(), 60.0, max_bracket_s: 1.0)
    assert [state] = artifact["spacecraft_states"]
    assert state["state_vector"]["position_km"] == [7060.0, 120.0, 180.0]
    assert state["state_vector"]["velocity_km_s"] == [1.0, 2.0, 3.0]

    evidence = artifact["provenance"]["oem_interpolation"]
    assert evidence["interpolation"]["method"] == "exact_sample"
    assert evidence["interpolation"]["selection"] == "exact_sample"
    assert evidence["source_bracket"]["before"] == evidence["source_bracket"]["after"]
    assert evidence["source_bracket"]["before"]["sample_index"] == 1
    assert evidence["source_bracket"]["span_s"] == 0.0
    assert artifact["provenance"]["sample_index"] == 1
    assert artifact["provenance"]["sample_epoch"] == "2000-01-01T12:01:00.000"
    assert state["metadata"]["sample_epoch"] == "2000-01-01T12:01:00.000"
  end

  test "enforces declared and usable coverage, source bracketing, and max bracket" do
    assert {:error, {:out_of_coverage, :strategy_epoch}} = interpolate(linear_oem(), 5.0)
    assert {:error, {:out_of_coverage, :strategy_epoch}} = interpolate(linear_oem(), 115.0)

    assert {:error, {:out_of_coverage, :ephemeris_sample_bracket}} =
             linear_oem(
               stop_time: "2000-01-01T12:03:00.000",
               usable_start_time: nil,
               usable_stop_time: nil
             )
             |> interpolate(150.0)

    assert {:error, {:max_bracket_exceeded, 60.0, 30.0}} =
             interpolate(linear_oem(), 90.0, max_bracket_s: 30.0)

    assert {:error, {:missing_field, "START_TIME"}} =
             linear_oem(start_time: nil)
             |> interpolate(90.0)
  end

  test "requires explicit strategy epoch and source revision on the opt-in path" do
    assert {:error, {:missing_option, :strategy_epoch}} =
             OrbitData.import_ccsds_oem(linear_oem(),
               interpolate: true,
               source_revision: @revision
             )

    assert {:error, {:missing_option, :source_revision}} =
             OrbitData.import_ccsds_oem(linear_oem(),
               interpolate: true,
               strategy_epoch: Epoch.new!(90.0, :utc)
             )

    assert {:error, {:invalid_option, :source_revision}} =
             OrbitData.import_ccsds_oem(linear_oem(),
               interpolate: true,
               strategy_epoch: Epoch.new!(90.0, :utc),
               source_revision: " "
             )

    assert {:error, {:time_scale_mismatch, "tai", "utc"}} =
             OrbitData.import_ccsds_oem(linear_oem(),
               interpolate: true,
               strategy_epoch: Epoch.new!(90.0, :tai),
               source_revision: @revision
             )
  end

  test "rejects duplicate and nonmonotonic epochs instead of reordering source samples" do
    assert {:error, {:invalid_field, "ephemeris_data.epochs_not_strictly_increasing"}} =
             linear_oem(sample_epochs: [0, 60, 60])
             |> interpolate(30.0)

    assert {:error, {:invalid_field, "ephemeris_data.epochs_not_strictly_increasing"}} =
             linear_oem(sample_epochs: [0, 120, 60])
             |> interpolate(30.0)
  end

  test "rejects malformed, nonfinite, unsupported, and mixed metadata inputs" do
    assert {:error, {:invalid_field, "ephemeris_data"}} =
             linear_oem()
             |> String.replace("7060 120 180", "NaN 120 180")
             |> interpolate(90.0)

    assert {:error, {:invalid_field, "REF_FRAME"}} =
             linear_oem(ref_frame: "ITRF")
             |> interpolate(90.0)

    assert {:error, {:invalid_field, "TIME_SYSTEM"}} =
             linear_oem(time_system: "UT1")
             |> interpolate(90.0)

    mixed_metadata =
      linear_oem() <>
        """
        META_START
        OBJECT_NAME = OTHER
        OBJECT_ID = OTHER-1
        CENTER_NAME = EARTH
        REF_FRAME = J2000
        TIME_SYSTEM = TAI
        META_STOP
        2000-01-01T12:03:00.000 7180 360 540 1 2 3
        """

    assert {:error,
            {:unsupported_field, "ccsds_oem.duplicate_single_value_field", _duplicate_key}} =
             interpolate(mixed_metadata, 90.0)
  end

  test "preserves source covariance while explicitly declining covariance interpolation" do
    assert {:ok, artifact} = interpolate(linear_oem() <> covariance_block(), 90.0)
    assert [state] = artifact["spacecraft_states"]
    evidence = artifact["provenance"]["oem_interpolation"]

    assert evidence["covariance"] == %{
             "present" => true,
             "matrix_present" => true,
             "epoch" => "2000-01-01T12:01:00.000",
             "reference_frame" => "EME2000",
             "status" => "source_matrix_preserved_not_interpolated"
           }

    assert state["quality"]["covariance_status"] ==
             "source_matrix_preserved_not_interpolated"

    assert state["quality"]["covariance_epoch"] == "2000-01-01T12:01:00.000"
    assert state["quality"]["covariance_matrix_6x6"] |> List.flatten() |> length() == 36
  end

  test "preserves legacy sample-selection results when interpolation is not requested" do
    kvn = linear_oem()
    assert {:ok, default_artifact} = OrbitData.import_ccsds_oem(kvn)
    assert {:ok, explicit_first_artifact} = OrbitData.import_ccsds_oem(kvn, sample: :first)
    assert default_artifact == explicit_first_artifact
    refute Map.has_key?(default_artifact["provenance"], "oem_interpolation")

    assert default_artifact["provenance"]["sample_selection"] ==
             "single_ephemeris_sample_no_interpolation"

    assert [state] = default_artifact["spacecraft_states"]
    assert state["epoch"]["seconds_since_j2000"] == 0.0
    assert state["state_vector"]["position_km"] == [7000.0, 0.0, 0.0]
    refute Map.has_key?(state["metadata"], "oem_interpolation_evidence_id")
  end

  test "wrapper JSON and schema validation preserve interpolation evidence" do
    source = %{
      "format" => "ccsds_oem_kvn",
      "content" => linear_oem(),
      "interpolate" => true,
      "strategy_epoch" => %{
        "seconds_since_j2000" => 90.0,
        "time_scale" => "UTC"
      },
      "source_revision" => @revision,
      "quality" => %{"level" => "planning_accepted"}
    }

    assert {:ok, artifact} = OrbitData.import_orbit_data(source)
    assert {:ok, json} = OrbitData.export_simple_json(artifact)
    decoded = :json.decode(json)
    assert decoded == artifact

    assert {:ok, %{"schema_contract" => "accepted_planning_state.v1"}} =
             Schema.validate_artifact(decoded, schema_contract: "accepted_planning_state.v1")

    assert get_in(decoded, ["provenance", "oem_interpolation", "source", "source_revision"]) ==
             @revision
  end

  test "repeated imports and JSON exports are reproducible" do
    kvn = linear_oem()
    assert {:ok, first} = interpolate(kvn, 90.0)
    assert {:ok, second} = interpolate(kvn, 90.0)
    assert first == second
    assert {:ok, first_json} = OrbitData.export_simple_json(first)
    assert {:ok, second_json} = OrbitData.export_simple_json(second)
    assert first_json == second_json

    first_evidence = first["provenance"]["oem_interpolation"]
    second_evidence = second["provenance"]["oem_interpolation"]
    assert first_evidence["id"] == second_evidence["id"]

    assert first_evidence["source"]["content_identity"] ==
             second_evidence["source"]["content_identity"]
  end

  defp interpolate(kvn, seconds_since_j2000, opts \\ []) do
    OrbitData.import_ccsds_oem(
      kvn,
      Keyword.merge(
        [
          interpolate: true,
          strategy_epoch: Epoch.new!(seconds_since_j2000, :utc),
          source_revision: @revision
        ],
        opts
      )
    )
  end

  defp linear_oem(opts \\ []) do
    start_time = Keyword.get(opts, :start_time, "2000-01-01T12:00:00.000")
    stop_time = Keyword.get(opts, :stop_time, "2000-01-01T12:02:00.000")
    usable_start_time = Keyword.get(opts, :usable_start_time, "2000-01-01T12:00:10.000")
    usable_stop_time = Keyword.get(opts, :usable_stop_time, "2000-01-01T12:01:50.000")
    sample_epochs = Keyword.get(opts, :sample_epochs, [0, 60, 120])

    metadata =
      [
        "OBJECT_NAME = LINEAR",
        "OBJECT_ID = LINEAR-1",
        "CENTER_NAME = EARTH",
        "REF_FRAME = #{Keyword.get(opts, :ref_frame, "EME2000")}",
        "TIME_SYSTEM = #{Keyword.get(opts, :time_system, "UTC")}",
        "START_TIME = #{start_time}",
        "STOP_TIME = #{stop_time}",
        if(usable_start_time, do: "USEABLE_START_TIME = #{usable_start_time}"),
        if(usable_stop_time, do: "USEABLE_STOP_TIME = #{usable_stop_time}"),
        "INTERPOLATION = HERMITE",
        "INTERPOLATION_DEGREE = 3"
      ]
      |> Enum.reject(&is_nil/1)
      |> Enum.join("\n")

    samples =
      sample_epochs
      |> Enum.map(fn seconds ->
        timestamp = DateTime.add(~U[2000-01-01 12:00:00Z], seconds, :second)
        epoch = Calendar.strftime(timestamp, "%Y-%m-%dT%H:%M:%S.000")
        "#{epoch} #{7000 + seconds} #{2 * seconds} #{3 * seconds} 1 2 3"
      end)
      |> Enum.join("\n")

    """
    CCSDS_OEM_VERS = 2.0
    CREATION_DATE = 2026-08-20T00:00:00Z
    ORIGINATOR = OrbitalDynamicsInterpolationTest
    META_START
    #{metadata}
    META_STOP
    #{samples}
    """
  end

  defp covariance_block do
    """
    COVARIANCE_START
    EPOCH = 2000-01-01T12:01:00.000
    COV_REF_FRAME = EME2000
    CX_X = 1.0e-4
    CY_X = 1.0e-5
    CY_Y = 2.0e-4
    CZ_X = 2.0e-5
    CZ_Y = 3.0e-5
    CZ_Z = 3.0e-4
    CX_DOT_X = 4.0e-7
    CX_DOT_Y = 5.0e-7
    CX_DOT_Z = 6.0e-7
    CX_DOT_X_DOT = 7.0e-8
    CY_DOT_X = 8.0e-7
    CY_DOT_Y = 9.0e-7
    CY_DOT_Z = 1.0e-6
    CY_DOT_X_DOT = 1.1e-8
    CY_DOT_Y_DOT = 1.2e-8
    CZ_DOT_X = 1.3e-6
    CZ_DOT_Y = 1.4e-6
    CZ_DOT_Z = 1.5e-6
    CZ_DOT_X_DOT = 1.6e-8
    CZ_DOT_Y_DOT = 1.7e-8
    CZ_DOT_Z_DOT = 2.1e-8
    COVARIANCE_STOP
    """
  end

  defp sha256(bytes) do
    bytes
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end
end
