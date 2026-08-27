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

  @max_container_depth 12
  @max_container_entries 4_096
  @max_list_length 1_024
  @max_map_size 128
  @max_opts_length 64
  @safe_number_limit 1.0e15
  @allowed_options [
    :samples,
    :seconds_since_j2000,
    :source,
    :body,
    :frame,
    :time_scale,
    :interpolation,
    :file_content_verification,
    :source_table_id,
    :provenance,
    :provider_id
  ]
  @epoch_aliases [
    {:seconds_since_j2000, "seconds_since_j2000"},
    {:epoch_s, "epoch_s"}
  ]
  @angle_aliases [
    {:earth_rotation_angle_rad, "earth_rotation_angle_rad"},
    {:rotation_angle_rad, "rotation_angle_rad"}
  ]
  @rate_aliases [
    {:earth_rotation_rate_rad_s, "earth_rotation_rate_rad_s"},
    {:rotation_rate_rad_s, "rotation_rate_rad_s"}
  ]
  @sample_option_keys Enum.flat_map(
                        @epoch_aliases ++ @angle_aliases ++ @rate_aliases,
                        fn {atom_key, string_key} -> [atom_key, string_key] end
                      )

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
      "supported_frames" => ["earth_fixed_era_from_eci_j2000_approximation"],
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
  def configured_capability(opts \\ []) do
    with :ok <- validate_opts(opts),
         {:ok, samples} <- normalized_samples(Keyword.get(opts, :samples, [])),
         {:ok, source} <- configured_source(opts) do
      configured_parameters = %{
        "sample_count" => length(samples),
        "coverage_source" => "declared_samples"
      }

      {:ok,
       capabilities()
       |> put_in(["coverage", "starts_at_s"], List.first(samples).seconds_since_j2000)
       |> put_in(["coverage", "ends_at_s"], List.last(samples).seconds_since_j2000)
       |> Map.put("source", source)
       |> Map.update!("parameters", &Map.merge(&1, configured_parameters))}
    end
  end

  def fetch(kind, opts \\ [])

  @impl OrbitalDynamics.Environment.Provider
  def fetch(:earth_rotation, opts) do
    with :ok <- validate_opts(opts),
         {:ok, seconds_since_j2000} <- required_number(opts, :seconds_since_j2000),
         :ok <- validate_request_context(opts),
         :ok <- validate_file_context(opts),
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

  def fetch_from_file(:earth_rotation, path, content_identity, opts) do
    with :ok <- validate_opts(opts),
         {:ok, %{bytes: bytes, evidence: evidence}} <-
           InputIntegrity.verify_file(path, content_identity,
             consumer: "environment.tabular_earth_orientation_provider"
           ),
         {:ok, table} <- decode_table(bytes),
         :ok <- preflight_container(table, :provider_table),
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
    _error in [ArgumentError, ErlangError] -> {:error, {:invalid_provider_table, :invalid_json}}
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

  defp table_source(_table, opts) do
    case Keyword.get(opts, :source, "verified_earth_orientation_table") do
      source when is_binary(source) and source != "" -> {:ok, source}
      _source -> {:error, {:invalid_provider_table, :invalid_source}}
    end
  end

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
    with {:ok, sample_items} <- bounded_list_items(samples, :samples, @max_list_length),
         {:ok, normalized} <- normalize_samples(sample_items) do
      samples = Enum.sort_by(normalized, & &1.seconds_since_j2000)

      cond do
        samples == [] ->
          {:error, {:missing_option, :samples}}

        duplicate_sample_times?(samples) ->
          {:error, {:invalid_option, :samples}}

        true ->
          {:ok, samples}
      end
    else
      {:error, {:container_limit_exceeded, _field}} -> {:error, {:invalid_option, :samples}}
      {:error, {:invalid_container, _field}} -> {:error, {:invalid_option, :samples}}
      {:error, _reason} -> {:error, {:invalid_option, :samples}}
    end
  end

  defp normalized_samples(_samples), do: {:error, {:invalid_option, :samples}}

  defp normalize_sample(%{} = sample) do
    with :ok <- preflight_container(sample, :sample),
         :ok <- reject_alias_group_collisions(sample, @epoch_aliases, :seconds_since_j2000),
         :ok <- reject_alias_group_collisions(sample, @angle_aliases, :earth_rotation_angle_rad),
         :ok <- reject_alias_group_collisions(sample, @rate_aliases, :earth_rotation_rate_rad_s),
         {:ok, seconds_since_j2000} <- sample_number(sample, @epoch_aliases),
         {:ok, angle_rad} <- sample_number(sample, @angle_aliases),
         {:ok, rate_rad_s} <- optional_sample_number(sample, @rate_aliases) do
      {:ok,
       %{
         seconds_since_j2000: seconds_since_j2000 * 1.0,
         angle_rad: angle_rad * 1.0,
         rate_rad_s: rate_rad_s
       }}
    end
  end

  defp normalize_sample(_sample), do: {:error, :invalid_sample}

  defp normalize_samples(items) do
    Enum.reduce_while(items, {:ok, []}, fn sample, {:ok, acc} ->
      case normalize_sample(sample) do
        {:ok, normalized} -> {:cont, {:ok, [normalized | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, normalized} -> {:ok, Enum.reverse(normalized)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp sample_number(sample, aliases) do
    case sample_value(sample, aliases) do
      {:ok, value} ->
        if finite_number?(value) do
          {:ok, value}
        else
          {:error, :invalid_sample_number}
        end

      :missing ->
        {:error, :missing_sample_number}
    end
  end

  defp optional_sample_number(sample, aliases) do
    case sample_value(sample, aliases) do
      {:ok, value} ->
        if finite_number?(value) do
          {:ok, value * 1.0}
        else
          {:error, :invalid_sample_number}
        end

      :missing ->
        {:ok, nil}
    end
  end

  defp sample_value(sample, aliases) do
    Enum.find_value(aliases, :missing, fn {atom_key, string_key} ->
      cond do
        Map.has_key?(sample, atom_key) -> {:ok, Map.get(sample, atom_key)}
        Map.has_key?(sample, string_key) -> {:ok, Map.get(sample, string_key)}
        true -> nil
      end
    end)
  end

  defp reject_alias_group_collisions(sample, aliases, field) do
    present =
      Enum.filter(aliases, fn {atom_key, string_key} ->
        Map.has_key?(sample, atom_key) or Map.has_key?(sample, string_key)
      end)

    cond do
      Enum.any?(aliases, fn {atom_key, string_key} ->
        Map.has_key?(sample, atom_key) and Map.has_key?(sample, string_key)
      end) ->
        {:error, {:atom_string_alias_collision, field}}

      length(present) > 1 ->
        {:error, {:sample_alias_collision, field}}

      true ->
        :ok
    end
  end

  defp duplicate_sample_times?(samples) do
    samples
    |> Enum.map(& &1.seconds_since_j2000)
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.any?(fn [before_s, after_s] -> after_s == before_s end)
  end

  defp validate_request_context(opts) do
    checks = [
      {:body, normalize_label(Keyword.get(opts, :body, :earth)), "earth", ["earth"]},
      {:frame, normalize_label(Keyword.get(opts, :frame)), nil,
       [nil, "earth_fixed_era_from_eci_j2000_approximation"]},
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

  defp required_number(opts, key) do
    case Keyword.fetch(opts, key) do
      {:ok, value} when is_integer(value) or is_float(value) ->
        if finite_number?(value) do
          {:ok, value * 1.0}
        else
          {:error, {:invalid_option, key}}
        end

      {:ok, _value} ->
        {:error, {:invalid_option, key}}

      :error ->
        {:error, {:missing_option, key}}
    end
  end

  defp validate_opts(opts) do
    with {:ok, items} <- bounded_list_items(opts, :opts, @max_opts_length),
         true <- Enum.all?(items, &keyword_entry?/1),
         true <- unique_keyword_keys?(items),
         :ok <- preflight_option_values(items),
         :ok <- reject_unsupported_options(items) do
      :ok
    else
      false -> {:error, {:invalid_option, :opts}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp keyword_entry?({key, _value}) when is_atom(key), do: true
  defp keyword_entry?(_entry), do: false

  defp unique_keyword_keys?(items) do
    keys = Enum.map(items, fn {key, _value} -> key end)
    length(keys) == length(Enum.uniq(keys))
  end

  defp preflight_option_values(items) do
    Enum.reduce_while(items, :ok, fn {key, value}, :ok ->
      case preflight_option_value(key, value) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp preflight_option_value(:seconds_since_j2000, value),
    do: preflight_numeric_option(:seconds_since_j2000, value)

  defp preflight_option_value(:samples, values), do: preflight_samples_option(values)

  defp preflight_option_value(_key, value), do: preflight_container(value, :opts)

  defp preflight_numeric_option(key, value) when is_integer(value) or is_float(value) do
    if finite_number?(value), do: :ok, else: {:error, {:invalid_option, key}}
  end

  defp preflight_numeric_option(_key, value), do: preflight_container(value, :opts)

  defp reject_unsupported_options(items) do
    Enum.reduce_while(items, :ok, fn {key, _value}, :ok ->
      if key in @allowed_options do
        {:cont, :ok}
      else
        {:halt, {:error, {:unsupported_option, key}}}
      end
    end)
  end

  defp preflight_samples_option(values) when is_list(values) do
    case bounded_list_items(values, :opts, @max_list_length) do
      {:ok, items} ->
        Enum.reduce_while(items, :ok, fn sample, :ok ->
          case preflight_sample_option(sample) do
            :ok -> {:cont, :ok}
            {:error, reason} -> {:halt, {:error, reason}}
          end
        end)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp preflight_samples_option(_values), do: {:error, {:invalid_container, :opts}}

  defp preflight_sample_option(%{__struct__: _struct}),
    do: {:error, {:invalid_container, :opts}}

  defp preflight_sample_option(%{} = sample) do
    cond do
      map_size(sample) > @max_map_size ->
        {:error, {:container_limit_exceeded, :opts}}

      invalid_map_key?(sample) ->
        {:error, {:invalid_container, :opts}}

      true ->
        with :ok <- reject_generic_alias_collisions(sample),
             :ok <- reject_unsupported_sample_option_keys(sample) do
          preflight_sample_option_values(Map.values(sample))
        end
    end
  end

  defp preflight_sample_option(_sample), do: {:error, {:invalid_container, :opts}}

  defp reject_unsupported_sample_option_keys(sample) do
    Enum.reduce_while(Map.keys(sample), :ok, fn key, :ok ->
      if key in @sample_option_keys do
        {:cont, :ok}
      else
        {:halt, {:error, {:invalid_option, :samples}}}
      end
    end)
  end

  defp preflight_sample_option_values(values) do
    Enum.reduce_while(values, :ok, fn value, :ok ->
      case preflight_sample_scalar(value) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp preflight_sample_scalar(value)
       when is_nil(value) or is_boolean(value) or is_atom(value) or is_binary(value),
       do: :ok

  defp preflight_sample_scalar(value) when is_integer(value) or is_float(value) do
    if finite_number?(value), do: :ok, else: {:error, {:invalid_option, :samples}}
  end

  defp preflight_sample_scalar(_value), do: {:error, {:invalid_container, :opts}}

  defp configured_source(opts) do
    case Keyword.get(opts, :source, "declared_earth_orientation_table") do
      source when is_binary(source) and source != "" -> {:ok, source}
      _source -> {:error, {:invalid_option, :source}}
    end
  end

  defp validate_file_context(opts) do
    case Keyword.get(opts, :file_content_verification) do
      %{} ->
        cond do
          not nonempty_string?(Keyword.get(opts, :source_table_id)) ->
            {:error, {:invalid_option, :source_table_id}}

          not is_map(Keyword.get(opts, :provenance)) ->
            {:error, {:invalid_option, :provenance}}

          true ->
            :ok
        end

      nil ->
        :ok

      _verification ->
        {:error, {:invalid_option, :file_content_verification}}
    end
  end

  defp preflight_container(term, field) do
    preflight_container([{term, 0}], 0, field)
  end

  defp preflight_container([], _visited, _field), do: :ok

  defp preflight_container(_stack, visited, field) when visited > @max_container_entries,
    do: {:error, {:container_limit_exceeded, field}}

  defp preflight_container([{_term, depth} | _rest], _visited, field)
       when depth > @max_container_depth do
    {:error, {:container_depth_exceeded, field}}
  end

  defp preflight_container([{%{__struct__: _struct}, _depth} | _rest], _visited, field),
    do: {:error, {:invalid_container, field}}

  defp preflight_container([{tuple, _depth} | _rest], _visited, field) when is_tuple(tuple),
    do: {:error, {:invalid_container, field}}

  defp preflight_container([{%{} = map, depth} | rest], visited, field) do
    cond do
      map_size(map) > @max_map_size ->
        {:error, {:container_limit_exceeded, field}}

      invalid_map_key?(map) ->
        {:error, {:invalid_container, field}}

      true ->
        with :ok <- reject_generic_alias_collisions(map) do
          children = Enum.map(Map.values(map), &{&1, depth + 1})
          preflight_container(children ++ rest, visited + map_size(map), field)
        end
    end
  end

  defp preflight_container([{list, depth} | rest], visited, field) when is_list(list) do
    case bounded_list_items(list, field, @max_list_length) do
      {:ok, items} ->
        children = Enum.map(items, &{&1, depth + 1})
        preflight_container(children ++ rest, visited + length(items), field)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp preflight_container([{term, _depth} | rest], visited, field)
       when is_nil(term) or is_boolean(term) or is_atom(term) or is_binary(term),
       do: preflight_container(rest, visited + 1, field)

  defp preflight_container([{term, _depth} | rest], visited, field)
       when is_integer(term) or is_float(term) do
    if finite_number?(term) do
      preflight_container(rest, visited + 1, field)
    else
      {:error, {:invalid_container, field}}
    end
  end

  defp preflight_container([_term | _rest], _visited, field),
    do: {:error, {:invalid_container, field}}

  defp invalid_map_key?(map) do
    Enum.any?(Map.keys(map), fn key -> not (is_atom(key) or is_binary(key)) end)
  end

  defp reject_generic_alias_collisions(%{} = map) do
    atom_key_strings =
      map
      |> Map.keys()
      |> Enum.filter(&is_atom/1)
      |> Enum.map(&Atom.to_string/1)
      |> MapSet.new()

    case Enum.find(Map.keys(map), fn key ->
           is_binary(key) and MapSet.member?(atom_key_strings, key)
         end) do
      nil -> :ok
      key -> {:error, {:atom_string_alias_collision, key}}
    end
  end

  defp bounded_list_items(list, field, limit) when is_list(list) do
    bounded_list_items(list, [], 0, field, limit)
  end

  defp bounded_list_items(_not_list, field, _limit), do: {:error, {:invalid_container, field}}

  defp bounded_list_items(_list, _acc, count, field, limit) when count > limit,
    do: {:error, {:container_limit_exceeded, field}}

  defp bounded_list_items([], acc, _count, _field, _limit), do: {:ok, Enum.reverse(acc)}

  defp bounded_list_items([head | tail], acc, count, field, limit) do
    bounded_list_items(tail, [head | acc], count + 1, field, limit)
  end

  defp bounded_list_items(_improper_tail, _acc, _count, field, _limit),
    do: {:error, {:invalid_container, field}}

  defp finite_number?(value) when is_integer(value), do: abs(value) <= @safe_number_limit

  defp finite_number?(value) when is_float(value) do
    value == value and value - value == 0.0 and abs(value) <= @safe_number_limit
  end

  defp finite_number?(_value), do: false

  defp nonempty_string?(value), do: is_binary(value) and String.trim(value) != ""

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
