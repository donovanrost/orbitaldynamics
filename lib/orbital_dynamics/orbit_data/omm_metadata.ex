defmodule OrbitalDynamics.OrbitData.OmmMetadata do
  @moduledoc false

  alias OrbitalDynamics.OrbitData.TleMetadata

  @j2000 ~U[2000-01-01 12:00:00Z]
  @supported_metadata_fields [
    "CCSDS_OMM_VERS",
    "CREATION_DATE",
    "ORIGINATOR",
    "OBJECT_NAME",
    "OBJECT_ID",
    "CENTER_NAME",
    "REF_FRAME",
    "TIME_SYSTEM",
    "MEAN_ELEMENT_THEORY",
    "EPOCH",
    "SEMI_MAJOR_AXIS",
    "INCLINATION",
    "RA_OF_ASC_NODE",
    "ECCENTRICITY",
    "ARG_OF_PERICENTER",
    "MEAN_ANOMALY",
    "MEAN_MOTION",
    "MEAN_MOTION_DOT",
    "MEAN_MOTION_DDOT",
    "BSTAR",
    "EPHEMERIS_TYPE",
    "CLASSIFICATION_TYPE",
    "NORAD_CAT_ID",
    "ELEMENT_SET_NO",
    "REV_AT_EPOCH"
  ]

  def supported_metadata_fields, do: @supported_metadata_fields

  def inspect(source, opts) when is_binary(source) do
    with :ok <- reject_duplicate_single_value_fields(source),
         {:ok, fields} <- parse_kvn(source),
         {:ok, metadata} <- metadata(fields, opts) do
      {:ok, metadata}
    end
  end

  def inspect(_source, _opts), do: {:error, {:invalid_field, "ccsds_omm"}}

  defp reject_duplicate_single_value_fields(kvn) do
    duplicate =
      kvn
      |> kvn_lines()
      |> Enum.map(fn line ->
        line |> String.split("=", parts: 2) |> List.first() |> String.trim() |> String.upcase()
      end)
      |> Enum.frequencies()
      |> Enum.find(fn {_key, count} -> count > 1 end)

    case duplicate do
      nil ->
        :ok

      {key, _count} ->
        {:error, {:unsupported_field, "ccsds_omm.duplicate_single_value_field", key}}
    end
  end

  defp parse_kvn(kvn) do
    fields =
      kvn
      |> kvn_lines()
      |> Enum.reduce(%{}, fn line, acc ->
        [key, value] = String.split(line, "=", parts: 2)
        Map.put(acc, key |> String.trim() |> String.upcase(), String.trim(value))
      end)

    if map_size(fields) == 0, do: {:error, {:invalid_field, "ccsds_omm"}}, else: {:ok, fields}
  end

  defp kvn_lines(kvn) do
    kvn
    |> String.split(~r/\R/)
    |> Enum.map(&(&1 |> String.trim() |> String.trim_leading("\uFEFF")))
    |> Enum.reject(&(&1 == "" or String.starts_with?(&1, "#")))
    |> Enum.reject(&String.starts_with?(&1, "COMMENT"))
    |> Enum.filter(&String.contains?(&1, "="))
  end

  defp metadata(fields, opts) do
    with {:ok, object_name} <- required_value(fields, "OBJECT_NAME"),
         {:ok, epoch} <- epoch(fields),
         {:ok, center_name} <- center_name(fields),
         {:ok, time_system} <- time_scale(fields),
         {:ok, mean_element_theory} <- required_value(fields, "MEAN_ELEMENT_THEORY"),
         {:ok, inclination_deg} <- number(fields, "INCLINATION"),
         {:ok, raan_deg} <- number(fields, "RA_OF_ASC_NODE"),
         {:ok, eccentricity} <- number(fields, "ECCENTRICITY"),
         {:ok, argument_of_pericenter_deg} <- number(fields, "ARG_OF_PERICENTER"),
         {:ok, mean_anomaly_deg} <- number(fields, "MEAN_ANOMALY"),
         {:ok, mean_motion_rev_per_day} <- number(fields, "MEAN_MOTION"),
         {:ok, source} <-
           optional_map(
             Keyword.get(opts, :source, %{"format" => "ccsds_omm_kvn"}),
             "source"
           ),
         {:ok, provenance} <- optional_map(Keyword.get(opts, :provenance, %{}), "provenance") do
      regime = TleMetadata.mean_element_regime(mean_motion_rev_per_day, eccentricity)
      object_id = optional_value(fields, "OBJECT_ID") || object_name

      provenance =
        provenance
        |> adapter_provenance(
          "ccsds_omm_kvn",
          "OrbitalDynamics.OrbitData.inspect_ccsds_omm/2"
        )

      {:ok,
       %{
         "format" => "ccsds_omm_kvn",
         "ccsds_omm_version" => optional_value(fields, "CCSDS_OMM_VERS") || "2.0",
         "creation_date" => optional_value(fields, "CREATION_DATE"),
         "originator" => optional_value(fields, "ORIGINATOR"),
         "object_name" => object_name,
         "object_id" => object_id,
         "center_name" => center_name,
         "ref_frame" => optional_value(fields, "REF_FRAME"),
         "time_system" => time_system,
         "mean_element_theory" => mean_element_theory,
         "epoch" => epoch,
         "semi_major_axis_km" => regime["semi_major_axis_km"],
         "imported_semi_major_axis_km" => optional_number(fields, "SEMI_MAJOR_AXIS"),
         "inclination_deg" => inclination_deg,
         "raan_deg" => raan_deg,
         "eccentricity" => eccentricity,
         "argument_of_pericenter_deg" => argument_of_pericenter_deg,
         "mean_anomaly_deg" => mean_anomaly_deg,
         "mean_motion_rev_per_day" => mean_motion_rev_per_day,
         "mean_motion_rad_per_s" => regime["mean_motion_rad_per_s"],
         "mean_motion_first_derivative" => optional_number(fields, "MEAN_MOTION_DOT"),
         "mean_motion_second_derivative" => optional_number(fields, "MEAN_MOTION_DDOT"),
         "bstar" => optional_number(fields, "BSTAR"),
         "ephemeris_type" => optional_number(fields, "EPHEMERIS_TYPE"),
         "classification_type" => optional_value(fields, "CLASSIFICATION_TYPE"),
         "norad_catalog_id" => optional_value(fields, "NORAD_CAT_ID"),
         "element_set_number" => optional_number(fields, "ELEMENT_SET_NO"),
         "revolution_number_at_epoch" => optional_number(fields, "REV_AT_EPOCH"),
         "orbital_period_min" => regime["orbital_period_min"],
         "perigee_altitude_km" => regime["perigee_altitude_km"],
         "apogee_altitude_km" => regime["apogee_altitude_km"],
         "altitude_regime" => regime["altitude_regime"],
         "mean_element_analysis_status" => "preflight_estimate_not_cartesian_state",
         "accepted_planning_state_compatible" => false,
         "required_propagation_regime" => required_propagation_regime(mean_element_theory),
         "state_vector_status" => "not_generated",
         "known_limits" => [
           "omm_requires_declared_mean_element_theory_not_cartesian_handoff",
           "omm_mean_element_altitudes_are_preflight_estimates",
           "no_state_vector_generated"
         ],
         "source" => source,
         "provenance" => provenance
       }
       |> compact_map()}
    end
  end

  defp epoch(fields) do
    with {:ok, epoch} <- required_value(fields, "EPOCH"),
         {:ok, datetime} <- parse_datetime(epoch) do
      {:ok,
       %{
         "iso8601" => DateTime.to_iso8601(datetime),
         "seconds_since_j2000" => DateTime.diff(datetime, @j2000, :microsecond) / 1_000_000.0
       }}
    end
  end

  defp center_name(fields) do
    case fields |> Map.get("CENTER_NAME", "EARTH") |> value() |> String.upcase() do
      "EARTH" -> {:ok, "EARTH"}
      _center -> {:error, {:unsupported_field, "CENTER_NAME"}}
    end
  end

  defp time_scale(fields) do
    case fields |> Map.get("TIME_SYSTEM", "UTC") |> value() |> String.downcase() do
      scale when scale in ["tdb", "tai", "utc"] -> {:ok, scale}
      _scale -> {:error, {:invalid_field, "TIME_SYSTEM"}}
    end
  end

  defp required_propagation_regime(mean_element_theory) do
    theory = mean_element_theory |> to_string() |> String.trim() |> String.downcase()

    cond do
      theory in ["sgp", "sgp4", "sdp4", "sgp4-xp"] -> "sgp4"
      theory == "" -> "declared_mean_element_theory"
      true -> theory
    end
  end

  defp number(fields, key) do
    with {:ok, field_value} <- required_value(fields, key),
         {number, ""} <- Float.parse(field_value) do
      {:ok, number}
    else
      _error -> {:error, {:invalid_field, key}}
    end
  end

  defp optional_number(fields, key) do
    case number(fields, key) do
      {:ok, number} -> number
      {:error, _reason} -> nil
    end
  end

  defp optional_value(fields, key) do
    case Map.get(fields, key) do
      field_value when is_binary(field_value) and field_value != "" -> value(field_value)
      _value -> nil
    end
  end

  defp required_value(fields, key) do
    case Map.get(fields, key) do
      field_value when is_binary(field_value) and field_value != "" -> {:ok, value(field_value)}
      _value -> {:error, {:missing_field, key}}
    end
  end

  defp value(field_value) do
    field_value
    |> String.trim()
    |> String.split(~r/\s+/, parts: 2)
    |> hd()
  end

  defp parse_datetime(field_value) do
    field_value = value(field_value)

    if String.ends_with?(field_value, "Z") do
      case DateTime.from_iso8601(field_value) do
        {:ok, datetime, _offset} -> {:ok, datetime}
        {:error, _reason} -> {:error, {:invalid_field, "EPOCH"}}
      end
    else
      case NaiveDateTime.from_iso8601(field_value) do
        {:ok, naive} -> DateTime.from_naive(naive, "Etc/UTC")
        {:error, _reason} -> {:error, {:invalid_field, "EPOCH"}}
      end
    end
  end

  defp optional_map(%{} = map, _path), do: {:ok, stringify_keys(map)}
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

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, field_value} -> field_value in [nil, ""] end)
    |> Map.new()
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn
      {key, field_value} when is_atom(key) -> {Atom.to_string(key), stringify_keys(field_value)}
      {key, field_value} when is_binary(key) -> {key, stringify_keys(field_value)}
      {key, field_value} -> {key, stringify_keys(field_value)}
    end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(field_value) when is_boolean(field_value), do: field_value
  defp stringify_keys(nil), do: nil
  defp stringify_keys(field_value) when is_atom(field_value), do: Atom.to_string(field_value)
  defp stringify_keys(field_value), do: field_value
end
