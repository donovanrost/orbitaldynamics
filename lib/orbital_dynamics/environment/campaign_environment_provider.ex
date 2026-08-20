defmodule OrbitalDynamics.Environment.CampaignEnvironmentProvider do
  @moduledoc """
  Offline, finite-coverage campaign Sun and Earth-orientation provider.

  A table is loaded only after exact-byte SHA-256 verification. The loader binds
  the provider, dataset revision, body, frames, time scale, interpolation policy,
  declared coverage, source-product records, and strictly ordered daily samples
  into an immutable dataset value. Runtime fetches never reopen the file or call
  a network service.

  Sun direction is derived by linearly interpolating the adjacent geocentric
  Cartesian source vectors and normalizing the result. Earth rotation delegates
  its angle interpolation to `TabularEarthOrientationProvider`; the angle samples
  are derived from IERS UT1-UTC using the IERS ERA relation. Polar motion and
  UT1-UTC are interpolated and archived, but polar motion is not applied by the
  current spherical ground-track geometry.
  """

  @behaviour OrbitalDynamics.Environment.Provider

  alias OrbitalDynamics.Environment.TabularEarthOrientationProvider
  alias OrbitalDynamics.{InputIntegrity, Vector3}

  @schema_contract "campaign_environment_table.v1"
  @provider_id "environment.provider.campaign.jpl_de441_iers_finals2000a"
  @provider_revision "campaign_environment_provider.v1"
  @dataset_revision "jpl_de441__iers_finals2000a_2026-08-13"
  @table_sha256 "bce2201bc77cc17d029542c383462ea70d2cafd930a296baebc80399aed82bdb"
  @j2000_mjd_utc 51_544.5
  @seconds_per_day 86_400.0
  @era_at_j2000_turns 0.779_057_273_264_0
  @era_rate_turns_per_ut1_day 1.002_737_811_911_354_6
  @two_pi 2.0 * :math.pi()
  @sha256_regex ~r/\A[0-9a-f]{64}\z/

  @source_identities [
    %{
      "product_id" => "JPL Horizons geocentric Sun vector response; target 10; center 500@399",
      "source_revision" => "DE441",
      "source_url" =>
        "https://ssd.jpl.nasa.gov/api/horizons.api?format=text&COMMAND=%2710%27&OBJ_DATA=%27YES%27&MAKE_EPHEM=%27YES%27&EPHEM_TYPE=%27VECTORS%27&CENTER=%27500%40399%27&START_TIME=%272026-01-01%27&STOP_TIME=%272026-01-04%27&STEP_SIZE=%271+d%27&TIME_TYPE=%27UT%27&TIME_DIGITS=%27SECONDS%27&REF_SYSTEM=%27ICRF%27&REF_PLANE=%27FRAME%27&OUT_UNITS=%27KM-S%27&VEC_TABLE=%271%27&VEC_CORR=%27NONE%27&CSV_FORMAT=%27YES%27&VEC_LABELS=%27YES%27",
      "response_sha256" => "0f6c4d48cf23769550d6d9660df29e03a467456268174f588fddc07c0fe20fa8"
    },
    %{
      "product_id" => "finals2000A.all; Bulletin B final PM-x, PM-y, and UT1-UTC columns",
      "source_revision" => "HTTP Last-Modified Thu, 13 Aug 2026 17:57:55 GMT",
      "source_url" => "https://maia.usno.navy.mil/ser7/finals2000A.all",
      "response_sha256" => "b3f879d81c507f67dd14aba056bd67f54bb65c19fe563eebaf70d079ad700994"
    },
    %{
      "product_id" =>
        "IERS Conventions (2010), updated Chapter 5, equation 5.14 Earth Rotation Angle relation",
      "source_revision" => "HTTP Last-Modified Wed, 26 Dec 2018 19:58:59 GMT",
      "source_url" => "https://iers-conventions.obspm.fr/content/chapter5/icc5.pdf",
      "response_sha256" => "9ec6fac43f7037ff43896539d759333fc7e6007176cd72043b38d71cfd3e69c0"
    }
  ]

  @known_limits [
    "finite four-day campaign table only",
    "daily source cadence with linear interpolation only inside an adjacent sample bracket",
    "ICRF is treated as repository ECI J2000 with the documented approximately 0.02 arcsecond alignment limit",
    "geometric Sun direction only; no light-time, aberration, solar range, or penumbra model",
    "Earth rotation uses IERS Bulletin B UT1-UTC and the IERS ERA relation",
    "IERS polar motion is archived and interpolated but not applied by current spherical ground-track geometry",
    "source binding is not the Domain 18 external numerical acceptance case"
  ]

  defmodule Dataset do
    @moduledoc false

    @enforce_keys [
      :table_id,
      :provider_id,
      :provider_revision,
      :dataset_revision,
      :body,
      :source_inertial_frame,
      :provider_inertial_frame,
      :earth_fixed_frame,
      :time_scale,
      :interpolation,
      :sample_interval_s,
      :coverage,
      :samples,
      :sources,
      :known_limits,
      :content_verification
    ]
    defstruct @enforce_keys
  end

  @doc """
  Returns the checked-in table path and immutable expected identities.

  Supplying this value to `load/1` or as provider options is explicitly opt-in.
  """
  def checked_in_options do
    [
      path:
        Path.expand(
          "../../../data/environment/campaign_environment_2026-01-01_2026-01-04.json",
          __DIR__
        ),
      content_identity: %{"sha256" => @table_sha256},
      expected_provider_id: @provider_id,
      expected_provider_revision: @provider_revision,
      expected_dataset_revision: @dataset_revision,
      expected_body: "earth",
      expected_source_inertial_frame: "icrf",
      expected_provider_inertial_frame: "eci_j2000",
      expected_earth_fixed_frame: "iers_tirs",
      expected_time_scale: "utc",
      expected_interpolation: "linear_sample_bracket"
    ]
  end

  @impl OrbitalDynamics.Environment.Provider
  def capabilities do
    %{
      "id" => @provider_id,
      "schema_contract" => "environment_provider_capability.v1",
      "category" => "combined_campaign_environment",
      "model" => "tabular_geocentric_sun_and_iers_earth_orientation",
      "source" => "verified_campaign_environment_table",
      "validation_level" => "analysis",
      "coverage" => %{
        "starts_at_s" => nil,
        "ends_at_s" => nil,
        "time_scale" => "utc_seconds_since_j2000",
        "coverage_policy" => "verified_table_samples"
      },
      "interpolation" => "linear_sample_bracket",
      "supported_bodies" => ["earth"],
      "supported_frames" => ["eci_j2000", "iers_tirs"],
      "supported_time_scales" => ["utc"],
      "network_access" => false,
      "outputs" => [
        "sun_direction",
        "earth_rotation",
        "earth_rotation_angle_rad",
        "earth_rotation_rate_rad_s",
        "polar_motion_x_arcsec",
        "polar_motion_y_arcsec",
        "ut1_utc_s"
      ],
      "parameters" => %{
        "input_mode" => "sha256_verified_json_file",
        "provider_revision" => @provider_revision,
        "file_input_integrity" => InputIntegrity.capabilities()
      },
      "known_limits" => @known_limits
    }
  end

  @doc """
  Loads and validates one verified table into an immutable dataset value.
  """
  def load(opts \\ [])

  def load(opts) when is_list(opts) do
    path = Keyword.get(opts, :path)
    content_identity = Keyword.get(opts, :content_identity)

    with :ok <- validate_keyword(opts),
         {:ok, %{bytes: bytes, evidence: evidence}} <-
           InputIntegrity.verify_file(path, content_identity,
             consumer: "environment.campaign_environment_provider"
           ),
         {:ok, table} <- decode_table(bytes),
         :ok <- validate_table_identity(table, opts),
         {:ok, samples} <- normalized_samples(table),
         :ok <- validate_declared_coverage(table, samples),
         :ok <- validate_sources(table["sources"]),
         :ok <- validate_known_limits(table["known_limits"]) do
      {:ok,
       %Dataset{
         table_id: table["table_id"],
         provider_id: table["provider_id"],
         provider_revision: table["provider_revision"],
         dataset_revision: table["dataset_revision"],
         body: table["body"],
         source_inertial_frame: table["source_inertial_frame"],
         provider_inertial_frame: table["provider_inertial_frame"],
         earth_fixed_frame: table["earth_fixed_frame"],
         time_scale: table["time_scale"],
         interpolation: table["interpolation"],
         sample_interval_s: table["sample_interval_s"] * 1.0,
         coverage: table["coverage"],
         samples: samples,
         sources: table["sources"],
         known_limits: table["known_limits"],
         content_verification: evidence
       }}
    end
  end

  def load(_opts), do: {:error, {:invalid_option, :campaign_environment}}

  @doc """
  Returns the finite capability record for a loaded or file-configured dataset.
  """
  def configured_capability(opts \\ []) when is_list(opts) do
    with {:ok, dataset} <- dataset_from_opts(opts) do
      {:ok,
       capabilities()
       |> put_in(["coverage", "starts_at_s"], dataset.coverage["starts_at_s"])
       |> put_in(["coverage", "ends_at_s"], dataset.coverage["ends_at_s"])
       |> Map.put("source", dataset.table_id)
       |> Map.put("provenance", provenance(dataset))
       |> Map.put("source_identity", source_identity(dataset))
       |> Map.update!("parameters", fn parameters ->
         Map.merge(parameters, %{
           "sample_count" => length(dataset.samples),
           "sample_interval_s" => dataset.sample_interval_s,
           "dataset_revision" => dataset.dataset_revision,
           "source_inertial_frame" => dataset.source_inertial_frame,
           "provider_inertial_frame" => dataset.provider_inertial_frame,
           "earth_fixed_frame" => dataset.earth_fixed_frame
         })
       end)}
    end
  end

  def fetch(kind, opts \\ [])

  @impl OrbitalDynamics.Environment.Provider
  def fetch(:sun_direction, opts) when is_list(opts) do
    with {:ok, dataset} <- dataset_from_opts(opts),
         {:ok, seconds_since_j2000} <- request_seconds(opts),
         :ok <- validate_request_context(dataset, :sun_direction, opts),
         {:ok, before, after_sample} <-
           bracketing_samples(dataset.samples, seconds_since_j2000),
         {:ok, direction, interpolation} <-
           interpolated_sun_direction(before, after_sample, seconds_since_j2000) do
      {:ok,
       common_product(dataset, seconds_since_j2000)
       |> Map.merge(interpolation)
       |> Map.merge(%{
         "model" => "tabular_geocentric_geometric_sun_direction",
         "frame" => dataset.provider_inertial_frame,
         "source_frame" => dataset.source_inertial_frame,
         "sun_direction" => Tuple.to_list(direction)
       })}
    end
  end

  def fetch(:earth_rotation, opts) when is_list(opts) do
    with {:ok, dataset} <- dataset_from_opts(opts),
         {:ok, seconds_since_j2000} <- request_seconds(opts),
         :ok <- validate_request_context(dataset, :earth_rotation, opts),
         {:ok, before, after_sample} <-
           bracketing_samples(dataset.samples, seconds_since_j2000),
         {:ok, orientation} <-
           interpolated_earth_orientation(before, after_sample, seconds_since_j2000),
         {:ok, rotation} <-
           TabularEarthOrientationProvider.fetch(:earth_rotation,
             seconds_since_j2000: seconds_since_j2000,
             samples: earth_rotation_samples(dataset.samples),
             provider_id: dataset.provider_id,
             source: dataset.table_id,
             source_revision: dataset.dataset_revision,
             body: dataset.body,
             frame: dataset.earth_fixed_frame,
             time_scale: dataset.time_scale,
             interpolation: dataset.interpolation
           ) do
      {:ok,
       rotation
       |> Map.merge(common_product(dataset, seconds_since_j2000))
       |> Map.merge(orientation)
       |> Map.merge(%{
         "model" => "iers_era_with_tabular_earth_orientation",
         "frame" => dataset.earth_fixed_frame,
         "polar_motion_applied" => false
       })}
    end
  end

  def fetch(kind, _opts), do: {:error, {:unsupported_environment_product, kind}}

  @doc """
  Returns the exact provider, revision, coverage, content, and source identity.
  """
  def provenance(%Dataset{} = dataset) do
    %{
      "provider_id" => dataset.provider_id,
      "provider_revision" => dataset.provider_revision,
      "dataset_revision" => dataset.dataset_revision,
      "source_table_id" => dataset.table_id,
      "content_sha256" => dataset.content_verification["actual_sha256"],
      "coverage" => Map.merge(dataset.coverage, %{"time_scale" => dataset.time_scale}),
      "body" => dataset.body,
      "source_inertial_frame" => dataset.source_inertial_frame,
      "provider_inertial_frame" => dataset.provider_inertial_frame,
      "earth_fixed_frame" => dataset.earth_fixed_frame,
      "interpolation" => dataset.interpolation,
      "sample_count" => length(dataset.samples),
      "sample_interval_s" => dataset.sample_interval_s,
      "network_access" => false,
      "trust_boundary" => "sha256_verified_checked_in_campaign_table",
      "source_products" => dataset.sources,
      "file_content_verification" => dataset.content_verification,
      "known_limits" => dataset.known_limits
    }
  end

  defp source_identity(dataset) do
    %{
      "provider_revision" => dataset.provider_revision,
      "source_revision" => dataset.dataset_revision,
      "content_identity" => %{
        "algorithm" => "sha256",
        "sha256" => dataset.content_verification["actual_sha256"]
      }
    }
  end

  defp dataset_from_opts(opts) do
    case Keyword.get(opts, :dataset) do
      %Dataset{} = dataset -> {:ok, dataset}
      nil -> load(opts)
      _dataset -> {:error, {:invalid_option, :dataset}}
    end
  end

  defp validate_keyword(opts) do
    if Keyword.keyword?(opts), do: :ok, else: {:error, {:invalid_option, :campaign_environment}}
  end

  defp decode_table(bytes) do
    case :json.decode(bytes) do
      %{} = table -> {:ok, table}
      _value -> {:error, {:invalid_campaign_environment_table, :expected_json_object}}
    end
  rescue
    _error -> {:error, {:invalid_campaign_environment_table, :invalid_json}}
  end

  defp validate_table_identity(table, opts) do
    required_matches = [
      {"schema_contract", @schema_contract},
      {"provider_id", Keyword.get(opts, :expected_provider_id)},
      {"provider_revision", Keyword.get(opts, :expected_provider_revision)},
      {"dataset_revision", Keyword.get(opts, :expected_dataset_revision)},
      {"body", Keyword.get(opts, :expected_body)},
      {"source_inertial_frame", Keyword.get(opts, :expected_source_inertial_frame)},
      {"provider_inertial_frame", Keyword.get(opts, :expected_provider_inertial_frame)},
      {"earth_fixed_frame", Keyword.get(opts, :expected_earth_fixed_frame)},
      {"time_scale", Keyword.get(opts, :expected_time_scale)},
      {"interpolation", Keyword.get(opts, :expected_interpolation)}
    ]

    with :ok <- validate_required_expectations(required_matches),
         :ok <- validate_matches(table, required_matches),
         :ok <- validate_supported_table_contract(table),
         :ok <- nonempty_string(table["table_id"], :table_id),
         :ok <- positive_number(table["sample_interval_s"], :sample_interval_s),
         :ok <- validate_derivation(table["derivation"]) do
      :ok
    end
  end

  defp validate_supported_table_contract(table) do
    supported = [
      {"provider_id", @provider_id},
      {"provider_revision", @provider_revision},
      {"dataset_revision", @dataset_revision},
      {"body", "earth"},
      {"source_inertial_frame", "icrf"},
      {"provider_inertial_frame", "eci_j2000"},
      {"earth_fixed_frame", "iers_tirs"},
      {"time_scale", "utc"},
      {"interpolation", "linear_sample_bracket"}
    ]

    case Enum.find(supported, fn {field, expected} -> table[field] != expected end) do
      nil -> :ok
      {field, _expected} -> {:error, {:unsupported_campaign_environment_table, field}}
    end
  end

  defp validate_required_expectations(matches) do
    case Enum.find(matches, fn {field, expected} ->
           field != "schema_contract" and is_nil(expected)
         end) do
      nil -> :ok
      {field, _expected} -> {:error, {:missing_campaign_environment_identity, field}}
    end
  end

  defp validate_matches(table, matches) do
    Enum.reduce_while(matches, :ok, fn {field, expected}, :ok ->
      actual = table[field]

      if actual == expected do
        {:cont, :ok}
      else
        {:halt, {:error, {:campaign_environment_identity_mismatch, field, expected, actual}}}
      end
    end)
  end

  defp validate_derivation(%{} = derivation) do
    required = [
      "seconds_since_j2000",
      "sun_direction",
      "frame_mapping",
      "earth_rotation_angle",
      "earth_orientation"
    ]

    if Enum.all?(required, &(is_binary(derivation[&1]) and derivation[&1] != "")) do
      :ok
    else
      {:error, {:invalid_campaign_environment_table, :derivation}}
    end
  end

  defp validate_derivation(_derivation),
    do: {:error, {:invalid_campaign_environment_table, :derivation}}

  defp normalized_samples(%{"samples" => samples, "sample_interval_s" => interval_s})
       when is_list(samples) and length(samples) >= 2 and is_number(interval_s) do
    with {:ok, normalized} <- normalize_sample_rows(samples),
         :ok <- strictly_increasing_samples(normalized),
         :ok <- contiguous_samples(normalized, interval_s * 1.0) do
      {:ok, add_earth_rotation_angles(normalized)}
    end
  end

  defp normalized_samples(_table),
    do: {:error, {:invalid_campaign_environment_table, :samples}}

  defp normalize_sample_rows(samples) do
    samples
    |> Enum.with_index()
    |> Enum.reduce_while({:ok, []}, fn {sample, index}, {:ok, acc} ->
      case normalize_sample(sample) do
        {:ok, normalized} -> {:cont, {:ok, [normalized | acc]}}
        {:error, reason} -> {:halt, {:error, {reason, index}}}
      end
    end)
    |> case do
      {:ok, normalized} -> {:ok, Enum.reverse(normalized)}
      error -> error
    end
  end

  defp normalize_sample(%{} = sample) do
    with {:ok, mjd_utc} <- number_field(sample, "mjd_utc"),
         {:ok, sun_position} <- vector_field(sample, "sun_position_icrf_km"),
         {:ok, polar_motion_x} <- number_field(sample, "polar_motion_x_arcsec"),
         {:ok, polar_motion_y} <- number_field(sample, "polar_motion_y_arcsec"),
         {:ok, ut1_utc_s} <- number_field(sample, "ut1_utc_s"),
         :ok <- nonempty_string(sample["calendar_utc"], :calendar_utc),
         :ok <- nonempty_string(sample["iers_source_record"], :iers_source_record) do
      {:ok,
       %{
         mjd_utc: mjd_utc * 1.0,
         seconds_since_j2000: (mjd_utc - @j2000_mjd_utc) * @seconds_per_day,
         sun_position_km: sun_position,
         polar_motion_x_arcsec: polar_motion_x * 1.0,
         polar_motion_y_arcsec: polar_motion_y * 1.0,
         ut1_utc_s: ut1_utc_s * 1.0,
         calendar_utc: sample["calendar_utc"],
         iers_source_record: sample["iers_source_record"]
       }}
    end
  end

  defp normalize_sample(_sample),
    do: {:error, {:invalid_campaign_environment_table, :sample}}

  defp strictly_increasing_samples(samples) do
    if Enum.chunk_every(samples, 2, 1, :discard)
       |> Enum.all?(fn [before, after_sample] -> after_sample.mjd_utc > before.mjd_utc end) do
      :ok
    else
      {:error, {:invalid_campaign_environment_table, :nonmonotonic_or_duplicate_epochs}}
    end
  end

  defp contiguous_samples(samples, interval_s) do
    tolerance_s = 1.0e-6

    if Enum.chunk_every(samples, 2, 1, :discard)
       |> Enum.all?(fn [before, after_sample] ->
         actual_s = after_sample.seconds_since_j2000 - before.seconds_since_j2000
         abs(actual_s - interval_s) <= tolerance_s
       end) do
      :ok
    else
      {:error, {:invalid_campaign_environment_table, :sample_gap}}
    end
  end

  defp add_earth_rotation_angles(samples) do
    first_turn_floor = samples |> List.first() |> era_turns() |> :math.floor()

    angled =
      Enum.map(samples, fn sample ->
        Map.put(
          sample,
          :earth_rotation_angle_rad,
          @two_pi * (era_turns(sample) - first_turn_floor)
        )
      end)

    Enum.with_index(angled)
    |> Enum.map(fn {sample, index} ->
      {before, after_sample} = rate_bracket(angled, index)

      rate =
        (after_sample.earth_rotation_angle_rad - before.earth_rotation_angle_rad) /
          (after_sample.seconds_since_j2000 - before.seconds_since_j2000)

      Map.put(sample, :earth_rotation_rate_rad_s, rate)
    end)
  end

  defp rate_bracket(samples, 0), do: {Enum.at(samples, 0), Enum.at(samples, 1)}

  defp rate_bracket(samples, index) when index == length(samples) - 1,
    do: {Enum.at(samples, index - 1), Enum.at(samples, index)}

  defp rate_bracket(samples, index),
    do: {Enum.at(samples, index - 1), Enum.at(samples, index + 1)}

  defp era_turns(sample) do
    jd_ut1 = sample.mjd_utc + 2_400_000.5 + sample.ut1_utc_s / @seconds_per_day
    @era_at_j2000_turns + @era_rate_turns_per_ut1_day * (jd_ut1 - 2_451_545.0)
  end

  defp validate_declared_coverage(%{"coverage" => coverage}, samples) when is_map(coverage) do
    expected_start = List.first(samples).seconds_since_j2000
    expected_end = List.last(samples).seconds_since_j2000

    if coverage["starts_at_s"] == expected_start and coverage["ends_at_s"] == expected_end do
      :ok
    else
      {:error, {:invalid_campaign_environment_table, :coverage_mismatch}}
    end
  end

  defp validate_declared_coverage(_table, _samples),
    do: {:error, {:invalid_campaign_environment_table, :coverage}}

  defp validate_sources(sources) when is_list(sources) do
    cond do
      not Enum.all?(sources, &valid_source?/1) ->
        {:error, {:invalid_campaign_environment_table, :sources}}

      source_identities(sources) != @source_identities ->
        {:error, {:invalid_campaign_environment_table, :source_identity_mismatch}}

      true ->
        :ok
    end
  end

  defp validate_sources(_sources),
    do: {:error, {:invalid_campaign_environment_table, :sources}}

  defp valid_source?(%{} = source) do
    Enum.all?(
      ["authority", "product_id", "source_revision", "source_url", "retrieved_at"],
      fn key ->
        is_binary(source[key]) and source[key] != ""
      end
    ) and is_binary(source["response_sha256"]) and
      Regex.match?(@sha256_regex, source["response_sha256"])
  end

  defp valid_source?(_source), do: false

  defp source_identities(sources) do
    Enum.map(
      sources,
      &Map.take(&1, ["product_id", "source_revision", "source_url", "response_sha256"])
    )
  end

  defp validate_known_limits(@known_limits), do: :ok

  defp validate_known_limits(_limits),
    do: {:error, {:invalid_campaign_environment_table, :known_limits}}

  defp request_seconds(opts) do
    case Keyword.get(opts, :seconds_since_j2000) do
      value when is_number(value) -> {:ok, value * 1.0}
      _value -> {:error, {:invalid_option, :seconds_since_j2000}}
    end
  end

  defp validate_request_context(dataset, product, opts) do
    expected_frame =
      case product do
        :sun_direction -> dataset.provider_inertial_frame
        :earth_rotation -> dataset.earth_fixed_frame
      end

    checks = [
      {:body, normalize_label(Keyword.get(opts, :body, dataset.body)), dataset.body},
      {:frame, normalize_label(Keyword.get(opts, :frame, expected_frame)), expected_frame},
      {:time_scale, normalize_label(Keyword.get(opts, :time_scale, dataset.time_scale)),
       dataset.time_scale},
      {:interpolation, normalize_label(Keyword.get(opts, :interpolation, dataset.interpolation)),
       dataset.interpolation}
    ]

    case Enum.find(checks, fn {_field, actual, expected} -> actual != expected end) do
      nil ->
        :ok

      {field, actual, expected} ->
        {:error, {:campaign_environment_request_mismatch, field, expected, actual}}
    end
  end

  defp normalize_label(value) when is_atom(value), do: Atom.to_string(value)
  defp normalize_label(value), do: value

  defp bracketing_samples(samples, seconds_since_j2000) do
    cond do
      seconds_since_j2000 < List.first(samples).seconds_since_j2000 or
          seconds_since_j2000 > List.last(samples).seconds_since_j2000 ->
        {:error, {:outside_coverage, :campaign_environment}}

      true ->
        case Enum.find(samples, &(&1.seconds_since_j2000 == seconds_since_j2000)) do
          nil ->
            samples
            |> Enum.chunk_every(2, 1, :discard)
            |> Enum.find(fn [before, after_sample] ->
              before.seconds_since_j2000 < seconds_since_j2000 and
                seconds_since_j2000 < after_sample.seconds_since_j2000
            end)
            |> case do
              [before, after_sample] -> {:ok, before, after_sample}
              _missing -> {:error, {:outside_coverage, :campaign_environment}}
            end

          sample ->
            {:ok, sample, sample}
        end
    end
  end

  defp interpolated_sun_direction(sample, sample, _seconds_since_j2000) do
    with {:ok, direction} <- normalize_vector(sample.sun_position_km) do
      {:ok, direction,
       %{
         "interpolation" => "source_sample_exact",
         "before_epoch_s" => sample.seconds_since_j2000,
         "after_epoch_s" => sample.seconds_since_j2000,
         "interpolation_fraction" => 0.0
       }}
    end
  end

  defp interpolated_sun_direction(before, after_sample, seconds_since_j2000) do
    fraction = interpolation_fraction(before, after_sample, seconds_since_j2000)

    position =
      before.sun_position_km
      |> Vector3.scale(1.0 - fraction)
      |> Vector3.add(Vector3.scale(after_sample.sun_position_km, fraction))

    with {:ok, direction} <- normalize_vector(position) do
      {:ok, direction,
       %{
         "interpolation" => "linear_position_then_normalize",
         "before_epoch_s" => before.seconds_since_j2000,
         "after_epoch_s" => after_sample.seconds_since_j2000,
         "interpolation_fraction" => fraction
       }}
    end
  end

  defp normalize_vector(vector) do
    norm = Vector3.norm(vector)

    if norm > 0.0 do
      {:ok, Vector3.scale(vector, 1.0 / norm)}
    else
      {:error, {:invalid_campaign_environment_table, :zero_sun_position}}
    end
  end

  defp interpolated_earth_orientation(sample, sample, _seconds_since_j2000) do
    {:ok,
     %{
       "earth_orientation_interpolation" => "source_sample_exact",
       "polar_motion_x_arcsec" => sample.polar_motion_x_arcsec,
       "polar_motion_y_arcsec" => sample.polar_motion_y_arcsec,
       "ut1_utc_s" => sample.ut1_utc_s,
       "orientation_before_epoch_s" => sample.seconds_since_j2000,
       "orientation_after_epoch_s" => sample.seconds_since_j2000,
       "orientation_interpolation_fraction" => 0.0
     }}
  end

  defp interpolated_earth_orientation(before, after_sample, seconds_since_j2000) do
    fraction = interpolation_fraction(before, after_sample, seconds_since_j2000)

    {:ok,
     %{
       "earth_orientation_interpolation" => "linear_sample_bracket",
       "polar_motion_x_arcsec" =>
         lerp(before.polar_motion_x_arcsec, after_sample.polar_motion_x_arcsec, fraction),
       "polar_motion_y_arcsec" =>
         lerp(before.polar_motion_y_arcsec, after_sample.polar_motion_y_arcsec, fraction),
       "ut1_utc_s" => lerp(before.ut1_utc_s, after_sample.ut1_utc_s, fraction),
       "orientation_before_epoch_s" => before.seconds_since_j2000,
       "orientation_after_epoch_s" => after_sample.seconds_since_j2000,
       "orientation_interpolation_fraction" => fraction
     }}
  end

  defp interpolation_fraction(before, after_sample, seconds_since_j2000) do
    (seconds_since_j2000 - before.seconds_since_j2000) /
      (after_sample.seconds_since_j2000 - before.seconds_since_j2000)
  end

  defp lerp(before, after_value, fraction), do: before + fraction * (after_value - before)

  defp earth_rotation_samples(samples) do
    Enum.map(samples, fn sample ->
      %{
        seconds_since_j2000: sample.seconds_since_j2000,
        earth_rotation_angle_rad: sample.earth_rotation_angle_rad,
        earth_rotation_rate_rad_s: sample.earth_rotation_rate_rad_s
      }
    end)
  end

  defp common_product(dataset, seconds_since_j2000) do
    %{
      "provider_id" => dataset.provider_id,
      "provider_revision" => dataset.provider_revision,
      "dataset_revision" => dataset.dataset_revision,
      "source_table_id" => dataset.table_id,
      "content_sha256" => dataset.content_verification["actual_sha256"],
      "seconds_since_j2000" => seconds_since_j2000,
      "coverage_starts_at_s" => dataset.coverage["starts_at_s"],
      "coverage_ends_at_s" => dataset.coverage["ends_at_s"],
      "coverage_time_scale" => dataset.time_scale,
      "sample_count" => length(dataset.samples),
      "network_access" => false,
      "provenance" => provenance(dataset),
      "known_limits" => dataset.known_limits
    }
  end

  defp number_field(map, key) do
    case map[key] do
      value when is_number(value) -> {:ok, value}
      _value -> {:error, {:invalid_campaign_environment_table, key}}
    end
  end

  defp vector_field(map, key) do
    case map[key] do
      [x, y, z] when is_number(x) and is_number(y) and is_number(z) ->
        {:ok, {x * 1.0, y * 1.0, z * 1.0}}

      _value ->
        {:error, {:invalid_campaign_environment_table, key}}
    end
  end

  defp nonempty_string(value, _field) when is_binary(value) and value != "", do: :ok
  defp nonempty_string(_value, field), do: {:error, {:invalid_campaign_environment_table, field}}

  defp positive_number(value, _field) when is_number(value) and value > 0, do: :ok
  defp positive_number(_value, field), do: {:error, {:invalid_campaign_environment_table, field}}
end
