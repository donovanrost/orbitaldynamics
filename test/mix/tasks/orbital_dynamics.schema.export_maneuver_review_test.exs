defmodule Mix.Tasks.OrbitalDynamics.Schema.ExportManeuverReviewTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  test "exports maneuver review contract" do
    output_path =
      Path.join(
        System.tmp_dir!(),
        "orbital_dynamics.maneuver_review.schema_bundle.#{System.unique_integer([:positive])}.json"
      )

    on_exit(fn ->
      File.rm(output_path)
      Mix.Task.reenable("orbital_dynamics.schema.export")
    end)

    capture_io(fn ->
      Mix.Task.run("orbital_dynamics.schema.export", ["--all", "--output", output_path])
    end)

    assert %{"schemas" => schemas} = output_path |> File.read!() |> :json.decode()

    assert get_in(schemas, [
             "maneuver_review_report.v1",
             "properties",
             "model",
             "const"
           ]) == "artifact_only_maneuver_review_report"

    assert get_in(schemas, [
             "maneuver_review_report.v1",
             "properties",
             "model_limits",
             "const"
           ]) == maneuver_review_report_model_limits()

    assert get_in(schemas, [
             "maneuver_review_report.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "delta_v_km_s",
             "items",
             "type"
           ]) == "number"
  end

  defp maneuver_review_report_model_limits do
    OrbitalDynamics.ManeuverReview.capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end
end
