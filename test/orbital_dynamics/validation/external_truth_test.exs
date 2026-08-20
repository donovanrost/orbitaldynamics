defmodule OrbitalDynamics.Validation.ExternalTruthTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Validation.ExternalTruth
  alias OrbitalDynamics.Validation.ExternalTruth.{OrekitLeoCase, StrictBundle}

  @case_id "external_truth.orekit_13_1_7.earth_j2_drag_rk4_10s_access_eclipse_6h"

  setup_all do
    assert {:ok, observations} = OrekitLeoCase.observations()
    %{observations: observations}
  end

  test "registers only the exact externally validated model combination" do
    assert [registration] = ExternalTruth.all()
    assert registration["id"] == @case_id
    assert registration["validation_level"] == "validated"
    assert String.contains?(registration["covered_regime"], "all 2161 ten-second states")

    assert registration["tolerances"] == %{
             "position_max_component_error_m" => 0.01,
             "velocity_max_component_error_m_s" => 1.0e-5,
             "access_boundary_absolute_error_s" => 0.001,
             "eclipse_boundary_absolute_error_s" => 0.05
           }

    assert registration["model"] ==
             "earth_j2_drag_rk4_10s_spherical_access_fixed_sun_cylindrical_eclipse_6h"

    assert registration["intended_uses"] == [
             "numerical_regression",
             "bounded_analysis_evidence"
           ]

    assert Enum.any?(registration["known_limits"], &String.contains?(&1, "120 kg"))
    assert "not flight certification or operational acceptance" in registration["known_limits"]

    assert {:ok, ^registration} = ExternalTruth.fetch(@case_id)
    assert :error = ExternalTruth.fetch("external_truth.not_registered")
  end

  test "verifies all pinned identities, full horizon, states, access, and eclipse boundaries" do
    assert {:ok, report} = ExternalTruth.verify(@case_id)
    assert report["status"] == "pass"
    assert report["validation_level"] == "validated"
    assert report["status_counts"] == %{"pass" => length(report["checks"])}
    assert {:ok, _schema_report} = OrbitalDynamics.Schema.validate_artifact(report)

    assert count_checks(report, "state.", ".epoch_s") == 2_161
    assert count_checks(report, "state.", ".position_m") == 2_161
    assert count_checks(report, "state.", ".velocity_m_s") == 2_161
    assert check(report, "state.0.epoch_s")["status"] == "pass"
    assert check(report, "state.12340.epoch_s")["status"] == "pass"
    assert check(report, "state.21600.epoch_s")["status"] == "pass"
    assert check(report, "bundle.manifest.semantic_declarations")["status"] == "pass"
    assert check(report, "bundle.manifest.case_properties_semantics")["status"] == "pass"
    assert check(report, "bundle.manifest.dependency_lock_semantics")["status"] == "pass"
    assert check(report, "bundle.manifest.generator_container_ref")["status"] == "pass"
    assert check(report, "bundle.manifest.toolchain_source_semantics")["status"] == "pass"

    assert check(report, "orbital_dynamics.manifest_runtime_semantics")["status"] ==
             "pass"

    assert max_residual(report, "state.", "max_abs_error", ".position_m") < 0.001
    assert max_residual(report, "state.", "max_abs_error", ".velocity_m_s") < 1.0e-6
    assert max_residual(report, "access.", "error", ".epoch_s") < 0.001

    eclipse_residual = max_residual(report, "eclipse.", "error", ".epoch_s")
    assert eclipse_residual > 0.02
    assert eclipse_residual < 0.05

    assert check(report, "orbital_dynamics.horizon_coverage")["observed"] == %{
             "starts_at_s" => 0.0,
             "ends_at_s" => 21_600.0,
             "sample_count" => 2_161
           }
  end

  test "rejects perturbed propagated state and access and eclipse truth", %{
    observations: observations
  } do
    perturbed =
      observations
      |> update_in([:states, Access.at(1_234), :position_m, Access.at(0)], &(&1 + 0.02))
      |> update_in([:access, Access.at(0), :epoch_s], &(&1 + 0.002))
      |> update_in([:eclipse, Access.at(0), :epoch_s], &(&1 + 0.1))

    assert {:error, report} = OrekitLeoCase.compare_observations(perturbed)
    assert report["status"] == "fail"
    assert check(report, "state.12340.position_m")["status"] == "fail"
    assert check(report, "access.1.epoch_s")["status"] == "fail"
    assert check(report, "eclipse.1.epoch_s")["status"] == "fail"
  end

  test "rejects frame, time-scale, and horizon coverage mismatches", %{
    observations: observations
  } do
    mismatched =
      observations
      |> put_in([:path_identity, :frame], :teme)
      |> put_in([:path_identity, :epoch_scale], :utc)
      |> put_in([:horizon, :ends_at_s], 21_590.0)
      |> put_in([:horizon, :sample_count], 2_160)

    assert {:error, report} = OrekitLeoCase.compare_observations(mismatched)
    assert check(report, "orbital_dynamics.path_identity")["status"] == "fail"
    assert check(report, "orbital_dynamics.horizon_coverage")["status"] == "fail"
  end

  test "content and filesystem binding rejects stale identities, symlinks, and oversized files" do
    stale_source = copy_bundle("stale-source")

    File.write!(
      Path.join(stale_source, "case.properties"),
      OrekitLeoCase.bundle_path()
      |> Path.join("case.properties")
      |> File.read!()
      |> String.replace("orekit_data_revision=none", "orekit_data_revision=stale")
    )

    assert_bundle_integrity_failure(stale_source)

    stale_manifest = copy_bundle("stale-manifest")

    File.write!(
      Path.join(stale_manifest, "manifest.json"),
      stale_manifest
      |> Path.join("manifest.json")
      |> File.read!()
      |> String.replace(~s("version": "13.1.7"), ~s("version": "13.1.6"))
    )

    assert_bundle_integrity_failure(stale_manifest)

    perturbed_result = copy_bundle("perturbed-result")

    File.write!(
      Path.join(perturbed_result, "reference-output.json"),
      perturbed_result
      |> Path.join("reference-output.json")
      |> File.read!()
      |> String.replace("7.00000000000000000e+06", "7.00000000000002000e+06", global: false)
    )

    assert_bundle_integrity_failure(perturbed_result)

    symlinked_root_target = copy_bundle("symlinked-root")
    symlinked_root = Path.join(Path.dirname(symlinked_root_target), "bundle-link")
    File.ln_s!(symlinked_root_target, symlinked_root)
    assert_bundle_integrity_failure(symlinked_root, "symlink_bundle_root")

    symlinked_parent = copy_bundle("symlinked-parent")
    source_directory = Path.join(symlinked_parent, "src")
    source_sibling = Path.join(Path.dirname(symlinked_parent), "source-sibling")
    File.rename!(source_directory, source_sibling)
    File.ln_s!(source_sibling, source_directory)
    assert_bundle_integrity_failure(symlinked_parent, "symlink_path_component")

    oversized_files = [
      {"manifest", "manifest.json", 131_073},
      {"result", "reference-output.json", 8_388_609},
      {"source-manifest", "source-manifest.sha256", 65_537},
      {"source", "src/main/java/org/orbitaldynamics/validation/OrekitTruthGenerator.java",
       1_048_577},
      {"dependency", "dependencies.lock", 1_048_577}
    ]

    for {label, relative_path, byte_count} <- oversized_files do
      oversized_bundle = copy_bundle("oversized-#{label}")
      write_sparse_file(Path.join(oversized_bundle, relative_path), byte_count)
      assert_bundle_integrity_failure(oversized_bundle, "file_size_exceeds_limit")
    end
  end

  test "semantic seal rejects contradictory declarations after a legitimate manifest re-pin" do
    mutations = [
      {"container-tag", ["reference_tool", "container_image"],
       "docker.io/library/maven:3.9.10-eclipse-temurin-21"},
      {"container-image-id", ["reference_tool", "container_image_id"],
       "sha256:4ead0ff36a4b796440e451013a4ce803dbd02f07b6c5b634cc2ad67927dfcc10"},
      {"sun-distance", ["data_sources", "sun_provider_distance_m"], 200_000_000_000.0},
      {"sun-direction", ["data_sources", "sun_direction_eme2000"], [-1.0, 0.0, 0.0]},
      {"earth-orientation", ["data_sources", "earth_orientation_model"],
       "iers_eop_driven_rotation"},
      {"mu", ["reference_model", "mu_m3_s2"], 398_600_441_700_000.0},
      {"radius", ["reference_model", "equatorial_radius_m"], 6_378_137.0},
      {"j2", ["reference_model", "j2"], 1.0827e-3},
      {"initial-state", ["reference_model", "initial_position_m"], [7_000_001.0, 0.0, 0.0]},
      {"dependency", ["dependencies", "hipparchus_version"], "4.0.4"},
      {"access", ["access_model", "minimum_elevation_deg"], 6.0},
      {"eclipse", ["eclipse_model", "light_source"],
       "infinitely_distant_fixed_negative_eme2000_x_direction"},
      {"orbital-path", ["orbital_dynamics_path", "access_root_tolerance_s"], 0.01}
    ]

    for {label, path, value} <- mutations do
      bundle_path = copy_bundle("semantic-#{label}")
      expectations = repin_manifest!(bundle_path, &put_in(&1, path, value))

      assert {:ok, loaded_bundle} = StrictBundle.load(bundle_path, expectations)
      assert {:error, report} = OrekitLeoCase.validate_semantic_seal(loaded_bundle)
      assert report["status"] == "fail"
      assert check(report, "bundle.manifest.semantic_declarations")["status"] == "fail"
    end
  end

  test "identity declarations reject unknown, missing, and altered fields after manifest re-pin" do
    mutations = [
      {"source-unknown", :source_identity_keys,
       fn manifest ->
         update_in(manifest, ["source_identity"], &Map.put(&1, "unknown_identity", "false"))
       end},
      {"source-missing", :source_identity_keys,
       fn manifest ->
         update_in(manifest, ["source_identity"], &Map.delete(&1, "algorithm"))
       end},
      {"source-altered", :source_manifest_path,
       fn manifest ->
         put_in(manifest, ["source_identity", "manifest_path"], "other-source-manifest.sha256")
       end},
      {"result-unknown", :result_identity_keys,
       fn manifest ->
         update_in(manifest, ["result_identity"], &Map.put(&1, "unknown_identity", "false"))
       end},
      {"result-missing", :result_identity_keys,
       fn manifest ->
         update_in(manifest, ["result_identity"], &Map.delete(&1, "algorithm"))
       end},
      {"result-altered", :result_path,
       fn manifest ->
         put_in(manifest, ["result_identity", "path"], "other-reference-output.json")
       end}
    ]

    for {label, expected_field, mutation} <- mutations do
      bundle_path = copy_bundle("identity-#{label}")
      expectations = repin_identity_manifest!(bundle_path, mutation)

      assert {:error, {:bundle_integrity_failed, ^expected_field, _expected, _observed}} =
               StrictBundle.load(bundle_path, expectations)
    end
  end

  test "raw handle checks reject path swaps, intermediate swaps, and growth during reads" do
    swapped_file_bundle = copy_bundle("race-final-symlink")
    swapped_file_expectations = expectations_from_bundle(swapped_file_bundle)
    manifest_path = Path.join(swapped_file_bundle, "manifest.json")
    manifest_sibling = Path.join(swapped_file_bundle, "manifest-sibling.json")
    File.cp!(manifest_path, manifest_sibling)

    final_swap = fn
      :after_path_preflight, "manifest.json" ->
        File.rename!(manifest_path, manifest_path <> ".original")
        File.ln_s!(manifest_sibling, manifest_path)
        :ok

      _stage, _path ->
        :ok
    end

    assert {:error, final_swap_reason} =
             StrictBundle.load(swapped_file_bundle, swapped_file_expectations,
               read_seam: final_swap
             )

    assert inspect(final_swap_reason) =~ "handle_identity_mismatch"

    swapped_parent_bundle = copy_bundle("race-parent-symlink")
    swapped_parent_expectations = expectations_from_bundle(swapped_parent_bundle)
    source_directory = Path.join(swapped_parent_bundle, "src")
    source_sibling = Path.join(Path.dirname(swapped_parent_bundle), "race-source-sibling")

    parent_swap = fn
      :after_handle_preflight,
      "src/main/java/org/orbitaldynamics/validation/OrekitTruthGenerator.java" ->
        File.rename!(source_directory, source_sibling)
        File.ln_s!(source_sibling, source_directory)
        :ok

      _stage, _path ->
        :ok
    end

    assert {:error, parent_swap_reason} =
             StrictBundle.load(swapped_parent_bundle, swapped_parent_expectations,
               read_seam: parent_swap
             )

    assert inspect(parent_swap_reason) =~ "symlink_path_component"

    grown_bundle = copy_bundle("race-growth")
    grown_expectations = expectations_from_bundle(grown_bundle)
    grown_manifest_path = Path.join(grown_bundle, "manifest.json")

    grow_after_open = fn
      :after_handle_preflight, "manifest.json" ->
        write_sparse_file(grown_manifest_path, 131_073)
        :ok

      _stage, _path ->
        :ok
    end

    assert {:error, growth_reason} =
             StrictBundle.load(grown_bundle, grown_expectations, read_seam: grow_after_open)

    assert inspect(growth_reason) =~ "file_size_exceeds_limit"
  end

  test "strict readers reject malformed and duplicate keys" do
    assert {:error, {:duplicate_json_key, "frame"}} =
             StrictBundle.decode_json_strict(~s({"frame":"EME2000","frame":"TEME"}))

    assert {:error, {:invalid_json, _reason}} = StrictBundle.decode_json_strict(~s({"frame":}))

    assert {:error, {:invalid_bundle, {:duplicate_config_key, "frame"}}} =
             StrictBundle.parse_properties_strict("frame=EME2000\nframe=TEME\n")

    source_line = String.duplicate("a", 64) <> "  case.properties\n"

    assert {:error, {:invalid_bundle, {:duplicate_source_path, "case.properties"}}} =
             StrictBundle.parse_source_manifest(source_line <> source_line)

    dependency_line =
      String.duplicate("a", 64) <>
        " https://repo.maven.apache.org/maven2/example.jar example.jar\n"

    assert {:error, {:invalid_bundle, {:duplicate_dependency_filename, "example.jar"}}} =
             StrictBundle.parse_dependency_lock(dependency_line <> dependency_line)
  end

  defp max_residual(report, prefix, residual_key, suffix) do
    report["checks"]
    |> Enum.filter(fn row ->
      String.starts_with?(row["field"], prefix) and String.ends_with?(row["field"], suffix) and
        is_number(row[residual_key])
    end)
    |> Enum.map(& &1[residual_key])
    |> Enum.max()
  end

  defp count_checks(report, prefix, suffix) do
    Enum.count(report["checks"], fn row ->
      String.starts_with?(row["field"], prefix) and String.ends_with?(row["field"], suffix)
    end)
  end

  defp check(report, field), do: Enum.find(report["checks"], &(&1["field"] == field))

  defp copy_bundle(label) do
    root =
      Path.join(
        System.tmp_dir!(),
        "orbital-dynamics-external-truth-#{label}-#{System.unique_integer([:positive])}"
      )

    destination = Path.join(root, "bundle")
    File.mkdir_p!(root)
    File.cp_r!(OrekitLeoCase.bundle_path(), destination)
    on_exit(fn -> File.rm_rf!(root) end)
    destination
  end

  defp write_sparse_file(path, byte_count) do
    io = File.open!(path, [:write, :binary])
    {:ok, _position} = :file.position(io, byte_count - 1)
    :ok = IO.binwrite(io, <<0>>)
    :ok = File.close(io)
  end

  defp repin_manifest!(bundle_path, mutation) do
    write_repinned_manifest!(bundle_path, mutation)
    expectations_from_bundle(bundle_path)
  end

  defp repin_identity_manifest!(bundle_path, mutation) do
    expectations = expectations_from_bundle(bundle_path)
    updated_bytes = write_repinned_manifest!(bundle_path, mutation)

    %{
      expectations
      | manifest_sha256: sha256(updated_bytes),
        manifest_byte_count: byte_size(updated_bytes)
    }
  end

  defp write_repinned_manifest!(bundle_path, mutation) do
    manifest_path = Path.join(bundle_path, "manifest.json")
    original_bytes = File.read!(manifest_path)
    {:ok, manifest} = StrictBundle.decode_json_strict(original_bytes)
    updated_bytes = manifest |> mutation.() |> :json.encode() |> IO.iodata_to_binary()
    File.write!(manifest_path, updated_bytes)

    sums_path = Path.join(bundle_path, "SHA256SUMS")
    updated_sha256 = sha256(updated_bytes)

    sums =
      sums_path
      |> File.read!()
      |> String.replace(sha256(original_bytes), updated_sha256)

    File.write!(sums_path, sums)
    updated_bytes
  end

  defp expectations_from_bundle(bundle_path) do
    manifest_bytes = bundle_path |> Path.join("manifest.json") |> File.read!()
    {:ok, manifest} = StrictBundle.decode_json_strict(manifest_bytes)

    source_files =
      manifest["source_identity"]["files"]
      |> Enum.map(fn file ->
        %{
          path: file["path"],
          byte_count: file["byte_count"],
          sha256: file["sha256"]
        }
      end)

    %{
      manifest_sha256: sha256(manifest_bytes),
      manifest_byte_count: byte_size(manifest_bytes),
      source_manifest_sha256: manifest["source_identity"]["sha256"],
      source_manifest_byte_count: manifest["source_identity"]["manifest_byte_count"],
      result_sha256: manifest["result_identity"]["sha256"],
      result_byte_count: manifest["result_identity"]["byte_count"],
      source_files: source_files,
      source_total_byte_count: manifest["source_identity"]["total_source_byte_count"]
    }
  end

  defp sha256(bytes), do: :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)

  defp assert_bundle_integrity_failure(bundle_path, reason_fragment \\ nil) do
    assert {:error, report} = OrekitLeoCase.verify(bundle_path: bundle_path)
    assert report["status"] == "fail"
    assert check(report, "bundle.verification")["status"] == "fail"

    if reason_fragment do
      assert inspect(check(report, "bundle.verification")["observed"]) =~ reason_fragment
    end
  end
end
