defmodule OrbitalDynamics.OperatorReview.ContactIntentTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.{OperatorReview, Schema}

  test "builds standalone contact intent review package" do
    intent = %{
      "schema_contract" => "contact_intent.v1",
      "id" => "refresh_downlink",
      "activity_id" => "refresh_downlink",
      "activity_type" => "downlink",
      "scenario_id" => "leo_1",
      "ground_station_id" => "equator_prime",
      "direction" => "downlink",
      "starts_at_s" => 100.0,
      "ends_at_s" => 160.0,
      "source_window_id" => "window:leo_1:ground_station_access:equator_prime:1",
      "cadence_import" => %{
        "external_id" => "refresh_downlink",
        "activity_type" => "contact",
        "schema_contract" => "proposed_contact.v1"
      },
      "approval_status" => "operator_review_required",
      "approval_requirements" => [
        %{
          "schema_contract" => "approval_requirement.v1",
          "id" => "approval:refresh_downlink",
          "activity_id" => "refresh_downlink",
          "activity_type" => "downlink",
          "action" => "review_contact_intent",
          "requirement_type" => "contact_schedule_change",
          "reason" => "contact intent requires schedule authority"
        }
      ],
      "approval_rule_matches" => [
        %{
          "rule_id" => "downlink_schedule_authority_review"
        }
      ],
      "policy_decision" => %{
        "schema_contract" => "policy_decision.v1",
        "policy_bundle_id" => "command_contact_authority_v1",
        "classification" => "operator_review_required",
        "escalations" => [
          %{
            "rule_id" => "downlink_schedule_authority_review",
            "required_authority" => "contact_schedule_authority"
          }
        ]
      }
    }

    package = OperatorReview.from_contact_intent(intent)
    assert OrbitalDynamics.operator_review_package(intent) == package

    assert %{
             "source_artifact_type" => "contact_intent.v1",
             "source_artifact_id" => "refresh_downlink",
             "review_count" => 1,
             "contact_intent_review_count" => 1,
             "rows" => [
               %{
                 "review_type" => "contact_intent_review",
                 "source" => "contact_intent",
                 "activity_id" => "refresh_downlink",
                 "required_operator_action" => "review_contact_intent",
                 "cadence_import_status" => "present",
                 "cadence_import_type" => "contact",
                 "cadence_import_id" => "refresh_downlink",
                 "cadence_import_contract" => "proposed_contact.v1",
                 "requirement_type" => "contact_schedule_change",
                 "required_authority" => "contact_schedule_authority",
                 "policy_bundle_id" => "command_contact_authority_v1",
                 "rule_id" => "downlink_schedule_authority_review",
                 "source_contact_intent" => %{"schema_contract" => "contact_intent.v1"}
               }
             ]
           } = package

    assert %{"review_count" => 0, "rows" => []} =
             OperatorReview.from_contact_intent(%{
               intent
               | "approval_status" => "auto_approvable",
                 "approval_requirements" => [],
                 "approval_rule_matches" => [],
                 "policy_decision" => nil
             })

    assert {:ok, %{"schema_contract" => "operator_review_package.v1"}} =
             Schema.validate_artifact(package)

    invalid_source_evidence =
      update_in(package, ["rows"], fn [row] ->
        [
          put_in(row, ["source_contact_intent", "source_window_id"], "source window with spaces")
        ]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_source_evidence)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_contact_intent.source_window_id")
           )

    invalid_package =
      update_in(package, ["rows"], fn [row] ->
        [
          row
          |> Map.put("source_window_id", "stale_source_window")
          |> Map.put("starts_at_s", 101.0)
        ]
      end)

    assert {:error, report} = Schema.validate_artifact(invalid_package)

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].source_window_id" and
                 &1["message"] == "must match source_contact_intent.source_window_id")
           )

    assert Enum.any?(
             report["errors"],
             &(&1["path"] == "$.rows[0].starts_at_s" and
                 &1["message"] == "must match source_contact_intent.starts_at_s")
           )
  end

  test "contact intent source ids fall back through defaults" do
    assert %{"source_artifact_id" => "contact-intent:row"} =
             OperatorReview.from_contact_intent(%{
               id: :"contact-intent:row",
               approval_status: :auto_approvable
             })

    assert %{"source_artifact_id" => "contact-intent:activity"} =
             OperatorReview.from_contact_intent(%{
               activity_id: :"contact-intent:activity",
               approval_status: :auto_approvable
             })

    assert %{"source_artifact_id" => "contact_intent"} =
             OperatorReview.from_contact_intent(%{approval_status: :auto_approvable})
  end
end
