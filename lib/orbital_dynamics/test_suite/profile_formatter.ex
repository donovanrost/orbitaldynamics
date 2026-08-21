defmodule OrbitalDynamics.TestSuite.ProfileFormatter do
  @moduledoc """
  ExUnit formatter that writes cumulative test runtime by source file as JSON.

  The formatter is enabled by setting `ORBITAL_DYNAMICS_TEST_PROFILE_PATH` before
  running `mix test`. Normal test runs retain ExUnit's default configuration.
  """

  use GenServer

  @schema_contract "test_suite_profile.v1"

  @impl GenServer
  def init(opts) do
    {:ok,
     %{
       files: %{},
       max_cases: Keyword.fetch!(opts, :max_cases),
       output_path: Keyword.fetch!(opts, :orbital_dynamics_test_profile_path),
       seed: Keyword.fetch!(opts, :seed)
     }}
  end

  @impl GenServer
  def handle_cast({:module_started, %ExUnit.TestModule{file: file}}, state) do
    {:noreply, ensure_file(state, file)}
  end

  def handle_cast({:test_finished, %ExUnit.Test{} = test}, state) do
    file = Map.fetch!(test.tags, :file)
    path = relative_test_path(file)
    file_profile = Map.get(state.files, path, empty_file_profile(path))

    file_profile =
      file_profile
      |> Map.update!(:duration_us, &(&1 + test.time))
      |> Map.update!(:tests, &(&1 + 1))

    {:noreply, put_in(state.files[path], file_profile)}
  end

  def handle_cast({:suite_finished, times_us}, state) do
    files = state.files |> Map.values() |> Enum.sort_by(& &1.path)

    totals =
      Enum.reduce(files, empty_totals(), fn file, totals ->
        Enum.reduce(Map.keys(totals), totals, fn key, acc ->
          Map.update!(acc, key, &(&1 + Map.fetch!(file, key)))
        end)
      end)

    artifact = %{
      schema_contract: @schema_contract,
      schema_version: 1,
      profile_basis: "sum_of_exunit_test_runtime_us_by_source_file",
      runner: %{
        max_cases: state.max_cases,
        partition: System.get_env("MIX_TEST_PARTITION") |> json_nullable(),
        schedulers_online: System.schedulers_online(),
        seed: state.seed
      },
      suite: %{
        async_us: json_nullable(times_us.async),
        load_us: json_nullable(times_us.load),
        run_us: times_us.run
      },
      totals: totals,
      files: files
    }

    write_artifact!(state.output_path, artifact)
    {:noreply, state}
  end

  def handle_cast(_event, state), do: {:noreply, state}

  defp ensure_file(state, file) do
    path = relative_test_path(file)
    update_in(state.files, &Map.put_new(&1, path, empty_file_profile(path)))
  end

  defp relative_test_path(file) do
    file
    |> Path.expand()
    |> Path.relative_to_cwd()
  end

  defp empty_file_profile(path) do
    %{
      path: path,
      duration_us: 0,
      tests: 0
    }
  end

  defp empty_totals do
    %{
      duration_us: 0,
      tests: 0
    }
  end

  defp json_nullable(nil), do: :null
  defp json_nullable(value), do: value

  defp write_artifact!(output_path, artifact) do
    output_path = Path.expand(output_path)
    File.mkdir_p!(Path.dirname(output_path))
    temporary_path = output_path <> ".tmp.#{System.unique_integer([:positive])}"

    json = artifact |> :json.encode() |> IO.iodata_to_binary()
    File.write!(temporary_path, json <> "\n")
    File.rename!(temporary_path, output_path)
  end
end
