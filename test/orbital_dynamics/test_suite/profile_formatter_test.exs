defmodule OrbitalDynamics.TestSuite.ProfileFormatterTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.TestSuite.ProfileFormatter

  test "writes sorted per-file runtime and test counts as JSON" do
    output_path =
      Path.join(
        System.tmp_dir!(),
        "orbital_dynamics_test_profile_#{System.unique_integer([:positive])}.json"
      )

    on_exit(fn -> File.rm(output_path) end)

    {:ok, formatter} =
      GenServer.start_link(ProfileFormatter,
        max_cases: 2,
        orbital_dynamics_test_profile_path: output_path,
        seed: 0
      )

    first_file = Path.expand("test/zeta_test.exs")
    second_file = Path.expand("test/alpha_test.exs")

    GenServer.cast(formatter, {:module_started, test_module(first_file)})
    GenServer.cast(formatter, {:test_finished, finished_test(first_file, 2_500, nil)})

    GenServer.cast(
      formatter,
      {:test_finished, finished_test(second_file, 1_500, {:failed, [{:error, :failure, []}]})}
    )

    GenServer.cast(formatter, {:suite_finished, %{async: 3_000, load: nil, run: 4_000}})
    :sys.get_state(formatter)

    artifact = output_path |> File.read!() |> :json.decode()

    assert artifact["schema_contract"] == "test_suite_profile.v1"
    assert artifact["profile_basis"] == "sum_of_exunit_test_runtime_us_by_source_file"
    assert artifact["runner"]["seed"] == 0
    assert artifact["runner"]["max_cases"] == 2
    assert artifact["suite"] == %{"async_us" => 3_000, "load_us" => :null, "run_us" => 4_000}
    assert artifact["totals"]["duration_us"] == 4_000
    assert artifact["totals"]["tests"] == 2
    refute Map.has_key?(artifact["totals"], "passed")
    refute Map.has_key?(artifact["totals"], "failures")

    assert Enum.map(artifact["files"], & &1["path"]) == [
             "test/alpha_test.exs",
             "test/zeta_test.exs"
           ]

    GenServer.stop(formatter)
  end

  test "records a module with no tests so file coverage remains explicit" do
    output_path =
      Path.join(
        System.tmp_dir!(),
        "orbital_dynamics_empty_test_profile_#{System.unique_integer([:positive])}.json"
      )

    on_exit(fn -> File.rm(output_path) end)

    {:ok, formatter} =
      GenServer.start_link(ProfileFormatter,
        max_cases: 1,
        orbital_dynamics_test_profile_path: output_path,
        seed: 1
      )

    GenServer.cast(formatter, {:module_started, test_module(Path.expand("test/empty_test.exs"))})
    GenServer.cast(formatter, {:suite_finished, %{async: nil, load: 10, run: 20}})
    :sys.get_state(formatter)

    assert [%{"path" => "test/empty_test.exs", "tests" => 0, "duration_us" => 0}] =
             output_path |> File.read!() |> :json.decode() |> Map.fetch!("files")

    GenServer.stop(formatter)
  end

  defp test_module(file) do
    %ExUnit.TestModule{name: __MODULE__, file: file, state: nil, tests: []}
  end

  defp finished_test(file, time, state) do
    %ExUnit.Test{
      name: :sample_test,
      module: __MODULE__,
      state: state,
      time: time,
      tags: %{file: file}
    }
  end
end
