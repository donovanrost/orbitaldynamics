defmodule Mix.Tasks.OrbitalDynamics.Mission.ExplainTest do
  use ExUnit.Case, async: false
  alias OrbitalDynamics.MissionAnalysis.RepeatedServiceQualityCases, as: Cases
  alias OrbitalDynamics.MissionAnalysis.PlanRevision.Snapshot

  test "offline explanation reads a content-checked snapshot, writes evidence and protects inputs/outputs" do
    dir = Path.join(System.tmp_dir!(), "explain-#{System.unique_integer([:positive])}")
    on_exit(fn -> File.rm_rf!(dir) end)
    File.mkdir_p!(dir)
    c = Enum.find(Cases.cases(), &(&1["id"] == "maneuver_gap"))
    report = Cases.plan!(c, nil)
    snapshot = Snapshot.new!(%{"case" => c}, report)
    path = Path.join(dir, "saved.json")
    bytes = :json.encode(snapshot) |> IO.iodata_to_binary()
    File.write!(path, bytes)
    output = Path.join(dir, "explanation")
    args = ["--snapshot", path, "--request", "early", "--output-dir", output]
    Mix.Tasks.OrbitalDynamics.Mission.Explain.run(args)
    e = Path.join(output, "explanation.json") |> File.read!() |> :json.decode()
    assert e["request_id"] == "early"
    assert e["snapshot_id"] == snapshot["snapshot_id"]
    assert e["summary"]["attempt_reasons"] == %{"outgoing_transition" => 1}
    assert File.read!(Path.join(output, "README.md")) =~ "outgoing_transition"
    assert File.read!(path) == bytes

    assert_raise Mix.Error, ~r/already exist/, fn ->
      Mix.Tasks.OrbitalDynamics.Mission.Explain.run(args)
    end

    assert_raise ArgumentError, ~r/unknown request/, fn ->
      Mix.Tasks.OrbitalDynamics.Mission.Explain.run([
        "--snapshot",
        path,
        "--request",
        "unknown",
        "--output-dir",
        Path.join(dir, "unknown")
      ])
    end

    refute File.exists?(Path.join(dir, "unknown"))

    File.write!(
      path,
      :json.encode(
        put_in(snapshot, ["payload", "report", "requests", Access.at(0), "value"], 999)
      )
    )

    assert_raise ArgumentError, ~r/identity mismatch/, fn ->
      Mix.Tasks.OrbitalDynamics.Mission.Explain.run(args)
    end
  end

  test "strict arguments fail before opening a snapshot" do
    for args <- [
          [],
          ["--snapshot", "missing"],
          ["--snapshot", "missing", "--request", "x", "--output-dir", "x", "--request", "y"]
        ] do
      assert_raise Mix.Error, ~r/required/, fn ->
        Mix.Tasks.OrbitalDynamics.Mission.Explain.run(args)
      end
    end
  end
end
