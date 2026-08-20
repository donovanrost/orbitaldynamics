defmodule OrbitalDynamics.Environment.TabularEarthOrientationProvider do
  @moduledoc """
  Declared-sample Earth-rotation provider.

  This adapter is a network-free boundary for externally prepared Earth
  orientation samples. It linearly interpolates declared rotation angles and
  does not fetch IERS or provider-side data.
  """

  @behaviour OrbitalDynamics.Environment.Provider

  alias OrbitalDynamics.InputIntegrity
  alias OrbitalDynamics.Schema.StableIdValidation

  @impl OrbitalDynamics.Environment.Provider
  def capabilities do
    %{
      "id" => "environment.provider.earth_orientation.tabular_rotation",
      "schema_contract" => "environment_provider_capability.v1",
      "category" => "body_rotation",
      "model" => "tabular_earth_orientation_rotation",
      "source" => "declared_earth_orientation_table",
      "validation_level" => "assumption_declared",
      "coverage" => %{
        "starts_at_s" => nil,
        "ends_at_s" => nil,
        "time_scale" => "seconds_since_j2000",
        "coverage_policy" => "declared_samples"
      },
      "interpolation" => "linear_declared_rotation_sample",
      "supported_bodies" => ["earth"],
      "supported_frames" => ["iers_tirs"],
      "supported_time_scales" => ["tdb", "tai", "utc"],
      "network_access" => false,
      "outputs" => ["earth_rotation", "earth_rotation_angle_rad", "earth_rotation_rate_rad_s"],
      "parameters" => %{
        "input_modes" => ["inline_declared_samples", "verified_json_file"],
        "file_input_integrity" => InputIntegrity.capabilities()
      },
      "known_limits" => [
        "declared_sample_table_only",
        "linear_interpolation_between_declared_rotation_samples",
        "no_iers_or_bulletin_fetch",
        "not_consumed_by_current_propagators"
      ]
    }
  end

  @doc """
  Returns a capability record for a concrete declared sample table.

  The generic provider capability is open-ended because the adapter has no
  bundled Earth-orientation data. A configured capability derives finite
  coverage from the caller-supplied samples so request-fit checks can reject
  out-of-table ground-track requests before the adapter is selected.
  """
  def configured_capability(opts \\ []) when is_list(opts) do
    with {:ok, samples} <- normalized_samples(Keyword.get(opts, :samples, [])) do
      configured_parameters = %{
        "sample_count" => length(samples),
        "coverage_source" => "declared_samples"
      }

      {:ok,
       capabilities()
       |> put_in(["coverage", "starts_at_s"], List.first(samples).seconds_since_j2000)
       |> put_in(["coverage", "ends_at_s"], List.last(samples).seconds_since_j2000)
       |> Map.put("source", Keyword.get(opts, :source, "declared_earth_orientation_table"))
       |> Map.update!("parameters", &Map.merge(&1, configured_parameters))}
    end
  end

  def fetch(kind, opts \\ [])

  @impl OrbitalDynamics.Environment.Provider
  def fetch(:earth_rotation, opts) do
    seconds_since_j2000 = Keyword.get(opts, :seconds_since_j2000)

    with :ok <- validate_number(:seconds_since_j2000, seconds_since_j2000),
         :ok <- validate_request_context(opts),
         {:ok, samples} <- normalized_samples(Keyword.get(opts, :samples, [])),
         {:ok, before, after_sample} <- bracketing_samples(samples, seconds_since_j2000) do
      {:ok, product(before, after_sample, seconds_since_j2000, samples, opts)}
    end
  end

  def fetch(kind, _opts), do: {:error, {:unsupported_environment_product, kind}}

  @doc """
  Verifies and consumes a JSON Earth-orientation sample table from disk.

  The table is an object with a `samples` array in the same shape accepted by
  `fetch/2`; optional `source` and `table_id` strings are preserved. The
  declared `%{"sha256" => digest}` is checked against the exact file bytes
  before JSON decoding or sample normalization.
  """
  def fetch_from_file(kind, path, content_identity, opts \\ [])

  def fetch_from_file(:earth_rotation, path, content_identity, opts) when is_list(opts) do
    with {:ok, %{bytes: bytes, evidence: evidence}} <-
           InputIntegrity.verify_file(path, content_identity,
             consumer: "environment.tabular_earth_orientation_provider"
           ),
         {:ok, table} <- decode_table(bytes),
         {:ok, samples} <- table_samples(table),
         {:ok, table_id} <- table_id(table, evidence),
         {:ok, source} <- table_source(table, opts) do
      fetch(
        :earth_rotation,
        opts
        |> Keyword.put(:samples, samples)
        |> Keyword.put(:source, source)
        |> Keyword.put(:source_table_id, table_id)
        |> Keyword.put(:file_content_verification, evidence)
        |> Keyword.put(:provenance, file_provenance(table_id, evidence))
      )
    end
  end

  def fetch_from_file(kind, _path, _content_identity, _opts),
    do: {:error, {:unsupported_environment_product, kind}}

  defp product(sample, sample, seconds_since_j2000, samples, opts) do
    %{
      "provider_id" => Keyword.get(opts, :provider_id, capabilities()["id"]),
      "model" => "tabular_earth_orientation_rotation",
      "earth_rotation_angle_rad" => sample.angle_rad,
      "earth_rotation_rate_rad_s" => sample.rate_rad_s,
      "seconds_since_j2000" => seconds_since_j2000 * 1.0,
      "interpolation" => "declared_sample_exact",
      "coverage_starts_at_s" => List.first(samples).seconds_since_j2000,
      "coverage_ends_at_s" => List.last(samples).seconds_since_j2000,
      "sample_count" => length(samples),
      "source" => Keyword.get(opts, :source, "declared_earth_orientation_table")
    }
    |> Map.merge(file_context(opts))
    |> compact_map()
  end

  defp product(before, after_sample, seconds_since_j2000, samples, opts) do
    span_s = after_sample.seconds_since_j2000 - before.seconds_since_j2000
    fraction = (seconds_since_j2000 - before.seconds_since_j2000) / span_s
    angle_rad = before.angle_rad + fraction * (after_sample.angle_rad - before.angle_rad)
    rate_rad_s = (after_sample.angle_rad - before.angle_rad) / span_s

    %{
      "provider_id" => Keyword.get(opts, :provider_id, capabilities()["id"]),
      "model" => "tabular_earth_orientation_rotation",
      "earth_rotation_angle_rad" => angle_rad,
      "earth_rotation_rate_rad_s" => rate_rad_s,
      "seconds_since_j2000" => seconds_since_j2000 * 1.0,
      "interpolation" => "linear_declared_rotation_sample",
      "interpolation_fraction" => fraction,
      "before_epoch_s" => before.seconds_since_j2000,
      "after_epoch_s" => after_sample.seconds_since_j2000,
      "coverage_starts_at_s" => List.first(samples).seconds_since_j2000,
      "coverage_ends_at_s" => List.last(samples).seconds_since_j2000,
      "sample_count" => length(samples),
      "source" => Keyword.get(opts, :source, "declared_earth_orientation_table")
    }
    |> Map.merge(file_context(opts))
    |> compact_map()
  end

  defp decode_table(bytes) do
    case :json.decode(bytes) do
      %{} = table -> {:ok, table}
      _value -> {:error, {:invalid_provider_table, :expected_json_object}}
    end
  rescue
    _error -> {:error, {:invalid_provider_table, :invalid_json}}
  end

  defp table_samples(%{"samples" => samples}) when is_list(samples), do: {:ok, samples}
  defp table_samples(_table), do: {:error, {:invalid_provider_table, :missing_samples}}

  defp table_id(%{"table_id" => table_id}, _evidence) when is_binary(table_id) do
    if StableIdValidation.valid?(table_id) do
      {:ok, table_id}
    else
      {:error, {:invalid_provider_table, :invalid_table_id}}
    end
  end

  defp table_id(%{"table_id" => _table_id}, _evidence),
    do: {:error, {:invalid_provider_table, :invalid_table_id}}

  defp table_id(_table, %{"actual_sha256" => sha256}) do
    {:ok, "earth_orientation_table:sha256:#{sha256}"}
  end

  defp table_source(%{"source" => source}, _opts) when is_binary(source) and source != "",
    do: {:ok, source}

  defp table_source(%{"source" => _source}, _opts),
    do: {:error, {:invalid_provider_table, :invalid_source}}

  defp table_source(_table, opts),
    do: {:ok, Keyword.get(opts, :source, "verified_earth_orientation_table")}

  defp file_provenance(table_id, evidence) do
    %{
      "source_table_id" => table_id,
      "input_format" => "json_earth_orientation_sample_table",
      "import_adapter" =>
        "OrbitalDynamics.Environment.TabularEarthOrientationProvider.fetch_from_file/4",
      "trust_boundary" => "sha256_verified_file_input",
      "network_access" => false,
      "file_content_verification" => evidence
    }
  end

  defp file_context(opts) do
    case Keyword.get(opts, :file_content_verification) do
      %{} ->
        %{
          "source_table_id" => Keyword.fetch!(opts, :source_table_id),
          "provenance" => Keyword.fetch!(opts, :provenance),
          "assumptions" => InputIntegrity.capabilities()["assumptions"],
          "known_limits" =>
            capabilities()["known_limits"] ++ InputIntegrity.capabilities()["known_limits"]
        }

      _verification ->
        %{}
    end
  end

  defp normalized_samples(samples) when is_list(samples) do
    normalized = Enum.map(samples, &normalize_sample/1)

    if Enum.all?(normalized, &match?({:ok, _sample}, &1)) do
      samples = Enum.map(normalized, fn {:ok, sample} -> sample end)

      cond do
        samples == [] ->
          {:error, {:missing_option, :samples}}

        nonmonotonic_or_duplicate_sample_times?(samples) ->
          {:error, {:invalid_option, :samples}}

        true ->
          {:ok, samples}
      end
    else
      {:error, {:invalid_option, :samples}}
    end
  end

  defp normalized_samples(_samples), do: {:error, {:invalid_option, :samples}}

  defp normalize_sample(%{} = sample) do
    with {:ok, seconds_since_j2000} <-
           sample_number(sample, [
             :seconds_since_j2000,
             "seconds_since_j2000",
             :epoch_s,
             "epoch_s"
           ]),
         {:ok, angle_rad} <-
           sample_number(sample, [
             :earth_rotation_angle_rad,
             "earth_rotation_angle_rad",
             :rotation_angle_rad,
             "rotation_angle_rad"
           ]) do
      {:ok,
       %{
         seconds_since_j2000: seconds_since_j2000 * 1.0,
         angle_rad: angle_rad * 1.0,
         rate_rad_s:
           optional_sample_number(sample, [
             :earth_rotation_rate_rad_s,
             "earth_rotation_rate_rad_s",
             :rotation_rate_rad_s,
             "rotation_rate_rad_s"
           ])
       }}
    end
  end

  defp normalize_sample(_sample), do: {:error, :invalid_sample}

  defp sample_number(sample, keys) do
    keys
    |> Enum.find_value(fn key ->
      case Map.get(sample, key) do
        value when is_number(value) -> {:ok, value}
        _value -> nil
      end
    end)
    |> case do
      {:ok, value} -> {:ok, value}
      nil -> {:error, :missing_sample_number}
    end
  end

  defp optional_sample_number(sample, keys) do
    keys
    |> Enum.find_value(fn key ->
      case Map.get(sample, key) do
        value when is_number(value) -> value * 1.0
        _value -> nil
      end
    end)
  end

  defp nonmonotonic_or_duplicate_sample_times?(samples) do
    samples
    |> Enum.map(& &1.seconds_since_j2000)
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.any?(fn [before_s, after_s] -> after_s <= before_s end)
  end

  defp validate_request_context(opts) do
    checks = [
      {:body, normalize_label(Keyword.get(opts, :body, :earth)), "earth", ["earth"]},
      {:frame, normalize_label(Keyword.get(opts, :frame)), nil, [nil, "iers_tirs"]},
      {:time_scale, normalize_label(Keyword.get(opts, :time_scale)), nil,
       [nil, "tdb", "tai", "utc"]},
      {:interpolation, normalize_label(Keyword.get(opts, :interpolation)), nil,
       [nil, "linear_sample_bracket", "linear_declared_rotation_sample"]}
    ]

    case Enum.find(checks, fn {_field, actual, _default, supported} -> actual not in supported end) do
      nil -> :ok
      {field, _actual, _default, _supported} -> {:error, {:invalid_option, field}}
    end
  end

  defp normalize_label(nil), do: nil
  defp normalize_label(value) when is_atom(value), do: Atom.to_string(value)
  defp normalize_label(value), do: value

  defp bracketing_samples([sample], seconds_since_j2000) do
    if sample.seconds_since_j2000 == seconds_since_j2000 do
      {:ok, sample, sample}
    else
      {:error, {:outside_coverage, :earth_rotation}}
    end
  end

  defp bracketing_samples(samples, seconds_since_j2000) do
    cond do
      seconds_since_j2000 < List.first(samples).seconds_since_j2000 ->
        {:error, {:outside_coverage, :earth_rotation}}

      seconds_since_j2000 > List.last(samples).seconds_since_j2000 ->
        {:error, {:outside_coverage, :earth_rotation}}

      true ->
        samples
        |> Enum.chunk_every(2, 1, :discard)
        |> Enum.find(fn [before, after_sample] ->
          before.seconds_since_j2000 <= seconds_since_j2000 and
            seconds_since_j2000 <= after_sample.seconds_since_j2000
        end)
        |> case do
          [before, after_sample] -> {:ok, before, after_sample}
          _missing -> {:error, {:outside_coverage, :earth_rotation}}
        end
    end
  end

  defp validate_number(_field, value) when is_number(value), do: :ok
  defp validate_number(field, _value), do: {:error, {:invalid_option, field}}

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
