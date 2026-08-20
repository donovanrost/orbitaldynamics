defmodule OrbitalDynamics.InputIntegrityTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Environment.TabularEarthOrientationProvider
  alias OrbitalDynamics.{InputIntegrity, OrbitData, Schema}

  test "verified orbit-data file bytes are imported with deterministic provenance" do
    bytes = orbit_json()
    path = write_tmp_file(bytes)
    sha256 = sha256(bytes)
    content_identity = %{"sha256" => sha256}

    assert {:ok, artifact} =
             OrbitalDynamics.import_orbit_data_from_file(path, content_identity)

    assert {:ok, repeated} =
             OrbitalDynamics.import_orbit_data_from_file(path, content_identity)

    assert repeated == artifact
    assert artifact["snapshot_id"] == "integrity-orbit-state"

    assert %{
             "verification_id" => verification_id,
             "consumer" => "orbit_data.simple_json_state_estimate_batch",
             "status" => "pass",
             "reason" => "content_identity_match",
             "path" => ^path,
             "algorithm" => "sha256",
             "expected_sha256" => ^sha256,
             "actual_sha256" => ^sha256,
             "byte_count" => byte_count,
             "verified_before_consumption" => true,
             "assumptions" => assumptions,
             "known_limits" => known_limits
           } = get_in(artifact, ["provenance", "file_content_verification"])

    assert verification_id ==
             "file_content_verification:orbit_data.simple_json_state_estimate_batch:sha256:#{sha256}"

    assert byte_count == byte_size(bytes)
    assert assumptions == InputIntegrity.capabilities()["assumptions"]
    assert known_limits == InputIntegrity.capabilities()["known_limits"]

    assert artifact["provenance"]["import_adapter"] ==
             "OrbitalDynamics.OrbitData.import_orbit_data_from_file/3"

    assert artifact["provenance"]["trust_boundary"] == "sha256_verified_file_input"

    assert {:ok, %{"schema_contract" => "accepted_planning_state.v1"}} =
             Schema.validate_artifact(artifact, schema_contract: "accepted_planning_state.v1")
  end

  test "verified provider-table file bytes are consumed with stable source identity and limits" do
    bytes = provider_table_json()
    path = write_tmp_file(bytes)
    sha256 = sha256(bytes)
    content_identity = %{sha256: sha256}

    opts = [seconds_since_j2000: 50.0]

    assert {:ok, product} =
             OrbitalDynamics.fetch_tabular_earth_orientation_from_file(
               path,
               content_identity,
               opts
             )

    assert {:ok, repeated} =
             OrbitalDynamics.fetch_tabular_earth_orientation_from_file(
               path,
               content_identity,
               opts
             )

    assert repeated == product
    assert product["source_table_id"] == "earth-orientation-integrity-table"
    assert product["source"] == "checked-in-eop-export"
    assert product["earth_rotation_angle_rad"] == 0.5
    assert product["earth_rotation_rate_rad_s"] == 0.01

    assert %{
             "source_table_id" => "earth-orientation-integrity-table",
             "input_format" => "json_earth_orientation_sample_table",
             "import_adapter" =>
               "OrbitalDynamics.Environment.TabularEarthOrientationProvider.fetch_from_file/4",
             "trust_boundary" => "sha256_verified_file_input",
             "network_access" => false,
             "file_content_verification" => %{
               "verification_id" => verification_id,
               "status" => "pass",
               "expected_sha256" => ^sha256,
               "actual_sha256" => ^sha256,
               "path" => ^path
             }
           } = product["provenance"]

    assert verification_id ==
             "file_content_verification:environment.tabular_earth_orientation_provider:sha256:#{sha256}"

    assert product["assumptions"] == InputIntegrity.capabilities()["assumptions"]

    assert product["known_limits"] ==
             TabularEarthOrientationProvider.capabilities()["known_limits"] ++
               InputIntegrity.capabilities()["known_limits"]
  end

  test "orbit-data boundary rejects a mismatched digest with expected and actual evidence" do
    expected_bytes = orbit_json()
    actual_bytes = String.replace(expected_bytes, "integrity-orbit-state", "wrong-orbit-state")
    path = write_tmp_file(actual_bytes)
    expected_sha256 = sha256(expected_bytes)
    actual_sha256 = sha256(actual_bytes)

    assert {:error,
            {:input_content_verification_failed,
             %{
               "consumer" => "orbit_data.simple_json_state_estimate_batch",
               "status" => "fail",
               "reason" => "sha256_mismatch",
               "message" => "file bytes do not match the declared sha256 content identity",
               "expected_sha256" => ^expected_sha256,
               "actual_sha256" => ^actual_sha256,
               "byte_count" => byte_count,
               "verified_before_consumption" => false
             }}} =
             OrbitData.import_orbit_data_from_file(path, %{"sha256" => expected_sha256})

    assert byte_count == byte_size(actual_bytes)
  end

  test "provider-table boundary rejects a mismatched digest before decoding" do
    invalid_json_bytes = "not-json\n"
    path = write_tmp_file(invalid_json_bytes)
    expected_sha256 = sha256(provider_table_json())
    actual_sha256 = sha256(invalid_json_bytes)

    assert {:error,
            {:input_content_verification_failed,
             %{
               "consumer" => "environment.tabular_earth_orientation_provider",
               "reason" => "sha256_mismatch",
               "expected_sha256" => ^expected_sha256,
               "actual_sha256" => ^actual_sha256
             }}} =
             TabularEarthOrientationProvider.fetch_from_file(
               :earth_rotation,
               path,
               %{"sha256" => expected_sha256},
               seconds_since_j2000: 50.0
             )
  end

  test "provider-table boundary derives a stable content-addressed table ID when absent" do
    bytes =
      %{"samples" => provider_samples()}
      |> :json.encode()
      |> IO.iodata_to_binary()

    path = write_tmp_file(bytes)
    sha256 = sha256(bytes)

    assert {:ok, product} =
             OrbitalDynamics.fetch_tabular_earth_orientation_from_file(
               path,
               %{"sha256" => sha256},
               seconds_since_j2000: 50.0
             )

    assert product["source_table_id"] == "earth_orientation_table:sha256:#{sha256}"
  end

  test "both file consumers reject a missing content identity before parsing" do
    path = write_tmp_file("not-json")

    for result <- [
          OrbitData.import_orbit_data_from_file(path, nil),
          TabularEarthOrientationProvider.fetch_from_file(
            :earth_rotation,
            path,
            nil,
            seconds_since_j2000: 0.0
          )
        ] do
      assert {:error,
              {:input_content_verification_failed,
               %{
                 "reason" => "missing_content_identity",
                 "message" => "content_identity is required for this file-backed input",
                 "expected_sha256" => nil,
                 "actual_sha256" => nil,
                 "byte_count" => nil
               }}} = result
    end
  end

  test "both file consumers reject malformed SHA-256 declarations before parsing" do
    path = write_tmp_file("not-json")
    malformed_identity = %{"sha256" => String.duplicate("A", 64)}

    for result <- [
          OrbitData.import_orbit_data_from_file(path, malformed_identity),
          TabularEarthOrientationProvider.fetch_from_file(
            :earth_rotation,
            path,
            malformed_identity,
            seconds_since_j2000: 0.0
          )
        ] do
      assert {:error,
              {:input_content_verification_failed,
               %{
                 "reason" => "malformed_sha256",
                 "message" =>
                   "content_identity.sha256 must be a lowercase 64-character hex digest",
                 "actual_sha256" => nil,
                 "byte_count" => nil
               }}} = result
    end
  end

  test "both file consumers report an unreadable path without parser errors" do
    path =
      Path.join(
        System.tmp_dir!(),
        "orbital_dynamics_missing_integrity_#{System.unique_integer([:positive, :monotonic])}.json"
      )

    identity = %{"sha256" => String.duplicate("0", 64)}

    for result <- [
          OrbitData.import_orbit_data_from_file(path, identity),
          TabularEarthOrientationProvider.fetch_from_file(
            :earth_rotation,
            path,
            identity,
            seconds_since_j2000: 0.0
          )
        ] do
      assert {:error,
              {:input_content_verification_failed,
               %{
                 "reason" => "file_read_error",
                 "message" => "could not read file bytes: enoent",
                 "path" => ^path,
                 "file_error" => "enoent",
                 "actual_sha256" => nil
               }}} = result
    end
  end

  test "content verification is sensitive to every byte" do
    declared_bytes = orbit_json()
    file_bytes = declared_bytes <> "\n"
    path = write_tmp_file(file_bytes)
    declared_sha256 = sha256(declared_bytes)
    file_sha256 = sha256(file_bytes)

    assert {:error,
            {:input_content_verification_failed,
             %{
               "reason" => "sha256_mismatch",
               "expected_sha256" => ^declared_sha256,
               "actual_sha256" => ^file_sha256
             }}} =
             OrbitData.import_orbit_data_from_file(path, %{"sha256" => declared_sha256})
  end

  test "legacy in-memory orbit-data and inline provider paths remain unchanged" do
    assert {:ok, orbit_artifact} = OrbitData.import_simple_json(orbit_json())
    refute Map.has_key?(orbit_artifact["provenance"], "file_content_verification")
    assert orbit_artifact["provenance"]["trust_boundary"] == "external_orbit_data_adapter"

    assert {:ok, inline_product} =
             TabularEarthOrientationProvider.fetch(:earth_rotation,
               seconds_since_j2000: 50.0,
               samples: provider_samples()
             )

    refute Map.has_key?(inline_product, "provenance")
    refute Map.has_key?(inline_product, "source_table_id")
    refute Map.has_key?(inline_product, "assumptions")
    refute Map.has_key?(inline_product, "known_limits")
    assert inline_product["earth_rotation_angle_rad"] == 0.5
  end

  test "capabilities declare the opt-in verification contract without changing defaults" do
    orbit_capabilities = OrbitData.capabilities()

    assert :verified_file_backed_simple_json_state_estimate_batch in orbit_capabilities.import_formats

    assert orbit_capabilities.file_input_integrity == InputIntegrity.capabilities()

    assert get_in(TabularEarthOrientationProvider.capabilities(), [
             "parameters",
             "input_modes"
           ]) == ["inline_declared_samples", "verified_json_file"]

    assert get_in(TabularEarthOrientationProvider.capabilities(), [
             "parameters",
             "file_input_integrity"
           ]) == InputIntegrity.capabilities()
  end

  defp orbit_json do
    %{
      "snapshot_id" => "integrity-orbit-state",
      "accepted_at" => "2026-08-19T00:00:00Z",
      "source" => %{"system" => "operator_drop", "source_id" => "orbit-drop-22"},
      "quality" => %{"level" => "accepted"},
      "provenance" => %{"received_by" => "input-integrity-test"},
      "state_estimates" => [
        %{
          "spacecraft_id" => "sat_integrity",
          "scenario_id" => "scenario_integrity",
          "seconds_since_j2000" => 120.0,
          "time_scale" => "utc",
          "frame" => "earth_inertial_j2000",
          "position_km" => [7000.0, 0.0, 0.0],
          "velocity_km_s" => [0.0, 7.5, 0.0],
          "source" => %{"system" => "od_tool", "source_id" => "estimate-22"},
          "quality" => %{"level" => "accepted"}
        }
      ]
    }
    |> :json.encode()
    |> IO.iodata_to_binary()
  end

  defp provider_table_json do
    %{
      "table_id" => "earth-orientation-integrity-table",
      "source" => "checked-in-eop-export",
      "samples" => provider_samples()
    }
    |> :json.encode()
    |> IO.iodata_to_binary()
  end

  defp provider_samples do
    [
      %{"seconds_since_j2000" => 0.0, "earth_rotation_angle_rad" => 0.0},
      %{"seconds_since_j2000" => 100.0, "earth_rotation_angle_rad" => 1.0}
    ]
  end

  defp write_tmp_file(bytes) do
    path =
      Path.join(
        System.tmp_dir!(),
        "orbital_dynamics_input_integrity_#{System.unique_integer([:positive, :monotonic])}.json"
      )

    File.write!(path, bytes)
    on_exit(fn -> File.rm(path) end)
    path
  end

  defp sha256(bytes) do
    :crypto.hash(:sha256, bytes)
    |> Base.encode16(case: :lower)
  end
end
