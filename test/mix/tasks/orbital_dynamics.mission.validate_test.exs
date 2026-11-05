defmodule Mix.Tasks.OrbitalDynamics.Mission.ValidateTest do
  use ExUnit.Case, async: false
  alias OrbitalDynamics.IndependentPlanFixture, as: F
  alias OrbitalDynamics.MissionAnalysis.PlanValidation.Reader
  alias Mix.Tasks.OrbitalDynamics.Mission.Validate

  setup_all do
    {:ok, F.build()}
  end

  test "CLI validates an offline chain and records semantic failures/partial scope without overwriting inputs",
       ctx do
    dir = Path.join(System.tmp_dir!(), "independent-cli-#{System.unique_integer([:positive])}")
    on_exit(fn -> File.rm_rf!(dir) end)
    inputs = Path.join(dir, "inputs")
    File.mkdir_p!(inputs)

    for {name, snapshot} <- ctx.snapshots,
        do: File.write!(Path.join(inputs, name), :json.encode(snapshot))

    File.write!(Path.join(inputs, "operations.json"), :json.encode(ctx.operations))
    before = Map.new(File.ls!(inputs), fn name -> {name, File.read!(Path.join(inputs, name))} end)
    out = Path.join(dir, "chain")
    args = ["--operations-dir", inputs, "--output-dir", out]
    Validate.run(args)
    {:ok, result} = Reader.read(Path.join(out, "validation.json"))
    assert result["status"] == "passed"
    assert length(result["snapshots"]) == 6
    assert_raise Mix.Error, ~r/already exist/, fn -> Validate.run(args) end
    assert Enum.all?(before, fn {name, bytes} -> File.read!(Path.join(inputs, name)) == bytes end)
    baseline = ctx.snapshots["baseline_snapshot.json"]

    bad =
      update_in(
        baseline,
        ["payload", "report", "activities", Access.at(0), "ends_at_s"],
        &(&1 + 1)
      )
      |> F.bind()

    path = Path.join(dir, "bad.json")
    File.write!(path, :json.encode(bad))
    failed = Path.join(dir, "failed")

    assert_raise Mix.Error, ~r/validation failed/, fn ->
      Validate.run(["--snapshot", path, "--output-dir", failed])
    end

    {:ok, evidence} = Reader.read(Path.join(failed, "validation.json"))
    assert Enum.any?(evidence["issues"], &(&1["code"] == "activity_duration"))
    refute Enum.any?(evidence["issues"], &(&1["code"] == "snapshot_content_identity"))

    partial =
      put_in(
        baseline,
        [
          "payload",
          "inputs",
          "study",
          "resources",
          "assets",
          "demo-3",
          Access.at(0),
          "configuration",
          "generation"
        ],
        %{"kind" => "solar_array"}
      )
      |> F.bind()

    File.write!(path, :json.encode(partial))
    partial_dir = Path.join(dir, "partial")

    assert_raise Mix.Error, ~r/validation partial/, fn ->
      Validate.run(["--snapshot", path, "--output-dir", partial_dir])
    end

    assert File.read!(Path.join(partial_dir, "README.md")) =~ "not a complete pass"
  end

  test "bounded JSON reader rejects duplicates, trailing data, malformed bytes and oversized files" do
    dir = Path.join(System.tmp_dir!(), "independent-reader-#{System.unique_integer([:positive])}")
    on_exit(fn -> File.rm_rf!(dir) end)
    File.mkdir_p!(dir)
    path = Path.join(dir, "input.json")

    for bytes <- ["{\"x\":1,\"x\":2}", "{} {}", "invalid", "[]"] do
      File.write!(path, bytes)
      assert {:error, _} = Reader.read(path)
    end

    {:ok, file} = File.open(path, [:write, :binary])
    :file.position(file, 64 * 1024 * 1024)
    IO.binwrite(file, "x")
    :ok = File.close(file)
    assert {:error, "artifact exceeds 64 MiB"} = Reader.read(path)

    for args <- [
          [],
          ["--snapshot", path],
          ["--snapshot", path, "--operations-dir", dir, "--output-dir", dir],
          ["--snapshot", path, "--snapshot", path, "--output-dir", dir]
        ] do
      assert_raise Mix.Error, ~r/required/, fn -> Validate.run(args) end
    end
  end
end
