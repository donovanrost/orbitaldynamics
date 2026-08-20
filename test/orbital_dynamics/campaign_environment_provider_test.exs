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
      frames: [:eci_j2000, :iers_tirs],
      time_scale: :utc
    }

    assert Environment.provider_supports_request?(capability, request)
    refute Environment.provider_supports_request?(capability, %{request | starts_at_s: 0.0})
    refute Environment.provider_supports_request?(capability, %{request | body: :mars})
    refute Environment.provider_supports_request?(capability, %{request | frames: [:eme2000]})
    refute Environment.provider_supports_request?(capability, %{request | time_scale: :tdb})

    provenance = Provider.provenance(dataset)

    assert provenance["provider_revision"] == "campaign_environment_provider.v1"
    assert provenance["dataset_revision"] == "jpl_de441__iers_finals2000a_2026-08-13"

    assert provenance["content_sha256"] ==
             "bce2201bc77cc17d029542c383462ea70d2cafd930a296baebc80399aed82bdb"

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
             "jpl_de441__iers_finals2000a_2026-08-13"}} = Provider.load(wrong_revision_opts)

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

  defp earth_rotation(dataset, seconds_since_j2000) do
    Provider.fetch(:earth_rotation,
      dataset: dataset,
      seconds_since_j2000: seconds_since_j2000,
      body: :earth,
      frame: :iers_tirs,
      time_scale: :utc,
      interpolation: :linear_sample_bracket
    )
  end

  defp checked_in_table do
    Provider.checked_in_options()
    |> Keyword.fetch!(:path)
    |> File.read!()
    |> :json.decode()
  end

  defp load_reencoded_table(table, name) do
    table
    |> reencoded_table_options(name)
    |> Provider.load()
  end

  defp reencoded_table_options(table, name) do
    bytes = table |> :json.encode() |> IO.iodata_to_binary()
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
end
