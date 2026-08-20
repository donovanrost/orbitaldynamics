defmodule OrbitalDynamics.CampaignEnvironmentProviderTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Environment
  alias OrbitalDynamics.Environment.CampaignEnvironmentProvider, as: Provider

  @coverage_start_s 820_497_600.0
  @coverage_end_s 820_756_800.0

  test "loads the checked-in source-bound table and proves finite request fit" do
    assert {:ok, dataset} = Provider.load(Provider.checked_in_options())
    assert {:ok, capability} = Provider.configured_capability(dataset: dataset)

    assert capability["id"] ==
             "environment.provider.campaign.jpl_de441_iers_finals2000a"

    assert capability["coverage"] == %{
             "starts_at_s" => @coverage_start_s,
             "ends_at_s" => @coverage_end_s,
             "time_scale" => "utc_seconds_since_j2000",
             "coverage_policy" => "verified_table_samples"
           }

    request = %{
      starts_at_s: @coverage_start_s,
      ends_at_s: @coverage_end_s,
      body: :earth,
      outputs: [:sun_direction, :earth_rotation],
      frames: [:eci_j2000, :earth_fixed_era_from_eci_j2000_approximation],
      time_scale: :utc
    }

    assert Environment.provider_supports_request?(capability, request)
    refute Environment.provider_supports_request?(capability, %{request | starts_at_s: 0.0})
    refute Environment.provider_supports_request?(capability, %{request | body: :mars})
    refute Environment.provider_supports_request?(capability, %{request | frames: [:eme2000]})
    refute Environment.provider_supports_request?(capability, %{request | time_scale: :tdb})

    provenance = Provider.provenance(dataset)

    assert provenance["provider_revision"] == "campaign_environment_provider.v2"
    assert provenance["dataset_revision"] == "jpl_de441__iers_finals2000a_2026-08-13.v2"

    assert provenance["dataset_semantic_sha256"] ==
             "afb0c7252b0b2d2c7e987651e639e02b76bc9ac1ff19d0927b3bf3e6a9ebb5db"

    assert provenance["content_sha256"] ==
             "757d8d4d1694d0a3cf3897b337cfd2ec818e3ab8715d7103df999d1a0a3697e9"

    assert provenance["earth_fixed_frame"] ==
             "earth_fixed_era_from_eci_j2000_approximation"

    assert provenance["coverage"]["starts_at_s"] == @coverage_start_s
    assert provenance["coverage"]["ends_at_s"] == @coverage_end_s
    assert length(provenance["source_products"]) == 3
    assert Enum.all?(provenance["source_products"], &is_binary(&1["response_sha256"]))
  end

  test "interpolates both products only within the declared adjacent bracket" do
    assert {:ok, dataset} = Provider.load(Provider.checked_in_options())
    midpoint_s = @coverage_start_s + 43_200.0

    assert {:ok, sun_before} =
             Provider.fetch(:sun_direction,
               dataset: dataset,
               seconds_since_j2000: @coverage_start_s,
               body: :earth,
               frame: :eci_j2000,
               time_scale: :utc,
               interpolation: :linear_sample_bracket
             )

    assert {:ok, sun_midpoint} =
             Provider.fetch(:sun_direction,
               dataset: dataset,
               seconds_since_j2000: midpoint_s,
               body: :earth,
               frame: :eci_j2000,
               time_scale: :utc,
               interpolation: :linear_sample_bracket
             )

    assert sun_before["interpolation"] == "source_sample_exact"
    assert sun_midpoint["interpolation"] == "linear_position_then_normalize"
    assert sun_midpoint["interpolation_fraction"] == 0.5
    assert_in_delta vector_norm(sun_midpoint["sun_direction"]), 1.0, 1.0e-12
    refute sun_midpoint["sun_direction"] == sun_before["sun_direction"]

    assert {:ok, rotation_before} = earth_rotation(dataset, @coverage_start_s)
    assert {:ok, rotation_after} = earth_rotation(dataset, @coverage_start_s + 86_400.0)
    assert {:ok, rotation_midpoint} = earth_rotation(dataset, midpoint_s)

    assert rotation_midpoint["interpolation"] == "linear_declared_rotation_sample"
    assert rotation_midpoint["earth_orientation_interpolation"] == "linear_sample_bracket"

    assert_in_delta rotation_midpoint["earth_rotation_angle_rad"],
                    (rotation_before["earth_rotation_angle_rad"] +
                       rotation_after["earth_rotation_angle_rad"]) / 2.0,
                    1.0e-12

    assert_in_delta rotation_midpoint["ut1_utc_s"], (0.0740869 + 0.0741827) / 2.0, 1.0e-12

    assert {:error, {:outside_coverage, :campaign_environment}} =
             Provider.fetch(:sun_direction,
               dataset: dataset,
               seconds_since_j2000: @coverage_start_s - 1.0,
               body: :earth,
               frame: :eci_j2000,
               time_scale: :utc
             )
  end

  test "rejects request context and unsupported interpolation mismatches" do
    assert {:ok, dataset} = Provider.load(Provider.checked_in_options())

    for {field, opts, expected, actual} <- [
          {:body, [body: :mars, frame: :eci_j2000, time_scale: :utc], "earth", "mars"},
          {:frame, [body: :earth, frame: :eme2000, time_scale: :utc], "eci_j2000", "eme2000"},
          {:time_scale, [body: :earth, frame: :eci_j2000, time_scale: :tdb], "utc", "tdb"},
          {:interpolation,
           [body: :earth, frame: :eci_j2000, time_scale: :utc, interpolation: :cubic],
           "linear_sample_bracket", "cubic"}
        ] do
      assert {:error, {:campaign_environment_request_mismatch, ^field, ^expected, ^actual}} =
               Provider.fetch(
                 :sun_direction,
                 [dataset: dataset, seconds_since_j2000: @coverage_start_s] ++ opts
               )
    end
  end

  test "binds source revision and rejects wrong content identity or tampered bytes" do
    wrong_revision_opts =
      Keyword.put(Provider.checked_in_options(), :expected_dataset_revision, "stale_revision")

    assert {:error,
            {:campaign_environment_identity_mismatch, "dataset_revision", "stale_revision",
             "jpl_de441__iers_finals2000a_2026-08-13.v2"}} = Provider.load(wrong_revision_opts)

    table = checked_in_table()

    wrong_source_revision =
      put_in(table, ["sources", Access.at(0), "source_revision"], "DE440")

    assert {:error, {:invalid_campaign_environment_table, :source_identity_mismatch}} =
             load_reencoded_table(wrong_source_revision, "wrong-source-revision.json")

    wrong_hash_opts =
      Keyword.put(Provider.checked_in_options(), :content_identity, %{
        "sha256" => String.duplicate("0", 64)
      })

    assert {:error, {:input_content_verification_failed, wrong_hash_evidence}} =
             Provider.load(wrong_hash_opts)

    assert wrong_hash_evidence["reason"] == "sha256_mismatch"
    assert wrong_hash_evidence["verified_before_consumption"] == false

    tampered_path = temporary_path("tampered.json")
    source_path = Keyword.fetch!(Provider.checked_in_options(), :path)
    File.write!(tampered_path, File.read!(source_path) <> "\n")

    tampered_opts = Keyword.put(Provider.checked_in_options(), :path, tampered_path)

    assert {:error, {:input_content_verification_failed, tamper_evidence}} =
             Provider.load(tampered_opts)

    assert tamper_evidence["reason"] == "sha256_mismatch"
    assert tamper_evidence["expected_sha256"] != tamper_evidence["actual_sha256"]
  end

  test "rejects duplicate, nonmonotonic, gapped, and unsupported tables" do
    table = checked_in_table()
    [first, second, third, fourth] = table["samples"]

    duplicate =
      put_in(table, ["samples"], [first, Map.put(second, "mjd_utc", 61041.0), third, fourth])

    assert {:error, {:invalid_campaign_environment_table, :nonmonotonic_or_duplicate_epochs}} =
             load_reencoded_table(duplicate, "duplicate.json")

    nonmonotonic = put_in(table, ["samples"], [second, first, third, fourth])

    assert {:error, {:invalid_campaign_environment_table, :nonmonotonic_or_duplicate_epochs}} =
             load_reencoded_table(nonmonotonic, "nonmonotonic.json")

    gap = put_in(table, ["samples"], [first, Map.put(second, "mjd_utc", 61042.5), third, fourth])

    assert {:error, {:invalid_campaign_environment_table, :sample_gap}} =
             load_reencoded_table(gap, "gap.json")

    unsupported = Map.put(table, "interpolation", "cubic_spline")

    opts =
      reencoded_table_options(unsupported, "unsupported.json")
      |> Keyword.put(:expected_interpolation, "cubic_spline")

    assert {:error, {:unsupported_campaign_environment_table, "interpolation"}} =
             Provider.load(opts)
  end

  test "rejects forged in-memory datasets before configured capability or fetch" do
    assert {:ok, dataset} = Provider.load(Provider.checked_in_options())

    forged_samples =
      update_in(dataset.samples, [Access.at(0), :sun_position_km], fn {x, y, z} ->
        {x + 1.0, y, z}
      end)

    forged_sources =
      update_in(dataset.sources, [Access.at(0)], &Map.put(&1, "source_revision", "DE440"))

    forged = [
      %{dataset | samples: forged_samples},
      %{dataset | sources: forged_sources},
      %{dataset | coverage: Map.put(dataset.coverage, "ends_at_s", @coverage_end_s - 1.0)}
    ]

    for forged_dataset <- forged do
      assert {:error,
              {:invalid_campaign_environment_dataset, :semantic_digest_mismatch, _expected,
               _actual}} = Provider.configured_capability(dataset: forged_dataset)

      assert {:error,
              {:invalid_campaign_environment_dataset, :semantic_digest_mismatch, _expected,
               _actual}} =
               Provider.fetch(:sun_direction,
                 dataset: forged_dataset,
                 seconds_since_j2000: @coverage_start_s
               )

      assert {:error,
              {:invalid_campaign_environment_dataset, :semantic_digest_mismatch, _expected,
               _actual}} = Provider.provenance(forged_dataset)
    end

    forged_verification =
      %{
        dataset
        | content_verification:
            Map.put(dataset.content_verification, "actual_sha256", String.duplicate("0", 64))
      }

    assert {:error, {:invalid_campaign_environment_dataset, :file_verification}} =
             Provider.configured_capability(dataset: forged_verification)

    assert {:error, {:invalid_campaign_environment_dataset, :file_verification}} =
             Provider.fetch(:earth_rotation,
               dataset: forged_verification,
               seconds_since_j2000: @coverage_start_s
             )
  end

  test "rejects improper and malformed Dataset containers without raising" do
    assert {:ok, dataset} = Provider.load(Provider.checked_in_options())

    malformed_datasets = [
      %{dataset | samples: [hd(dataset.samples) | :improper_tail]},
      %{dataset | sources: [hd(dataset.sources) | :improper_tail]},
      %{dataset | known_limits: [hd(dataset.known_limits) | :improper_tail]},
      %{dataset | coverage: [starts_at_s: @coverage_start_s]},
      %{
        dataset
        | content_verification: [
            actual_sha256: dataset.content_verification["actual_sha256"]
          ]
      }
    ]

    for malformed <- malformed_datasets do
      assert_invalid_dataset_error(Provider.configured_capability(dataset: malformed))

      assert_invalid_dataset_error(
        Provider.fetch(:sun_direction,
          dataset: malformed,
          seconds_since_j2000: @coverage_start_s
        )
      )

      assert_invalid_dataset_error(Provider.provenance(malformed))
    end

    assert {:error, {:invalid_campaign_environment_dataset, :invalid_container}} =
             Provider.provenance(%{})

    assert {:error, {:invalid_campaign_environment_dataset, :invalid_container}} =
             Provider.configured_capability(%{dataset: dataset})

    assert {:error, {:invalid_campaign_environment_dataset, :invalid_container}} =
             Provider.fetch(:earth_rotation, %{dataset: dataset})

    improper_opts = [{:dataset, dataset} | :improper_tail]
    assert_invalid_dataset_error(Provider.configured_capability(improper_opts))
    assert_invalid_dataset_error(Provider.fetch(:sun_direction, improper_opts))

    duplicate_dataset_opts = [dataset: dataset, dataset: hd(malformed_datasets)]
    assert_invalid_dataset_error(Provider.configured_capability(duplicate_dataset_opts))
    assert_invalid_dataset_error(Provider.fetch(:earth_rotation, duplicate_dataset_opts))
  end

  test "rejects duplicate JSON keys at top-level, source, and sample nesting" do
    bytes = checked_in_bytes()

    duplicate_cases = [
      {"top-identical.json", "  \"body\": \"earth\",", "  \"body\": \"earth\",", "body"},
      {"top-conflicting.json", "  \"body\": \"earth\",", "  \"body\": \"mars\",", "body"},
      {"source-identical.json", "      \"source_revision\": \"DE441\",",
       "      \"source_revision\": \"DE441\",", "source_revision"},
      {"source-conflicting.json", "      \"source_revision\": \"DE441\",",
       "      \"source_revision\": \"DE440\",", "source_revision"},
      {"sample-identical.json", "      \"mjd_utc\": 61041.0,", "      \"mjd_utc\": 61041.0,",
       "mjd_utc"},
      {"sample-conflicting.json", "      \"mjd_utc\": 61041.0,", "      \"mjd_utc\": 0.0,",
       "mjd_utc"}
    ]

    for {name, expected_line, inserted_line, key} <- duplicate_cases do
      duplicate_bytes =
        String.replace(bytes, expected_line, inserted_line <> "\n" <> expected_line,
          global: false
        )

      assert {:error, {:invalid_campaign_environment_table, {:duplicate_json_key, ^key}}} =
               load_raw_table(duplicate_bytes, name)
    end
  end

  test "binds checked-in Horizons rows and derives every sample epoch and vector from them" do
    table = checked_in_table()
    horizons = hd(table["sources"])
    payload = Enum.join(horizons["raw_soe_rows"], "\n") <> "\n"

    assert sha256(payload) == horizons["extracted_payload_sha256"]

    altered_sample =
      update_in(
        table,
        ["samples", Access.at(0), "sun_position_icrf_km", Access.at(0)],
        &(&1 + 1.0)
      )

    assert {:error, {:invalid_campaign_environment_table, {:horizons_sample_mismatch, 0}}} =
             load_reencoded_table(altered_sample, "altered-derived-sample.json")

    altered_row =
      update_in(table, ["sources", Access.at(0), "raw_soe_rows", Access.at(0)], &(&1 <> " "))

    assert {:error, {:invalid_campaign_environment_table, :horizons_payload_digest_mismatch}} =
             load_reencoded_table(altered_row, "altered-source-row.json")
  end

  defp earth_rotation(dataset, seconds_since_j2000) do
    Provider.fetch(:earth_rotation,
      dataset: dataset,
      seconds_since_j2000: seconds_since_j2000,
      body: :earth,
      frame: :earth_fixed_era_from_eci_j2000_approximation,
      time_scale: :utc,
      interpolation: :linear_sample_bracket
    )
  end

  defp checked_in_table do
    checked_in_bytes()
    |> :json.decode()
  end

  defp checked_in_bytes do
    Provider.checked_in_options()
    |> Keyword.fetch!(:path)
    |> File.read!()
  end

  defp load_reencoded_table(table, name) do
    table
    |> reencoded_table_options(name)
    |> Provider.load()
  end

  defp reencoded_table_options(table, name) do
    bytes = table |> :json.encode() |> IO.iodata_to_binary()
    raw_table_options(bytes, name)
  end

  defp load_raw_table(bytes, name) do
    bytes
    |> raw_table_options(name)
    |> Provider.load()
  end

  defp raw_table_options(bytes, name) do
    path = temporary_path(name)
    File.write!(path, bytes)

    Provider.checked_in_options()
    |> Keyword.put(:path, path)
    |> Keyword.put(:content_identity, %{"sha256" => sha256(bytes)})
  end

  defp temporary_path(name) do
    directory =
      Path.join(
        System.tmp_dir!(),
        "orbital-dynamics-campaign-environment-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(directory)
    on_exit(fn -> File.rm_rf!(directory) end)
    Path.join(directory, name)
  end

  defp sha256(bytes) do
    :crypto.hash(:sha256, bytes)
    |> Base.encode16(case: :lower)
  end

  defp vector_norm([x, y, z]), do: :math.sqrt(x * x + y * y + z * z)

  defp assert_invalid_dataset_error({:error, reason}) do
    assert is_tuple(reason)
    assert tuple_size(reason) >= 2
    assert elem(reason, 0) == :invalid_campaign_environment_dataset
  end
end
