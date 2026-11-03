defmodule Mix.Tasks.OrbitalDynamics.Events.VerifyTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO

  test "finite-Sun CLI writes reviewable offline residual evidence" do
    dir = Path.join(System.tmp_dir!(), "event-verification-#{System.unique_integer([:positive])}")

    on_exit(fn ->
      File.rm_rf!(dir)
      Mix.Task.reenable("orbital_dynamics.events.verify")
    end)

    capture_io(fn ->
      Mix.Task.run("orbital_dynamics.events.verify", [
        "--group",
        "finite-sun",
        "--output-dir",
        dir
      ])
    end)

    report = dir |> Path.join("report.json") |> File.read!() |> :json.decode()
    assert report["status"] == "pass"
    assert Map.keys(report["groups"]) == ["finite_sun"]
    assert File.read!(Path.join(dir, "README.md")) =~ "numerical disk-area integration"
  end

  test "invalid groups and frozen reference output locations are rejected" do
    Mix.Task.reenable("orbital_dynamics.events.verify")

    assert_raise Mix.Error, fn ->
      Mix.Task.run("orbital_dynamics.events.verify", [
        "--group",
        "invalid",
        "--output-dir",
        "tmp/invalid"
      ])
    end

    Mix.Task.reenable("orbital_dynamics.events.verify")
    dir = OrbitalDynamics.Validation.EventSearch.FiniteSunCheck.bundle_path()
    before = File.read!(Path.join(dir, "README.md"))

    assert_raise Mix.Error, fn ->
      Mix.Task.run("orbital_dynamics.events.verify", [
        "--group",
        "finite-sun",
        "--output-dir",
        dir
      ])
    end

    assert File.read!(Path.join(dir, "README.md")) == before
    # Source and build paths can name the same bundle through symlinked parents.
    for destination <- [
          Path.expand("priv/validation/event_search_orekit"),
          Path.expand("priv/validation/external_truth/orekit_13_1_7_leo_j2_drag_access_eclipse")
        ] do
      Mix.Task.reenable("orbital_dynamics.events.verify")

      assert_raise Mix.Error, fn ->
        Mix.Task.run("orbital_dynamics.events.verify", [
          "--group",
          "finite-sun",
          "--output-dir",
          destination
        ])
      end
    end

    Mix.Task.reenable("orbital_dynamics.events.verify")
  end

  test "final output symlinks cannot overwrite frozen reference evidence" do
    dir = Path.join(System.tmp_dir!(), "event-output-links-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)

    on_exit(fn ->
      File.rm_rf!(dir)
      Mix.Task.reenable("orbital_dynamics.events.verify")
    end)

    frozen =
      Path.join(OrbitalDynamics.Validation.EventSearch.FiniteSunCheck.bundle_path(), "README.md")

    before = File.read!(frozen)

    for name <- ["report.json", "README.md"] do
      path = Path.join(dir, name)
      File.ln_s!(frozen, path)
      Mix.Task.reenable("orbital_dynamics.events.verify")

      assert_raise Mix.Error, fn ->
        Mix.Task.run("orbital_dynamics.events.verify", [
          "--group",
          "finite-sun",
          "--output-dir",
          dir
        ])
      end

      assert File.read!(frozen) == before
      File.rm!(path)
    end
  end
end
