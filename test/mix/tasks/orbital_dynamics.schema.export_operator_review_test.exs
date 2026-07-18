defmodule Mix.Tasks.OrbitalDynamics.Schema.ExportOperatorReviewTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  test "exports operator review model and priority evidence contract" do
    output_path =
      Path.join(
        System.tmp_dir!(),
        "orbital_dynamics.operator_review.schema_bundle.#{System.unique_integer([:positive])}.json"
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
             "operator_review_package.v1",
             "properties",
             "model",
             "const"
           ]) == "artifact_only_operator_review_package"

    assert get_in(schemas, [
             "operator_review_package.v1",
             "properties",
             "model_limits",
             "const"
           ]) == operator_review_package_model_limits()

    assert get_in(schemas, [
             "operator_review_package.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "priority_fields_without_numeric_evidence",
             "items",
             "type"
           ]) == "string"

    assert get_in(schemas, [
             "operator_review_package.v1",
             "properties",
             "rows",
             "items",
             "properties",
             "priority_fields_without_numeric_evidence_count",
             "minimum"
           ]) == 0
  end

  defp operator_review_package_model_limits do
    OrbitalDynamics.OperatorReview.capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end
end
