defmodule Mix.Tasks.OrbitalDynamics.Events.DemoTest do
  use ExUnit.Case, async: false
  @moduletag :integration
  import ExUnit.CaptureIO

  test "event catalog demo emits explicit source, timing, contact and budget evidence" do
    directory = Path.join(System.tmp_dir!(), "events-demo-#{System.unique_integer([:positive])}")

    on_exit(fn ->
      File.rm_rf!(directory)
      Mix.Task.reenable("orbital_dynamics.events.demo")
    end)

    output =
      capture_io(fn ->
        Mix.Task.run("orbital_dynamics.events.demo", ["--output-dir", directory])
      end)

    assert output =~ "21 event functions"
    r = directory |> Path.join("report.json") |> File.read!() |> :json.decode()
    assert r["status"] == "complete_under_search_policy"
    assert length(r["results"]) == 21

    assert r["source_query_count"] + r["function_evaluation_count"] <=
             r["controls"]["max_evaluations"]

    eclipse = Enum.find(r["results"], &(&1["function"]["id"] == "eclipse.penumbra"))
    assert length(eclipse["events"]) == 4
    assert length(eclipse["condition_windows"]) == 2
    assert Enum.all?(eclipse["events"], &(&1["bracket_width_s"] <= 1.0e-6))
    assert File.read!(Path.join(directory, "README.md")) =~ "Synthetic geometry"
    catalog = directory |> Path.join("catalog.json") |> File.read!() |> :json.decode()
    assert catalog["format"] == "orbital_event_catalog.v1"
    assert length(catalog["families"]) == 22
  end
end
