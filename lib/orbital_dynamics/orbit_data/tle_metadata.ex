defmodule OrbitalDynamics.OrbitData.TleMetadata do
  @moduledoc false

  @earth_mu_km3_s2 398_600.4418
  @earth_equatorial_radius_km 6_378.137
  @supported_metadata_fields [
    "OBJECT_NAME",
    "SATELLITE_CATALOG_NUMBER",
    "CLASSIFICATION",
    "INTERNATIONAL_DESIGNATOR",
    "EPOCH",
    "INCLINATION",
    "RAAN",
    "ECCENTRICITY",
    "ARGUMENT_OF_PERIGEE",
    "MEAN_ANOMALY",
    "MEAN_MOTION",
    "MEAN_MOTION_FIRST_DERIVATIVE",
    "MEAN_MOTION_SECOND_DERIVATIVE",
    "BSTAR",
    "EPHEMERIS_TYPE",
    "ELEMENT_SET_NUMBER",
    "REVOLUTION_NUMBER_AT_EPOCH",
    "ORBITAL_PERIOD",
    "SEMI_MAJOR_AXIS",
    "PERIGEE_ALTITUDE",
    "APOGEE_ALTITUDE",
    "ALTITUDE_REGIME"
  ]

  def supported_metadata_fields, do: @supported_metadata_fields

  def inspect_tle(source, opts) when is_binary(source) do
    source
    |> String.split(~r/\R/)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == "" or String.starts_with?(&1, "#")))
    |> inspect_tle(opts)
  end

  def inspect_tle(lines, opts) when is_list(lines) do
    with {:ok, object_name, line1, line2} <- tle_lines(lines),
         :ok <- validate_tle_line_prefixes(line1, line2),
         :ok <- validate_tle_catalog_numbers(line1, line2),
         :ok <- validate_tle_checksum(line1),
         :ok <- validate_tle_checksum(line2),
         {:ok, metadata} <- metadata(object_name, line1, line2, opts) do
      {:ok, metadata}
    end
  end

  def inspect_tle(_source, _opts), do: {:error, {:invalid_field, "tle"}}

  defp tle_lines([line1, line2]) do
    {:ok, nil, line1, line2}
  end

  defp tle_lines([object_name, line1, line2]) do
    {:ok, object_name, line1, line2}
  end

  defp tle_lines([_object_name, _line1, _line2 | _rest]) do
    {:error, {:unsupported_field, "tle.multiple_objects"}}
  end

  defp tle_lines(_lines), do: {:error, {:invalid_field, "tle"}}

  defp validate_tle_line_prefixes(line1, line2) do
    cond do
      not is_binary(line1) or not String.starts_with?(line1, "1 ") ->
        {:error, {:invalid_field, "tle.line1"}}

      not is_binary(line2) or not String.starts_with?(line2, "2 ") ->
        {:error, {:invalid_field, "tle.line2"}}

      true ->
        :ok
    end
  end

  defp validate_tle_catalog_numbers(line1, line2) do
    if tle_slice(line1, 2, 5) == tle_slice(line2, 2, 5) do
      :ok
    else
      {:error, {:invalid_field, "tle.satellite_catalog_number"}}
    end
  end

  defp validate_tle_checksum(line) do
    padded = String.pad_trailing(line, 69)

    with checksum_char when checksum_char in ~w(0 1 2 3 4 5 6 7 8 9) <- String.at(padded, 68),
         {expected, ""} <- Integer.parse(checksum_char) do
      computed =
        padded
        |> String.slice(0, 68)
        |> String.to_charlist()
        |> Enum.reduce(0, fn
          char, acc when char in ?0..?9 -> acc + (char - ?0)
          ?-, acc -> acc + 1
          _char, acc -> acc
        end)
        |> rem(10)

      if computed == expected, do: :ok, else: {:error, {:invalid_field, "tle.checksum"}}
    else
      _error -> {:error, {:invalid_field, "tle.checksum"}}
    end
  end

  defp metadata(object_name, line1, line2, opts) do
    with {:ok, epoch_year} <- tle_integer(line1, 18, 2, "tle.epoch_year"),
         {:ok, epoch_day} <- tle_float(line1, 20, 12, "tle.epoch_day"),
         {:ok, epoch} <- tle_epoch(epoch_year, epoch_day),
         {:ok, mean_motion_derivative} <-
           tle_float(line1, 33, 10, "tle.mean_motion_first_derivative"),
         {:ok, mean_motion_second_derivative} <-
           tle_compact_exponential(line1, 44, 8, "tle.mean_motion_second_derivative"),
         {:ok, bstar} <- tle_compact_exponential(line1, 53, 8, "tle.bstar"),
         {:ok, ephemeris_type} <- tle_integer(line1, 62, 1, "tle.ephemeris_type"),
         {:ok, element_set_number} <- tle_integer(line1, 64, 4, "tle.element_set_number"),
         {:ok, inclination_deg} <- tle_float(line2, 8, 8, "tle.inclination_deg"),
         {:ok, raan_deg} <- tle_float(line2, 17, 8, "tle.raan_deg"),
         {:ok, eccentricity} <- tle_eccentricity(line2),
         {:ok, argument_of_perigee_deg} <-
           tle_float(line2, 34, 8, "tle.argument_of_perigee_deg"),
         {:ok, mean_anomaly_deg} <- tle_float(line2, 43, 8, "tle.mean_anomaly_deg"),
         {:ok, mean_motion_rev_per_day} <-
           tle_float(line2, 52, 11, "tle.mean_motion_rev_per_day"),
         {:ok, revolution_number} <-
           tle_integer(line2, 63, 5, "tle.revolution_number_at_epoch"),
         {:ok, source} <-
           optional_map(
             Keyword.get(opts, :source, %{"format" => "tle_two_line_element"}),
             "source"
           ),
         {:ok, provenance} <- optional_map(Keyword.get(opts, :provenance, %{}), "provenance") do
      satellite_catalog_number = tle_slice(line1, 2, 5)
      object_name = object_name || satellite_catalog_number
      regime = mean_element_regime(mean_motion_rev_per_day, eccentricity)

      provenance =
        provenance
        |> adapter_provenance(
          "tle_two_line_element",
          "OrbitalDynamics.OrbitData.inspect_tle/2"
        )

      {:ok,
       %{
         "format" => "tle_two_line_element",
         "object_name" => object_name,
         "satellite_catalog_number" => satellite_catalog_number,
         "classification" => tle_slice(line1, 7, 1),
         "international_designator" => tle_slice(line1, 9, 8),
         "epoch" => epoch,
         "mean_motion_first_derivative" => mean_motion_derivative,
         "mean_motion_second_derivative" => mean_motion_second_derivative,
         "bstar" => bstar,
         "ephemeris_type" => ephemeris_type,
         "element_set_number" => element_set_number,
         "inclination_deg" => inclination_deg,
         "raan_deg" => raan_deg,
         "eccentricity" => eccentricity,
         "argument_of_perigee_deg" => argument_of_perigee_deg,
         "mean_anomaly_deg" => mean_anomaly_deg,
         "mean_motion_rev_per_day" => mean_motion_rev_per_day,
         "mean_motion_rad_per_s" => regime["mean_motion_rad_per_s"],
         "orbital_period_min" => regime["orbital_period_min"],
         "semi_major_axis_km" => regime["semi_major_axis_km"],
         "perigee_altitude_km" => regime["perigee_altitude_km"],
         "apogee_altitude_km" => regime["apogee_altitude_km"],
         "altitude_regime" => regime["altitude_regime"],
         "mean_element_analysis_status" => "preflight_estimate_not_sgp4_state",
         "revolution_number_at_epoch" => revolution_number,
         "accepted_planning_state_compatible" => false,
         "required_propagation_regime" => "sgp4",
         "state_vector_status" => "not_generated",
         "known_limits" => [
           "tle_requires_sgp4_not_two_body_cartesian_handoff",
           "tle_mean_element_altitudes_are_preflight_estimates",
           "no_state_vector_generated"
         ],
         "source" => source,
         "provenance" => provenance
       }}
    end
  end

  defp tle_slice(line, start, length) do
    line
    |> String.pad_trailing(start + length)
    |> String.slice(start, length)
    |> String.trim()
  end

  defp tle_integer(line, start, length, field_name) do
    case line |> tle_slice(start, length) |> Integer.parse() do
      {integer, ""} -> {:ok, integer}
      _error -> {:error, {:invalid_field, field_name}}
    end
  end

  defp tle_float(line, start, length, field_name) do
    case line |> tle_slice(start, length) |> tle_decimal_string() |> Float.parse() do
      {number, ""} -> {:ok, number}
      _error -> {:error, {:invalid_field, field_name}}
    end
  end

  defp tle_decimal_string("." <> rest), do: "0." <> rest
  defp tle_decimal_string("-." <> rest), do: "-0." <> rest
  defp tle_decimal_string("+." <> rest), do: "+0." <> rest
  defp tle_decimal_string(value), do: value

  defp tle_compact_exponential(line, start, length, field_name) do
    value = tle_slice(line, start, length)

    case Regex.run(~r/^([+-]?)(\d+)([+-]\d+)$/, value) do
      [_match, sign, mantissa, exponent] ->
        case Float.parse("#{sign}0.#{mantissa}e#{exponent}") do
          {number, ""} -> {:ok, number}
          _error -> {:error, {:invalid_field, field_name}}
        end

      _error ->
        {:error, {:invalid_field, field_name}}
    end
  end

  defp tle_eccentricity(line2) do
    case line2 |> tle_slice(26, 7) |> then(&Float.parse("0." <> &1)) do
      {number, ""} -> {:ok, number}
      _error -> {:error, {:invalid_field, "tle.eccentricity"}}
    end
  end

  def mean_element_regime(mean_motion_rev_per_day, eccentricity)
      when is_number(mean_motion_rev_per_day) and mean_motion_rev_per_day > 0.0 and
             is_number(eccentricity) do
    mean_motion_rad_per_s = mean_motion_rev_per_day * 2.0 * :math.pi() / 86_400.0
    semi_major_axis_km = :math.pow(@earth_mu_km3_s2 / :math.pow(mean_motion_rad_per_s, 2), 1 / 3)
    perigee_altitude_km = semi_major_axis_km * (1.0 - eccentricity) - @earth_equatorial_radius_km
    apogee_altitude_km = semi_major_axis_km * (1.0 + eccentricity) - @earth_equatorial_radius_km

    %{
      "mean_motion_rad_per_s" => mean_motion_rad_per_s,
      "orbital_period_min" => 1_440.0 / mean_motion_rev_per_day,
      "semi_major_axis_km" => semi_major_axis_km,
      "perigee_altitude_km" => perigee_altitude_km,
      "apogee_altitude_km" => apogee_altitude_km,
      "altitude_regime" => altitude_regime(perigee_altitude_km, apogee_altitude_km)
    }
  end

  defp altitude_regime(perigee_altitude_km, apogee_altitude_km) do
    cond do
      perigee_altitude_km < 160.0 ->
        "decay_or_reentry_screening"

      apogee_altitude_km < 2_000.0 ->
        "leo"

      perigee_altitude_km >= 34_000.0 and apogee_altitude_km <= 38_000.0 ->
        "geo"

      apogee_altitude_km >= 35_786.0 ->
        "heo_or_transfer"

      true ->
        "meo"
    end
  end

  defp tle_epoch(epoch_year, epoch_day) do
    year = if epoch_year >= 57, do: 1900 + epoch_year, else: 2000 + epoch_year
    day_index = trunc(epoch_day)
    fraction = epoch_day - day_index

    with true <- day_index >= 1,
         {:ok, date} <- Date.new(year, 1, 1) do
      datetime =
        date
        |> Date.add(day_index - 1)
        |> DateTime.new!(Time.new!(0, 0, 0), "Etc/UTC")
        |> DateTime.add(round(fraction * 86_400_000_000), :microsecond)

      {:ok,
       %{
         "year" => year,
         "day_of_year" => epoch_day,
         "iso8601" => DateTime.to_iso8601(datetime)
       }}
    else
      _error -> {:error, {:invalid_field, "tle.epoch"}}
    end
  end

  defp optional_map(%{} = value, _path), do: {:ok, stringify_keys(value)}
  defp optional_map(nil, _path), do: {:ok, %{}}
  defp optional_map(_value, path), do: {:error, {:invalid_field, path}}

  defp adapter_provenance(provenance, input_format, import_adapter) do
    provenance
    |> Kernel.||(%{})
    |> stringify_keys()
    |> Map.put_new("input_format", input_format)
    |> Map.put_new("import_adapter", import_adapter)
    |> Map.put_new("trust_boundary", "external_orbit_data_adapter")
    |> Map.put_new("network_access", false)
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} ->
      key = if is_atom(key), do: Atom.to_string(key), else: key
      {key, stringify_keys(value)}
    end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value) when is_boolean(value), do: value
  defp stringify_keys(nil), do: nil
  defp stringify_keys(value) when is_atom(value), do: Atom.to_string(value)
  defp stringify_keys(value), do: value
end
