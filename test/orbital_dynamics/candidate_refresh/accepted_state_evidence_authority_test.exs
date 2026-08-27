Code.require_file(
  "../../support/candidate_refresh/source_report_input_provenance_fixture.ex",
  __DIR__
)

defmodule OrbitalDynamics.CandidateRefresh.AcceptedStateEvidenceAuthorityTest do
  use ExUnit.Case, async: true

  alias OrbitalDynamics.CampaignPlanner.{
    PlanBranch,
    RepairSourceReports,
    StrategyRecommendationBuilder
  }

  alias OrbitalDynamics.CandidateRefresh
  alias OrbitalDynamics.CandidateRefresh.AcceptedStateEvidenceAuthority
  alias OrbitalDynamics.CandidateRefresh.BuildContext
  alias OrbitalDynamics.Schema

  import OrbitalDynamics.CandidateRefresh.SourceReportInputProvenanceFixture

  defmodule HostileEvidenceStruct do
    defstruct [:value]
  end

  @generated_at ~U[2026-05-14 00:00:00Z]
  @review_warning "accepted-state OrbitData evidence requires operator review but has no CandidateRefresh decision authority"

  test "classifies missing covariance as clean metadata-only no-authority" do
    artifact = build_artifact()
    summary = get_in(artifact, ["accepted_planning_state", "evidence_authority"])

    assert summary["schema_contract"] == "accepted_state_evidence_authority.v1"
    assert summary["status"] == "clean"
    assert summary["review_required"] == false
    assert summary["review_reasons"] == []
    assert summary["decision_authority"] == "no_decision_authority"
    assert summary["covariance_authority"] == "metadata_only_not_consumed"
    assert summary["content_identity_authority"] == "byte_identity_not_authenticated"
    assert summary["states_with_covariance_evidence_count"] == 0
    assert summary["states_missing_covariance_evidence_count"] == 1

    assert get_in(artifact, ["provenance", "accepted_planning_state", "evidence_authority"]) ==
             summary

    refute @review_warning in artifact["warnings"]

    assert {:ok, %{"schema_contract" => "candidate_refresh.v1", "status" => "pass"}} =
             Schema.validate_artifact(artifact)
  end

  test "carries valid covariance and source identity evidence without changing refresh decisions" do
    base_artifact = build_artifact()

    artifact =
      valid_covariance_quality()
      |> accepted_state_with_quality(
        source: %{
          "content_identity" => %{
            "sha256" => "d8f8a0d01099c2034a5a8d66f90e6ef92a8a7f7f861d83f4d8198e9b46a74a01",
            "authority" => "not_authenticated"
          }
        }
      )
      |> refresh_with_accepted_state()
      |> build_artifact()

    summary = get_in(artifact, ["accepted_planning_state", "evidence_authority"])

    assert summary["status"] == "clean"
    assert summary["states_with_covariance_evidence_count"] == 1
    assert summary["states_missing_covariance_evidence_count"] == 0
    assert summary["decision_authority"] == "no_decision_authority"
    assert summary["content_identity_authority"] == "byte_identity_not_authenticated"

    assert get_in(artifact, ["provenance", "accepted_planning_state", "evidence_authority"]) ==
             summary

    refute @review_warning in artifact["warnings"]
    assert decision_surface(artifact) == decision_surface(base_artifact)
  end

  test "surfaces unsafe accepted-state evidence without changing refresh decisions" do
    base_artifact = build_artifact()

    cases = [
      {"claimed source authentication", forged_authority_state(),
       "claimed_content_identity_authority"},
      {"stale covariance epoch",
       covariance_quality_state(["covariance_epoch_binding"], "matched", false),
       "covariance_epoch_mismatch"},
      {"mismatched covariance frame",
       covariance_quality_state(["covariance_frame_binding"], "matched", false),
       "covariance_frame_mismatch"},
      {"unsupported covariance status",
       covariance_quality_state(["covariance_status"], "flight_truth"),
       "unsupported_covariance_status"},
      {"unsupported numerical status",
       covariance_quality_state(["covariance_numerical_check"], "status", "failed"),
       "unsupported_covariance_numerical_status"},
      {"partial evidence",
       accepted_state_with_quality(%{"covariance_status" => "metadata_only_no_propagation"}),
       "partial_covariance_evidence"},
      {"invalid covariance shape", covariance_quality_state(["covariance_matrix_6x6"], [[1.0]]),
       "invalid_covariance_matrix_shape"},
      {"claimed propagation",
       covariance_quality_state(["covariance_propagation_status"], "propagated"),
       "covariance_propagation_or_filtering_claimed"}
    ]

    for {_label, state, reason} <- cases do
      artifact =
        state
        |> refresh_with_accepted_state()
        |> build_artifact()

      summary = get_in(artifact, ["accepted_planning_state", "evidence_authority"])

      assert summary["status"] == "review_required"
      assert summary["review_required"] == true
      assert reason in summary["review_reasons"]
      assert @review_warning in artifact["warnings"]
      assert decision_surface(artifact) == decision_surface(base_artifact)
    end
  end

  test "rejects complete-looking covariance with malformed unit and binding evidence" do
    base_artifact = build_artifact()

    artifact =
      valid_covariance_quality()
      |> Map.put("covariance_unit_contract", "bogus")
      |> Map.put("covariance_frame_binding", "not_a_map")
      |> Map.put("covariance_epoch_binding", "not_a_map")
      |> accepted_state_with_quality()
      |> refresh_with_accepted_state()
      |> build_artifact()

    assert_issue(
      artifact,
      "invalid_covariance_unit_contract_shape",
      "$.accepted_planning_state.spacecraft_states[0].quality.covariance_unit_contract"
    )

    assert_issue(
      artifact,
      "invalid_covariance_frame_binding_shape",
      "$.accepted_planning_state.spacecraft_states[0].quality.covariance_frame_binding"
    )

    assert_issue(
      artifact,
      "invalid_covariance_epoch_binding_shape",
      "$.accepted_planning_state.spacecraft_states[0].quality.covariance_epoch_binding"
    )

    assert_handoff_preserves_review(artifact, "invalid_covariance_frame_binding_shape")
    assert @review_warning in artifact["warnings"]
    assert decision_surface(artifact) == decision_surface(base_artifact)
  end

  test "validates every present binding across quality metadata and provenance" do
    base_artifact = build_artifact()

    valid_all_container_artifact =
      valid_covariance_quality()
      |> accepted_state_with_quality()
      |> put_state_container("metadata", valid_covariance_metadata())
      |> put_state_container("provenance", valid_covariance_metadata())
      |> refresh_with_accepted_state()
      |> build_artifact()

    summary =
      get_in(valid_all_container_artifact, ["accepted_planning_state", "evidence_authority"])

    assert summary["status"] == "clean"
    refute @review_warning in valid_all_container_artifact["warnings"]

    masked_false_artifact =
      valid_covariance_quality()
      |> accepted_state_with_quality()
      |> put_state_container("metadata", %{
        "covariance_frame_binding" => Map.put(valid_frame_binding(), "matched", false)
      })
      |> put_state_container("provenance", %{
        "covariance_epoch_binding" => Map.put(valid_epoch_binding(), "matched", false)
      })
      |> refresh_with_accepted_state()
      |> build_artifact()

    assert_issue(
      masked_false_artifact,
      "covariance_frame_mismatch",
      "$.accepted_planning_state.spacecraft_states[0].metadata.covariance_frame_binding.matched"
    )

    assert_issue(
      masked_false_artifact,
      "covariance_epoch_mismatch",
      "$.accepted_planning_state.spacecraft_states[0].provenance.covariance_epoch_binding.matched"
    )

    assert_handoff_preserves_review(masked_false_artifact, "covariance_epoch_mismatch")
    assert @review_warning in masked_false_artifact["warnings"]
    assert decision_surface(masked_false_artifact) == decision_surface(base_artifact)

    wrong_value_artifact =
      valid_covariance_quality()
      |> accepted_state_with_quality()
      |> put_state_container("metadata", %{
        "covariance_frame_binding" =>
          Map.put(valid_frame_binding(), "accepted_state_frame", "body_fixed")
      })
      |> put_state_container("provenance", %{
        "covariance_epoch_binding" => Map.put(valid_epoch_binding(), "time_scale", "gps")
      })
      |> refresh_with_accepted_state()
      |> build_artifact()

    assert_issue(
      wrong_value_artifact,
      "invalid_covariance_frame_binding_shape",
      "$.accepted_planning_state.spacecraft_states[0].metadata.covariance_frame_binding.accepted_state_frame"
    )

    assert_issue(
      wrong_value_artifact,
      "invalid_covariance_epoch_binding_shape",
      "$.accepted_planning_state.spacecraft_states[0].provenance.covariance_epoch_binding.time_scale"
    )

    assert_handoff_preserves_review(
      wrong_value_artifact,
      "invalid_covariance_epoch_binding_shape"
    )

    assert @review_warning in wrong_value_artifact["warnings"]
    assert decision_surface(wrong_value_artifact) == decision_surface(base_artifact)
  end

  test "detects deterministic covariance evidence conflicts across containers" do
    base_artifact = build_artifact()

    artifact =
      valid_covariance_quality()
      |> accepted_state_with_quality()
      |> put_state_container("metadata", %{
        "covariance_unit_contract" => valid_unit_contract("implicit_ccsds_units"),
        "covariance_frame_binding" => valid_frame_binding("J2000"),
        "covariance_epoch_binding" => valid_epoch_binding("2000-01-01T12:01:00.000000Z")
      })
      |> refresh_with_accepted_state()
      |> build_artifact()

    assert_issue(
      artifact,
      "covariance_unit_contract_conflict",
      "$.accepted_planning_state.spacecraft_states[0].metadata.covariance_unit_contract"
    )

    assert_issue(
      artifact,
      "covariance_frame_binding_conflict",
      "$.accepted_planning_state.spacecraft_states[0].metadata.covariance_frame_binding"
    )

    assert_issue(
      artifact,
      "covariance_epoch_binding_conflict",
      "$.accepted_planning_state.spacecraft_states[0].metadata.covariance_epoch_binding"
    )

    assert_handoff_preserves_review(artifact, "covariance_frame_binding_conflict")
    assert @review_warning in artifact["warnings"]
    assert decision_surface(artifact) == decision_surface(base_artifact)
  end

  test "classifies hostile values in every present binding without changing decisions" do
    base_surface = build_artifact() |> decision_surface()

    hostile_values = [
      {deep_map(10), "accepted_state_evidence_shape_deep"},
      {List.duplicate("component", 129), "accepted_state_evidence_shape_oversize"},
      {self(), "unsupported_accepted_state_evidence_value"},
      {make_ref(), "unsupported_accepted_state_evidence_value"},
      {fn -> :ok end, "unsupported_accepted_state_evidence_value"}
    ]

    for container <- ~w(quality metadata provenance),
        {binding_key, binding_reason} <- [
          {"covariance_frame_binding", "invalid_covariance_frame_binding_shape"},
          {"covariance_epoch_binding", "invalid_covariance_epoch_binding_shape"}
        ],
        {hostile_value, hostile_reason} <- hostile_values do
      artifact =
        valid_covariance_quality()
        |> accepted_state_with_quality()
        |> put_state_container(container, %{binding_key => hostile_value})
        |> refresh_with_accepted_state()
        |> build_artifact()

      summary = get_in(artifact, ["accepted_planning_state", "evidence_authority"])

      unless is_map(hostile_value) do
        assert_issue(
          artifact,
          binding_reason,
          "$.accepted_planning_state.spacecraft_states[0].#{container}.#{binding_key}"
        )
      end

      assert summary["status"] == "review_required"
      assert hostile_reason in summary["review_reasons"]

      assert get_in(artifact, ["provenance", "accepted_planning_state", "evidence_authority"]) ==
               summary

      assert @review_warning in artifact["warnings"]
      assert decision_surface(artifact) == base_surface
    end
  end

  test "rejects malformed metadata covariance epoch seconds evidence" do
    base_surface = build_artifact() |> decision_surface()

    for seconds <- [10_000_000_000_000_000_000, :infinity] do
      artifact =
        valid_covariance_quality()
        |> accepted_state_with_quality()
        |> put_state_container("metadata", %{
          "covariance_epoch_binding" =>
            Map.put(valid_epoch_binding(), "seconds_since_j2000", seconds)
        })
        |> refresh_with_accepted_state()
        |> build_artifact()

      assert_issue(
        artifact,
        "invalid_covariance_epoch_binding_shape",
        "$.accepted_planning_state.spacecraft_states[0].metadata.covariance_epoch_binding.seconds_since_j2000"
      )

      assert @review_warning in artifact["warnings"]
      assert decision_surface(artifact) == base_surface
    end
  end

  test "requires exact numerical support tokens in every present covariance check" do
    base_surface = build_artifact() |> decision_surface()

    quality_path =
      "$.accepted_planning_state.spacecraft_states[0].quality.covariance_numerical_check"

    cases = [
      {%{"status" => "passed"}, "name"},
      {Map.put(valid_numerical_check(), "name", nil), "name"},
      {Map.delete(valid_numerical_check(), "name"), "name"},
      {Map.put(valid_numerical_check(), "claim", nil), "claim"},
      {Map.delete(valid_numerical_check(), "claim"), "claim"},
      {Map.put(valid_numerical_check(), "name", "normalized_principal_minors_external"), "name"},
      {Map.put(valid_numerical_check(), "claim", "external_validation"), "claim"}
    ]

    for {check, field} <- cases do
      artifact =
        valid_covariance_quality()
        |> Map.put("covariance_numerical_check", check)
        |> accepted_state_with_quality()
        |> refresh_with_accepted_state()
        |> build_artifact()

      assert_issue(
        artifact,
        "unsupported_covariance_numerical_check",
        quality_path <> "." <> field
      )

      assert_handoff_preserves_review(artifact, "unsupported_covariance_numerical_check")
      assert @review_warning in artifact["warnings"]
      assert decision_surface(artifact) == base_surface
    end

    masked_artifact =
      valid_covariance_quality()
      |> accepted_state_with_quality()
      |> put_state_container("metadata", %{
        "covariance_numerical_check" => %{"status" => "passed"}
      })
      |> put_state_container("provenance", %{
        "covariance_numerical_check" =>
          Map.put(valid_numerical_check(), "claim", "external_validation")
      })
      |> refresh_with_accepted_state()
      |> build_artifact()

    assert_issue(
      masked_artifact,
      "unsupported_covariance_numerical_check",
      "$.accepted_planning_state.spacecraft_states[0].metadata.covariance_numerical_check.name"
    )

    assert_issue(
      masked_artifact,
      "unsupported_covariance_numerical_check",
      "$.accepted_planning_state.spacecraft_states[0].provenance.covariance_numerical_check.claim"
    )

    assert_handoff_preserves_review(masked_artifact, "unsupported_covariance_numerical_check")
    assert @review_warning in masked_artifact["warnings"]
    assert decision_surface(masked_artifact) == base_surface
  end

  test "requires direct covariance epoch to be exact text matching binding" do
    base_surface = build_artifact() |> decision_surface()
    quality_epoch_path = "$.accepted_planning_state.spacecraft_states[0].quality.covariance_epoch"

    valid_exact_artifact =
      valid_covariance_quality()
      |> accepted_state_with_quality()
      |> refresh_with_accepted_state()
      |> build_artifact()

    summary = get_in(valid_exact_artifact, ["accepted_planning_state", "evidence_authority"])
    assert summary["status"] == "clean"
    refute @review_warning in valid_exact_artifact["warnings"]
    assert decision_surface(valid_exact_artifact) == base_surface

    absent_direct_summary =
      valid_covariance_quality()
      |> Map.delete("covariance_epoch")
      |> accepted_state_with_quality()
      |> AcceptedStateEvidenceAuthority.from_accepted_state()

    assert absent_direct_summary["status"] == "clean"

    absent_direct_artifact =
      valid_covariance_quality()
      |> Map.delete("covariance_epoch")
      |> accepted_state_with_quality()
      |> refresh_with_accepted_state()
      |> build_artifact()

    absent_direct_artifact_summary =
      get_in(absent_direct_artifact, ["accepted_planning_state", "evidence_authority"])

    assert absent_direct_artifact_summary["status"] == "clean"
    refute @review_warning in absent_direct_artifact["warnings"]
    assert decision_surface(absent_direct_artifact) == base_surface

    direct_nil_summary =
      valid_covariance_quality()
      |> Map.put("covariance_epoch", nil)
      |> accepted_state_with_quality()
      |> AcceptedStateEvidenceAuthority.from_accepted_state()

    assert_summary_issue(direct_nil_summary, "invalid_covariance_epoch_shape", quality_epoch_path)

    cases = [
      {Map.put(valid_covariance_quality(), "covariance_epoch", nil),
       "invalid_covariance_epoch_shape", quality_epoch_path},
      {Map.put(valid_covariance_quality(), "covariance_epoch", 0.0),
       "invalid_covariance_epoch_shape", quality_epoch_path},
      {Map.put(valid_covariance_quality(), "covariance_epoch", "2000-01-01T12:01:00.000000Z"),
       "covariance_epoch_mismatch", quality_epoch_path},
      {Map.put(valid_covariance_quality(), "covariance_epoch", :binary.copy("2", 257)),
       "invalid_covariance_epoch_shape", quality_epoch_path},
      {valid_covariance_quality()
       |> Map.put("covariance_epoch", "2000-01-01T12:01:00.000000Z")
       |> Map.put("covariance_epoch_binding", valid_epoch_binding("2000-01-01T12:02:00.000000Z")),
       "covariance_epoch_mismatch", quality_epoch_path}
    ]

    for {quality, reason, path} <- cases do
      artifact =
        quality
        |> accepted_state_with_quality()
        |> refresh_with_accepted_state()
        |> build_artifact()

      assert_issue(artifact, reason, path)
      assert_handoff_preserves_review(artifact, reason)
      assert @review_warning in artifact["warnings"]
      assert decision_surface(artifact) == base_surface
    end

    empty_epoch_quality =
      valid_covariance_quality()
      |> Map.put("covariance_epoch", "")
      |> Map.put("covariance_epoch_binding", %{
        "state_epoch" => "",
        "covariance_epoch" => "",
        "time_scale" => "utc",
        "matched" => true,
        "seconds_since_j2000" => 0.0
      })

    empty_summary =
      empty_epoch_quality
      |> accepted_state_with_quality()
      |> AcceptedStateEvidenceAuthority.from_accepted_state()

    assert_summary_issue(empty_summary, "invalid_covariance_epoch_shape", quality_epoch_path)

    assert_summary_issue(
      empty_summary,
      "invalid_covariance_epoch_binding_shape",
      "$.accepted_planning_state.spacecraft_states[0].quality.covariance_epoch_binding.state_epoch"
    )

    assert_summary_issue(
      empty_summary,
      "invalid_covariance_epoch_binding_shape",
      "$.accepted_planning_state.spacecraft_states[0].quality.covariance_epoch_binding.covariance_epoch"
    )

    empty_artifact =
      empty_epoch_quality
      |> accepted_state_with_quality()
      |> refresh_with_accepted_state()
      |> build_artifact()

    assert_issue(empty_artifact, "invalid_covariance_epoch_shape", quality_epoch_path)

    assert_issue(
      empty_artifact,
      "invalid_covariance_epoch_binding_shape",
      "$.accepted_planning_state.spacecraft_states[0].quality.covariance_epoch_binding.state_epoch"
    )

    assert_issue(
      empty_artifact,
      "invalid_covariance_epoch_binding_shape",
      "$.accepted_planning_state.spacecraft_states[0].quality.covariance_epoch_binding.covariance_epoch"
    )

    assert_handoff_preserves_review(empty_artifact, "invalid_covariance_epoch_shape")
    assert @review_warning in empty_artifact["warnings"]
    assert decision_surface(empty_artifact) == base_surface

    masked_mismatch_artifact =
      valid_covariance_quality()
      |> accepted_state_with_quality()
      |> put_state_container("metadata", %{
        "covariance_epoch" => "2000-01-01T12:01:00.000000Z",
        "covariance_epoch_binding" => valid_epoch_binding()
      })
      |> refresh_with_accepted_state()
      |> build_artifact()

    assert_issue(
      masked_mismatch_artifact,
      "covariance_epoch_mismatch",
      "$.accepted_planning_state.spacecraft_states[0].metadata.covariance_epoch"
    )

    assert_handoff_preserves_review(masked_mismatch_artifact, "covariance_epoch_mismatch")
    assert @review_warning in masked_mismatch_artifact["warnings"]
    assert decision_surface(masked_mismatch_artifact) == base_surface
  end

  test "rejects categorical atoms in free-form covariance epoch fields" do
    base_surface = build_artifact() |> decision_surface()
    direct_epoch_path = "$.accepted_planning_state.spacecraft_states[0].quality.covariance_epoch"

    state_epoch_path =
      "$.accepted_planning_state.spacecraft_states[0].quality.covariance_epoch_binding.state_epoch"

    binding_epoch_path =
      "$.accepted_planning_state.spacecraft_states[0].quality.covariance_epoch_binding.covariance_epoch"

    cases = [
      {Map.put(valid_covariance_quality(), "covariance_epoch", :utc),
       "invalid_covariance_epoch_shape", direct_epoch_path},
      {valid_covariance_quality()
       |> update_in(["covariance_epoch_binding"], &Map.put(&1, "state_epoch", :utc)),
       "invalid_covariance_epoch_binding_shape", state_epoch_path},
      {valid_covariance_quality()
       |> update_in(["covariance_epoch_binding"], &Map.put(&1, "covariance_epoch", :utc)),
       "invalid_covariance_epoch_binding_shape", binding_epoch_path},
      {Map.put(valid_covariance_quality(), "covariance_epoch", :passed),
       "invalid_covariance_epoch_shape", direct_epoch_path}
    ]

    for {quality, reason, path} <- cases do
      summary =
        quality
        |> accepted_state_with_quality()
        |> AcceptedStateEvidenceAuthority.from_accepted_state()

      assert_summary_issue(summary, reason, path)
      assert_summary_issue_detail(summary, reason, path, "unsupported_atom")

      artifact =
        quality
        |> accepted_state_with_quality()
        |> refresh_with_accepted_state()
        |> build_artifact()

      assert_issue(artifact, reason, path)
      assert_issue_detail(artifact, reason, path, "unsupported_atom")
      assert_handoff_issue(artifact, reason, path)
      assert @review_warning in artifact["warnings"]
      assert decision_surface(artifact) == base_surface
    end

    all_atom_quality =
      valid_covariance_quality()
      |> Map.put("covariance_epoch", :utc)
      |> Map.put("covariance_epoch_binding", %{
        "state_epoch" => :utc,
        "covariance_epoch" => :utc,
        "time_scale" => "utc",
        "matched" => true,
        "seconds_since_j2000" => 0.0
      })

    {all_atom_summary, all_atom_artifact} = assert_freeform_epoch_review(all_atom_quality)
    assert_summary_issue(all_atom_summary, "invalid_covariance_epoch_shape", direct_epoch_path)

    assert_summary_issue_detail(
      all_atom_summary,
      "invalid_covariance_epoch_shape",
      direct_epoch_path,
      "unsupported_atom"
    )

    assert_summary_issue(
      all_atom_summary,
      "invalid_covariance_epoch_binding_shape",
      state_epoch_path
    )

    assert_summary_issue_detail(
      all_atom_summary,
      "invalid_covariance_epoch_binding_shape",
      state_epoch_path,
      "unsupported_atom"
    )

    assert_summary_issue(
      all_atom_summary,
      "invalid_covariance_epoch_binding_shape",
      binding_epoch_path
    )

    assert_summary_issue_detail(
      all_atom_summary,
      "invalid_covariance_epoch_binding_shape",
      binding_epoch_path,
      "unsupported_atom"
    )

    assert_issue(all_atom_artifact, "invalid_covariance_epoch_shape", direct_epoch_path)

    assert_issue_detail(
      all_atom_artifact,
      "invalid_covariance_epoch_shape",
      direct_epoch_path,
      "unsupported_atom"
    )

    assert_issue(all_atom_artifact, "invalid_covariance_epoch_binding_shape", state_epoch_path)

    assert_issue_detail(
      all_atom_artifact,
      "invalid_covariance_epoch_binding_shape",
      state_epoch_path,
      "unsupported_atom"
    )

    assert_issue(all_atom_artifact, "invalid_covariance_epoch_binding_shape", binding_epoch_path)

    assert_issue_detail(
      all_atom_artifact,
      "invalid_covariance_epoch_binding_shape",
      binding_epoch_path,
      "unsupported_atom"
    )

    assert_handoff_issue(all_atom_artifact, "invalid_covariance_epoch_shape", direct_epoch_path)

    assert_handoff_issue(
      all_atom_artifact,
      "invalid_covariance_epoch_binding_shape",
      state_epoch_path
    )

    assert_handoff_issue(
      all_atom_artifact,
      "invalid_covariance_epoch_binding_shape",
      binding_epoch_path
    )

    assert decision_surface(all_atom_artifact) == base_surface

    mixed_quality =
      valid_covariance_quality()
      |> Map.put("covariance_epoch", :utc)
      |> Map.put("covariance_epoch_binding", %{
        "state_epoch" => "utc",
        "covariance_epoch" => :utc,
        "time_scale" => "utc",
        "matched" => true,
        "seconds_since_j2000" => 0.0
      })

    {mixed_summary, mixed_artifact} = assert_freeform_epoch_review(mixed_quality)
    assert_summary_issue(mixed_summary, "invalid_covariance_epoch_shape", direct_epoch_path)

    assert_summary_issue_detail(
      mixed_summary,
      "invalid_covariance_epoch_shape",
      direct_epoch_path,
      "unsupported_atom"
    )

    assert_summary_issue(
      mixed_summary,
      "invalid_covariance_epoch_binding_shape",
      binding_epoch_path
    )

    assert_summary_issue_detail(
      mixed_summary,
      "invalid_covariance_epoch_binding_shape",
      binding_epoch_path,
      "unsupported_atom"
    )

    assert_issue(mixed_artifact, "invalid_covariance_epoch_shape", direct_epoch_path)

    assert_issue_detail(
      mixed_artifact,
      "invalid_covariance_epoch_shape",
      direct_epoch_path,
      "unsupported_atom"
    )

    assert_issue(mixed_artifact, "invalid_covariance_epoch_binding_shape", binding_epoch_path)

    assert_issue_detail(
      mixed_artifact,
      "invalid_covariance_epoch_binding_shape",
      binding_epoch_path,
      "unsupported_atom"
    )

    assert_handoff_issue(mixed_artifact, "invalid_covariance_epoch_shape", direct_epoch_path)

    assert_handoff_issue(
      mixed_artifact,
      "invalid_covariance_epoch_binding_shape",
      binding_epoch_path
    )

    assert decision_surface(mixed_artifact) == base_surface
  end

  test "requires present state epoch seconds before binding seconds consistency" do
    base_surface = build_artifact() |> decision_surface()

    state_seconds_path =
      "$.accepted_planning_state.spacecraft_states[0].epoch.seconds_since_j2000"

    binding_seconds_path =
      "$.accepted_planning_state.spacecraft_states[0].quality.covariance_epoch_binding.seconds_since_j2000"

    invalid_values = [
      nil,
      "",
      "0.0",
      :infinity,
      10_000_000_000_000_000_000,
      self(),
      make_ref(),
      fn -> :ok end,
      ["component" | "tail"],
      deep_map(10)
    ]

    for value <- invalid_values do
      accepted_state =
        valid_covariance_quality()
        |> accepted_state_with_quality()
        |> put_state_epoch_seconds(value)

      summary = AcceptedStateEvidenceAuthority.from_accepted_state(accepted_state)
      assert_summary_issue(summary, "invalid_state_epoch_seconds_shape", state_seconds_path)
      assert_summary_issue(summary, "covariance_epoch_mismatch", binding_seconds_path)

      artifact =
        accepted_state
        |> refresh_with_accepted_state()
        |> build_artifact()

      assert_issue(artifact, "invalid_state_epoch_seconds_shape", state_seconds_path)
      assert_issue(artifact, "covariance_epoch_mismatch", binding_seconds_path)
      assert_handoff_preserves_review(artifact, "invalid_state_epoch_seconds_shape")
      assert @review_warning in artifact["warnings"]
      assert decision_surface(artifact) == base_surface
    end

    missing_state =
      valid_covariance_quality()
      |> accepted_state_with_quality()
      |> delete_state_epoch_seconds()

    missing_summary = AcceptedStateEvidenceAuthority.from_accepted_state(missing_state)
    refute_summary_issue(missing_summary, "invalid_state_epoch_seconds_shape", state_seconds_path)
    assert_summary_issue(missing_summary, "covariance_epoch_mismatch", binding_seconds_path)

    missing_artifact =
      missing_state
      |> refresh_with_accepted_state()
      |> build_artifact()

    assert_issue(missing_artifact, "covariance_epoch_mismatch", binding_seconds_path)
    assert_handoff_preserves_review(missing_artifact, "covariance_epoch_mismatch")
    assert @review_warning in missing_artifact["warnings"]
    assert decision_surface(missing_artifact) == base_surface

    allowed_missing_state =
      valid_covariance_quality()
      |> update_in(["covariance_epoch_binding"], &Map.delete(&1, "seconds_since_j2000"))
      |> accepted_state_with_quality()
      |> delete_state_epoch_seconds()

    allowed_missing_summary =
      AcceptedStateEvidenceAuthority.from_accepted_state(allowed_missing_state)

    assert allowed_missing_summary["status"] == "clean"

    mismatched_state =
      valid_covariance_quality()
      |> accepted_state_with_quality()
      |> put_state_epoch_seconds(1.0)

    mismatched_summary = AcceptedStateEvidenceAuthority.from_accepted_state(mismatched_state)

    refute_summary_issue(
      mismatched_summary,
      "invalid_state_epoch_seconds_shape",
      state_seconds_path
    )

    assert_summary_issue(mismatched_summary, "covariance_epoch_mismatch", binding_seconds_path)

    mismatched_artifact =
      mismatched_state
      |> refresh_with_accepted_state()
      |> build_artifact()

    assert_issue(mismatched_artifact, "covariance_epoch_mismatch", binding_seconds_path)
    assert_handoff_preserves_review(mismatched_artifact, "covariance_epoch_mismatch")
    assert @review_warning in mismatched_artifact["warnings"]
    assert decision_surface(mismatched_artifact) == base_surface
  end

  test "build carries improper state epoch review before accepted-state stringification" do
    base_surface = build_artifact() |> decision_surface()

    state_seconds_path =
      "$.accepted_planning_state.spacecraft_states[0].epoch.seconds_since_j2000"

    binding_seconds_path =
      "$.accepted_planning_state.spacecraft_states[0].quality.covariance_epoch_binding.seconds_since_j2000"

    accepted_state =
      valid_covariance_quality()
      |> accepted_state_with_quality()
      |> put_state_epoch_seconds([2 | "tail"])

    raw_summary = AcceptedStateEvidenceAuthority.from_accepted_state(accepted_state)
    assert_summary_issue(raw_summary, "invalid_state_epoch_seconds_shape", state_seconds_path)
    assert_summary_issue(raw_summary, "covariance_epoch_mismatch", binding_seconds_path)

    artifact =
      accepted_state
      |> refresh_with_accepted_state()
      |> build_artifact()

    summary = get_in(artifact, ["accepted_planning_state", "evidence_authority"])

    assert summary == raw_summary
    assert_issue(artifact, "invalid_state_epoch_seconds_shape", state_seconds_path)
    assert_issue(artifact, "covariance_epoch_mismatch", binding_seconds_path)
    assert_handoff_preserves_review(artifact, "invalid_state_epoch_seconds_shape")
    assert @review_warning in artifact["warnings"]
    assert decision_surface(artifact) == base_surface
  end

  test "build redacts unsafe accepted-state evidence hidden beyond displayed issues" do
    base_surface = build_artifact() |> decision_surface()

    state_seconds_path =
      "$.accepted_planning_state.spacecraft_states[0].epoch.seconds_since_j2000"

    accepted_state =
      valid_covariance_quality()
      |> accepted_state_with_quality()
      |> put_state_epoch_seconds([2 | "tail"])
      |> add_oversize_binary_evidence_noise(55)

    refresh = refresh_with_accepted_state(accepted_state)

    raw_summary =
      AcceptedStateEvidenceAuthority.analyze_refresh_wrapper(refresh).evidence_authority

    assert raw_summary["issue_count"] > 50
    assert "accepted_state_evidence_improper_list_shape" in raw_summary["review_reasons"]
    assert state_seconds_path in raw_summary["accepted_state_encoding_projection_paths"]

    refute Enum.any?(raw_summary["issues"], fn issue ->
             issue["reason"] == "accepted_state_evidence_improper_list_shape" and
               issue["path"] == state_seconds_path
           end)

    artifact = build_artifact(refresh)

    summary = get_in(artifact, ["accepted_planning_state", "evidence_authority"])

    assert summary == raw_summary
    assert_handoff_preserves_review(artifact, "accepted_state_evidence_improper_list_shape")
    assert @review_warning in artifact["warnings"]
    assert decision_surface(artifact) == base_surface
  end

  test "build projection removes only unsafe evidence while preserving accepted-state decisions" do
    matrix_path =
      "$.accepted_planning_state.spacecraft_states[0].quality.covariance_matrix_6x6"

    accepted_state =
      valid_covariance_quality()
      |> Map.put("covariance_matrix_6x6", [List.duplicate(0.0, 6) | "tail"])
      |> accepted_state_with_quality()
      |> put_accepted_state_decision_fields()

    evidence_absent_state =
      update_in(
        accepted_state,
        ["spacecraft_states", Access.at(0), "quality"],
        &Map.delete(&1, "covariance_matrix_6x6")
      )

    unsafe_artifact =
      accepted_state
      |> refresh_with_only_accepted_state_inputs()
      |> build_artifact()

    evidence_absent_artifact =
      evidence_absent_state
      |> refresh_with_only_accepted_state_inputs()
      |> build_artifact()

    assert_issue(unsafe_artifact, "accepted_state_evidence_improper_list_shape", matrix_path)
    assert_issue(unsafe_artifact, "invalid_covariance_matrix_shape", matrix_path)

    assert unsafe_artifact["refresh_id"] == evidence_absent_artifact["refresh_id"]

    assert get_in(unsafe_artifact, ["accepted_planning_state", "snapshot_id"]) ==
             get_in(evidence_absent_artifact, ["accepted_planning_state", "snapshot_id"])

    assert get_in(unsafe_artifact, ["accepted_planning_state", "accepted_at"]) ==
             get_in(evidence_absent_artifact, ["accepted_planning_state", "accepted_at"])

    assert unsafe_artifact["current_epoch_s"] == evidence_absent_artifact["current_epoch_s"]
    assert unsafe_artifact["remaining_horizon"] == evidence_absent_artifact["remaining_horizon"]
    assert unsafe_artifact["freshness_report"] == evidence_absent_artifact["freshness_report"]
    assert unsafe_artifact["resource_summaries"] == evidence_absent_artifact["resource_summaries"]

    assert unsafe_artifact["candidate_activities"] ==
             evidence_absent_artifact["candidate_activities"]

    assert unsafe_artifact["contact_filter_report"] ==
             evidence_absent_artifact["contact_filter_report"]

    assert decision_surface(unsafe_artifact) == decision_surface(evidence_absent_artifact)
  end

  test "build projection treats dotted and bracketed evidence keys as literal segments" do
    literal_epoch_key = "covariance_epoch_binding.seconds_since_j2000"
    literal_matrix_key = "covariance_matrix_6x6[0]"

    literal_epoch_path =
      "$.accepted_planning_state.spacecraft_states[0].quality." <> literal_epoch_key

    literal_matrix_path =
      "$.accepted_planning_state.spacecraft_states[0].quality." <> literal_matrix_key

    accepted_state =
      valid_covariance_quality()
      |> Map.put(literal_epoch_key, [2 | "tail"])
      |> Map.put(literal_matrix_key, self())
      |> accepted_state_with_quality()
      |> put_accepted_state_decision_fields()

    evidence_absent_state =
      delete_quality_keys(accepted_state, [literal_epoch_key, literal_matrix_key])

    unsafe_artifact =
      accepted_state
      |> refresh_with_only_accepted_state_inputs()
      |> build_artifact()

    evidence_absent_artifact =
      evidence_absent_state
      |> refresh_with_only_accepted_state_inputs()
      |> build_artifact()

    summary = get_in(unsafe_artifact, ["accepted_planning_state", "evidence_authority"])

    assert_issue(
      unsafe_artifact,
      "accepted_state_evidence_improper_list_shape",
      literal_epoch_path
    )

    assert_issue(
      unsafe_artifact,
      "unsupported_accepted_state_evidence_value",
      literal_matrix_path
    )

    assert_summary_projection_action(
      summary,
      "accepted_planning_state",
      "delete",
      ["spacecraft_states", 0, "quality", literal_epoch_key]
    )

    assert_summary_projection_action(
      summary,
      "accepted_planning_state",
      "delete",
      ["spacecraft_states", 0, "quality", literal_matrix_key]
    )

    projected_refresh =
      accepted_state
      |> refresh_with_only_accepted_state_inputs()
      |> BuildContext.refresh_for_build_encoding(summary)

    assert get_in(
             projected_refresh,
             [
               "accepted_planning_state",
               "spacecraft_states",
               Access.at(0),
               "quality",
               "covariance_epoch_binding",
               "seconds_since_j2000"
             ]
           ) == 0.0

    assert get_in(unsafe_artifact, ["provenance", "accepted_planning_state", "quality"]) ==
             get_in(evidence_absent_artifact, ["provenance", "accepted_planning_state", "quality"])

    assert unsafe_artifact["refresh_id"] == evidence_absent_artifact["refresh_id"]
    assert decision_surface(unsafe_artifact) == decision_surface(evidence_absent_artifact)
  end

  test "build sanitizes non accepted-state wrapper alias collisions before value encoding" do
    base_refresh =
      refresh_request()
      |> Map.put("targets", [%{"id" => "target_a", "priority" => 2.0}])

    refresh =
      base_refresh
      |> Map.put(:targets, [%{"id" => "target_a", "priority" => 9.0}])

    alias_absent_refresh =
      base_refresh
      |> Map.delete("targets")
      |> Map.delete(:targets)

    artifact = build_artifact(refresh)
    alias_absent_artifact = build_artifact(alias_absent_refresh)
    summary = get_in(artifact, ["accepted_planning_state", "evidence_authority"])

    assert_issue(artifact, "atom_string_alias_collision", "$.candidate_refresh.targets")
    assert_summary_projection_action(summary, "candidate_refresh", "sanitize_map", [])
    assert_handoff_preserves_review(artifact, "atom_string_alias_collision")
    assert decision_surface(artifact) == decision_surface(alias_absent_artifact)
  end

  test "accepted-state root budget projection preserves known decision fields" do
    clean_state =
      valid_covariance_quality()
      |> accepted_state_with_quality()
      |> put_accepted_state_decision_fields()

    oversized_state = add_root_noise(clean_state, 70)

    artifact =
      oversized_state
      |> refresh_with_only_accepted_state_inputs()
      |> build_artifact()

    clean_artifact =
      clean_state
      |> refresh_with_only_accepted_state_inputs()
      |> build_artifact()

    summary = get_in(artifact, ["accepted_planning_state", "evidence_authority"])

    assert_issue(
      artifact,
      "accepted_state_evidence_shape_oversize",
      "$.accepted_planning_state"
    )

    assert_summary_issue_detail(
      summary,
      "accepted_state_evidence_shape_oversize",
      "$.accepted_planning_state",
      "max_map_entries_exceeded"
    )

    assert_summary_projection_action(summary, "accepted_planning_state", "safe_project", [])

    assert get_in(artifact, ["accepted_planning_state", "snapshot_id"]) ==
             get_in(clean_artifact, ["accepted_planning_state", "snapshot_id"])

    assert artifact["refresh_id"] == clean_artifact["refresh_id"]
    assert artifact["current_epoch_s"] == clean_artifact["current_epoch_s"]
    assert artifact["remaining_horizon"] == clean_artifact["remaining_horizon"]
    assert artifact["resource_summaries"] == clean_artifact["resource_summaries"]
    assert artifact["candidate_activities"] == clean_artifact["candidate_activities"]
    assert artifact["contact_filter_report"] == clean_artifact["contact_filter_report"]
    assert decision_surface(artifact) == decision_surface(clean_artifact)
  end

  test "build recursively sanitizes wrapper subtree atom string alias collisions" do
    cases = [
      {
        "target row",
        refresh_request()
        |> Map.put("targets", [%{"id" => "target_a", :id => "target_b", "priority" => 2.0}]),
        refresh_request()
        |> Map.put("targets", [%{"priority" => 2.0}]),
        "$.candidate_refresh.targets[0].id",
        ["targets", 0]
      },
      {
        "resource row",
        refresh_request()
        |> Map.put("resource_summaries", [
          %{"spacecraft_id" => "leo_1", :spacecraft_id => "leo_2", "fuel_margin" => 0.8}
        ]),
        refresh_request()
        |> Map.put("resource_summaries", [%{"fuel_margin" => 0.8}]),
        "$.candidate_refresh.resource_summaries[0].spacecraft_id",
        ["resource_summaries", 0]
      },
      {
        "station row",
        refresh_request()
        |> Map.put("ground_network", [
          %{"id" => "equator_prime", :id => "polar_prime", "status" => "available"}
        ]),
        refresh_request()
        |> Map.put("ground_network", [%{"status" => "available"}]),
        "$.candidate_refresh.ground_network[0].id",
        ["ground_network", 0]
      },
      {
        "prior candidate row",
        refresh_request()
        |> Map.put("prior_candidate_activities", [
          %{"id" => "prior_a", :id => "prior_b", "scenario_id" => "leo_1"}
        ]),
        refresh_request()
        |> Map.put("prior_candidate_activities", [%{"scenario_id" => "leo_1"}]),
        "$.candidate_refresh.prior_candidate_activities[0].id",
        ["prior_candidate_activities", 0]
      },
      {
        "policy map",
        refresh_request()
        |> Map.put("resource_filter_policy", %{"mode" => "strict", :mode => "permissive"}),
        refresh_request()
        |> Map.put("resource_filter_policy", %{}),
        "$.candidate_refresh.resource_filter_policy.mode",
        ["resource_filter_policy"]
      },
      {
        "nested filter map",
        refresh_request()
        |> Map.put("constraints", %{
          "filters" => [%{"type" => "visibility", :type => "shadow"}]
        }),
        refresh_request()
        |> Map.put("constraints", %{"filters" => [%{}]}),
        "$.candidate_refresh.constraints.filters[0].type",
        ["constraints", "filters", 0]
      },
      {
        "source report collection",
        refresh_request()
        |> Map.put("source_resource_projection_reports", %{
          "report_a" => %{
            "schema_contract" => "resource_projection_report.v1",
            :schema_contract => "forged_resource_projection_report.v1"
          }
        }),
        refresh_request()
        |> Map.put("source_resource_projection_reports", %{"report_a" => %{}}),
        "$.candidate_refresh.source_resource_projection_reports.report_a.schema_contract",
        ["source_resource_projection_reports", "report_a"]
      }
    ]

    for {_label, refresh, alias_absent_refresh, path, segments} <- cases do
      artifact = build_artifact(refresh)
      alias_absent_artifact = build_artifact(alias_absent_refresh)
      summary = get_in(artifact, ["accepted_planning_state", "evidence_authority"])

      assert_issue(artifact, "atom_string_alias_collision", path)
      assert_summary_projection_action(summary, "candidate_refresh", "sanitize_map", segments)
      assert_handoff_preserves_review(artifact, "atom_string_alias_collision")
      assert decision_surface(artifact) == decision_surface(alias_absent_artifact)
    end
  end

  test "build deletes long literal evidence keys by structured segment without whole-state fallback" do
    for size <- [129, 256] do
      literal_key = String.duplicate("k", size)
      literal_path = "$.accepted_planning_state.spacecraft_states[0].quality." <> literal_key

      accepted_state =
        valid_covariance_quality()
        |> Map.put(literal_key, [2 | "tail"])
        |> accepted_state_with_quality()
        |> put_accepted_state_decision_fields()

      evidence_absent_state = delete_quality_keys(accepted_state, [literal_key])

      artifact =
        accepted_state
        |> refresh_with_only_accepted_state_inputs()
        |> build_artifact()

      evidence_absent_artifact =
        evidence_absent_state
        |> refresh_with_only_accepted_state_inputs()
        |> build_artifact()

      summary = get_in(artifact, ["accepted_planning_state", "evidence_authority"])

      assert_issue(artifact, "accepted_state_evidence_improper_list_shape", literal_path)

      assert_summary_projection_action(
        summary,
        "accepted_planning_state",
        "delete",
        ["spacecraft_states", 0, "quality", literal_key]
      )

      refute Enum.any?(summary["build_encoding_projection_actions"], fn action ->
               action["scope"] == "accepted_planning_state" and action["action"] == "safe_project"
             end)

      assert get_in(artifact, ["provenance", "accepted_planning_state", "quality"]) ==
               get_in(evidence_absent_artifact, [
                 "provenance",
                 "accepted_planning_state",
                 "quality"
               ])

      assert artifact["refresh_id"] == evidence_absent_artifact["refresh_id"]
      assert decision_surface(artifact) == decision_surface(evidence_absent_artifact)
    end
  end

  test "build detects oversized wrapper source-report collection aliases before truncation" do
    source_reports = [
      %{
        "schema_contract" => "resource_projection_report.v1",
        "provenance" => %{"trust_boundary" => "declared"},
        "resource_pressure_rows" => []
      }
    ]

    cases = [
      {"equal", source_reports},
      {"unequal",
       [
         %{
           "schema_contract" => "forged_resource_projection_report.v1",
           "provenance" => %{"trust_boundary" => "forged"},
           "resource_pressure_rows" => []
         }
       ]}
    ]

    for {_label, atom_source_reports} <- cases do
      refresh =
        refresh_request()
        |> put_refresh_consumer_surface()
        |> Map.put("source_resource_projection_reports", source_reports)
        |> Map.put(:source_resource_projection_reports, atom_source_reports)
        |> add_root_noise(70)

      both_absent_refresh =
        refresh_request()
        |> put_refresh_consumer_surface()
        |> Map.delete("source_resource_projection_reports")
        |> Map.delete(:source_resource_projection_reports)
        |> add_root_noise(70)

      artifact = build_artifact(refresh)
      both_absent_artifact = build_artifact(both_absent_refresh)
      summary = get_in(artifact, ["accepted_planning_state", "evidence_authority"])

      assert_issue(
        artifact,
        "atom_string_alias_collision",
        "$.candidate_refresh.source_resource_projection_reports"
      )

      assert_summary_projection_action(summary, "candidate_refresh", "sanitize_map", [])
      assert_handoff_preserves_review(artifact, "atom_string_alias_collision")

      assert get_in(artifact, ["provenance", "source_reports"]) ==
               get_in(both_absent_artifact, ["provenance", "source_reports"])

      assert decision_surface(artifact) == decision_surface(both_absent_artifact)
    end
  end

  test "whole-state projection preserves consumer surface under root and depth noise and redacts node overflow" do
    clean_state =
      valid_covariance_quality()
      |> accepted_state_with_quality()
      |> put_accepted_state_decision_fields()
      |> put_accepted_state_consumer_surface()

    cases = [
      {
        "root",
        add_root_noise(clean_state, 70),
        "accepted_state_evidence_shape_oversize"
      },
      {
        "depth",
        Map.put(clean_state, "aaa_depth_noise", deep_map(10)),
        "accepted_state_evidence_shape_deep"
      }
    ]

    clean_artifact =
      clean_state
      |> refresh_with_only_accepted_state_inputs()
      |> build_artifact()

    for {_label, noisy_state, reason} <- cases do
      artifact =
        noisy_state
        |> refresh_with_only_accepted_state_inputs()
        |> build_artifact()

      summary = get_in(artifact, ["accepted_planning_state", "evidence_authority"])

      assert summary["status"] == "review_required"
      assert reason in summary["review_reasons"]
      assert artifact["refresh_id"] == clean_artifact["refresh_id"]
      assert artifact["current_epoch_s"] == clean_artifact["current_epoch_s"]
      assert artifact["remaining_horizon"] == clean_artifact["remaining_horizon"]
      assert artifact["resource_summaries"] == clean_artifact["resource_summaries"]
      assert artifact["candidate_activities"] == clean_artifact["candidate_activities"]
      assert artifact["contact_filter_report"] == clean_artifact["contact_filter_report"]
      assert artifact["operational_feedback"] == clean_artifact["operational_feedback"]

      assert get_in(artifact, ["provenance", "source_reports"]) ==
               get_in(clean_artifact, ["provenance", "source_reports"])

      assert decision_surface(artifact) == decision_surface(clean_artifact)
    end

    node_refresh =
      clean_state
      |> Map.put("aaa_node_noise", node_budget_noise())
      |> refresh_with_only_accepted_state_inputs()

    node_analysis = AcceptedStateEvidenceAuthority.analyze_refresh_wrapper(node_refresh)
    node_summary = node_analysis.evidence_authority
    node_artifact = build_artifact(node_refresh)

    redaction_artifact =
      refresh_encoding_redaction()
      |> build_artifact()

    assert node_analysis.analysis_cursor == %{nodes: 512, overflow: true}
    assert node_analysis.build_encoding_outcome == :whole_refresh_redaction
    assert node_analysis.refresh == refresh_encoding_redaction()
    assert node_summary["status"] == "review_required"
    assert "accepted_state_evidence_node_budget_exceeded" in node_summary["review_reasons"]
    assert node_artifact["refresh_id"] == redaction_artifact["refresh_id"]
    assert node_artifact["current_epoch_s"] == redaction_artifact["current_epoch_s"]
    assert node_artifact["remaining_horizon"] == redaction_artifact["remaining_horizon"]
    assert node_artifact["resource_summaries"] == redaction_artifact["resource_summaries"]
    assert node_artifact["candidate_activities"] == redaction_artifact["candidate_activities"]
    assert node_artifact["contact_filter_report"] == redaction_artifact["contact_filter_report"]
    assert node_artifact["operational_feedback"] == redaction_artifact["operational_feedback"]

    assert get_in(node_artifact, ["provenance", "source_reports"]) ==
             get_in(redaction_artifact, ["provenance", "source_reports"])

    assert decision_surface(node_artifact) == decision_surface(redaction_artifact)
  end

  test "refresh projection preserves wrapper consumer surface under root and depth noise and redacts node overflow" do
    clean_state =
      valid_covariance_quality()
      |> accepted_state_with_quality()
      |> put_accepted_state_decision_fields()
      |> put_accepted_state_consumer_surface()

    clean_refresh =
      clean_state
      |> refresh_with_only_accepted_state_inputs()
      |> put_refresh_consumer_surface()

    cases = [
      {
        "root",
        add_root_noise(clean_refresh, 70),
        "accepted_state_evidence_shape_oversize"
      },
      {
        "depth",
        Map.put(clean_refresh, "aaa_depth_noise", deep_map(10)),
        "accepted_state_evidence_shape_deep"
      }
    ]

    clean_artifact = build_artifact(clean_refresh)

    for {_label, refresh, reason} <- cases do
      artifact = build_artifact(refresh)
      summary = get_in(artifact, ["accepted_planning_state", "evidence_authority"])

      assert summary["status"] == "review_required"
      assert reason in summary["review_reasons"]
      accepted_state_ref = Map.delete(artifact["accepted_planning_state"], "evidence_authority")

      clean_accepted_state_ref =
        Map.delete(clean_artifact["accepted_planning_state"], "evidence_authority")

      accepted_state_provenance =
        artifact
        |> get_in(["provenance", "accepted_planning_state"])
        |> Map.delete("evidence_authority")

      clean_accepted_state_provenance =
        clean_artifact
        |> get_in(["provenance", "accepted_planning_state"])
        |> Map.delete("evidence_authority")

      assert accepted_state_ref == clean_accepted_state_ref
      assert accepted_state_provenance == clean_accepted_state_provenance
      assert artifact["refresh_id"] == clean_artifact["refresh_id"]

      assert get_in(artifact, ["provenance", "operational_feedback"]) ==
               get_in(clean_artifact, ["provenance", "operational_feedback"])

      assert get_in(artifact, ["provenance", "source_reports"]) ==
               get_in(clean_artifact, ["provenance", "source_reports"])

      assert decision_surface(artifact) == decision_surface(clean_artifact)
    end

    node_refresh = Map.put(clean_refresh, "aaa_node_noise", node_budget_noise())
    node_analysis = AcceptedStateEvidenceAuthority.analyze_refresh_wrapper(node_refresh)
    node_summary = node_analysis.evidence_authority
    node_artifact = build_artifact(node_refresh)

    redaction_artifact =
      refresh_encoding_redaction()
      |> build_artifact()

    assert node_analysis.analysis_cursor == %{nodes: 512, overflow: true}
    assert node_analysis.build_encoding_outcome == :whole_refresh_redaction
    assert node_analysis.refresh == refresh_encoding_redaction()
    assert node_summary["status"] == "review_required"
    assert "accepted_state_evidence_node_budget_exceeded" in node_summary["review_reasons"]

    node_accepted_state_ref =
      Map.delete(node_artifact["accepted_planning_state"], "evidence_authority")

    redaction_accepted_state_ref =
      Map.delete(redaction_artifact["accepted_planning_state"], "evidence_authority")

    node_accepted_state_provenance =
      node_artifact
      |> get_in(["provenance", "accepted_planning_state"])
      |> Map.delete("evidence_authority")

    redaction_accepted_state_provenance =
      redaction_artifact
      |> get_in(["provenance", "accepted_planning_state"])
      |> Map.delete("evidence_authority")

    assert node_accepted_state_ref == redaction_accepted_state_ref
    assert node_accepted_state_provenance == redaction_accepted_state_provenance
    assert node_artifact["refresh_id"] == redaction_artifact["refresh_id"]

    assert get_in(node_artifact, ["provenance", "operational_feedback"]) ==
             get_in(redaction_artifact, ["provenance", "operational_feedback"])

    assert get_in(node_artifact, ["provenance", "source_reports"]) ==
             get_in(redaction_artifact, ["provenance", "source_reports"])

    assert decision_surface(node_artifact) == decision_surface(redaction_artifact)
  end

  test "refresh projection preserves closed atom keys and drops unrelated atom noise" do
    clean_refresh =
      valid_covariance_quality()
      |> accepted_state_with_quality()
      |> refresh_with_only_accepted_state_inputs()
      |> put_refresh_consumer_surface()

    atom_schema_refresh = Map.put(clean_refresh, :schema_contract, "candidate_refresh_request.v1")

    string_schema_refresh =
      Map.put(clean_refresh, "schema_contract", "candidate_refresh_request.v1")

    atom_noise_refresh = Map.put(clean_refresh, :unrelated_noise, "ignored")

    atom_schema_artifact = build_artifact(atom_schema_refresh)
    string_schema_artifact = build_artifact(string_schema_refresh)
    atom_noise_artifact = build_artifact(atom_noise_refresh)
    clean_artifact = build_artifact(clean_refresh)

    atom_noise_summary =
      get_in(atom_noise_artifact, ["accepted_planning_state", "evidence_authority"])

    assert decision_surface(atom_schema_artifact) == decision_surface(string_schema_artifact)

    assert get_in(atom_schema_artifact, ["provenance", "source_reports"]) ==
             get_in(string_schema_artifact, ["provenance", "source_reports"])

    assert "unsupported_accepted_state_evidence_atom_key" in atom_noise_summary["review_reasons"]
    assert decision_surface(atom_noise_artifact) == decision_surface(clean_artifact)

    assert get_in(atom_noise_artifact, ["provenance", "source_reports"]) ==
             get_in(clean_artifact, ["provenance", "source_reports"])
  end

  test "real build safe-projects transactionally at wrapper node budget boundary" do
    ceiling_state = minimal_budget_accepted_state()
    operational_feedback = operational_feedback_budget_tree(:spanning_ceiling)

    ceiling_expected_projection = %{
      "accepted_planning_state" => ceiling_state,
      "operational_feedback" => operational_feedback
    }

    ceiling_refresh = add_root_noise(ceiling_expected_projection, 70)

    overflow_refresh =
      %{
        "accepted_planning_state" => Map.put(ceiling_state, "source", %{}),
        "operational_feedback" => operational_feedback
      }
      |> add_root_noise(70)

    redaction = refresh_encoding_redaction()
    ceiling_artifact = build_artifact(ceiling_refresh)
    expected_artifact = build_artifact(ceiling_expected_projection)
    overflow_artifact = build_artifact(overflow_refresh)
    redaction_artifact = build_artifact(redaction)
    ceiling_summary = get_in(ceiling_artifact, ["accepted_planning_state", "evidence_authority"])

    overflow_summary =
      get_in(overflow_artifact, ["accepted_planning_state", "evidence_authority"])

    assert ceiling_summary["status"] == "review_required"
    assert "accepted_state_evidence_shape_oversize" in ceiling_summary["review_reasons"]
    assert_summary_projection_action(ceiling_summary, "candidate_refresh", "safe_project", [])

    assert BuildContext.refresh_for_build_encoding(ceiling_refresh, ceiling_summary) ==
             ceiling_expected_projection

    assert get_in(ceiling_artifact, ["provenance", "operational_feedback"]) ==
             get_in(expected_artifact, ["provenance", "operational_feedback"])

    assert ceiling_artifact["refresh_id"] == expected_artifact["refresh_id"]
    assert decision_surface(ceiling_artifact) == decision_surface(expected_artifact)

    assert overflow_summary["status"] == "review_required"
    assert "accepted_state_evidence_shape_oversize" in overflow_summary["review_reasons"]
    assert_summary_projection_action(overflow_summary, "candidate_refresh", "safe_project", [])

    assert BuildContext.refresh_for_build_encoding(overflow_refresh, overflow_summary) ==
             redaction

    assert_handoff_preserves_review(overflow_artifact, "accepted_state_evidence_shape_oversize")

    refute get_in(overflow_artifact, [
             "provenance",
             "operational_feedback",
             "station_throughput_factor",
             "equator_prime_edge_1"
           ])

    assert get_in(overflow_artifact, ["provenance", "operational_feedback"]) ==
             get_in(redaction_artifact, ["provenance", "operational_feedback"])

    assert overflow_artifact["refresh_id"] == redaction_artifact["refresh_id"]
    assert decision_surface(overflow_artifact) == decision_surface(redaction_artifact)
  end

  test "public analyzer locks summary and build projection outcome" do
    clean_refresh = refresh_request()
    clean_analysis = AcceptedStateEvidenceAuthority.analyze_refresh_wrapper(clean_refresh)
    clean_summary = clean_analysis.evidence_authority

    assert clean_analysis.analysis_cursor.overflow == false
    assert clean_analysis.build_encoding_outcome == :byte_preserve_raw_refresh
    assert clean_analysis.refresh == clean_refresh
    assert clean_summary["status"] == "clean"
    assert clean_summary["accepted_state_encoding_projection_required"] == false

    ceiling_state = minimal_budget_accepted_state()
    operational_feedback = operational_feedback_budget_tree(:spanning_ceiling)

    ceiling_projection = %{
      "accepted_planning_state" => ceiling_state,
      "operational_feedback" => operational_feedback
    }

    ceiling_refresh = add_root_noise(ceiling_projection, 70)
    ceiling_analysis = AcceptedStateEvidenceAuthority.analyze_refresh_wrapper(ceiling_refresh)
    ceiling_summary = ceiling_analysis.evidence_authority

    assert ceiling_analysis.analysis_cursor.overflow == false
    assert ceiling_analysis.build_encoding_outcome == :complete_projected_refresh
    assert ceiling_analysis.refresh == ceiling_projection

    assert_summary_issue(
      ceiling_summary,
      "accepted_state_evidence_shape_oversize",
      "$.candidate_refresh"
    )

    assert_summary_projection_action(ceiling_summary, "candidate_refresh", "safe_project", [])

    overflow_refresh =
      %{
        "accepted_planning_state" => Map.put(ceiling_state, "source", %{}),
        "operational_feedback" => operational_feedback
      }
      |> add_root_noise(70)

    overflow_analysis = AcceptedStateEvidenceAuthority.analyze_refresh_wrapper(overflow_refresh)
    overflow_summary = overflow_analysis.evidence_authority

    assert overflow_analysis.analysis_cursor.overflow == true
    assert overflow_analysis.build_encoding_outcome == :whole_refresh_redaction
    assert overflow_analysis.refresh == refresh_encoding_redaction()
    assert "accepted_state_evidence_node_budget_exceeded" in overflow_summary["review_reasons"]
  end

  test "public analyzer scans known late fields in oversized refresh wrappers" do
    refresh =
      %{
        "accepted_planning_state" => minimal_budget_accepted_state(),
        "source_reports" => %{
          "zz_late_report" => %{
            "authenticated" => true,
            "content_identity" => %{"authority" => "authenticated"}
          }
        }
      }
      |> add_alphabetic_root_noise(70)

    analysis = AcceptedStateEvidenceAuthority.analyze_refresh_wrapper(refresh)
    summary = analysis.evidence_authority

    assert analysis.build_encoding_outcome == :complete_projected_refresh

    assert_summary_issue(
      summary,
      "claimed_content_identity_authority",
      "$.candidate_refresh.source_reports.zz_late_report.authenticated"
    )

    assert_summary_issue(
      summary,
      "claimed_content_identity_authority",
      "$.candidate_refresh.source_reports.zz_late_report.content_identity.authority"
    )
  end

  test "public analyzer never complete-projects unreported late retained authority claims" do
    refresh =
      %{
        "accepted_planning_state" => minimal_budget_accepted_state(),
        "approval_policy" => cursor_consuming_approval_policy(),
        "source_reports" => %{
          "zz_late_report" => %{
            "content_identity" => %{"authority" => "authenticated"}
          }
        }
      }
      |> add_root_noise(70)

    analysis = AcceptedStateEvidenceAuthority.analyze_refresh_wrapper(refresh)
    summary = analysis.evidence_authority

    late_claim_reported? =
      Enum.any?(summary["issues"], fn issue ->
        issue["reason"] == "claimed_content_identity_authority" and
          issue["path"] ==
            "$.candidate_refresh.source_reports.zz_late_report.content_identity.authority"
      end)

    assert analysis.build_encoding_outcome == :whole_refresh_redaction or late_claim_reported?

    refute analysis.build_encoding_outcome == :complete_projected_refresh and
             not late_claim_reported?
  end

  test "public analyzer handles oversized map aliases independently of construction order" do
    source_reports = [
      %{
        "schema_contract" => "resource_projection_report.v1",
        "provenance" => %{"trust_boundary" => "declared"},
        "resource_pressure_rows" => []
      }
    ]

    atom_source_reports = [
      %{
        "schema_contract" => "forged_resource_projection_report.v1",
        "provenance" => %{"trust_boundary" => "forged"},
        "resource_pressure_rows" => []
      }
    ]

    base_refresh =
      %{"accepted_planning_state" => minimal_budget_accepted_state()}
      |> add_root_noise(70)

    absent_analysis = AcceptedStateEvidenceAuthority.analyze_refresh_wrapper(base_refresh)

    collision_first =
      %{
        "source_resource_projection_reports" => source_reports,
        source_resource_projection_reports: atom_source_reports
      }
      |> Map.merge(base_refresh)

    collision_last =
      base_refresh
      |> Map.put(:source_resource_projection_reports, atom_source_reports)
      |> Map.put("source_resource_projection_reports", source_reports)

    for refresh <- [collision_first, collision_last] do
      analysis = AcceptedStateEvidenceAuthority.analyze_refresh_wrapper(refresh)
      summary = analysis.evidence_authority

      assert analysis.build_encoding_outcome == :complete_projected_refresh
      assert analysis.refresh == absent_analysis.refresh

      assert_summary_issue(
        summary,
        "atom_string_alias_collision",
        "$.candidate_refresh.source_resource_projection_reports"
      )
    end
  end

  test "public analyzer projects hostile spacecraft-state carrier rows from inspected children" do
    cases = [
      {
        "improper list",
        [0.0, 1.0 | "tail"],
        "accepted_state_evidence_improper_list_shape",
        :base
      },
      {
        "function",
        fn -> :ok end,
        "unsupported_accepted_state_evidence_value",
        :base
      },
      {
        "deep map",
        deep_map(10),
        "accepted_state_evidence_shape_deep",
        :nested
      },
      {
        "oversized map",
        add_root_noise(%{}, 65),
        "accepted_state_evidence_shape_oversize",
        :base
      },
      {
        "atom string alias",
        %{"position_km" => 1.0, position_km: 2.0},
        "atom_string_alias_collision",
        ".position_km"
      }
    ]

    for {_label, value, reason, expected_path} <- cases do
      accepted_state =
        %{}
        |> accepted_state_with_quality()
        |> put_in(["spacecraft_states", Access.at(0), "state_vector"], value)

      refresh = refresh_with_accepted_state(accepted_state)
      analysis = AcceptedStateEvidenceAuthority.analyze_refresh_wrapper(refresh)
      summary = analysis.evidence_authority
      artifact = build_artifact(refresh)
      artifact_summary = get_in(artifact, ["accepted_planning_state", "evidence_authority"])
      path = "$.accepted_planning_state.spacecraft_states[0].state_vector"

      assert reason in summary["review_reasons"]
      assert summary["accepted_state_encoding_projection_required"] == true
      assert analysis.build_encoding_outcome == :complete_projected_refresh
      assert analysis.analysis_cursor.overflow == false

      assert analysis.analysis_cursor.nodes <=
               AcceptedStateEvidenceAuthority.max_encoding_projection_nodes()

      assert artifact_summary == summary
      assert @review_warning in artifact["warnings"]

      assert_carrier_attack_removed(
        analysis.refresh,
        ["accepted_planning_state", "spacecraft_states", Access.at(0), "state_vector"],
        refresh,
        expected_path
      )

      assert Enum.any?(summary["issues"], fn issue ->
               issue["reason"] == reason and
                 carrier_issue_path?(issue["path"], path, expected_path)
             end)
    end
  end

  test "public analyzer projects hostile maneuver delta carrier rows from inspected children" do
    delta = %{"id" => "delta_1", "spacecraft_id" => "leo_1"}

    cases = [
      {
        "improper list",
        [0.0, 1.0 | "tail"],
        "accepted_state_evidence_improper_list_shape",
        :base
      },
      {
        "function",
        fn -> :ok end,
        "unsupported_accepted_state_evidence_value",
        :base
      },
      {
        "deep map",
        deep_map(10),
        "accepted_state_evidence_shape_deep",
        :nested
      },
      {
        "oversized map",
        add_root_noise(%{}, 65),
        "accepted_state_evidence_shape_oversize",
        :base
      },
      {
        "atom string alias",
        %{"position_km" => 1.0, position_km: 2.0},
        "atom_string_alias_collision",
        ".position_km"
      }
    ]

    for {_label, value, reason, expected_path} <- cases do
      accepted_state =
        %{}
        |> accepted_state_with_quality()
        |> Map.put("maneuver_execution_deltas", [Map.put(delta, "state_vector", value)])

      refresh = refresh_with_accepted_state(accepted_state)
      analysis = AcceptedStateEvidenceAuthority.analyze_refresh_wrapper(refresh)
      summary = analysis.evidence_authority
      artifact = build_artifact(refresh)
      artifact_summary = get_in(artifact, ["accepted_planning_state", "evidence_authority"])
      path = "$.accepted_planning_state.maneuver_execution_deltas[0].state_vector"

      assert reason in summary["review_reasons"]
      assert summary["accepted_state_encoding_projection_required"] == true
      assert analysis.build_encoding_outcome == :complete_projected_refresh
      assert analysis.analysis_cursor.overflow == false

      assert analysis.analysis_cursor.nodes <=
               AcceptedStateEvidenceAuthority.max_encoding_projection_nodes()

      assert artifact_summary == summary
      assert @review_warning in artifact["warnings"]

      assert_carrier_attack_removed(
        analysis.refresh,
        [
          "accepted_planning_state",
          "maneuver_execution_deltas",
          Access.at(0),
          "state_vector"
        ],
        refresh,
        expected_path
      )

      assert Enum.any?(summary["issues"], fn issue ->
               issue["reason"] == reason and
                 carrier_issue_path?(issue["path"], path, expected_path)
             end)
    end
  end

  test "public analyzer charges spacecraft and maneuver carrier rows on one cursor" do
    refresh = %{
      "accepted_planning_state" => %{
        "maneuver_execution_deltas" => [%{"state_vector" => fn -> :ok end}],
        "spacecraft_states" => [%{"state_vector" => fn -> :ok end}]
      }
    }

    analysis = AcceptedStateEvidenceAuthority.analyze_refresh_wrapper(refresh)
    summary = analysis.evidence_authority

    assert analysis.analysis_cursor == %{nodes: 8, overflow: false}
    assert analysis.build_encoding_outcome == :complete_projected_refresh
    assert summary["spacecraft_state_count"] == 1
    assert "unsupported_accepted_state_evidence_value" in summary["review_reasons"]

    assert_summary_issue(
      summary,
      "unsupported_accepted_state_evidence_value",
      "$.accepted_planning_state.spacecraft_states[0].state_vector"
    )

    assert_summary_issue(
      summary,
      "unsupported_accepted_state_evidence_value",
      "$.accepted_planning_state.maneuver_execution_deltas[0].state_vector"
    )
  end

  test "public analyzer and build mutation-lock hostile spacecraft-state values" do
    base_surface = build_artifact() |> decision_surface()
    base_path = "$.accepted_planning_state.spacecraft_states[0].state_vector"

    cases = [
      {
        "huge integer",
        9_007_199_254_740_992,
        "accepted_state_evidence_integer_oversize",
        base_path
      },
      {
        "tuple",
        {:hostile, "tuple"},
        "unsupported_accepted_state_evidence_value",
        base_path
      },
      {
        "struct",
        %HostileEvidenceStruct{value: "hostile"},
        "unsupported_accepted_state_evidence_atom_key",
        base_path <> ".unsupported_key"
      },
      {
        "invalid binary",
        <<255>>,
        "accepted_state_evidence_invalid_utf8",
        base_path
      },
      {
        "oversized binary",
        :binary.copy("a", 257),
        "accepted_state_evidence_binary_oversize",
        base_path
      },
      {
        "alias collision",
        %{"position_km" => 1.0, position_km: 2.0},
        "atom_string_alias_collision",
        base_path <> ".position_km"
      },
      {
        "depth",
        deep_map(10),
        "accepted_state_evidence_shape_deep",
        base_path <> ".nested.nested.nested.nested.nested"
      },
      {
        "width",
        add_root_noise(%{}, 65),
        "accepted_state_evidence_shape_oversize",
        base_path
      },
      {
        "improper list",
        [0.0, 1.0 | "tail"],
        "accepted_state_evidence_improper_list_shape",
        base_path
      },
      {
        "function",
        fn -> :ok end,
        "unsupported_accepted_state_evidence_value",
        base_path
      }
    ]

    for {_label, value, reason, path} <- cases do
      refresh =
        %{}
        |> accepted_state_with_quality()
        |> put_in(["spacecraft_states", Access.at(0), "state_vector"], value)
        |> refresh_with_accepted_state()

      analysis = AcceptedStateEvidenceAuthority.analyze_refresh_wrapper(refresh)
      summary = analysis.evidence_authority
      artifact = build_artifact(refresh)
      artifact_summary = get_in(artifact, ["accepted_planning_state", "evidence_authority"])

      assert_authority_denied_review(summary, reason, path)
      assert_summary_issue(artifact_summary, reason, path)
      assert artifact_summary == summary
      assert @review_warning in artifact["warnings"]
      assert decision_surface(artifact) == base_surface

      assert analysis.analysis_cursor.nodes <=
               AcceptedStateEvidenceAuthority.max_encoding_projection_nodes()

      refute analysis.refresh == refresh

      projected_value =
        get_in(analysis.refresh, [
          "accepted_planning_state",
          "spacecraft_states",
          Access.at(0),
          "state_vector"
        ])

      if reason in [
           "accepted_state_evidence_shape_deep",
           "atom_string_alias_collision",
           "unsupported_accepted_state_evidence_atom_key"
         ] do
        assert projected_value != value
      else
        refute projected_value
      end
    end
  end

  test "nil covariance containers remain absence-compatible through analyzer and build" do
    base_surface = build_artifact() |> decision_surface()

    refresh =
      %{
        "covariance_unit_contract" => nil,
        "covariance_frame_binding" => nil,
        "covariance_epoch_binding" => nil
      }
      |> accepted_state_with_quality()
      |> refresh_with_accepted_state()

    analysis = AcceptedStateEvidenceAuthority.analyze_refresh_wrapper(refresh)
    artifact = build_artifact(refresh)
    summary = get_in(artifact, ["accepted_planning_state", "evidence_authority"])

    assert analysis.evidence_authority["status"] == "clean"
    assert analysis.evidence_authority["review_reasons"] == []
    assert summary == analysis.evidence_authority
    refute @review_warning in artifact["warnings"]
    assert decision_surface(artifact) == base_surface
  end

  test "public analyzer charges nonempty covariance conflicts at the shared node boundary" do
    accepted_state = minimal_covariance_conflict_state()
    operational_feedback = operational_feedback_padding_tree([64, 64, 64, 64, 64, 64, 64, 34])

    ceiling_refresh =
      %{
        "accepted_planning_state" => accepted_state,
        "operational_feedback" => operational_feedback
      }
      |> add_root_noise(70)

    ceiling_projection = %{
      "accepted_planning_state" => accepted_state,
      "operational_feedback" => operational_feedback
    }

    ceiling_analysis = AcceptedStateEvidenceAuthority.analyze_refresh_wrapper(ceiling_refresh)
    ceiling_summary = ceiling_analysis.evidence_authority

    assert ceiling_analysis.analysis_cursor == %{nodes: 512, overflow: false}
    assert ceiling_analysis.build_encoding_outcome == :complete_projected_refresh
    assert ceiling_analysis.refresh == ceiling_projection

    assert_summary_issue(
      ceiling_summary,
      "covariance_epoch_conflict",
      "$.accepted_planning_state.provenance.covariance_epoch"
    )

    overflow_refresh =
      %{
        "accepted_planning_state" => Map.put(accepted_state, "source", %{}),
        "operational_feedback" => operational_feedback
      }
      |> add_root_noise(70)

    overflow_analysis = AcceptedStateEvidenceAuthority.analyze_refresh_wrapper(overflow_refresh)
    overflow_summary = overflow_analysis.evidence_authority

    assert overflow_analysis.analysis_cursor == %{nodes: 512, overflow: true}
    assert overflow_analysis.build_encoding_outcome == :whole_refresh_redaction
    assert overflow_analysis.refresh == refresh_encoding_redaction()
    assert "accepted_state_evidence_node_budget_exceeded" in overflow_summary["review_reasons"]
  end

  test "public analyzer keeps epoch and covariance semantics while projecting carriers" do
    stale_quality =
      valid_covariance_quality()
      |> put_in(["covariance_epoch_binding", "seconds_since_j2000"], 1.0)

    stale_analysis =
      stale_quality
      |> accepted_state_with_quality()
      |> refresh_with_accepted_state()
      |> AcceptedStateEvidenceAuthority.analyze_refresh_wrapper()

    stale_summary = stale_analysis.evidence_authority

    assert_summary_issue(
      stale_summary,
      "covariance_epoch_mismatch",
      "$.accepted_planning_state.spacecraft_states[0].quality.covariance_epoch_binding.seconds_since_j2000"
    )

    valid_analysis =
      valid_covariance_quality()
      |> accepted_state_with_quality()
      |> refresh_with_accepted_state()
      |> AcceptedStateEvidenceAuthority.analyze_refresh_wrapper()

    assert valid_analysis.evidence_authority["status"] == "clean"
    assert valid_analysis.evidence_authority["states_with_covariance_evidence_count"] == 1
    assert valid_analysis.build_encoding_outcome == :byte_preserve_raw_refresh
  end

  test "refresh projection preserves every declared source report collection" do
    clean_refresh =
      valid_covariance_quality()
      |> accepted_state_with_quality()
      |> refresh_with_only_accepted_state_inputs()
      |> put_refresh_consumer_surface()

    noisy_refresh = add_root_noise(clean_refresh, 70)
    clean_artifact = build_artifact(clean_refresh)
    noisy_artifact = build_artifact(noisy_refresh)
    summary = get_in(noisy_artifact, ["accepted_planning_state", "evidence_authority"])

    projected_refresh = BuildContext.refresh_for_build_encoding(noisy_refresh, summary)

    for field <- declared_source_report_collections() do
      assert Map.has_key?(projected_refresh, field)
    end

    assert get_in(noisy_artifact, ["provenance", "source_reports"]) ==
             get_in(clean_artifact, ["provenance", "source_reports"])

    assert decision_surface(noisy_artifact) == decision_surface(clean_artifact)
  end

  test "build validates present spacecraft state lists before accepted-state counts" do
    state = accepted_state_with_quality(%{})
    state_row = %{"spacecraft_id" => "leo_1", "scenario_id" => "scenario_1"}

    cases = [
      {"missing", Map.delete(state, "spacecraft_states"), nil, 0, nil},
      {"nil", Map.put(state, "spacecraft_states", nil), "invalid_spacecraft_states_shape", 0,
       "nil"},
      {"scalar", Map.put(state, "spacecraft_states", "bad"), "invalid_spacecraft_states_shape", 0,
       "bad"},
      {"proper", Map.put(state, "spacecraft_states", [state_row]), nil, 1, nil},
      {"proper max", Map.put(state, "spacecraft_states", List.duplicate(state_row, 128)), nil,
       128, nil},
      {"improper", Map.put(state, "spacecraft_states", [state_row | "tail"]),
       "invalid_spacecraft_states_shape", 0, nil},
      {"oversize", Map.put(state, "spacecraft_states", List.duplicate(state_row, 129)),
       "accepted_state_spacecraft_states_oversize", 0, "max_spacecraft_states_exceeded"}
    ]

    for {_label, accepted_state, reason, expected_count, detail} <- cases do
      artifact =
        accepted_state
        |> refresh_with_accepted_state()
        |> build_artifact()

      summary = get_in(artifact, ["accepted_planning_state", "evidence_authority"])

      assert get_in(artifact, ["accepted_planning_state", "spacecraft_state_count"]) ==
               expected_count

      if reason do
        path = "$.accepted_planning_state.spacecraft_states"
        assert_issue(artifact, reason, path)

        assert_summary_projection_action(summary, "accepted_planning_state", "delete", [
          "spacecraft_states"
        ])

        if detail do
          assert_summary_issue_detail(summary, reason, path, detail)
        end
      else
        refute reason in summary["review_reasons"]
      end
    end
  end

  test "build validates present maneuver execution delta lists before accepted-state counts" do
    state = accepted_state_with_quality(%{})
    delta = %{"id" => "delta_1", "spacecraft_id" => "leo_1"}

    cases = [
      {"missing", Map.delete(state, "maneuver_execution_deltas"), nil, 0, nil},
      {"nil", Map.put(state, "maneuver_execution_deltas", nil),
       "invalid_maneuver_execution_deltas_shape", 0, "nil"},
      {"scalar", Map.put(state, "maneuver_execution_deltas", "bad"),
       "invalid_maneuver_execution_deltas_shape", 0, "bad"},
      {"proper", Map.put(state, "maneuver_execution_deltas", [delta]), nil, 1, nil},
      {"proper max", Map.put(state, "maneuver_execution_deltas", List.duplicate(delta, 128)), nil,
       128, nil},
      {"improper", Map.put(state, "maneuver_execution_deltas", [delta | "tail"]),
       "invalid_maneuver_execution_deltas_shape", 0, nil},
      {"oversize", Map.put(state, "maneuver_execution_deltas", List.duplicate(delta, 129)),
       "accepted_state_maneuver_execution_deltas_oversize", 0,
       "max_maneuver_execution_deltas_exceeded"}
    ]

    for {_label, accepted_state, reason, expected_count, detail} <- cases do
      artifact =
        accepted_state
        |> refresh_with_accepted_state()
        |> build_artifact()

      summary = get_in(artifact, ["accepted_planning_state", "evidence_authority"])

      assert get_in(artifact, ["accepted_planning_state", "maneuver_execution_delta_count"]) ==
               expected_count

      if reason do
        path = "$.accepted_planning_state.maneuver_execution_deltas"
        assert_issue(artifact, reason, path)

        assert_summary_projection_action(summary, "accepted_planning_state", "delete", [
          "maneuver_execution_deltas"
        ])

        if detail do
          assert_summary_issue_detail(summary, reason, path, detail)
        end
      else
        refute reason in summary["review_reasons"]
      end
    end
  end

  test "classifies hostile terms within bounded public preflight" do
    cases = [
      {"pid", self(), "unsupported_accepted_state_evidence_value"},
      {"reference", make_ref(), "unsupported_accepted_state_evidence_value"},
      {"function", fn -> :ok end, "unsupported_accepted_state_evidence_value"},
      {"deep", deep_map(10), "accepted_state_evidence_shape_deep"},
      {"oversize", List.duplicate("component", 129), "accepted_state_evidence_shape_oversize"},
      {"invalid utf8", <<255>>, "accepted_state_evidence_invalid_utf8"},
      {"huge binary", :binary.copy("a", 257), "accepted_state_evidence_binary_oversize"},
      {"huge integer", 10_000_000_000_000_000_000, "accepted_state_evidence_integer_oversize"},
      {"improper", ["component" | "tail"], "accepted_state_evidence_improper_list_shape"}
    ]

    for {_label, value, reason} <- cases do
      summary =
        %{
          "covariance_status" => "metadata_only_no_propagation",
          "covariance_component_order" => value
        }
        |> accepted_state_with_quality()
        |> AcceptedStateEvidenceAuthority.from_accepted_state()

      assert summary["status"] == "review_required"
      assert reason in summary["review_reasons"]
      assert summary["decision_authority"] == "no_decision_authority"
      assert summary["covariance_authority"] == "metadata_only_not_consumed"
    end
  end

  test "classifies component-order short exact long and improper lists through public classifier" do
    path = "$.accepted_planning_state.spacecraft_states[0].quality.covariance_component_order"

    exact_summary =
      valid_covariance_quality()
      |> accepted_state_with_quality()
      |> AcceptedStateEvidenceAuthority.from_accepted_state()

    assert exact_summary["status"] == "clean"

    for values <- [
          Enum.take(component_order(), 5),
          component_order() ++ ["extra_component"],
          ["x_km" | "tail"]
        ] do
      summary =
        valid_covariance_quality()
        |> Map.put("covariance_component_order", values)
        |> accepted_state_with_quality()
        |> AcceptedStateEvidenceAuthority.from_accepted_state()

      assert_summary_issue(summary, "unsupported_covariance_component_order", path)
      assert summary["decision_authority"] == "no_decision_authority"
      assert summary["covariance_authority"] == "metadata_only_not_consumed"
    end
  end

  test "classifies covariance matrix outer-list short exact long and improper shapes" do
    path = "$.accepted_planning_state.spacecraft_states[0].quality.covariance_matrix_6x6"
    matrix = covariance_matrix()

    exact_summary =
      valid_covariance_quality()
      |> Map.put("covariance_matrix_6x6", matrix)
      |> accepted_state_with_quality()
      |> AcceptedStateEvidenceAuthority.from_accepted_state()

    assert exact_summary["status"] == "clean"

    for {value, detail} <- [
          {Enum.take(matrix, 5), "expected_6x6_numeric_matrix"},
          {matrix ++ [List.duplicate(0.0, 6)], "expected_6x6_numeric_matrix"},
          {[List.duplicate(0.0, 6) | "tail"], "expected_proper_6x6_numeric_matrix"}
        ] do
      summary =
        valid_covariance_quality()
        |> Map.put("covariance_matrix_6x6", value)
        |> accepted_state_with_quality()
        |> AcceptedStateEvidenceAuthority.from_accepted_state()

      assert_authority_denied_review(summary, "invalid_covariance_matrix_shape", path)
      assert_summary_issue_detail(summary, "invalid_covariance_matrix_shape", path, detail)
    end
  end

  test "classifies covariance matrix row-list short exact long and improper shapes" do
    matrix_path = "$.accepted_planning_state.spacecraft_states[0].quality.covariance_matrix_6x6"
    row_path = matrix_path <> "[0]"
    matrix = covariance_matrix()
    exact_row = List.duplicate(0.0, 6)

    exact_summary =
      valid_covariance_quality()
      |> Map.put("covariance_matrix_6x6", List.replace_at(matrix, 0, exact_row))
      |> accepted_state_with_quality()
      |> AcceptedStateEvidenceAuthority.from_accepted_state()

    assert exact_summary["status"] == "clean"

    for {row, detail} <- [
          {Enum.take(exact_row, 5), "expected_six_numeric_rows_with_six_numeric_values_each"},
          {exact_row ++ [0.0], "expected_six_numeric_rows_with_six_numeric_values_each"},
          {[0.0 | "tail"], "expected_six_numeric_rows_with_six_numeric_values_each"}
        ] do
      summary =
        valid_covariance_quality()
        |> Map.put("covariance_matrix_6x6", List.replace_at(matrix, 0, row))
        |> accepted_state_with_quality()
        |> AcceptedStateEvidenceAuthority.from_accepted_state()

      assert_authority_denied_review(summary, "invalid_covariance_matrix_shape", matrix_path)
      assert_summary_issue_detail(summary, "invalid_covariance_matrix_shape", matrix_path, detail)
    end

    improper_summary =
      valid_covariance_quality()
      |> Map.put("covariance_matrix_6x6", List.replace_at(matrix, 0, [0.0 | "tail"]))
      |> accepted_state_with_quality()
      |> AcceptedStateEvidenceAuthority.from_accepted_state()

    assert_summary_issue(
      improper_summary,
      "accepted_state_evidence_improper_list_shape",
      row_path
    )
  end

  test "detects outer and inner atom/string alias collisions before stringification" do
    base_surface = build_artifact() |> decision_surface()
    accepted_state = accepted_state_with_quality(valid_covariance_quality())

    atom_only_summary =
      refresh_request()
      |> Map.delete("accepted_planning_state")
      |> Map.put(:accepted_planning_state, atom_keyed_accepted_state())
      |> AcceptedStateEvidenceAuthority.from_refresh_wrapper()

    assert atom_only_summary["status"] == "clean"

    for present_value <- [nil, false] do
      invalid_summary =
        refresh_request()
        |> Map.put("accepted_planning_state", present_value)
        |> AcceptedStateEvidenceAuthority.from_refresh_wrapper()

      assert invalid_summary["status"] == "review_required"
      assert "invalid_accepted_state_shape" in invalid_summary["review_reasons"]
    end

    for refresh <- [
          refresh_request()
          |> Map.put("accepted_planning_state", accepted_state)
          |> Map.put(:accepted_planning_state, accepted_state),
          refresh_request()
          |> Map.put("accepted_planning_state", accepted_state)
          |> Map.put(
            :accepted_planning_state,
            accepted_state_with_quality(%{"quality" => "different"})
          )
        ] do
      summary = AcceptedStateEvidenceAuthority.from_refresh_wrapper(refresh)
      artifact = build_artifact(refresh)

      assert summary["status"] == "review_required"
      assert "atom_string_alias_collision" in summary["review_reasons"]
      assert get_in(artifact, ["accepted_planning_state", "evidence_authority"]) == summary
      assert @review_warning in artifact["warnings"]
      assert decision_surface(artifact) == base_surface
    end

    inner_equal_alias_summary =
      valid_covariance_quality()
      |> Map.put(:covariance_status, "matrix_imported_metadata_only_no_propagation")
      |> accepted_state_with_quality()
      |> AcceptedStateEvidenceAuthority.from_accepted_state()

    assert "atom_string_alias_collision" in inner_equal_alias_summary["review_reasons"]

    inner_conflicting_alias_summary =
      valid_covariance_quality()
      |> Map.put(:covariance_status, "flight_truth")
      |> accepted_state_with_quality()
      |> AcceptedStateEvidenceAuthority.from_accepted_state()

    assert "atom_string_alias_collision" in inner_conflicting_alias_summary["review_reasons"]

    wrong_key_summary =
      refresh_request()
      |> Map.put(123, "wrong key type")
      |> AcceptedStateEvidenceAuthority.from_refresh_wrapper()

    assert "unsupported_accepted_state_evidence_key" in wrong_key_summary["review_reasons"]
  end

  test "build handles accepted planning state wrapper collision without last-win collapse" do
    base_surface = build_artifact() |> decision_surface()

    absent_artifact =
      refresh_request()
      |> Map.delete("accepted_planning_state")
      |> build_artifact()

    string_state =
      valid_covariance_quality()
      |> accepted_state_with_quality()
      |> Map.put("snapshot_id", "string-state")
      |> Map.put("current_epoch_s", 100.0)

    atom_state =
      valid_covariance_quality()
      |> accepted_state_with_quality()
      |> Map.put("snapshot_id", "atom-state")
      |> Map.put("current_epoch_s", 200.0)

    refresh =
      refresh_request()
      |> Map.put("accepted_planning_state", string_state)
      |> Map.put(:accepted_planning_state, atom_state)

    summary = AcceptedStateEvidenceAuthority.from_refresh_wrapper(refresh)
    artifact = build_artifact(refresh)

    assert summary["status"] == "review_required"
    assert "atom_string_alias_collision" in summary["review_reasons"]

    assert_issue(
      artifact,
      "atom_string_alias_collision",
      "$.candidate_refresh.accepted_planning_state"
    )

    refute artifact["snapshot_id"] in ["string-state", "atom-state"]
    assert artifact["snapshot_id"] == absent_artifact["snapshot_id"]
    assert artifact["current_epoch_s"] == absent_artifact["current_epoch_s"]
    assert_handoff_preserves_review(artifact, "atom_string_alias_collision")
    assert decision_surface(artifact) == decision_surface(absent_artifact)
    assert decision_surface(artifact) == base_surface
  end

  test "detects refresh handoff loss without changing V3 recommendation authority" do
    artifact =
      valid_covariance_quality()
      |> accepted_state_with_quality()
      |> refresh_with_accepted_state()
      |> build_artifact()

    summary = get_in(artifact, ["accepted_planning_state", "evidence_authority"])

    assert RepairSourceReports.candidate_refresh_accepted_planning_state(artifact)[
             "evidence_authority"
           ] == summary

    lost =
      update_in(artifact, ["provenance", "accepted_planning_state"], fn provenance ->
        Map.delete(provenance, "evidence_authority")
      end)

    lost_summary = AcceptedStateEvidenceAuthority.candidate_refresh_handoff_summary(lost)

    assert "candidate_refresh_evidence_authority_summary_missing" in lost_summary[
             "review_reasons"
           ]

    mismatched =
      put_in(
        artifact,
        ["provenance", "accepted_planning_state", "evidence_authority", "status"],
        "review_required"
      )

    mismatch_summary =
      AcceptedStateEvidenceAuthority.candidate_refresh_handoff_summary(mismatched)

    assert "candidate_refresh_evidence_authority_summary_mismatch" in mismatch_summary[
             "review_reasons"
           ]

    clean_recommendation = recommendation_surface(summary)
    review_recommendation = recommendation_surface(mismatch_summary)

    assert clean_recommendation == review_recommendation
  end

  test "handoff preserves full review reasons beyond capped displayed issues" do
    hidden_reason = "accepted_state_evidence_improper_list_shape"

    displayed_issues =
      for index <- 1..50 do
        %{
          "reason" => "accepted_state_evidence_binary_oversize",
          "path" => "$.accepted_planning_state.noise_#{index}",
          "detail" => "accepted_state_evidence_binary_oversize"
        }
      end

    summary =
      clean_evidence_summary()
      |> Map.put("status", "review_required")
      |> Map.put("review_required", true)
      |> Map.put("review_reasons", ["accepted_state_evidence_binary_oversize", hidden_reason])
      |> Map.put("issue_count", 51)
      |> Map.put("issues", displayed_issues)
      |> Map.put("omitted_issue_count", 1)
      |> Map.put("accepted_state_encoding_projection_required", true)
      |> Map.put("accepted_state_encoding_projection_paths", [
        "$.accepted_planning_state.spacecraft_states[0].epoch.seconds_since_j2000"
      ])
      |> Map.put("build_encoding_projection_actions", [
        projection_action("accepted_planning_state", "delete", [
          "spacecraft_states",
          0,
          "epoch",
          "seconds_since_j2000"
        ])
      ])

    handoff_summary =
      summary
      |> artifact_with_evidence_summary()
      |> AcceptedStateEvidenceAuthority.candidate_refresh_handoff_summary()

    assert handoff_summary["status"] == "review_required"
    assert hidden_reason in handoff_summary["review_reasons"]
    assert "accepted_state_evidence_binary_oversize" in handoff_summary["review_reasons"]
    assert handoff_summary["accepted_state_encoding_projection_required"] == true

    assert "$.accepted_planning_state.spacecraft_states[0].epoch.seconds_since_j2000" in handoff_summary[
             "accepted_state_encoding_projection_paths"
           ]

    assert_summary_projection_action(
      handoff_summary,
      "accepted_planning_state",
      "delete",
      ["spacecraft_states", 0, "epoch", "seconds_since_j2000"]
    )

    refute Enum.any?(handoff_summary["issues"], fn issue ->
             issue["reason"] == hidden_reason
           end)
  end

  test "handoff fails closed for malformed legacy evidence summaries" do
    hidden_reason = "accepted_state_evidence_improper_list_shape"

    cases = [
      {
        "schema contract atom string collision",
        clean_evidence_summary()
        |> Map.put(:schema_contract, "forged_accepted_state_evidence_authority.v1"),
        "atom_string_alias_collision"
      },
      {
        "review reasons atom string collision",
        clean_evidence_summary()
        |> Map.put("review_reasons", [])
        |> Map.put(:review_reasons, [hidden_reason]),
        "atom_string_alias_collision"
      },
      {
        "issues atom string collision",
        clean_evidence_summary()
        |> Map.put("issues", [])
        |> Map.put(:issues, [
          %{
            "reason" => hidden_reason,
            "path" => "$.accepted_planning_state.spacecraft_states[0].epoch.seconds_since_j2000"
          }
        ]),
        "atom_string_alias_collision"
      },
      {
        "projection flag atom string collision",
        clean_evidence_summary()
        |> Map.put("accepted_state_encoding_projection_required", false)
        |> Map.put(:accepted_state_encoding_projection_required, true),
        "atom_string_alias_collision"
      },
      {
        "projection paths without structured actions",
        clean_evidence_summary()
        |> Map.put("status", "review_required")
        |> Map.put("review_required", true)
        |> Map.put("review_reasons", [hidden_reason])
        |> Map.put("accepted_state_encoding_projection_required", true)
        |> Map.put("accepted_state_encoding_projection_paths", [
          "$.accepted_planning_state.spacecraft_states[0].epoch.seconds_since_j2000"
        ])
        |> Map.put("build_encoding_projection_actions", []),
        "invalid_evidence_authority_projection_summary"
      },
      {
        "projection action atom string collision",
        clean_evidence_summary()
        |> Map.put("build_encoding_projection_actions", [])
        |> Map.put(:build_encoding_projection_actions, [
          projection_action("accepted_planning_state", "safe_project", [])
        ]),
        "atom_string_alias_collision"
      },
      {
        "malformed projection action segment",
        clean_evidence_summary()
        |> Map.put("build_encoding_projection_actions", [
          projection_action("accepted_planning_state", "delete", ["spacecraft_states", -1])
        ]),
        "invalid_evidence_authority_projection_actions_shape"
      },
      {
        "improper projection action segments",
        clean_evidence_summary()
        |> Map.put("build_encoding_projection_actions", [
          %{
            "scope" => "accepted_planning_state",
            "action" => "delete",
            "segments" => ["spacecraft_states" | "tail"]
          }
        ]),
        "invalid_evidence_authority_projection_actions_shape"
      },
      {
        "empty reason",
        clean_evidence_summary()
        |> Map.put("review_reasons", [""]),
        "invalid_evidence_authority_review_reasons_shape"
      },
      {
        "malformed reasons",
        clean_evidence_summary()
        |> Map.put("review_reasons", "not_a_list"),
        "invalid_evidence_authority_review_reasons_shape"
      },
      {
        "improper reasons",
        clean_evidence_summary()
        |> Map.put("review_reasons", ["legacy_review" | "tail"]),
        "invalid_evidence_authority_review_reasons_shape"
      },
      {
        "over cap reasons",
        clean_evidence_summary()
        |> Map.put("review_reasons", List.duplicate("legacy_review", 65)),
        "invalid_evidence_authority_review_reasons_shape"
      },
      {
        "unsafe reason beyond cap",
        clean_evidence_summary()
        |> Map.put(
          "review_reasons",
          List.duplicate("legacy_review", 64) ++ [hidden_reason]
        ),
        "invalid_evidence_authority_review_reasons_shape"
      },
      {
        "validated issues fallback",
        clean_evidence_summary()
        |> Map.delete("review_reasons")
        |> Map.put("issue_count", 1)
        |> Map.put("issues", [
          %{
            "reason" => hidden_reason,
            "path" => "$.accepted_planning_state.spacecraft_states[0].epoch.seconds_since_j2000"
          }
        ]),
        hidden_reason
      }
    ]

    for {_label, summary, reason} <- cases do
      handoff_summary =
        summary
        |> artifact_with_evidence_summary()
        |> AcceptedStateEvidenceAuthority.candidate_refresh_handoff_summary()

      assert handoff_summary["status"] == "review_required"
      assert reason in handoff_summary["review_reasons"]
      assert handoff_summary["decision_authority"] == "no_decision_authority"
      assert handoff_summary["covariance_authority"] == "metadata_only_not_consumed"
      assert handoff_summary["accepted_state_encoding_projection_required"] == true
      assert handoff_summary["build_encoding_projection_actions"] != []
    end
  end

  test "refresh encoding boundary validates malformed legacy summary members before build" do
    state_seconds_path =
      "$.accepted_planning_state.spacecraft_states[0].epoch.seconds_since_j2000"

    accepted_state =
      valid_covariance_quality()
      |> accepted_state_with_quality()
      |> put_state_epoch_seconds([2 | "tail"])

    malformed_summary =
      clean_evidence_summary()
      |> Map.put("status", "review_required")
      |> Map.put("review_required", true)
      |> Map.put("review_reasons", ["accepted_state_evidence_improper_list_shape"])
      |> Map.put("issues", [nil])
      |> Map.put("accepted_state_encoding_projection_required", false)
      |> Map.put("accepted_state_encoding_projection_paths", [])
      |> Map.put("build_encoding_projection_actions", [])

    path_alias_summary =
      clean_evidence_summary()
      |> Map.put("status", "review_required")
      |> Map.put("review_required", true)
      |> Map.put("review_reasons", ["accepted_state_evidence_improper_list_shape"])
      |> Map.put("issues", [
        %{
          "reason" => "accepted_state_evidence_improper_list_shape",
          "path" => state_seconds_path,
          :path => "$.accepted_planning_state.spacecraft_states[0].quality.covariance_epoch"
        }
      ])
      |> Map.put("accepted_state_encoding_projection_required", false)
      |> Map.put("accepted_state_encoding_projection_paths", [])
      |> Map.put("build_encoding_projection_actions", [])

    over_cap_reason_summary =
      clean_evidence_summary()
      |> Map.put("status", "review_required")
      |> Map.put("review_required", true)
      |> Map.put(
        "review_reasons",
        List.duplicate("legacy_review", 64) ++ ["accepted_state_evidence_improper_list_shape"]
      )
      |> Map.put("issues", [])
      |> Map.put("accepted_state_encoding_projection_required", false)
      |> Map.put("accepted_state_encoding_projection_paths", [])
      |> Map.put("build_encoding_projection_actions", [])

    incomplete_summary = %{"status" => "clean"}

    projected_refresh =
      accepted_state
      |> refresh_with_accepted_state()
      |> BuildContext.refresh_for_build_encoding(malformed_summary)

    refute get_in(projected_refresh, [
             "accepted_planning_state",
             "spacecraft_states",
             Access.at(0),
             "epoch",
             "seconds_since_j2000"
           ])

    for summary <- [path_alias_summary, over_cap_reason_summary, incomplete_summary] do
      projected_refresh =
        accepted_state
        |> refresh_with_accepted_state()
        |> BuildContext.refresh_for_build_encoding(summary)

      refute get_in(projected_refresh, [
               "accepted_planning_state",
               "spacecraft_states",
               Access.at(0),
               "epoch",
               "seconds_since_j2000"
             ])
    end

    artifact =
      accepted_state
      |> Map.put("evidence_authority", malformed_summary)
      |> refresh_with_accepted_state()
      |> build_artifact()

    assert_issue(artifact, "accepted_state_evidence_improper_list_shape", state_seconds_path)
    assert_issue(artifact, "invalid_state_epoch_seconds_shape", state_seconds_path)
    assert_handoff_preserves_review(artifact, "accepted_state_evidence_improper_list_shape")
    assert @review_warning in artifact["warnings"]
  end

  test "refresh encoding boundary fails closed for non-map roots and summaries" do
    state_seconds_path =
      "$.accepted_planning_state.spacecraft_states[0].epoch.seconds_since_j2000"

    unsafe_refresh =
      valid_covariance_quality()
      |> accepted_state_with_quality()
      |> put_state_epoch_seconds([2 | "tail"])
      |> refresh_with_accepted_state()

    for authority <- [
          nil,
          "not_a_summary",
          ["not_a_summary" | "tail"],
          clean_evidence_summary() |> add_root_noise(70)
        ] do
      projected_refresh = BuildContext.refresh_for_build_encoding(unsafe_refresh, authority)
      refute unsafe_epoch_seconds_present?(projected_refresh)
    end

    for refresh <- [nil, "not_a_refresh", ["not_a_refresh" | "tail"]] do
      artifact = build_artifact(refresh)

      assert_issue(artifact, "invalid_candidate_refresh_shape", "$.candidate_refresh")
      assert_handoff_preserves_review(artifact, "invalid_candidate_refresh_shape")
      assert @review_warning in artifact["warnings"]
    end

    oversized_refresh = refresh_request() |> add_root_noise(70)
    oversized_artifact = build_artifact(oversized_refresh)

    oversized_summary =
      get_in(oversized_artifact, ["accepted_planning_state", "evidence_authority"])

    assert "accepted_state_evidence_shape_oversize" in oversized_summary["review_reasons"]
    assert_summary_projection_action(oversized_summary, "candidate_refresh", "safe_project", [])

    artifact = build_artifact(unsafe_refresh)
    assert_issue(artifact, "accepted_state_evidence_improper_list_shape", state_seconds_path)
  end

  test "refresh encoding boundary recomputes authority before clean summary byte preservation" do
    unsafe_refresh =
      valid_covariance_quality()
      |> accepted_state_with_quality()
      |> put_state_epoch_seconds([2 | "tail"])
      |> refresh_with_accepted_state()

    function_refresh =
      refresh_request()
      |> Map.put("operational_feedback", fn -> :ok end)

    unrelated_clean_summary = clean_evidence_summary()

    unsafe_projection =
      BuildContext.refresh_for_build_encoding(unsafe_refresh, unrelated_clean_summary)

    function_projection =
      BuildContext.refresh_for_build_encoding(function_refresh, unrelated_clean_summary)

    assert BuildContext.refresh_for_build_encoding(
             ["not_a_refresh" | "tail"],
             unrelated_clean_summary
           ) ==
             refresh_encoding_redaction()

    assert BuildContext.refresh_for_build_encoding(fn -> :ok end, unrelated_clean_summary) ==
             refresh_encoding_redaction()

    refute unsafe_epoch_seconds_present?(unsafe_projection)
    refute Map.has_key?(function_projection, "operational_feedback")
  end

  defp build_artifact(refresh \\ refresh_request()) do
    result_set()
    |> CandidateRefresh.build(candidate_refresh: refresh, generated_at: @generated_at)
  end

  defp refresh_with_accepted_state(accepted_state) do
    Map.put(refresh_request(), "accepted_planning_state", accepted_state)
  end

  defp refresh_with_only_accepted_state_inputs(accepted_state) do
    refresh_request()
    |> Map.delete("current_epoch_s")
    |> Map.delete("remaining_horizon")
    |> Map.delete("targets")
    |> Map.delete("resource_summaries")
    |> Map.put("accepted_planning_state", accepted_state)
  end

  defp accepted_state_with_quality(quality, opts \\ []) do
    source = Keyword.get(opts, :source, %{"system" => "cadence"})

    refresh_request()
    |> Map.fetch!("accepted_planning_state")
    |> put_in(["spacecraft_states", Access.at(0), "epoch"], %{
      "seconds_since_j2000" => 0.0,
      "time_scale" => "tdb"
    })
    |> put_in(["spacecraft_states", Access.at(0), "frame"], "earth_inertial_j2000")
    |> put_in(["spacecraft_states", Access.at(0), "source"], source)
    |> put_in(["spacecraft_states", Access.at(0), "quality"], quality)
  end

  defp put_accepted_state_decision_fields(accepted_state) do
    accepted_state
    |> Map.put("current_epoch_s", 0.0)
    |> Map.put("remaining_horizon", %{
      "starts_at_s" => 0.0,
      "ends_at_s" => 600.0,
      "output_step_s" => 60.0
    })
    |> Map.put("targets", [%{"id" => "target_a", "priority" => 2.0}])
    |> Map.put("objectives", [
      %{
        "id" => "accepted-state-revisit",
        "type" => "target_revisit",
        "target_id" => "target_a",
        "required_observations" => 1.0
      }
    ])
    |> Map.put("ground_network", [
      %{
        "id" => "accepted_state_outage",
        "ground_station_id" => "equator_prime",
        "status" => "maintenance",
        "starts_at_s" => 280.0,
        "ends_at_s" => 450.0,
        "provenance" => %{"trust_boundary" => "accepted_ground_network_snapshot"}
      }
    ])
    |> Map.put("resource_summaries", [
      %{
        "spacecraft_id" => "leo_1",
        "fuel_margin" => 0.9,
        "storage_capacity_mb" => 1000.0,
        "storage_used_mb" => 200.0
      }
    ])
  end

  defp minimal_budget_accepted_state do
    %{
      "accepted_at" => "2026-05-14T00:00:00Z",
      "snapshot_id" => "ops-budget",
      "spacecraft_states" => []
    }
  end

  defp minimal_covariance_conflict_state do
    %{
      "accepted_at" => "2026-05-14T00:00:00Z",
      "snapshot_id" => "ops-budget",
      "quality" => %{
        "covariance_epoch" => "2000-01-01T12:00:00.000000Z",
        "covariance_epoch_binding" => valid_epoch_binding("2000-01-01T12:00:00.000000Z")
      },
      "provenance" => %{
        "covariance_epoch" => "2000-01-01T12:01:00.000000Z",
        "covariance_epoch_binding" => valid_epoch_binding("2000-01-01T12:01:00.000000Z")
      },
      "spacecraft_states" => []
    }
  end

  defp refresh_encoding_redaction do
    %{
      "accepted_planning_state" => %{
        "spacecraft_states" => [],
        "maneuver_execution_deltas" => []
      }
    }
  end

  defp put_accepted_state_consumer_surface(accepted_state) do
    accepted_state
    |> Map.put("operational_feedback", %{
      "trust_boundary" => "declared",
      "contact_success_rate" => %{"equator_prime" => 0.95}
    })
    |> Map.put("source_link_capacity_summary", link_capacity_summary("source"))
    |> Map.put("link_capacity_summary", link_capacity_summary("direct"))
    |> Map.put("source_relay_data_path_summary", relay_data_path_summary("source"))
    |> Map.put("relay_data_path_summary", relay_data_path_summary("direct"))
    |> put_source_report_collections()
    |> Map.put("source_timeline_feedback_reports", [
      %{
        "schema_contract" => "timeline_feedback_report.v1",
        "provenance" => %{"trust_boundary" => "declared"},
        "operational_feedback" => %{
          "trust_boundary" => "declared",
          "contact_success_rate" => %{"equator_prime" => 0.95}
        }
      }
    ])
    |> Map.put("source_resource_projection_reports", [
      %{
        "schema_contract" => "resource_projection_report.v1",
        "provenance" => %{"trust_boundary" => "declared"},
        "resource_pressure_rows" => []
      }
    ])
  end

  defp put_refresh_consumer_surface(refresh) do
    refresh
    |> Map.put("objectives", [
      %{
        "id" => "refresh-revisit",
        "type" => "target_revisit",
        "target_id" => "target_a",
        "required_observations" => 1.0
      }
    ])
    |> Map.put("operational_feedback", %{
      "trust_boundary" => "declared",
      "contact_success_rate" => %{"equator_prime" => 0.95}
    })
    |> Map.put("source_link_capacity_summary", link_capacity_summary("source"))
    |> Map.put("link_capacity_summary", link_capacity_summary("direct"))
    |> Map.put("source_relay_data_path_summary", relay_data_path_summary("source"))
    |> Map.put("relay_data_path_summary", relay_data_path_summary("direct"))
    |> Map.put("candidate_refresh_request_source_report_summary", %{
      "source_reports" => %{
        "link_capacity_report" => %{
          "contract" => "link_capacity_summary.v1",
          "count" => 1,
          "row_count" => 1,
          "trust_boundary_status" => "declared"
        }
      }
    })
    |> Map.put("source_reports", %{
      "relay_data_path_report" => %{
        "contract" => "relay_data_path_summary.v1",
        "count" => 1,
        "row_count" => 1,
        "trust_boundary_status" => "declared",
        "paths" => ["relay_data_path_summary"]
      }
    })
    |> put_source_report_collections()
    |> Map.put("source_timeline_feedback_reports", [
      %{
        "schema_contract" => "timeline_feedback_report.v1",
        "provenance" => %{"trust_boundary" => "declared"},
        "operational_feedback" => %{
          "trust_boundary" => "declared",
          "contact_success_rate" => %{"equator_prime" => 0.95}
        }
      }
    ])
    |> Map.put("source_resource_projection_reports", [
      %{
        "schema_contract" => "resource_projection_report.v1",
        "provenance" => %{"trust_boundary" => "declared"},
        "resource_pressure_rows" => []
      }
    ])
  end

  defp put_source_report_collections(refresh) do
    Enum.reduce(declared_source_report_collections(), refresh, fn field, acc ->
      Map.put_new(acc, field, [])
    end)
  end

  defp declared_source_report_collections do
    ~w(
	      source_candidate_diff_reports
	      source_candidate_rejection_reports
	      source_command_window_reports
	      source_constraint_reports
	      source_contact_allocation_reports
	      source_contact_contention_reports
	      source_contact_contention_resolution_reports
	      source_contact_filter_reports
	      source_contact_intents
	      source_freshness_reports
	      source_link_capacity_reports
	      source_maneuver_review_reports
	      source_model_acceptance_reports
	      source_objective_satisfaction_reports
	      source_objective_tradeoff_reports
	      source_operational_readiness_reports
	      source_operational_timeline_reports
	      source_provider_counteroffer_reports
	      source_quality_gate_reports
	      source_refresh_budget_reports
	      source_resource_filter_reports
	      source_resource_projection_reports
	      source_schema_validation_reports
	      source_score_term_reports
	      source_station_calendar_reports
	      source_station_reservation_reports
	      source_timeline_activity_lifecycle_states
	      source_timeline_activity_precondition_summaries
	      source_timeline_activity_states
	      source_timeline_dependency_impact_summaries
	      source_timeline_diff_reports
	      source_timeline_feedback_reports
	      source_timeline_integrity_reports
	      source_timeline_lifecycle_state_summaries
	      source_timeline_publication_summaries
	      source_timeline_transition_application_reports
	      source_validation_safety_case_summaries
	    )
  end

  defp link_capacity_summary(source) do
    %{
      "schema_contract" => "link_capacity_summary.v1",
      "source" => source,
      "spacecraft_id" => "leo_1",
      "ground_station_id" => "equator_prime",
      "capacity_bps" => 1_000_000.0
    }
  end

  defp relay_data_path_summary(source) do
    %{
      "schema_contract" => "relay_data_path_summary.v1",
      "source" => source,
      "spacecraft_id" => "leo_1",
      "relay_path" => ["leo_1", "equator_prime"]
    }
  end

  defp unsafe_epoch_seconds_present?(%{
         "accepted_planning_state" => %{
           "spacecraft_states" => [
             %{"epoch" => %{"seconds_since_j2000" => [_head | _tail]}} | _rest
           ]
         }
       }),
       do: true

  defp unsafe_epoch_seconds_present?(_refresh), do: false

  defp put_state_container(accepted_state, key, value) do
    put_in(accepted_state, ["spacecraft_states", Access.at(0), key], value)
  end

  defp put_state_epoch_seconds(accepted_state, value) do
    put_in(
      accepted_state,
      ["spacecraft_states", Access.at(0), "epoch", "seconds_since_j2000"],
      value
    )
  end

  defp delete_state_epoch_seconds(accepted_state) do
    update_in(accepted_state, ["spacecraft_states", Access.at(0), "epoch"], fn epoch ->
      Map.delete(epoch, "seconds_since_j2000")
    end)
  end

  defp add_oversize_binary_evidence_noise(accepted_state, count) do
    Enum.reduce(1..count, accepted_state, fn index, state ->
      key = "aaa_oversize_binary_#{index}"
      Map.put(state, key, :binary.copy("a", 257))
    end)
  end

  defp add_root_noise(accepted_state, count) do
    Enum.reduce(1..count, accepted_state, fn index, state ->
      Map.put(state, "noise_#{index}", "ignored")
    end)
  end

  defp add_alphabetic_root_noise(refresh, count) do
    Enum.reduce(1..count, refresh, fn index, acc ->
      Map.put(acc, "aaa_noise_#{index}", "ignored")
    end)
  end

  defp delete_quality_keys(accepted_state, keys) do
    update_in(accepted_state, ["spacecraft_states", Access.at(0), "quality"], fn quality ->
      Enum.reduce(keys, quality, fn key, acc -> Map.delete(acc, key) end)
    end)
  end

  defp atom_keyed_accepted_state do
    %{
      snapshot_id: "ops-state-1",
      accepted_at: "2026-05-14T00:00:00Z",
      spacecraft_states: [
        %{
          spacecraft_id: "sat_1",
          scenario_id: "leo_1",
          source: %{system: "cadence"},
          quality: %{level: "accepted"},
          provenance: %{created_by: "test"}
        }
      ],
      maneuver_execution_deltas: [],
      source: %{system: "cadence"},
      quality: %{level: "accepted"},
      provenance: %{created_by: "test"}
    }
  end

  defp valid_covariance_quality do
    matrix =
      for row <- 0..5 do
        for column <- 0..5 do
          if row == column, do: 1.0e-6, else: 0.0
        end
      end

    %{
      "covariance_reference_frame" => "EME2000",
      "covariance_epoch" => "2000-01-01T12:00:00.000000Z",
      "covariance_status" => "matrix_imported_metadata_only_no_propagation",
      "covariance_component_order" => component_order(),
      "covariance_matrix_6x6" => matrix,
      "covariance_unit_contract" => valid_unit_contract(),
      "covariance_frame_binding" => valid_frame_binding(),
      "covariance_epoch_binding" => valid_epoch_binding(),
      "covariance_numerical_check" => valid_numerical_check(),
      "covariance_propagation_status" => "metadata_only_not_propagated"
    }
  end

  defp valid_numerical_check do
    %{
      "name" => "normalized_principal_minors_nonnegative_relative_symmetric_6x6_bounded_float",
      "claim" => "deterministic_normalized_principal_minor_support_check_not_external_validation",
      "status" => "passed"
    }
  end

  defp valid_covariance_metadata do
    Map.delete(valid_covariance_quality(), "covariance_matrix_6x6")
  end

  defp covariance_matrix do
    Map.fetch!(valid_covariance_quality(), "covariance_matrix_6x6")
  end

  defp valid_unit_contract(declaration \\ "explicit_ccsds_units") do
    %{
      "declaration" => declaration,
      "component_order" => component_order(),
      "position_position" => "km**2",
      "position_velocity" => "km**2/s",
      "velocity_velocity" => "km**2/s**2",
      "mixed_unit_declarations" => false
    }
  end

  defp valid_frame_binding(ref_frame \\ "EME2000") do
    %{
      "source_ref_frame" => ref_frame,
      "covariance_ref_frame" => ref_frame,
      "accepted_state_frame" => "earth_inertial_j2000",
      "conversion_applied" => false,
      "matched" => true
    }
  end

  defp valid_epoch_binding(epoch \\ "2000-01-01T12:00:00.000000Z") do
    %{
      "state_epoch" => epoch,
      "covariance_epoch" => epoch,
      "time_scale" => "utc",
      "matched" => true,
      "seconds_since_j2000" => 0.0
    }
  end

  defp component_order do
    [
      "x_km",
      "y_km",
      "z_km",
      "x_dot_km_s",
      "y_dot_km_s",
      "z_dot_km_s"
    ]
  end

  defp covariance_quality_state(path, value) do
    valid_covariance_quality()
    |> put_in(path, value)
    |> accepted_state_with_quality()
  end

  defp covariance_quality_state(path, key, value) do
    valid_covariance_quality()
    |> put_in(path ++ [key], value)
    |> accepted_state_with_quality()
  end

  defp forged_authority_state do
    valid_covariance_quality()
    |> accepted_state_with_quality(
      source: %{
        "content_identity" => %{
          "sha256" => "d8f8a0d01099c2034a5a8d66f90e6ef92a8a7f7f861d83f4d8198e9b46a74a01",
          "authority" => "authenticated"
        }
      }
    )
  end

  defp clean_evidence_summary do
    %{}
    |> accepted_state_with_quality()
    |> AcceptedStateEvidenceAuthority.from_accepted_state()
  end

  defp artifact_with_evidence_summary(summary) do
    %{
      "schema_contract" => "candidate_refresh.v1",
      "artifact_type" => "candidate_refresh",
      "accepted_planning_state" => %{"evidence_authority" => summary},
      "provenance" => %{
        "accepted_planning_state" => %{"evidence_authority" => summary}
      }
    }
  end

  defp assert_issue(artifact, reason, path) do
    summary = get_in(artifact, ["accepted_planning_state", "evidence_authority"])

    assert summary["status"] == "review_required"
    assert reason in summary["review_reasons"]

    assert Enum.any?(summary["issues"], fn issue ->
             issue["reason"] == reason and issue["path"] == path
           end)

    assert get_in(artifact, ["provenance", "accepted_planning_state", "evidence_authority"]) ==
             summary
  end

  defp assert_issue_detail(artifact, reason, path, detail) do
    artifact
    |> get_in(["accepted_planning_state", "evidence_authority"])
    |> assert_summary_issue_detail(reason, path, detail)
  end

  defp assert_summary_issue(summary, reason, path) do
    assert summary["status"] == "review_required"
    assert reason in summary["review_reasons"]

    assert Enum.any?(summary["issues"], fn issue ->
             issue["reason"] == reason and issue["path"] == path
           end)
  end

  defp assert_authority_denied_review(summary, reason, path) do
    assert_summary_issue(summary, reason, path)
    assert summary["decision_authority"] == "no_decision_authority"
    assert summary["covariance_authority"] == "metadata_only_not_consumed"
  end

  defp assert_summary_issue_detail(summary, reason, path, detail) do
    assert Enum.any?(summary["issues"], fn issue ->
             issue["reason"] == reason and issue["path"] == path and issue["detail"] == detail
           end)
  end

  defp assert_summary_projection_action(summary, scope, action, segments) do
    actions = Map.fetch!(summary, "build_encoding_projection_actions")
    assert %{"scope" => scope, "action" => action, "segments" => segments} in actions
  end

  defp assert_carrier_attack_removed(
         projected_refresh,
         carrier_path,
         raw_refresh,
         ".position_km"
       ) do
    refute get_in(projected_refresh, carrier_path ++ ["position_km"])
    assert projected_refresh != raw_refresh
  end

  defp assert_carrier_attack_removed(projected_refresh, carrier_path, raw_refresh, :nested) do
    assert projected_refresh != raw_refresh
    refute deep_leaf_present?(get_in(projected_refresh, carrier_path))
  end

  defp assert_carrier_attack_removed(projected_refresh, carrier_path, _raw_refresh, :base) do
    refute get_in(projected_refresh, carrier_path)
  end

  defp carrier_issue_path?(path, base_path, :base), do: path == base_path

  defp carrier_issue_path?(path, base_path, :nested),
    do: String.starts_with?(path, base_path <> ".")

  defp carrier_issue_path?(path, base_path, suffix) when is_binary(suffix),
    do: path == base_path <> suffix

  defp deep_leaf_present?(%{"nested" => value}), do: deep_leaf_present?(value)
  defp deep_leaf_present?("leaf"), do: true
  defp deep_leaf_present?(_value), do: false

  defp projection_action(scope, action, segments) do
    %{"scope" => scope, "action" => action, "segments" => segments}
  end

  defp refute_summary_issue(summary, reason, path) do
    refute Enum.any?(summary["issues"], fn issue ->
             issue["reason"] == reason and issue["path"] == path
           end)
  end

  defp assert_freeform_epoch_review(quality) do
    summary =
      quality
      |> accepted_state_with_quality()
      |> AcceptedStateEvidenceAuthority.from_accepted_state()

    assert summary["status"] == "review_required"

    artifact =
      quality
      |> accepted_state_with_quality()
      |> refresh_with_accepted_state()
      |> build_artifact()

    assert @review_warning in artifact["warnings"]
    {summary, artifact}
  end

  defp assert_handoff_issue(artifact, reason, path) do
    summary = get_in(artifact, ["accepted_planning_state", "evidence_authority"])
    handoff_summary = AcceptedStateEvidenceAuthority.candidate_refresh_handoff_summary(artifact)

    assert RepairSourceReports.candidate_refresh_accepted_planning_state(artifact)[
             "evidence_authority"
           ] == summary

    assert handoff_summary["status"] == "review_required"
    assert reason in handoff_summary["review_reasons"]

    assert Enum.any?(handoff_summary["issues"], fn issue ->
             issue["reason"] == reason and issue["path"] == path
           end)

    assert recommendation_surface(summary) == recommendation_surface(handoff_summary)
  end

  defp assert_handoff_preserves_review(artifact, reason) do
    summary = get_in(artifact, ["accepted_planning_state", "evidence_authority"])

    assert RepairSourceReports.candidate_refresh_accepted_planning_state(artifact)[
             "evidence_authority"
           ] == summary

    handoff_summary = AcceptedStateEvidenceAuthority.candidate_refresh_handoff_summary(artifact)
    assert handoff_summary["status"] == "review_required"
    assert reason in handoff_summary["review_reasons"]
    assert recommendation_surface(summary) == recommendation_surface(handoff_summary)
  end

  defp decision_surface(artifact) do
    Map.take(artifact, [
      "assumptions",
      "current_epoch_s",
      "remaining_horizon",
      "refreshed_windows",
      "candidate_activities",
      "contact_intents",
      "contact_filter_report",
      "contact_allocation_report",
      "resource_filter_report",
      "refresh_budget_report",
      "candidate_diff_report",
      "invalidated_candidates",
      "source_window_lineage"
    ])
  end

  defp recommendation_surface(evidence_summary) do
    recommendation =
      [
        branch("recommended", 20.0, evidence_summary),
        branch("baseline", 10.0, %{})
      ]
      |> StrategyRecommendationBuilder.build()

    %{
      recommended_branch_id: recommendation.recommended_branch_id,
      ranked_branch_ids: recommendation.ranked_branch_ids,
      approval_status: recommendation.approval_status,
      eligibility_status: recommendation.eligibility_status,
      authority_context: recommendation.authority_context,
      authority_context_evaluation: recommendation.authority_context_evaluation
    }
  end

  defp branch(id, score, evidence_summary) do
    %PlanBranch{
      id: id,
      repair_result: %{
        "source_candidate_refresh_accepted_planning_state" => %{
          "evidence_authority" => evidence_summary
        }
      },
      score: score,
      score_terms: %{
        "mission_value_score" => score,
        "schedule_stability_penalty" => 0.0
      },
      approval_status: "auto_approvable",
      policy_decision: %{
        "eligibility_status" => "eligible",
        "authority_context" => "campaign_strategy_policy",
        "authority_context_evaluation" => %{"status" => "eligible"}
      }
    }
  end

  defp deep_map(0), do: "leaf"
  defp deep_map(depth), do: %{"nested" => deep_map(depth - 1)}

  defp node_budget_noise do
    Enum.reduce(1..64, %{}, fn index, acc ->
      Map.put(acc, "node_#{index}", List.duplicate(%{"leaf" => "value"}, 8))
    end)
  end

  defp cursor_consuming_approval_policy do
    %{
      "mode" => "strict",
      "filters" =>
        for index <- 1..128 do
          %{
            "id" => "approval_filter_#{index}",
            "type" => "resource",
            "status" => "enabled",
            "priority" => index
          }
        end
    }
  end

  defp operational_feedback_budget_tree(:spanning_ceiling),
    do: operational_feedback_budget_tree(57)

  defp operational_feedback_budget_tree(:ceiling), do: operational_feedback_budget_tree(57)
  defp operational_feedback_budget_tree(:overflow), do: operational_feedback_budget_tree(58)
  defp operational_feedback_budget_tree(:edge_absent), do: operational_feedback_budget_tree(nil)

  defp operational_feedback_budget_tree(edge_count) do
    tree = %{
      "blur_score" => dynamic_feedback_values("target_blur", 63, 0.2),
      "cloud_cover_fraction" => dynamic_feedback_values("target_cloud", 63, 0.1),
      "command_success_rate" => dynamic_feedback_values("command_station", 63, 0.97),
      "contact_success_rate" => dynamic_feedback_values("contact_station", 63, 0.95),
      "image_quality_score" => dynamic_feedback_values("target_quality", 63, 0.8),
      "maneuver_success_rate" => dynamic_feedback_values("maneuver", 63, 0.98),
      "observation_success_rate" => dynamic_feedback_values("target_observation", 63, 0.9)
    }

    case edge_count do
      nil ->
        tree

      count ->
        Map.put(
          tree,
          "station_throughput_factor",
          dynamic_feedback_values("equator_prime_edge", count, 0.96)
        )
    end
  end

  defp dynamic_feedback_values(prefix, count, value) do
    Enum.reduce(1..count, %{}, fn index, acc ->
      Map.put(acc, "#{prefix}_#{index}", value)
    end)
  end

  defp operational_feedback_padding_tree(counts) do
    fields = ~w(
      blur_score
      cloud_cover_fraction
      command_success_rate
      contact_success_rate
      image_quality_score
      maneuver_success_rate
      observation_success_rate
      station_throughput_factor
    )

    fields
    |> Enum.zip(counts)
    |> Enum.reduce(%{}, fn {field, count}, acc ->
      Map.put(acc, field, dynamic_feedback_values(field, count, 0.5))
    end)
  end
end
