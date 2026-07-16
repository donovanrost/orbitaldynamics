defmodule OrbitalDynamics.Schema.ManeuverContractsTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema

  test "validates standalone maneuver recommendation contracts" do
    maneuver = %{
      "schema_contract" => "maneuver_recommendation.v1",
      "id" => "trim_burn",
      "scenario_id" => "leo_1",
      "type" => "impulsive_burn",
      "epoch_s" => 120.0,
      "epoch_scale" => "tdb",
      "frame" => "eci_j2000",
      "delta_v_km_s" => [0.0, 0.01, 0.0],
      "delta_v_magnitude_km_s" => 0.01,
      "maneuver_model" => "impulsive_burns",
      "validation_level" => "artifact_contract",
      "model_limits" => OrbitalDynamics.ManeuverReview.recommendation_model_limits(),
      "assumptions" => %{"execution_boundary" => "recommendation_only_no_command_execution"}
    }

    assert {:ok, %{"schema_contract" => "maneuver_recommendation.v1"}} =
             Schema.validate_artifact(maneuver)

    invalid = Map.put(maneuver, "delta_v_km_s", [0.0, 0.01])

    assert {:error, report} = Schema.validate_artifact(invalid)
    assert Enum.any?(report["errors"], &(&1["path"] == "$.delta_v_km_s"))

    invalid_limits = Map.put(maneuver, "model_limits", ["stale_limit"])

    assert {:error, report} = Schema.validate_artifact(invalid_limits)
    assert Enum.any?(report["errors"], &(&1["path"] == "$.model_limits"))
  end

  test "exports maneuver delta-v vector schemas" do
    assert {:ok, recommendation_schema} = Schema.json_schema("maneuver_recommendation.v1")

    assert get_in(recommendation_schema, ["properties", "delta_v_km_s", "items", "type"]) ==
             "number"

    assert get_in(recommendation_schema, ["properties", "delta_v_km_s", "minItems"]) == 3
    assert get_in(recommendation_schema, ["properties", "delta_v_km_s", "maxItems"]) == 3

    assert get_in(recommendation_schema, [
             "properties",
             "delta_v_magnitude_km_s",
             "type"
           ]) == "number"

    assert get_in(recommendation_schema, ["properties", "epoch_scale", "type"]) == "string"
    assert get_in(recommendation_schema, ["properties", "validation_level", "type"]) == "string"

    assert get_in(recommendation_schema, ["properties", "model_limits", "items", "enum"]) ==
             OrbitalDynamics.ManeuverReview.recommendation_model_limits()

    assert {:ok, review_schema} = Schema.json_schema("maneuver_review_report.v1")

    assert get_in(review_schema, [
             "properties",
             "rows",
             "items",
             "properties",
             "delta_v_km_s",
             "maxItems"
           ]) == 3

    assert get_in(review_schema, [
             "properties",
             "rows",
             "items",
             "properties",
             "execution_uncertainty_status",
             "type"
           ]) == "string"

    assert get_in(review_schema, ["properties", "model_limits", "const"]) ==
             maneuver_review_report_model_limits()

    assert get_in(review_schema, [
             "properties",
             "invalid_maneuver_recommendation_ids",
             "items",
             "pattern"
           ]) == Schema.identity_policy()["stable_id_pattern"]

    Enum.each(
      [
        "maneuver_count",
        "review_required_count",
        "invalid_maneuver_recommendation_count",
        "execution_uncertainty_declared_count",
        "execution_uncertainty_missing_count"
      ],
      fn field ->
        assert get_in(review_schema, ["properties", field]) == %{
                 "type" => "integer",
                 "minimum" => 0
               }
      end
    )

    review_report = read_json!("study_results/maneuver_review_report_v1.json")

    invalid_review =
      put_in(review_report, ["rows", Access.at(0), "execution_uncertainty_status"], 42)

    assert {:error, validation_report} = Schema.validate_artifact(invalid_review)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.rows[0].execution_uncertainty_status")
           )

    invalid_count = Map.put(review_report, "execution_uncertainty_missing_count", 99)

    assert {:error, count_report} = Schema.validate_artifact(invalid_count)

    assert Enum.any?(
             count_report["errors"],
             &(&1["path"] == "$.execution_uncertainty_missing_count" and
                 &1["message"] == "must equal 1")
           )

    invalid_count_shape = Map.put(review_report, "maneuver_count", 1.0)

    assert {:error, count_shape_report} = Schema.validate_artifact(invalid_count_shape)

    assert Enum.any?(
             count_shape_report["errors"],
             &(&1["path"] == "$.maneuver_count")
           )

    stale_model_limits = Map.put(review_report, "model_limits", ["no_command_execution"])

    assert {:error, model_limits_report} = Schema.validate_artifact(stale_model_limits)

    assert Enum.any?(
             model_limits_report["errors"],
             &(&1["path"] == "$.model_limits" and
                 &1["message"] == "must match maneuver review report model limits")
           )

    invalid_negative_count = Map.put(review_report, "invalid_maneuver_recommendation_count", -1)

    assert {:error, negative_count_report} = Schema.validate_artifact(invalid_negative_count)

    assert Enum.any?(
             negative_count_report["errors"],
             &(&1["path"] == "$.invalid_maneuver_recommendation_count")
           )
  end

  defp read_json!(path) do
    path
    |> File.read!()
    |> :json.decode()
  end

  defp maneuver_review_report_model_limits do
    OrbitalDynamics.ManeuverReview.capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end
end
