defmodule OrbitalDynamics.Benchmark.ArtifactTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Benchmark.Artifact
  alias OrbitalDynamics.Benchmark.Result
  alias OrbitalDynamics.Propagators.TwoBody

  test "builds a JSON-serializable benchmark artifact" do
    result = result()
    generated_at = DateTime.from_unix!(1_700_000_000)
    started_at = DateTime.from_unix!(1_700_000_001)
    completed_at = DateTime.from_unix!(1_700_000_003)

    artifact =
      Artifact.build([result], [counts: [1, 10], max_step_s: 10.0],
        generated_at: generated_at,
        started_at: started_at,
        completed_at: completed_at
      )

    assert artifact.schema_version == 1
    assert artifact.generated_at == "2023-11-14T22:13:20Z"
    assert artifact.benchmark_options == %{"counts" => [1, 10], "max_step_s" => 10.0}
    assert artifact.run.elapsed_ms == 2_000
    assert artifact.environment.elixir_version == System.version()

    assert [
             %{
               id: "scalar_direct_1",
               mode: "scalar_direct",
               backend: "Elixir.OrbitalDynamics.Propagators.TwoBody",
               scenario_count: 1,
               sample_count: 3,
               failure_count: 0,
               options: %{"max_step_s" => 10.0}
             }
           ] = artifact.results
  end

  test "writes artifact JSON to disk" do
    path = Path.join(System.tmp_dir!(), "orbital_dynamics_benchmark_artifact_test.json")
    on_exit(fn -> File.rm(path) end)

    artifact = Artifact.build([result()], counts: [1])

    assert ^path = Artifact.write_json!(artifact, path)

    json = File.read!(path)

    assert json =~ ~s("schema_version":1)
    assert json =~ ~s("results":[)
  end

  defp result do
    Result.new!(%{
      id: "scalar_direct_1",
      mode: :scalar_direct,
      backend: TwoBody,
      scenario_count: 1,
      sample_count: 3,
      failure_count: 0,
      elapsed_us: 1_000,
      memory_delta_bytes: 512,
      options: [max_step_s: 10.0],
      metadata: %{validation_level: :educational}
    })
  end
end
