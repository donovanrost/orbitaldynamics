defmodule OrbitalDynamics.Benchmark.Artifact do
  @moduledoc """
  JSON-serializable benchmark run artifact.

  Artifacts make benchmark output comparable across future backend experiments.
  They intentionally include runtime environment metadata because scheduler
  count, OTP version, and node placement materially affect BEAM benchmarks.
  """

  @schema_version 1

  @doc """
  Builds a JSON-serializable artifact map from benchmark results.
  """
  def build(results, benchmark_opts, opts \\ [])
      when is_list(results) and is_list(benchmark_opts) do
    generated_at = Keyword.get_lazy(opts, :generated_at, &DateTime.utc_now/0)
    started_at = Keyword.get(opts, :started_at)
    completed_at = Keyword.get(opts, :completed_at)

    %{
      schema_version: @schema_version,
      generated_at: DateTime.to_iso8601(generated_at),
      environment: environment(),
      benchmark_options: encode_value(benchmark_opts),
      run: %{
        started_at: encode_datetime(started_at),
        completed_at: encode_datetime(completed_at),
        elapsed_ms: elapsed_ms(started_at, completed_at)
      },
      results: Enum.map(results, &result_to_map/1)
    }
  end

  @doc """
  Writes an artifact as JSON.
  """
  def write_json!(artifact, path) when is_map(artifact) and is_binary(path) do
    path
    |> Path.dirname()
    |> File.mkdir_p!()

    json =
      artifact
      |> :json.encode()
      |> IO.iodata_to_binary()

    File.write!(path, json <> "\n")
    path
  end

  defp environment do
    %{
      elixir_version: System.version(),
      otp_release: List.to_string(:erlang.system_info(:otp_release)),
      node: Atom.to_string(node()),
      schedulers_online: System.schedulers_online(),
      system_architecture: List.to_string(:erlang.system_info(:system_architecture))
    }
  end

  defp result_to_map(result) do
    %{
      id: encode_value(result.id),
      mode: encode_value(result.mode),
      backend: encode_value(result.backend),
      node: encode_value(result.node),
      scenario_count: result.scenario_count,
      sample_count: result.sample_count,
      failure_count: result.failure_count,
      elapsed_us: result.elapsed_us,
      elapsed_ms: result.elapsed_us / 1_000.0,
      memory_delta_bytes: result.memory_delta_bytes,
      options: encode_value(result.options),
      metadata: encode_value(result.metadata)
    }
  end

  defp elapsed_ms(%DateTime{} = started_at, %DateTime{} = completed_at) do
    DateTime.diff(completed_at, started_at, :millisecond)
  end

  defp elapsed_ms(_started_at, _completed_at), do: nil

  defp encode_datetime(%DateTime{} = datetime), do: DateTime.to_iso8601(datetime)
  defp encode_datetime(nil), do: nil

  defp encode_value(values) when is_list(values) do
    if Keyword.keyword?(values) do
      Map.new(values, fn {key, value} -> {encode_key(key), encode_value(value)} end)
    else
      Enum.map(values, &encode_value/1)
    end
  end

  defp encode_value(value) when is_map(value) do
    Map.new(value, fn {key, value} -> {encode_key(key), encode_value(value)} end)
  end

  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(value), do: value

  defp encode_key(key) when is_atom(key), do: Atom.to_string(key)
  defp encode_key(key) when is_binary(key), do: key
  defp encode_key(key), do: inspect(key)
end
