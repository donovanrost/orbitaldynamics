defmodule OrbitalDynamics.TimelineRevisionReplayTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.Schema
  alias OrbitalDynamics.Timeline

  test "identical replay returns the same named replacement revision" do
    {source, replacement} = timeline_pair()
    opts = [source: "timeline_revision_replay", timeline_revision?: true]

    assert %{
             timeline_revision_contract: "timeline_revision.v1",
             timeline_revision_identity_scheme: "sha256_canonical_json",
             timeline_revision_canonicalization: "timeline_revision_content.v1",
             timeline_revision_replay_limits: replay_limits
           } = Timeline.capabilities()

    assert :pure_artifact_replay in replay_limits
    assert :no_revision_store in replay_limits
    assert :no_locking in replay_limits
    assert :no_planner_default_change in replay_limits
    assert :no_schedule_mutation in replay_limits
    assert :no_distributed_concurrency_guarantee in replay_limits

    assert :replay_transition_application_report in Timeline.capabilities().transition_helpers

    assert :timeline_replay_transition_application_report in Timeline.capabilities().public_facades

    report = Timeline.transition_application_report(source, replacement, opts)

    assert %{
             "schema_contract" => "timeline_revision.v1",
             "identity_scheme" => "sha256_canonical_json",
             "canonicalization" => "timeline_revision_content.v1",
             "prior_revision_id" => "timeline_revision.sha256:" <> prior_digest,
             "transition_batch_id" => "timeline_transition_batch.sha256:" <> batch_digest,
             "replacement_revision_id" => "timeline_revision.sha256:" <> replacement_digest
           } = report["timeline_revision"]

    assert String.match?(prior_digest, ~r/^[0-9a-f]{64}$/)
    assert String.match?(batch_digest, ~r/^[0-9a-f]{64}$/)
    assert String.match?(replacement_digest, ~r/^[0-9a-f]{64}$/)

    assert Enum.all?(
             report["applications"],
             &(&1["timeline_revision"] == report["timeline_revision"])
           )

    assert {:ok, replayed} =
             Timeline.replay_transition_application_report(source, replacement, report, opts)

    assert replayed == report

    assert {:ok, ^report} =
             OrbitalDynamics.timeline_replay_transition_application_report(
               source,
               replacement,
               report,
               opts
             )
  end

  test "changed prior timeline is reported as a revision conflict before batch comparison" do
    {source, replacement} = timeline_pair()
    opts = [source: "timeline_revision_conflict", timeline_revision?: true]
    report = Timeline.transition_application_report(source, replacement, opts)

    changed_source =
      List.update_at(source, 0, fn activity ->
        %{activity | starts_at_s: activity.starts_at_s + 1.0}
      end)

    assert {:error,
            %{
              "error_type" => "revision_conflict",
              "conflict_scope" => "prior_revision",
              "expected_prior_revision_id" => expected,
              "actual_prior_revision_id" => actual
            }} =
             Timeline.replay_transition_application_report(
               changed_source,
               replacement,
               report,
               opts
             )

    assert expected == report["timeline_revision"]["prior_revision_id"]
    refute actual == expected
  end

  test "canonical timeline ordering gives reordered equivalent input the same identities" do
    {source, replacement} = timeline_pair()
    opts = [source: "timeline_revision_canonical_order", timeline_revision?: true]

    report = Timeline.transition_application_report(source, replacement, opts)

    reordered =
      Timeline.transition_application_report(
        Enum.reverse(source),
        Enum.reverse(replacement),
        opts
      )

    assert reordered["timeline_revision"] == report["timeline_revision"]

    assert {:ok, replayed} =
             Timeline.replay_transition_application_report(
               Enum.reverse(source),
               Enum.reverse(replacement),
               report,
               opts
             )

    assert replayed["timeline_revision"] == report["timeline_revision"]
  end

  test "changed named transition batch is rejected without replacing the prior revision" do
    {source, replacement} = timeline_pair()
    opts = [source: "timeline_batch_conflict", timeline_revision?: true]
    report = Timeline.transition_application_report(source, replacement, opts)

    changed_replacement =
      List.update_at(replacement, 1, fn activity ->
        %{activity | ends_at_s: activity.ends_at_s + 2.0}
      end)

    changed_report =
      Timeline.transition_application_report(source, changed_replacement, opts)

    assert changed_report["timeline_revision"]["prior_revision_id"] ==
             report["timeline_revision"]["prior_revision_id"]

    refute changed_report["timeline_revision"]["transition_batch_id"] ==
             report["timeline_revision"]["transition_batch_id"]

    assert {:error,
            %{
              "error_type" => "batch_conflict",
              "conflict_scope" => "transition_batch",
              "expected_transition_batch_id" => expected,
              "actual_transition_batch_id" => actual
            }} =
             Timeline.replay_transition_application_report(
               source,
               changed_replacement,
               report,
               opts
             )

    assert expected == report["timeline_revision"]["transition_batch_id"]
    refute actual == expected
  end

  test "replay rejects missing and malformed revision identity evidence" do
    {source, replacement} = timeline_pair()
    legacy = Timeline.transition_application_report(source, replacement)

    assert {:error,
            %{
              "error_type" => "invalid_replay_evidence",
              "reason" => "missing_timeline_revision",
              "path" => "$.timeline_revision"
            }} =
             Timeline.replay_transition_application_report(
               source,
               replacement,
               legacy
             )

    malformed =
      Map.put(legacy, "timeline_revision", %{
        "schema_contract" => "timeline_revision.v1",
        "identity_scheme" => "sha256_canonical_json",
        "canonicalization" => "timeline_revision_content.v1",
        "prior_revision_id" => "bad prior revision",
        "transition_batch_id" => "timeline_transition_batch.sha256:" <> String.duplicate("0", 64),
        "replacement_revision_id" => "timeline_revision.sha256:" <> String.duplicate("0", 64)
      })

    assert {:error,
            %{
              "error_type" => "invalid_replay_evidence",
              "reason" => "malformed_prior_revision_id",
              "path" => "$.timeline_revision.prior_revision_id"
            }} =
             Timeline.replay_transition_application_report(
               source,
               replacement,
               malformed
             )

    bound =
      Timeline.transition_application_report(source, replacement, timeline_revision?: true)

    missing_row_copy =
      update_in(bound, ["applications", Access.at(0)], &Map.delete(&1, "timeline_revision"))

    assert {:error,
            %{
              "error_type" => "invalid_replay_evidence",
              "reason" => "application_revision_evidence_mismatch",
              "path" => "$.applications[0].timeline_revision"
            }} =
             Timeline.replay_transition_application_report(
               source,
               replacement,
               missing_row_copy
             )
  end

  test "legacy arities and default report output remain revision-free" do
    {source, replacement} = timeline_pair()

    legacy = Timeline.transition_application_report(source, replacement)

    explicit_legacy =
      Timeline.transition_application_report(source, replacement, timeline_revision?: false)

    assert legacy == explicit_legacy
    refute Map.has_key?(legacy, "timeline_revision")
    assert Enum.all?(legacy["applications"], &(not Map.has_key?(&1, "timeline_revision")))
    assert Timeline.transition_application_report(legacy) == legacy
    assert OrbitalDynamics.timeline_transition_application_report(legacy) == legacy
  end

  test "revision evidence survives JSON round trip and executable schema validation" do
    {source, replacement} = timeline_pair()

    report =
      Timeline.transition_application_report(source, replacement,
        source: "timeline_revision_json_round_trip",
        timeline_revision?: true
      )

    round_tripped = report |> :json.encode() |> IO.iodata_to_binary() |> :json.decode()
    summary = Timeline.transition_application_summary(round_tripped)

    assert round_tripped == report
    assert summary["timeline_revision"] == report["timeline_revision"]

    assert {:ok, %{"schema_contract" => "timeline_revision.v1"}} =
             Schema.validate_artifact(report["timeline_revision"])

    assert {:ok, %{"schema_contract" => "timeline_transition_application_report.v1"}} =
             Schema.validate_artifact(round_tripped)

    assert {:ok, %{"schema_contract" => "timeline_transition_application_summary.v1"}} =
             Schema.validate_artifact(summary)

    assert {:ok, revision_schema} = Schema.json_schema("timeline_revision.v1")

    assert get_in(revision_schema, ["properties", "schema_contract", "const"]) ==
             "timeline_revision.v1"

    assert {:ok, report_schema} =
             Schema.json_schema("timeline_transition_application_report.v1")

    assert get_in(report_schema, [
             "properties",
             "timeline_revision",
             "properties",
             "transition_batch_id",
             "pattern"
           ]) =~ "[0-9a-f]{64}"

    malformed =
      put_in(
        report,
        ["applications", Access.at(0), "timeline_revision", "replacement_revision_id"],
        "timeline_revision.sha256:" <> String.duplicate("0", 64)
      )

    assert {:error, validation_report} = Schema.validate_artifact(malformed)

    assert Enum.any?(
             validation_report["errors"],
             &(&1["path"] == "$.applications[0].timeline_revision" and
                 &1["message"] == "must equal report timeline_revision evidence")
           )
  end

  test "revision and batch evidence is reproducible across repeated pure builds" do
    {source, replacement} = timeline_pair()
    opts = [source: "timeline_revision_reproducibility", timeline_revision?: true]
    expected = Timeline.transition_application_report(source, replacement, opts)

    reports =
      Enum.map(1..25, fn _iteration ->
        Timeline.transition_application_report(source, replacement, opts)
      end)

    assert Enum.all?(reports, &(&1 == expected))
  end

  defp timeline_pair do
    unchanged = %{
      id: :obs_keep,
      type: :observe,
      target_id: :target_a,
      starts_at_s: 30.0,
      ends_at_s: 40.0,
      metadata: %{timeline_id: :"timeline:obs_keep"}
    }

    changed_source = %{
      id: :cmd_change,
      type: :command,
      status: :planned,
      starts_at_s: 50.0,
      ends_at_s: 60.0,
      metadata: %{timeline_id: :"timeline:cmd_change"}
    }

    changed_replacement = %{
      id: :cmd_change,
      type: :command,
      status: :planned,
      starts_at_s: 52.0,
      ends_at_s: 62.0,
      metadata: %{timeline_id: :"timeline:cmd_change"}
    }

    added = %{
      id: :new_contact,
      type: :planned_contact,
      ground_station_id: :dss_14,
      starts_at_s: 70.0,
      ends_at_s: 80.0,
      metadata: %{timeline_id: :"timeline:new_contact"}
    }

    {[unchanged, changed_source], [unchanged, changed_replacement, added]}
  end
end
