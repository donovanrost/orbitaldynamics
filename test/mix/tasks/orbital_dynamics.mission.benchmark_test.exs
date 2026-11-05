defmodule Mix.Tasks.OrbitalDynamics.Mission.BenchmarkTest do
  use ExUnit.Case, async: false

  test "invalid controls fail before creating artifacts or doing physical planning" do
    for args <- [
          [],
          ["--output-dir", "tmp/unused", "--sizes", "0"],
          ["--output-dir", "tmp/unused", "--sizes", "1,1"],
          ["--output-dir", "tmp/unused", "--sizes", "1.5"],
          ["--output-dir", "tmp/unused", "--repeats", "6"],
          ["--output-dir", "tmp/unused", "--repeats", "1", "--repeats", "2"],
          ["--output-dir", "tmp/unused", "--unknown"],
          ["--output-dir", "tmp/unused", "--strategy", "arbitrary"],
          ["--output-dir", "tmp/unused", "--strategy", "bounded_reassignment"],
          [
            "--output-dir",
            "tmp/unused",
            "--strategy",
            "bounded_reassignment",
            "--max-trials",
            "65"
          ],
          [
            "--output-dir",
            "tmp/unused",
            "--strategy",
            "bounded_reassignment",
            "--max-trials",
            "2",
            "--max-trials",
            "3"
          ]
        ] do
      assert_raise Mix.Error, fn -> Mix.Tasks.OrbitalDynamics.Mission.Benchmark.run(args) end
    end
  end
end
