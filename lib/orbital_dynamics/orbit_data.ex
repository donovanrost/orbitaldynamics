defmodule OrbitalDynamics.OrbitData do
  @moduledoc """
  Orbit-data adapter boundary for accepted planning-state artifacts.

  This module intentionally handles a simple JSON/map state-estimate batch, not a
  flight-dynamics interchange standard. External OD, catalog, or operator tools
  can hand OrbitalDynamics accepted Cartesian states here; the output is the
  executable `accepted_planning_state.v1` contract used by candidate refresh.
  """

  alias OrbitalDynamics.InputIntegrity
  alias OrbitalDynamics.Schema
  alias OrbitalDynamics.OrbitData.AcceptedPlanningState
  alias OrbitalDynamics.OrbitData.OmmMetadata
  alias OrbitalDynamics.OrbitData.OemInterpolation
  alias OrbitalDynamics.OrbitData.TleMetadata

  @j2000 ~U[2000-01-01 12:00:00Z]
  @opm_covariance_components [
    {0, 0, "CX_X"},
    {1, 0, "CY_X"},
    {1, 1, "CY_Y"},
    {2, 0, "CZ_X"},
    {2, 1, "CZ_Y"},
    {2, 2, "CZ_Z"},
    {3, 0, "CX_DOT_X"},
    {3, 1, "CX_DOT_Y"},
    {3, 2, "CX_DOT_Z"},
    {3, 3, "CX_DOT_X_DOT"},
    {4, 0, "CY_DOT_X"},
    {4, 1, "CY_DOT_Y"},
    {4, 2, "CY_DOT_Z"},
    {4, 3, "CY_DOT_X_DOT"},
    {4, 4, "CY_DOT_Y_DOT"},
    {5, 0, "CZ_DOT_X"},
    {5, 1, "CZ_DOT_Y"},
    {5, 2, "CZ_DOT_Z"},
    {5, 3, "CZ_DOT_X_DOT"},
    {5, 4, "CZ_DOT_Y_DOT"},
    {5, 5, "CZ_DOT_Z_DOT"}
  ]
  @opm_covariance_component_keys Enum.map(@opm_covariance_components, &elem(&1, 2))
  @opm_covariance_component_order ~w(
    x_km
    y_km
    z_km
    x_dot_km_s
    y_dot_km_s
    z_dot_km_s
  )
  @opm_spacecraft_metadata_fields [
    {"DRAG_AREA", "drag_area_m2", :drag_area_m2, " [m**2]"},
    {"DRAG_COEFF", "drag_coefficient", :drag_coefficient, ""},
    {"SOLAR_RAD_AREA", "solar_radiation_pressure_area_m2", :solar_radiation_pressure_area_m2,
     " [m**2]"},
    {"SOLAR_RAD_COEFF", "solar_radiation_pressure_coefficient",
     :solar_radiation_pressure_coefficient, ""}
  ]
  @opm_spacecraft_metadata_keys Enum.map(@opm_spacecraft_metadata_fields, &elem(&1, 0))
  @opm_maneuver_blocks_key "__OPM_MANEUVER_BLOCKS__"
  @doc """
  Declares the orbit-data adapter formats and known limits.
  """
  def capabilities do
    %{
      artifact_contract: "accepted_planning_state.v1",
      model: :planning_grade_cartesian_state_handoff,
      validation_level: :artifact_contract,
      import_formats: [
        :simple_json_state_estimate_batch,
        :verified_file_backed_simple_json_state_estimate_batch,
        :ccsds_opm_kvn_single_object_cartesian,
        :ccsds_oem_kvn_single_object_cartesian_ephemeris
      ],
      file_input_integrity: InputIntegrity.capabilities(),
      metadata_formats: [
        :tle_two_line_element,
        :ccsds_omm_kvn_mean_elements
      ],
      export_formats: [
        :simple_json_accepted_planning_state,
        :ccsds_opm_kvn_single_object_cartesian,
        :ccsds_oem_kvn_single_object_cartesian_ephemeris
      ],
      supported_frames: ["earth_inertial_j2000"],
      supported_opm_reference_frames: ["EME2000", "J2000", "ICRF"],
      supported_oem_reference_frames: ["EME2000", "J2000", "ICRF"],
      supported_opm_metadata_fields: [
        "CCSDS_OPM_VERS",
        "CREATION_DATE",
        "ORIGINATOR",
        "OBJECT_NAME",
        "OBJECT_ID",
        "CENTER_NAME",
        "REF_FRAME",
        "TIME_SYSTEM",
        "MASS",
        "DRAG_AREA",
        "DRAG_COEFF",
        "SOLAR_RAD_AREA",
        "SOLAR_RAD_COEFF",
        "COV_REF_FRAME",
        "MAN_EPOCH",
        "MAN_DURATION",
        "MAN_DELTA_MASS",
        "MAN_REF_FRAME",
        "MAN_DV_1",
        "MAN_DV_2",
        "MAN_DV_3"
      ],
      supported_opm_covariance_fields: ["COV_REF_FRAME" | @opm_covariance_component_keys],
      supported_opm_spacecraft_metadata_fields: @opm_spacecraft_metadata_keys,
      supported_oem_metadata_fields: [
        "CCSDS_OEM_VERS",
        "CREATION_DATE",
        "ORIGINATOR",
        "OBJECT_NAME",
        "OBJECT_ID",
        "CENTER_NAME",
        "REF_FRAME",
        "TIME_SYSTEM",
        "INTERPOLATION",
        "INTERPOLATION_DEGREE",
        "START_TIME",
        "STOP_TIME",
        "USEABLE_START_TIME",
        "USEABLE_STOP_TIME",
        "EPOCH",
        "COV_REF_FRAME"
      ],
      oem_interpolation: OemInterpolation.capabilities(),
      supported_oem_covariance_fields: ["EPOCH", "COV_REF_FRAME" | @opm_covariance_component_keys],
      supported_covariance_component_order: @opm_covariance_component_order,
      supported_tle_metadata_fields: TleMetadata.supported_metadata_fields(),
      supported_omm_metadata_fields: OmmMetadata.supported_metadata_fields(),
      supported_opm_maneuver_metadata_blocks: :multiple,
      exported_opm_maneuver_metadata_blocks: :multiple,
      known_limits: [
        :oem_import_selects_one_sample_without_interpolation,
        :oem_interpolation_is_explicit_opt_in,
        :oem_interpolation_requires_declared_coverage_and_source_revision,
        :oem_interpolation_rejects_extrapolation,
        :oem_interpolation_covariance_is_preserved_not_interpolated,
        :oem_export_single_sample_no_interpolation,
        :no_tle_sgp4_import,
        :tle_metadata_only_no_sgp4_state_generation,
        :tle_mean_element_altitudes_are_preflight_estimates,
        :single_object_tle_metadata_preflight_only,
        :no_omm_sgp4_import,
        :omm_metadata_only_no_state_generation,
        :omm_mean_elements_are_preflight_estimates,
        :opm_covariance_metadata_only_no_propagation,
        :oem_covariance_metadata_only_no_propagation,
        :duplicate_single_value_kvn_fields_rejected,
        :opm_spacecraft_metadata_only_no_propagation,
        :opm_maneuver_metadata_only_no_propagation,
        :single_object_opm_only,
        :single_object_oem_only,
        :no_hidden_frame_or_time_scale_conversion
      ]
    }
  end

  @doc """
  Builds an `accepted_planning_state.v1` artifact from state-estimate rows.
  """
  def accepted_planning_state(estimates, opts \\ [])

  def accepted_planning_state(estimates, opts) when is_list(estimates) do
    with {:ok, artifact} <- build_accepted_planning_state(estimates, opts),
         {:ok, _report} <-
           Schema.validate_artifact(artifact, schema_contract: "accepted_planning_state.v1") do
      {:ok, artifact}
    else
      {:error, %{"status" => "fail"} = report} ->
        {:error, {:invalid_accepted_planning_state, report}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def accepted_planning_state(_estimates, _opts),
    do: {:error, {:invalid_field, "state_estimates"}}

  @doc """
  Bang variant of `accepted_planning_state/2`.
  """
  def accepted_planning_state!(estimates, opts \\ []) do
    case accepted_planning_state(estimates, opts) do
      {:ok, artifact} ->
        artifact

      {:error, reason} ->
        raise ArgumentError, "invalid orbit-data state estimates: #{inspect(reason)}"
    end
  end

  @doc """
  Imports a simple JSON or decoded map state-estimate batch.

  Expected input shape:

      %{
        "snapshot_id" => "...",
        "accepted_at" => "...",
        "state_estimates" => [%{"spacecraft_id" => "...", ...}]
      }
  """
  def import_simple_json(source, opts \\ [])

  def import_simple_json(json, opts) when is_binary(json) do
    case :json.decode(json) do
      %{} = decoded -> import_simple_json(decoded, opts)
      _decoded -> {:error, :invalid_json_object}
    end
  rescue
    _error -> {:error, :invalid_json}
  end

  def import_simple_json(%{} = source, opts) do
    source = stringify_keys(source)

    provenance =
      opts
      |> Keyword.get(:provenance, Map.get(source, "provenance"))
      |> file_verification_provenance(Keyword.get(opts, :file_content_verification))

    opts =
      opts
      |> Keyword.put_new(:snapshot_id, Map.get(source, "snapshot_id"))
      |> Keyword.put_new(:accepted_at, Map.get(source, "accepted_at"))
      |> Keyword.put_new(:source, Map.get(source, "source"))
      |> Keyword.put_new(:quality, Map.get(source, "quality"))
      |> Keyword.put(:provenance, simple_json_provenance(source, provenance))
      |> Keyword.put_new(
        :maneuver_execution_deltas,
        Map.get(source, "maneuver_execution_deltas", [])
      )

    accepted_planning_state(Map.get(source, "state_estimates"), opts)
  end

  def import_simple_json(_source, _opts), do: {:error, :invalid_json_object}

  defp simple_json_provenance(source, provenance) when is_map(provenance) or is_nil(provenance) do
    provenance
    |> adapter_provenance(
      "simple_json_state_estimate_batch",
      "OrbitalDynamics.OrbitData.import_simple_json/2"
    )
    |> maybe_put("state_estimate_count", state_estimate_count(source))
  end

  defp simple_json_provenance(_source, provenance), do: provenance

  defp file_verification_provenance(%{} = provenance, %{} = evidence) do
    provenance
    |> stringify_keys()
    |> Map.put("file_content_verification", evidence)
    |> Map.put("import_adapter", "OrbitalDynamics.OrbitData.import_orbit_data_from_file/3")
    |> Map.put_new("trust_boundary", "sha256_verified_file_input")
    |> Map.put_new("network_access", false)
  end

  defp file_verification_provenance(nil, %{} = evidence),
    do: file_verification_provenance(%{}, evidence)

  defp file_verification_provenance(provenance, _evidence), do: provenance

  defp state_estimate_count(%{"state_estimates" => estimates}) when is_list(estimates),
    do: length(estimates)

  defp state_estimate_count(_source), do: nil

  @doc """
  Bang variant of `import_simple_json/2`.
  """
  def import_simple_json!(source, opts \\ []) do
    case import_simple_json(source, opts) do
      {:ok, artifact} -> artifact
      {:error, reason} -> raise ArgumentError, "invalid orbit-data JSON: #{inspect(reason)}"
    end
  end

  @doc """
  Verifies and imports a file-backed simple JSON state-estimate batch.

  `content_identity` must declare `%{"sha256" => lowercase_hex_digest}`. The
  exact bytes returned by content verification are parsed, avoiding a separate
  check-then-reopen step. Existing in-memory import functions do not require a
  content identity.
  """
  def import_orbit_data_from_file(path, content_identity, opts \\ []) do
    with {:ok, %{bytes: bytes, evidence: evidence}} <-
           InputIntegrity.verify_file(path, content_identity,
             consumer: "orbit_data.simple_json_state_estimate_batch"
           ) do
      import_simple_json(bytes, Keyword.put(opts, :file_content_verification, evidence))
    end
  end

  @doc """
  Imports orbit data from a decoded source wrapper or simple state-estimate batch.

  Supported wrapper formats:

  - `%{"format" => "simple_json_state_estimate_batch", ...}`
  - `%{"format" => "ccsds_opm_kvn", "content" => "..."}`
  - `%{"format" => "ccsds_oem_kvn", "content" => "..."}`

  TLE wrappers are parsed by `inspect_tle/2`, but intentionally rejected here
  because this adapter emits accepted Cartesian planning states and no SGP4
  propagation regime exists in this project yet.

  Unwrapped maps continue to use the simple JSON adapter.
  """
  def import_orbit_data(source, opts \\ [])

  def import_orbit_data(%{} = source, opts) do
    source = stringify_keys(source)

    case Map.get(source, "format") do
      format when format in ["ccsds_opm_kvn", "ccsds_opm_kvn_single_object_cartesian"] ->
        import_ccsds_opm(Map.get(source, "content"), orbit_data_opts(source, opts))

      format
      when format in [
             "ccsds_oem_kvn",
             "ccsds_oem_kvn_single_object_cartesian_ephemeris"
           ] ->
        import_ccsds_oem(Map.get(source, "content"), orbit_data_opts(source, opts))

      format when format in ["tle", "tle_sgp4", "tle_two_line_element"] ->
        with {:ok, metadata} <- inspect_tle(Map.get(source, "content"), opts) do
          {:error, {:unsupported_field, "format", "tle_requires_separate_sgp4_regime", metadata}}
        end

      format when format in ["ccsds_omm_kvn", "ccsds_omm_kvn_mean_elements", "omm"] ->
        with {:ok, metadata} <- inspect_ccsds_omm(Map.get(source, "content"), opts) do
          {:error,
           {:unsupported_field, "format", "omm_requires_separate_propagation_regime", metadata}}
        end

      format when format in [nil, "simple_json_state_estimate_batch"] ->
        import_simple_json(source, opts)

      format ->
        {:error, {:unsupported_field, "format", format}}
    end
  end

  def import_orbit_data(source, opts), do: import_simple_json(source, opts)

  @doc """
  Parses TLE metadata without producing an accepted Cartesian planning state.

  This is a preflight boundary only. TLEs require SGP4/SDP4 semantics and are not
  interchangeable with the Cartesian state-estimate adapters used by
  `accepted_planning_state.v1`.
  """
  def inspect_tle(source, opts \\ []), do: TleMetadata.inspect_tle(source, opts)

  @doc """
  Parses CCSDS OMM KVN mean-element metadata without producing a Cartesian state.

  This is a preflight boundary only. OMM mean elements need their declared
  element theory, often SGP4, and are not interchangeable with the Cartesian
  state-estimate adapters used by `accepted_planning_state.v1`.
  """
  def inspect_ccsds_omm(source, opts \\ []), do: OmmMetadata.inspect(source, opts)

  defp orbit_data_opts(source, opts) do
    opts
    |> Keyword.put_new(:snapshot_id, Map.get(source, "snapshot_id"))
    |> Keyword.put_new(:accepted_at, Map.get(source, "accepted_at"))
    |> Keyword.put_new(:source, Map.get(source, "source"))
    |> Keyword.put_new(:quality, Map.get(source, "quality"))
    |> Keyword.put_new(:provenance, Map.get(source, "provenance"))
    |> Keyword.put_new(:sample, Map.get(source, "sample"))
    |> Keyword.put_new(:sample_index, Map.get(source, "sample_index"))
    |> Keyword.put_new(:interpolate, Map.get(source, "interpolate"))
    |> Keyword.put_new(:interpolation, Map.get(source, "interpolation"))
    |> Keyword.put_new(:strategy_epoch, Map.get(source, "strategy_epoch"))
    |> Keyword.put_new(:source_revision, Map.get(source, "source_revision"))
    |> Keyword.put_new(:max_bracket_s, Map.get(source, "max_bracket_s"))
  end

  @doc """
  Exports a validated `accepted_planning_state.v1` artifact to deterministic JSON.
  """
  def export_simple_json(artifact) when is_map(artifact) do
    with {:ok, _report} <-
           Schema.validate_artifact(artifact, schema_contract: "accepted_planning_state.v1") do
      {:ok, artifact |> :json.encode() |> IO.iodata_to_binary()}
    else
      {:error, report} -> {:error, {:invalid_accepted_planning_state, report}}
    end
  end

  def export_simple_json(_artifact), do: {:error, {:invalid_field, "accepted_planning_state"}}

  @doc """
  Bang variant of `export_simple_json/1`.
  """
  def export_simple_json!(artifact) do
    case export_simple_json(artifact) do
      {:ok, json} ->
        json

      {:error, reason} ->
        raise ArgumentError, "invalid accepted planning state: #{inspect(reason)}"
    end
  end

  @doc """
  Imports a single-object CCSDS OPM KVN message into `accepted_planning_state.v1`.

  This is a deliberately narrow interchange adapter for planning-grade Cartesian
  state handoff. It supports Earth-centered `EME2000`/`J2000` OPM states in
  kilometers and kilometers per second.
  """
  def import_ccsds_opm(kvn, opts \\ [])

  def import_ccsds_opm(kvn, opts) when is_binary(kvn) do
    with :ok <-
           reject_duplicate_kvn_single_value_fields(kvn, "ccsds_opm",
             allow_duplicate_prefixes: ["MAN_"]
           ),
         {:ok, fields} <- parse_opm_kvn(kvn),
         {:ok, estimate} <- opm_state_estimate(fields),
         {:ok, accepted_at} <- opm_accepted_at(fields),
         {:ok, source} <- opm_source(fields),
         {:ok, quality} <-
           quality_map(Keyword.get(opts, :quality, %{"level" => "accepted"}), "quality"),
         {:ok, provenance} <- opm_provenance(fields, opts),
         {:ok, opm_maneuver_execution_deltas} <- opm_maneuver_execution_deltas(fields, estimate),
         {:ok, opt_maneuver_execution_deltas} <-
           maneuver_execution_deltas(
             Keyword.get(opts, :maneuver_execution_deltas, []),
             provenance
           ) do
      accepted_planning_state([estimate],
        snapshot_id: Keyword.get(opts, :snapshot_id) || opm_snapshot_id(fields, estimate),
        accepted_at: Keyword.get(opts, :accepted_at) || accepted_at,
        source: Keyword.get(opts, :source) || source,
        quality: quality,
        provenance: provenance,
        maneuver_execution_deltas: opt_maneuver_execution_deltas ++ opm_maneuver_execution_deltas
      )
    end
  end

  def import_ccsds_opm(_kvn, _opts), do: {:error, {:invalid_field, "ccsds_opm"}}

  @doc """
  Imports a single-object CCSDS OEM KVN ephemeris into `accepted_planning_state.v1`.

  By default the adapter deliberately selects one Cartesian ephemeris sample and
  records the sample-selection policy in provenance. Legacy selection does not
  interpolate between samples.

  Callers may explicitly request bounded strategy-epoch interpolation with
  `interpolate: true`, a scale-bearing `:strategy_epoch`, and a non-empty
  `:source_revision`. The accepted time must be supplied as a timezone-bearing
  ISO-8601 `:accepted_at` option or a valid timezone-bearing ISO-8601
  `CREATION_DATE` header. That path uses exact-sample selection at exact epochs
  and cubic Hermite position/velocity interpolation inside the declared OEM
  coverage and source bracket. It never extrapolates or interpolates covariance.
  """
  def import_ccsds_oem(kvn, opts \\ [])

  def import_ccsds_oem(kvn, opts) when is_binary(kvn) do
    with :ok <- reject_duplicate_kvn_single_value_fields(kvn, "ccsds_oem"),
         {:ok, oem} <- parse_oem_kvn(kvn),
         {:ok, selection} <- oem_selection(kvn, oem, opts),
         {:ok, estimate} <-
           oem_state_estimate(
             oem.fields,
             selection.sample,
             selection.sample_index,
             oem.covariance_fields,
             selection.evidence
           ),
         {:ok, accepted_at} <-
           oem_accepted_at(oem.fields, selection.sample, opts, selection.evidence),
         {:ok, source} <- oem_source(oem.fields, selection.evidence),
         {:ok, quality} <-
           quality_map(Keyword.get(opts, :quality, %{"level" => "accepted"}), "quality"),
         {:ok, provenance} <-
           oem_provenance(
             oem.fields,
             selection.sample,
             selection.sample_index,
             oem.covariance_fields,
             opts,
             selection.evidence
           ) do
      accepted_planning_state([estimate],
        snapshot_id: Keyword.get(opts, :snapshot_id) || oem_snapshot_id(oem.fields, estimate),
        accepted_at: accepted_at,
        source: Keyword.get(opts, :source) || source,
        quality: quality,
        provenance: provenance
      )
    end
  end

  def import_ccsds_oem(_kvn, _opts), do: {:error, {:invalid_field, "ccsds_oem"}}

  @doc """
  Exports a single-state `accepted_planning_state.v1` artifact as CCSDS OPM KVN.
  """
  def export_ccsds_opm(artifact, opts \\ [])

  def export_ccsds_opm(%{} = artifact, opts) do
    with {:ok, _report} <-
           Schema.validate_artifact(artifact, schema_contract: "accepted_planning_state.v1"),
         {:ok, state} <- single_spacecraft_state(artifact),
         {:ok, epoch} <- opm_epoch_from_state(state) do
      {:ok, opm_kvn(artifact, state, epoch, opts)}
    else
      {:error, %{"status" => "fail"} = report} ->
        {:error, {:invalid_accepted_planning_state, report}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def export_ccsds_opm(_artifact, _opts),
    do: {:error, {:invalid_field, "accepted_planning_state"}}

  @doc """
  Exports a single-state `accepted_planning_state.v1` artifact as single-sample CCSDS OEM KVN.

  The export is intentionally narrow: one object, one Cartesian ephemeris sample,
  and explicit no-interpolation metadata. It is a planning handoff format, not a
  sampled trajectory export. When accepted-state quality carries a complete
  covariance matrix, the matrix is exported as a metadata-only covariance block.
  """
  def export_ccsds_oem(artifact, opts \\ [])

  def export_ccsds_oem(%{} = artifact, opts) do
    with {:ok, _report} <-
           Schema.validate_artifact(artifact, schema_contract: "accepted_planning_state.v1"),
         {:ok, state} <- single_spacecraft_state(artifact),
         {:ok, epoch} <- opm_epoch_from_state(state) do
      {:ok, oem_kvn(artifact, state, epoch, opts)}
    else
      {:error, %{"status" => "fail"} = report} ->
        {:error, {:invalid_accepted_planning_state, report}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def export_ccsds_oem(_artifact, _opts),
    do: {:error, {:invalid_field, "accepted_planning_state"}}

  defp reject_duplicate_kvn_single_value_fields(kvn, namespace, opts \\ []) do
    allowed_duplicate_prefixes = Keyword.get(opts, :allow_duplicate_prefixes, [])

    duplicate =
      kvn
      |> String.split(~r/\R/)
      |> Enum.map(&(&1 |> String.trim() |> String.trim_leading("\uFEFF")))
      |> Enum.reject(&(&1 == "" or String.starts_with?(&1, "#")))
      |> Enum.reject(&String.starts_with?(&1, "COMMENT"))
      |> Enum.filter(&String.contains?(&1, "="))
      |> Enum.map(fn line ->
        line |> String.split("=", parts: 2) |> List.first() |> String.trim() |> String.upcase()
      end)
      |> Enum.reject(fn key ->
        Enum.any?(allowed_duplicate_prefixes, &String.starts_with?(key, &1))
      end)
      |> Enum.frequencies()
      |> Enum.find(fn {_key, count} -> count > 1 end)

    case duplicate do
      nil ->
        :ok

      {key, _count} ->
        {:error, {:unsupported_field, "#{namespace}.duplicate_single_value_field", key}}
    end
  end

  defp parse_oem_kvn(kvn) do
    lines =
      kvn
      |> String.split(~r/\R/)
      |> Enum.map(&(&1 |> String.trim() |> String.trim_leading("\uFEFF")))
      |> Enum.reject(
        &(&1 == "" or String.starts_with?(&1, "#") or String.starts_with?(&1, "COMMENT"))
      )

    with {:ok, data_lines, covariance_fields} <- split_oem_covariance_lines(lines) do
      parse_oem_kvn_lines(data_lines, covariance_fields)
    end
  end

  defp split_oem_covariance_lines(lines) do
    lines
    |> Enum.reduce_while({:ok, [], [], nil}, fn
      "COVARIANCE_START", {:ok, data_lines, covariance_blocks, nil} ->
        {:cont, {:ok, data_lines, covariance_blocks, %{}}}

      "COVARIANCE_START", {:ok, _data_lines, _covariance_blocks, _open_block} ->
        {:halt, {:error, {:unsupported_field, "oem_covariance_segment"}}}

      "COVARIANCE_STOP", {:ok, _data_lines, _covariance_blocks, nil} ->
        {:halt, {:error, {:invalid_field, "covariance_matrix"}}}

      "COVARIANCE_STOP", {:ok, data_lines, covariance_blocks, open_block} ->
        {:cont, {:ok, data_lines, covariance_blocks ++ [open_block], nil}}

      line, {:ok, data_lines, covariance_blocks, nil} ->
        {:cont, {:ok, data_lines ++ [line], covariance_blocks, nil}}

      line, {:ok, data_lines, covariance_blocks, open_block} ->
        if String.contains?(line, "=") do
          [key, value] = String.split(line, "=", parts: 2)
          key = key |> String.trim() |> String.upcase()

          {:cont,
           {:ok, data_lines, covariance_blocks, Map.put(open_block, key, String.trim(value))}}
        else
          {:halt, {:error, {:invalid_field, "covariance_matrix"}}}
        end
    end)
    |> case do
      {:ok, _data_lines, _covariance_blocks, %{} = _open_block} ->
        {:error, {:missing_field, "COVARIANCE_STOP"}}

      {:ok, data_lines, [], nil} ->
        {:ok, data_lines, %{}}

      {:ok, data_lines, [covariance_fields], nil} ->
        {:ok, data_lines, covariance_fields}

      {:ok, _data_lines, _covariance_blocks, nil} ->
        {:error, {:unsupported_field, "oem_covariance_segment"}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse_oem_kvn_lines(lines, covariance_fields) do
    fields =
      lines
      |> Enum.filter(&String.contains?(&1, "="))
      |> Enum.reduce(%{}, fn line, acc ->
        [key, value] = String.split(line, "=", parts: 2)
        key = key |> String.trim() |> String.upcase()

        if key in ["META_START", "META_STOP"] do
          acc
        else
          Map.put(acc, key, String.trim(value))
        end
      end)

    samples =
      lines
      |> Enum.reject(&String.contains?(&1, "="))
      |> Enum.reject(&(&1 in ["META_START", "META_STOP"]))
      |> Enum.map(&parse_oem_sample/1)

    cond do
      map_size(fields) == 0 ->
        {:error, {:invalid_field, "ccsds_oem"}}

      Enum.count(lines, &(&1 == "META_START")) > 1 ->
        {:error, {:unsupported_field, "oem_metadata_segment"}}

      Enum.any?(samples, &match?({:error, _reason}, &1)) ->
        {:error, {:invalid_field, "ephemeris_data"}}

      samples == [] ->
        {:error, {:missing_field, "ephemeris_data"}}

      true ->
        {:ok,
         %{
           fields: fields,
           samples: Enum.map(samples, fn {:ok, sample} -> sample end),
           covariance_fields: covariance_fields
         }}
    end
  end

  defp parse_oem_sample(line) do
    case String.split(line) do
      [epoch, x, y, z, x_dot, y_dot, z_dot] ->
        with {:ok, x} <- parse_finite_float(x),
             {:ok, y} <- parse_finite_float(y),
             {:ok, z} <- parse_finite_float(z),
             {:ok, x_dot} <- parse_finite_float(x_dot),
             {:ok, y_dot} <- parse_finite_float(y_dot),
             {:ok, z_dot} <- parse_finite_float(z_dot) do
          {:ok,
           %{
             "epoch" => epoch,
             "position_km" => [x, y, z],
             "velocity_km_s" => [x_dot, y_dot, z_dot]
           }}
        else
          _error -> {:error, :invalid_sample}
        end

      _tokens ->
        {:error, :invalid_sample}
    end
  end

  defp parse_finite_float(value) do
    case Float.parse(value) do
      {number, ""} when number == number and abs(number) <= 1.7976931348623157e308 ->
        {:ok, number}

      _result ->
        {:error, :invalid_number}
    end
  end

  defp oem_selection(kvn, oem, opts) do
    if OemInterpolation.requested?(opts) do
      OemInterpolation.select(kvn, oem, opts)
    else
      with {:ok, sample, sample_index} <- oem_selected_sample(oem.samples, opts) do
        {:ok, %{sample: sample, sample_index: sample_index, evidence: nil}}
      end
    end
  end

  defp oem_selected_sample(samples, opts) do
    sample_selector = Keyword.get(opts, :sample) || Keyword.get(opts, :sample_index) || :first

    case sample_selector do
      selector when selector in [:first, "first"] ->
        {:ok, List.first(samples), 0}

      selector when selector in [:last, "last"] ->
        index = length(samples) - 1
        {:ok, Enum.at(samples, index), index}

      index when is_integer(index) and index >= 0 and index < length(samples) ->
        {:ok, Enum.at(samples, index), index}

      index
      when is_float(index) and index >= 0 and index < length(samples) and trunc(index) == index ->
        index = trunc(index)
        {:ok, Enum.at(samples, index), index}

      _selector ->
        {:error, {:invalid_field, "sample"}}
    end
  end

  defp oem_state_estimate(
         fields,
         sample,
         sample_index,
         covariance_fields,
         interpolation_evidence
       ) do
    with {:ok, object_name} <- opm_object_name(fields),
         {:ok, epoch_s} <- oem_epoch_seconds(sample),
         {:ok, time_scale} <- opm_time_scale(fields),
         {:ok, center_name} <- opm_center_name(fields),
         {:ok, frame} <- opm_frame(fields),
         {:ok, source} <- oem_source(fields, interpolation_evidence),
         {:ok, covariance_matrix} <- opm_covariance_matrix(covariance_fields) do
      covariance_status =
        interpolation_covariance_status(interpolation_evidence) ||
          oem_covariance_status(covariance_fields, covariance_matrix)

      quality =
        %{"level" => "accepted"}
        |> maybe_put(
          "covariance_reference_frame",
          oem_covariance_reference_frame(covariance_fields)
        )
        |> maybe_put("covariance_matrix_6x6", covariance_matrix)
        |> maybe_put(
          "covariance_component_order",
          if(covariance_matrix, do: @opm_covariance_component_order)
        )
        |> maybe_put(
          "covariance_status",
          covariance_status
        )
        |> maybe_put("covariance_epoch", opm_optional_value(covariance_fields, "EPOCH"))

      {:ok,
       %{
         "spacecraft_id" => object_name,
         "scenario_id" => object_name,
         "seconds_since_j2000" => epoch_s,
         "time_scale" => time_scale,
         "frame" => frame,
         "position_km" => Map.fetch!(sample, "position_km"),
         "velocity_km_s" => Map.fetch!(sample, "velocity_km_s"),
         "source" => source,
         "quality" => quality,
         "metadata" =>
           oem_metadata(
             fields,
             center_name,
             sample,
             sample_index,
             covariance_fields,
             interpolation_evidence
           )
       }}
    end
  end

  defp oem_epoch_seconds(%{"seconds_since_j2000" => epoch_s}) when is_number(epoch_s),
    do: {:ok, epoch_s * 1.0}

  defp oem_epoch_seconds(%{"epoch" => epoch}) do
    with {:ok, datetime} <- parse_opm_datetime(epoch) do
      {:ok, DateTime.diff(datetime, @j2000, :microsecond) / 1_000_000.0}
    end
  end

  defp oem_accepted_at(fields, sample, opts, nil) do
    with {:ok, accepted_at} <- legacy_oem_accepted_at(fields, sample) do
      {:ok, Keyword.get(opts, :accepted_at) || accepted_at}
    end
  end

  defp oem_accepted_at(fields, _sample, opts, %{} = _interpolation_evidence) do
    case Keyword.get(opts, :accepted_at) do
      nil -> oem_creation_accepted_at(fields)
      accepted_at -> validate_oem_accepted_at(accepted_at, :option)
    end
  end

  defp legacy_oem_accepted_at(fields, sample) do
    case Map.get(fields, "CREATION_DATE") do
      nil -> {:ok, Map.fetch!(sample, "epoch")}
      value -> {:ok, opm_value(value)}
    end
  end

  defp oem_creation_accepted_at(fields) do
    case Map.get(fields, "CREATION_DATE") do
      nil -> {:error, {:missing_field, "CREATION_DATE"}}
      value -> value |> opm_value() |> validate_oem_accepted_at(:field)
    end
  end

  defp validate_oem_accepted_at(accepted_at, source) when is_binary(accepted_at) do
    case DateTime.from_iso8601(accepted_at) do
      {:ok, _datetime, _offset} -> {:ok, accepted_at}
      {:error, _reason} -> invalid_oem_accepted_at(source)
    end
  end

  defp validate_oem_accepted_at(_accepted_at, source), do: invalid_oem_accepted_at(source)

  defp invalid_oem_accepted_at(:option), do: {:error, {:invalid_option, :accepted_at}}
  defp invalid_oem_accepted_at(:field), do: {:error, {:invalid_field, "CREATION_DATE"}}

  defp oem_source(fields, interpolation_evidence) do
    source =
      %{
        "format" => "ccsds_oem_kvn",
        "object_name" => opm_value(Map.get(fields, "OBJECT_NAME", "")),
        "object_id" => opm_value(Map.get(fields, "OBJECT_ID", "")),
        "originator" => opm_value(Map.get(fields, "ORIGINATOR", "unknown")),
        "center_name" => opm_value(Map.get(fields, "CENTER_NAME", "EARTH")),
        "ref_frame" => opm_value(Map.get(fields, "REF_FRAME", "EME2000")),
        "time_system" => opm_value(Map.get(fields, "TIME_SYSTEM", "UTC"))
      }

    source =
      case interpolation_evidence do
        %{"source" => interpolation_source} ->
          source
          |> Map.put("source_id", Map.fetch!(interpolation_source, "source_id"))
          |> Map.put("source_revision", Map.fetch!(interpolation_source, "source_revision"))
          |> Map.put("content_identity", Map.fetch!(interpolation_source, "content_identity"))

        _evidence ->
          source
      end

    {:ok, source}
  end

  defp oem_provenance(
         fields,
         sample,
         sample_index,
         covariance_fields,
         opts,
         interpolation_evidence
       ) do
    optional_map(
      Keyword.get(opts, :provenance, %{
        "format" => "ccsds_oem_kvn",
        "ccsds_oem_version" => opm_value(Map.get(fields, "CCSDS_OEM_VERS", "2.0")),
        "originator" => opm_value(Map.get(fields, "ORIGINATOR", "unknown"))
      }),
      "provenance"
    )
    |> case do
      {:ok, provenance} ->
        provenance =
          provenance
          |> adapter_provenance(
            "ccsds_oem_kvn",
            "OrbitalDynamics.OrbitData.import_ccsds_oem/2"
          )
          |> maybe_put("object_name", opm_optional_value(fields, "OBJECT_NAME"))
          |> maybe_put("object_id", opm_optional_value(fields, "OBJECT_ID"))
          |> maybe_put("center_name", opm_optional_value(fields, "CENTER_NAME") || "EARTH")
          |> maybe_put("ref_frame", opm_optional_value(fields, "REF_FRAME") || "EME2000")
          |> maybe_put("time_system", opm_optional_value(fields, "TIME_SYSTEM") || "UTC")
          |> maybe_put(
            "sample_selection",
            oem_sample_selection(interpolation_evidence)
          )
          |> maybe_put("sample_index", sample_index)
          |> maybe_put("sample_epoch", Map.fetch!(sample, "epoch"))
          |> maybe_put(
            "covariance_reference_frame",
            oem_covariance_reference_frame(covariance_fields)
          )
          |> maybe_put("covariance_epoch", opm_optional_value(covariance_fields, "EPOCH"))
          |> maybe_put(
            "covariance_component_order",
            if(opm_covariance_matrix_present?(covariance_fields),
              do: @opm_covariance_component_order
            )
          )
          |> maybe_put(
            "covariance_status",
            interpolation_covariance_status(interpolation_evidence) ||
              oem_covariance_status(covariance_fields)
          )

        {:ok, maybe_put(provenance, "oem_interpolation", interpolation_evidence)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp oem_snapshot_id(fields, estimate) do
    object_id = Map.get(fields, "OBJECT_ID") || Map.fetch!(estimate, "spacecraft_id")
    "ccsds_oem:#{opm_value(object_id)}:#{Map.fetch!(estimate, "seconds_since_j2000")}"
  end

  defp oem_metadata(
         fields,
         center_name,
         sample,
         sample_index,
         covariance_fields,
         interpolation_evidence
       ) do
    %{
      "input_format" => "ccsds_oem_kvn",
      "ccsds_oem_version" => opm_optional_value(fields, "CCSDS_OEM_VERS") || "2.0",
      "creation_date" => opm_optional_value(fields, "CREATION_DATE"),
      "originator" => opm_optional_value(fields, "ORIGINATOR"),
      "object_name" => opm_optional_value(fields, "OBJECT_NAME"),
      "object_id" => opm_optional_value(fields, "OBJECT_ID"),
      "center_name" => center_name,
      "ref_frame" => opm_optional_value(fields, "REF_FRAME") || "EME2000",
      "time_system" => opm_optional_value(fields, "TIME_SYSTEM") || "UTC",
      "interpolation" => opm_optional_value(fields, "INTERPOLATION"),
      "interpolation_degree" => opm_optional_value(fields, "INTERPOLATION_DEGREE"),
      "sample_index" => sample_index,
      "sample_epoch" => Map.fetch!(sample, "epoch"),
      "covariance_reference_frame" => oem_covariance_reference_frame(covariance_fields),
      "covariance_epoch" => opm_optional_value(covariance_fields, "EPOCH"),
      "covariance_status" =>
        interpolation_covariance_status(interpolation_evidence) ||
          oem_covariance_status(covariance_fields),
      "oem_interpolation_evidence_id" =>
        if(is_map(interpolation_evidence), do: interpolation_evidence["id"]),
      "requested_epoch" =>
        if(is_map(interpolation_evidence), do: interpolation_evidence["requested_epoch"]),
      "interpolation_method" =>
        if(is_map(interpolation_evidence),
          do: get_in(interpolation_evidence, ["interpolation", "method"])
        ),
      "interpolation_version" =>
        if(is_map(interpolation_evidence),
          do: get_in(interpolation_evidence, ["interpolation", "version"])
        )
    }
    |> Enum.reject(fn {_key, value} -> value in [nil, ""] end)
    |> Map.new()
  end

  defp oem_sample_selection(nil), do: "single_ephemeris_sample_no_interpolation"

  defp oem_sample_selection(%{"interpolation" => %{"selection" => selection}}),
    do: selection

  defp interpolation_covariance_status(%{"covariance" => %{"status" => status}}), do: status
  defp interpolation_covariance_status(_evidence), do: nil

  defp oem_covariance_reference_frame(covariance_fields) do
    opm_optional_value(covariance_fields, "COV_REF_FRAME")
  end

  defp oem_covariance_status(covariance_fields, covariance_matrix \\ :not_loaded)

  defp oem_covariance_status(covariance_fields, covariance_matrix)
       when is_list(covariance_matrix) do
    if map_size(covariance_fields) > 0, do: "matrix_imported_metadata_only_no_propagation"
  end

  defp oem_covariance_status(covariance_fields, :not_loaded) do
    cond do
      opm_covariance_matrix_present?(covariance_fields) ->
        "matrix_imported_metadata_only_no_propagation"

      map_size(covariance_fields) > 0 ->
        "reference_frame_only_no_matrix_import"

      true ->
        nil
    end
  end

  defp oem_covariance_status(covariance_fields, _covariance_matrix) do
    if map_size(covariance_fields) > 0, do: "reference_frame_only_no_matrix_import"
  end

  defp parse_opm_kvn(kvn) do
    {fields, maneuver_block, maneuver_blocks} =
      kvn
      |> String.split(~r/\R/)
      |> Enum.reduce({%{}, %{}, []}, fn line, {fields, maneuver_block, maneuver_blocks} ->
        line = line |> String.trim() |> String.trim_leading("\uFEFF")

        cond do
          line == "" or String.starts_with?(line, "#") or String.starts_with?(line, "COMMENT") ->
            {fields, maneuver_block, maneuver_blocks}

          String.contains?(line, "=") ->
            [key, value] = String.split(line, "=", parts: 2)
            key = key |> String.trim() |> String.upcase()
            value = String.trim(value)

            parse_opm_field(key, value, fields, maneuver_block, maneuver_blocks)

          true ->
            {fields, maneuver_block, maneuver_blocks}
        end
      end)

    fields =
      case maybe_append_opm_maneuver_block(maneuver_blocks, maneuver_block) do
        [] -> fields
        maneuver_blocks -> Map.put(fields, @opm_maneuver_blocks_key, maneuver_blocks)
      end

    if map_size(fields) == 0, do: {:error, {:invalid_field, "ccsds_opm"}}, else: {:ok, fields}
  end

  defp parse_opm_field("MAN_EPOCH" = key, value, fields, maneuver_block, maneuver_blocks)
       when map_size(maneuver_block) > 0 do
    {fields, %{key => value}, maneuver_blocks ++ [maneuver_block]}
  end

  defp parse_opm_field("MAN_" <> _rest = key, value, fields, maneuver_block, maneuver_blocks) do
    {fields, Map.put(maneuver_block, key, value), maneuver_blocks}
  end

  defp parse_opm_field(key, value, fields, maneuver_block, maneuver_blocks) do
    {Map.put(fields, key, value), maneuver_block, maneuver_blocks}
  end

  defp maybe_append_opm_maneuver_block(maneuver_blocks, maneuver_block)
       when map_size(maneuver_block) == 0,
       do: maneuver_blocks

  defp maybe_append_opm_maneuver_block(maneuver_blocks, maneuver_block),
    do: maneuver_blocks ++ [maneuver_block]

  defp opm_state_estimate(fields) do
    with {:ok, object_name} <- opm_object_name(fields),
         {:ok, epoch_s} <- opm_epoch_seconds(fields),
         {:ok, time_scale} <- opm_time_scale(fields),
         {:ok, center_name} <- opm_center_name(fields),
         {:ok, frame} <- opm_frame(fields),
         {:ok, position_km} <- opm_vector(fields, ["X", "Y", "Z"], "position_km"),
         {:ok, velocity_km_s} <- opm_vector(fields, ["X_DOT", "Y_DOT", "Z_DOT"], "velocity_km_s"),
         {:ok, source} <- opm_source(fields),
         {:ok, covariance_matrix} <- opm_covariance_matrix(fields) do
      quality =
        %{"level" => "accepted"}
        |> maybe_put("covariance_reference_frame", opm_optional_value(fields, "COV_REF_FRAME"))
        |> maybe_put("covariance_matrix_6x6", covariance_matrix)
        |> maybe_put(
          "covariance_component_order",
          if(covariance_matrix, do: @opm_covariance_component_order)
        )
        |> maybe_put(
          "covariance_status",
          opm_covariance_status(fields, covariance_matrix)
        )

      {:ok,
       %{
         "spacecraft_id" => object_name,
         "scenario_id" => object_name,
         "seconds_since_j2000" => epoch_s,
         "time_scale" => time_scale,
         "frame" => frame,
         "position_km" => position_km,
         "velocity_km_s" => velocity_km_s,
         "source" => source,
         "quality" => quality,
         "metadata" => opm_metadata(fields, center_name)
       }
       |> maybe_put("dry_mass_kg", opm_optional_number(fields, "MASS"))}
    end
  end

  defp opm_object_name(fields) do
    case Map.get(fields, "OBJECT_ID") || Map.get(fields, "OBJECT_NAME") do
      value when is_binary(value) and value != "" -> {:ok, opm_value(value)}
      _value -> {:error, {:missing_field, "OBJECT_NAME"}}
    end
  end

  defp opm_epoch_seconds(fields) do
    with {:ok, epoch} <- opm_required_value(fields, "EPOCH"),
         {:ok, datetime} <- parse_opm_datetime(epoch) do
      {:ok, DateTime.diff(datetime, @j2000, :microsecond) / 1_000_000.0}
    end
  end

  defp opm_accepted_at(fields) do
    case Map.get(fields, "CREATION_DATE") do
      nil ->
        opm_required_value(fields, "EPOCH")

      value ->
        {:ok, opm_value(value)}
    end
  end

  defp opm_time_scale(fields) do
    case fields |> Map.get("TIME_SYSTEM", "UTC") |> opm_value() |> String.downcase() do
      scale when scale in ["tdb", "tai", "utc"] -> {:ok, scale}
      _scale -> {:error, {:invalid_field, "TIME_SYSTEM"}}
    end
  end

  defp opm_center_name(fields) do
    case fields |> Map.get("CENTER_NAME", "EARTH") |> opm_value() |> String.upcase() do
      "EARTH" -> {:ok, "EARTH"}
      _center -> {:error, {:unsupported_field, "CENTER_NAME"}}
    end
  end

  defp opm_frame(fields) do
    case fields |> Map.get("REF_FRAME", "EME2000") |> opm_value() |> String.upcase() do
      frame when frame in ["EME2000", "J2000", "ICRF"] -> {:ok, "earth_inertial_j2000"}
      _frame -> {:error, {:invalid_field, "REF_FRAME"}}
    end
  end

  defp opm_vector(fields, keys, field_name) do
    values =
      keys
      |> Enum.map(&opm_number(fields, &1))

    case values do
      [{:ok, x}, {:ok, y}, {:ok, z}] -> {:ok, [x, y, z]}
      _values -> {:error, {:invalid_field, field_name}}
    end
  end

  defp opm_number(fields, key) do
    with {:ok, value} <- opm_required_value(fields, key),
         {number, ""} <- Float.parse(value) do
      {:ok, number}
    else
      _error -> {:error, {:invalid_field, key}}
    end
  end

  defp opm_optional_number(fields, key) do
    case opm_number(fields, key) do
      {:ok, number} -> number
      {:error, _reason} -> nil
    end
  end

  defp opm_optional_value(fields, key) do
    case Map.get(fields, key) do
      value when is_binary(value) and value != "" -> opm_value(value)
      _value -> nil
    end
  end

  defp opm_required_value(fields, key) do
    case Map.get(fields, key) do
      value when is_binary(value) and value != "" -> {:ok, opm_value(value)}
      _value -> {:error, {:missing_field, key}}
    end
  end

  defp opm_value(value) do
    value
    |> String.trim()
    |> String.split(~r/\s+/, parts: 2)
    |> hd()
  end

  defp parse_opm_datetime(value) do
    value = opm_value(value)

    cond do
      String.ends_with?(value, "Z") ->
        case DateTime.from_iso8601(value) do
          {:ok, datetime, _offset} -> {:ok, datetime}
          {:error, _reason} -> {:error, {:invalid_field, "EPOCH"}}
        end

      true ->
        case NaiveDateTime.from_iso8601(value) do
          {:ok, naive} -> DateTime.from_naive(naive, "Etc/UTC")
          {:error, _reason} -> {:error, {:invalid_field, "EPOCH"}}
        end
    end
  end

  defp opm_source(fields) do
    {:ok,
     %{
       "format" => "ccsds_opm_kvn",
       "object_name" => opm_value(Map.get(fields, "OBJECT_NAME", "")),
       "object_id" => opm_value(Map.get(fields, "OBJECT_ID", "")),
       "originator" => opm_value(Map.get(fields, "ORIGINATOR", "unknown")),
       "center_name" => opm_value(Map.get(fields, "CENTER_NAME", "EARTH")),
       "ref_frame" => opm_value(Map.get(fields, "REF_FRAME", "EME2000")),
       "time_system" => opm_value(Map.get(fields, "TIME_SYSTEM", "UTC"))
     }}
  end

  defp opm_provenance(fields, opts) do
    optional_map(
      Keyword.get(opts, :provenance, %{
        "format" => "ccsds_opm_kvn",
        "ccsds_opm_version" => opm_value(Map.get(fields, "CCSDS_OPM_VERS", "2.0")),
        "originator" => opm_value(Map.get(fields, "ORIGINATOR", "unknown"))
      }),
      "provenance"
    )
    |> case do
      {:ok, provenance} ->
        {:ok,
         provenance
         |> adapter_provenance(
           "ccsds_opm_kvn",
           "OrbitalDynamics.OrbitData.import_ccsds_opm/2"
         )
         |> maybe_put("object_name", opm_optional_value(fields, "OBJECT_NAME"))
         |> maybe_put("object_id", opm_optional_value(fields, "OBJECT_ID"))
         |> maybe_put("center_name", opm_optional_value(fields, "CENTER_NAME") || "EARTH")
         |> maybe_put("ref_frame", opm_optional_value(fields, "REF_FRAME") || "EME2000")
         |> maybe_put("time_system", opm_optional_value(fields, "TIME_SYSTEM") || "UTC")
         |> maybe_put(
           "opm_spacecraft_metadata_status",
           opm_spacecraft_metadata_status(fields)
         )
         |> maybe_put("covariance_reference_frame", opm_optional_value(fields, "COV_REF_FRAME"))
         |> maybe_put(
           "covariance_component_order",
           if(opm_covariance_matrix_present?(fields), do: @opm_covariance_component_order)
         )
         |> maybe_put(
           "covariance_status",
           opm_covariance_status(fields)
         )
         |> maybe_put("opm_maneuver_metadata_count", opm_maneuver_metadata_count(fields))
         |> maybe_put(
           "opm_maneuver_metadata_status",
           opm_maneuver_metadata_status(fields)
         )}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp opm_snapshot_id(fields, estimate) do
    object_id = Map.get(fields, "OBJECT_ID") || Map.fetch!(estimate, "spacecraft_id")
    "ccsds_opm:#{opm_value(object_id)}:#{Map.fetch!(estimate, "seconds_since_j2000")}"
  end

  defp opm_maneuver_execution_deltas(fields, estimate) do
    fields
    |> opm_maneuver_blocks()
    |> Enum.reduce_while({:ok, []}, fn maneuver_block, {:ok, deltas} ->
      with {:ok, epoch_s} <- opm_maneuver_epoch_s(maneuver_block),
           {:ok, delta_v_km_s} <-
             opm_vector(
               maneuver_block,
               ["MAN_DV_1", "MAN_DV_2", "MAN_DV_3"],
               "maneuver_delta_v_km_s"
             ) do
        {:cont,
         {:ok,
          deltas ++
            [
              opm_maneuver_execution_delta(
                fields,
                maneuver_block,
                estimate,
                epoch_s,
                delta_v_km_s
              )
            ]}}
      else
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp opm_maneuver_execution_delta(fields, maneuver_block, estimate, epoch_s, delta_v_km_s) do
    object_id = opm_optional_value(fields, "OBJECT_ID") || Map.fetch!(estimate, "spacecraft_id")
    activity_id = "ccsds_opm_maneuver:#{object_id}:#{epoch_s}"

    %{
      "activity_id" => activity_id,
      "status" => "reported",
      "epoch_s" => epoch_s,
      "delta_v_km_s" => delta_v_km_s,
      "source" =>
        %{
          "format" => "ccsds_opm_kvn",
          "object_id" => object_id,
          "object_name" => opm_optional_value(fields, "OBJECT_NAME"),
          "maneuver_source" => "opm_man_fields",
          "maneuver_reference_frame" => opm_optional_value(maneuver_block, "MAN_REF_FRAME")
        }
        |> compact_map(),
      "quality" => %{
        "level" => "metadata_only",
        "maneuver_status" => "declared_no_execution_confirmation"
      },
      "metadata" =>
        %{
          "man_epoch" => opm_optional_value(maneuver_block, "MAN_EPOCH"),
          "man_duration_s" => opm_optional_number(maneuver_block, "MAN_DURATION"),
          "man_delta_mass_kg" => opm_optional_number(maneuver_block, "MAN_DELTA_MASS"),
          "man_ref_frame" => opm_optional_value(maneuver_block, "MAN_REF_FRAME"),
          "model_limit" => "maneuver_metadata_preserved_without_propagation"
        }
        |> compact_map(),
      "notes" => "CCSDS OPM maneuver metadata preserved; no maneuver propagation applied"
    }
  end

  defp opm_maneuver_epoch_s(fields) do
    with {:ok, epoch} <- opm_required_value(fields, "MAN_EPOCH"),
         {:ok, datetime} <- parse_opm_datetime(epoch) do
      {:ok, DateTime.diff(datetime, @j2000, :microsecond) / 1_000_000.0}
    end
  end

  defp opm_maneuver_metadata_count(fields) do
    fields
    |> opm_maneuver_blocks()
    |> length()
  end

  defp opm_maneuver_metadata_status(fields) do
    if opm_maneuver_metadata_count(fields) > 0, do: "metadata_only_no_propagation"
  end

  defp opm_maneuver_blocks(fields) do
    Map.get(fields, @opm_maneuver_blocks_key, [])
  end

  defp single_spacecraft_state(%{"spacecraft_states" => [state]}), do: {:ok, state}

  defp single_spacecraft_state(%{"spacecraft_states" => []}),
    do: {:error, {:missing_field, "spacecraft_states"}}

  defp single_spacecraft_state(%{"spacecraft_states" => [_ | _]}),
    do: {:error, {:unsupported_field, "spacecraft_states"}}

  defp single_spacecraft_state(_artifact), do: {:error, {:missing_field, "spacecraft_states"}}

  defp opm_covariance_matrix(fields) do
    if opm_covariance_matrix_present?(fields) do
      missing_keys =
        @opm_covariance_component_keys
        |> Enum.reject(&Map.has_key?(fields, &1))

      if missing_keys == [] do
        opm_covariance_matrix_from_components(fields)
      else
        {:error, {:missing_field, "covariance_matrix.#{List.first(missing_keys)}"}}
      end
    else
      {:ok, nil}
    end
  end

  defp opm_covariance_matrix_present?(fields),
    do: Enum.any?(@opm_covariance_component_keys, &Map.has_key?(fields, &1))

  defp opm_covariance_matrix_from_components(fields) do
    base_matrix = List.duplicate(List.duplicate(0.0, 6), 6)

    Enum.reduce_while(@opm_covariance_components, {:ok, base_matrix}, fn {row, column, key},
                                                                         {:ok, matrix} ->
      case opm_number(fields, key) do
        {:ok, value} ->
          matrix =
            matrix
            |> put_covariance_value(row, column, value)
            |> put_covariance_value(column, row, value)

          {:cont, {:ok, matrix}}

        {:error, _reason} ->
          {:halt, {:error, {:invalid_field, "covariance_matrix.#{key}"}}}
      end
    end)
  end

  defp put_covariance_value(matrix, row, column, value) do
    List.update_at(matrix, row, fn row_values ->
      List.replace_at(row_values, column, value)
    end)
  end

  defp opm_covariance_status(fields, covariance_matrix \\ :not_loaded)

  defp opm_covariance_status(_fields, covariance_matrix) when is_list(covariance_matrix),
    do: "matrix_imported_metadata_only_no_propagation"

  defp opm_covariance_status(fields, :not_loaded) do
    if opm_covariance_matrix_present?(fields) do
      "matrix_imported_metadata_only_no_propagation"
    else
      opm_covariance_status(fields, nil)
    end
  end

  defp opm_covariance_status(fields, _covariance_matrix) do
    if Map.has_key?(fields, "COV_REF_FRAME"), do: "reference_frame_only_no_matrix_import"
  end

  defp opm_epoch_from_state(%{"epoch" => %{"seconds_since_j2000" => seconds}})
       when is_number(seconds) do
    {:ok,
     @j2000 |> DateTime.add(round(seconds * 1_000_000), :microsecond) |> DateTime.to_iso8601()}
  end

  defp opm_epoch_from_state(_state), do: {:error, {:missing_field, "epoch"}}

  defp opm_kvn(artifact, state, epoch, opts) do
    position = get_in(state, ["state_vector", "position_km"])
    velocity = get_in(state, ["state_vector", "velocity_km_s"])
    metadata = Map.get(state, "metadata", %{})

    object_name =
      Keyword.get(opts, :object_name) || metadata["object_name"] ||
        Map.fetch!(state, "spacecraft_id")

    object_id = Keyword.get(opts, :object_id) || metadata["object_id"] || object_name
    center_name = Keyword.get(opts, :center_name) || metadata["center_name"] || "EARTH"
    ref_frame = Keyword.get(opts, :ref_frame) || metadata["ref_frame"] || "EME2000"
    mass_kg = opm_export_mass_kg(state, metadata, opts)
    covariance_reference_frame = opm_export_covariance_reference_frame(state, metadata, opts)

    [
      "CCSDS_OPM_VERS = 2.0",
      "CREATION_DATE = #{export_creation_date(artifact, metadata, opts)}",
      "ORIGINATOR = #{export_originator(metadata, opts)}",
      "OBJECT_NAME = #{object_name}",
      "OBJECT_ID = #{object_id}",
      "CENTER_NAME = #{center_name}",
      "REF_FRAME = #{ref_frame}",
      "TIME_SYSTEM = #{state |> get_in(["epoch", "time_scale"]) |> String.upcase()}",
      mass_kg && "MASS = #{format_kvn_number(mass_kg)} [kg]",
      opm_export_spacecraft_metadata_lines(metadata, opts),
      covariance_reference_frame && "COV_REF_FRAME = #{covariance_reference_frame}",
      "EPOCH = #{epoch}",
      "X = #{format_kvn_number(Enum.at(position, 0))} [km]",
      "Y = #{format_kvn_number(Enum.at(position, 1))} [km]",
      "Z = #{format_kvn_number(Enum.at(position, 2))} [km]",
      "X_DOT = #{format_kvn_number(Enum.at(velocity, 0))} [km/s]",
      "Y_DOT = #{format_kvn_number(Enum.at(velocity, 1))} [km/s]",
      "Z_DOT = #{format_kvn_number(Enum.at(velocity, 2))} [km/s]"
    ]
    |> List.flatten()
    |> Kernel.++(opm_export_covariance_lines(state))
    |> Kernel.++(opm_export_maneuver_lines(artifact, opts))
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n")
    |> Kernel.<>("\n")
  end

  defp opm_export_mass_kg(state, metadata, opts) do
    Keyword.get(opts, :mass_kg) || Keyword.get(opts, :spacecraft_mass_kg) ||
      Map.get(state, "dry_mass_kg") || Map.get(metadata, "spacecraft_mass_kg")
  end

  defp opm_export_covariance_reference_frame(state, metadata, opts) do
    Keyword.get(opts, :covariance_reference_frame) ||
      Map.get(metadata, "covariance_reference_frame") ||
      get_in(state, ["quality", "covariance_reference_frame"])
  end

  defp opm_export_spacecraft_metadata_lines(metadata, opts) do
    @opm_spacecraft_metadata_fields
    |> Enum.map(fn {field, metadata_key, opt_key, unit_suffix} ->
      case Keyword.get(opts, opt_key) || Map.get(metadata, metadata_key) do
        value when is_number(value) -> "#{field} = #{format_kvn_number(value)}#{unit_suffix}"
        _value -> nil
      end
    end)
  end

  defp opm_export_covariance_lines(state) do
    case get_in(state, ["quality", "covariance_matrix_6x6"]) do
      matrix when is_list(matrix) and length(matrix) == 6 ->
        covariance_component_lines(matrix)

      _matrix ->
        []
    end
  end

  defp opm_export_maneuver_lines(artifact, opts) do
    artifact
    |> Map.get("maneuver_execution_deltas", [])
    |> Enum.flat_map(&opm_export_maneuver_delta_lines(&1, opts))
  end

  defp opm_export_maneuver_delta_lines(%{} = delta, opts) do
    metadata = map_or_empty(Map.get(delta, "metadata"))
    source = map_or_empty(Map.get(delta, "source"))
    delta_v_km_s = Map.get(delta, "delta_v_km_s")

    with epoch when is_binary(epoch) <- opm_export_maneuver_epoch(delta, metadata),
         [dv_1, dv_2, dv_3] <- delta_v_km_s,
         true <- Enum.all?(delta_v_km_s, &is_number/1) do
      [
        "MAN_EPOCH = #{epoch}",
        opm_export_maneuver_duration_line(metadata),
        opm_export_maneuver_delta_mass_line(metadata),
        opm_export_maneuver_ref_frame_line(metadata, source, opts),
        "MAN_DV_1 = #{format_kvn_number(dv_1)} [km/s]",
        "MAN_DV_2 = #{format_kvn_number(dv_2)} [km/s]",
        "MAN_DV_3 = #{format_kvn_number(dv_3)} [km/s]"
      ]
      |> Enum.reject(&is_nil/1)
    else
      _missing_or_invalid -> []
    end
  end

  defp opm_export_maneuver_delta_lines(_delta, _opts), do: []

  defp map_or_empty(%{} = map), do: map
  defp map_or_empty(_value), do: %{}

  defp opm_export_maneuver_epoch(_delta, %{"man_epoch" => man_epoch})
       when is_binary(man_epoch) and man_epoch != "",
       do: man_epoch

  defp opm_export_maneuver_epoch(%{"epoch_s" => epoch_s}, _metadata) when is_number(epoch_s) do
    @j2000
    |> DateTime.add(round(epoch_s * 1_000_000), :microsecond)
    |> DateTime.to_iso8601()
  end

  defp opm_export_maneuver_epoch(_delta, _metadata), do: nil

  defp opm_export_maneuver_duration_line(%{"man_duration_s" => duration_s})
       when is_number(duration_s),
       do: "MAN_DURATION = #{format_kvn_number(duration_s)} [s]"

  defp opm_export_maneuver_duration_line(%{"duration_s" => duration_s})
       when is_number(duration_s),
       do: "MAN_DURATION = #{format_kvn_number(duration_s)} [s]"

  defp opm_export_maneuver_duration_line(_metadata), do: nil

  defp opm_export_maneuver_delta_mass_line(%{"man_delta_mass_kg" => delta_mass_kg})
       when is_number(delta_mass_kg),
       do: "MAN_DELTA_MASS = #{format_kvn_number(delta_mass_kg)} [kg]"

  defp opm_export_maneuver_delta_mass_line(%{"delta_mass_kg" => delta_mass_kg})
       when is_number(delta_mass_kg),
       do: "MAN_DELTA_MASS = #{format_kvn_number(delta_mass_kg)} [kg]"

  defp opm_export_maneuver_delta_mass_line(_metadata), do: nil

  defp opm_export_maneuver_ref_frame_line(metadata, source, opts) do
    ref_frame =
      Keyword.get(opts, :maneuver_ref_frame) ||
        Map.get(metadata, "man_ref_frame") ||
        Map.get(source, "maneuver_reference_frame")

    if is_binary(ref_frame) and ref_frame != "", do: "MAN_REF_FRAME = #{ref_frame}"
  end

  defp covariance_component_lines(matrix) do
    @opm_covariance_components
    |> Enum.map(fn {row, column, key} ->
      with row_values when is_list(row_values) <- Enum.at(matrix, row),
           value when is_number(value) <- Enum.at(row_values, column) do
        "#{key} = #{format_kvn_number(value)}"
      else
        _value -> nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp oem_kvn(artifact, state, epoch, opts) do
    position = get_in(state, ["state_vector", "position_km"])
    velocity = get_in(state, ["state_vector", "velocity_km_s"])
    metadata = Map.get(state, "metadata", %{})

    object_name =
      Keyword.get(opts, :object_name) || metadata["object_name"] ||
        Map.fetch!(state, "spacecraft_id")

    object_id = Keyword.get(opts, :object_id) || metadata["object_id"] || object_name
    center_name = Keyword.get(opts, :center_name) || metadata["center_name"] || "EARTH"
    ref_frame = Keyword.get(opts, :ref_frame) || metadata["ref_frame"] || "EME2000"

    ([
       "CCSDS_OEM_VERS = 2.0",
       "CREATION_DATE = #{export_creation_date(artifact, metadata, opts)}",
       "ORIGINATOR = #{export_originator(metadata, opts)}",
       "META_START",
       "OBJECT_NAME = #{object_name}",
       "OBJECT_ID = #{object_id}",
       "CENTER_NAME = #{center_name}",
       "REF_FRAME = #{ref_frame}",
       "TIME_SYSTEM = #{state |> get_in(["epoch", "time_scale"]) |> String.upcase()}",
       "INTERPOLATION = NONE",
       "INTERPOLATION_DEGREE = 0",
       "META_STOP",
       "#{epoch} #{format_kvn_number(Enum.at(position, 0))} #{format_kvn_number(Enum.at(position, 1))} #{format_kvn_number(Enum.at(position, 2))} #{format_kvn_number(Enum.at(velocity, 0))} #{format_kvn_number(Enum.at(velocity, 1))} #{format_kvn_number(Enum.at(velocity, 2))}"
     ] ++ oem_export_covariance_lines(state, metadata, epoch, opts))
    |> Enum.join("\n")
    |> Kernel.<>("\n")
  end

  defp export_creation_date(artifact, metadata, opts) do
    Keyword.get(opts, :creation_date) || metadata["creation_date"] ||
      Map.get(artifact, "accepted_at")
  end

  defp export_originator(metadata, opts) do
    Keyword.get(opts, :originator) || metadata["originator"] || "OrbitalDynamics"
  end

  defp oem_export_covariance_lines(state, metadata, epoch, opts) do
    case get_in(state, ["quality", "covariance_matrix_6x6"]) do
      matrix when is_list(matrix) and length(matrix) == 6 ->
        covariance_reference_frame =
          Keyword.get(opts, :covariance_reference_frame) ||
            Map.get(metadata, "covariance_reference_frame") ||
            get_in(state, ["quality", "covariance_reference_frame"])

        covariance_epoch =
          Keyword.get(opts, :covariance_epoch) ||
            get_in(state, ["quality", "covariance_epoch"]) ||
            Map.get(metadata, "covariance_epoch") ||
            epoch

        [
          "COVARIANCE_START",
          "EPOCH = #{covariance_epoch}",
          covariance_reference_frame && "COV_REF_FRAME = #{covariance_reference_frame}"
          | covariance_component_lines(matrix)
        ]
        |> Enum.reject(&is_nil/1)
        |> Kernel.++(["COVARIANCE_STOP"])

      _matrix ->
        []
    end
  end

  defp format_kvn_number(value) when is_float(value) do
    :erlang.float_to_binary(value, [:compact, decimals: 12])
  end

  defp format_kvn_number(value), do: value

  defp opm_metadata(fields, center_name) do
    %{
      "input_format" => "ccsds_opm_kvn",
      "ccsds_opm_version" => opm_optional_value(fields, "CCSDS_OPM_VERS") || "2.0",
      "creation_date" => opm_optional_value(fields, "CREATION_DATE"),
      "originator" => opm_optional_value(fields, "ORIGINATOR"),
      "object_name" => opm_optional_value(fields, "OBJECT_NAME"),
      "object_id" => opm_optional_value(fields, "OBJECT_ID"),
      "center_name" => center_name,
      "ref_frame" => opm_optional_value(fields, "REF_FRAME") || "EME2000",
      "time_system" => opm_optional_value(fields, "TIME_SYSTEM") || "UTC",
      "spacecraft_mass_kg" => opm_optional_number(fields, "MASS"),
      "opm_spacecraft_metadata_status" => opm_spacecraft_metadata_status(fields),
      "covariance_reference_frame" => opm_optional_value(fields, "COV_REF_FRAME"),
      "opm_maneuver_metadata_count" => opm_maneuver_metadata_count(fields),
      "opm_maneuver_metadata_status" => opm_maneuver_metadata_status(fields)
    }
    |> Map.merge(opm_spacecraft_metadata(fields))
    |> Enum.reject(fn {_key, value} -> value in [nil, ""] end)
    |> Map.new()
  end

  defp opm_spacecraft_metadata(fields) do
    @opm_spacecraft_metadata_fields
    |> Enum.reduce(%{}, fn {field, metadata_key, _opt_key, _unit_suffix}, acc ->
      maybe_put(acc, metadata_key, opm_optional_number(fields, field))
    end)
  end

  defp opm_spacecraft_metadata_status(fields) do
    if Enum.any?(@opm_spacecraft_metadata_keys, &Map.has_key?(fields, &1)),
      do: "metadata_only_no_propagation"
  end

  defp build_accepted_planning_state(estimates, opts),
    do: AcceptedPlanningState.build(estimates, opts)

  defp maneuver_execution_deltas(deltas, parent_provenance),
    do: AcceptedPlanningState.normalize_maneuver_execution_deltas(deltas, parent_provenance)

  defp quality_map(%{} = quality, path) do
    quality = stringify_keys(quality)

    case Map.get(quality, "level") do
      level when is_binary(level) and level != "" -> {:ok, quality}
      level when is_atom(level) -> {:ok, Map.put(quality, "level", Atom.to_string(level))}
      _level -> {:error, {:missing_field, path <> ".level"}}
    end
  end

  defp quality_map(nil, path), do: {:error, {:missing_field, path}}
  defp quality_map(_quality, path), do: {:error, {:invalid_field, path}}

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

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, stringify_keys(value))

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> value in [nil, ""] end)
    |> Map.new()
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), stringify_keys(value)}
      {key, value} when is_binary(key) -> {key, stringify_keys(value)}
      {key, value} -> {key, stringify_keys(value)}
    end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value) when is_boolean(value), do: value
  defp stringify_keys(nil), do: nil
  defp stringify_keys(value) when is_atom(value), do: Atom.to_string(value)
  defp stringify_keys(value), do: value
end
