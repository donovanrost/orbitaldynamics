# Level 5 Workflow

This is the checked operator/developer path for producing the current V1 study,
V2 rolling-repair, and V3 strategy artifacts. It composes existing public Mix
tasks; it does not add a CLI, write to Cadence, or refresh checked fixtures.

Run the workflow from the repository root. Replace `${OUTPUT_ROOT}` with one
new empty directory outside the checkout, then invoke each `task` with its
`argv` in listed order. The `--format json` summaries and output artifacts are
machine-readable. V1 pins the run ID and generated timestamp in argv. V2 and V3
do not expose run-ID or timestamp flags; their generated timestamps are pinned
by the checked request inputs.

The fenced block is the source of truth consumed by the focused workflow test.

<!-- level5-workflow-index:begin -->
```json
{
  "index_contract": "orbital_dynamics.level5_workflow.v1",
  "index_version": 1,
  "level": 5,
  "execution": {
    "order": [
      "v1_study_run",
      "v2_campaign_repair",
      "v3_campaign_strategy"
    ],
    "mode": "synchronous_in_caller",
    "output_root": "${OUTPUT_ROOT}",
    "checked_fixtures_mutated": false
  },
  "documentation_links": [
    {
      "source": "README.md",
      "href": "docs/feature_set/level5_workflow.md"
    },
    {
      "source": "docs/feature_set/README.md",
      "href": "level5_workflow.md"
    },
    {
      "source": "docs/feature_set/capability_map/21_developer_and_user_experience.md",
      "href": "../level5_workflow.md"
    }
  ],
  "capability_discovery": {
    "task": "orbital_dynamics.capabilities",
    "argv": [
      "--format",
      "json"
    ],
    "expected": {
      "schema_contract": "capability_catalog.v1",
      "schema_version": 1,
      "artifact_contract_count": 127,
      "compatibility_policy_version": 1,
      "identity_policy_version": 1,
      "required_artifact_contracts": [
        "result_artifact.v1",
        "campaign_repair.v2",
        "campaign_strategy.v3",
        "cadence_import_manifest.v1"
      ]
    },
    "failure": {
      "diagnostic": "capability or policy version differs from this index",
      "remediation": "Review the compatibility change and update this checked index and its focused test together."
    }
  },
  "schema_registry": {
    "task": "orbital_dynamics.schema.export",
    "argv": [
      "--all",
      "--output",
      "${OUTPUT_ROOT}/orbital_dynamics.schema_bundle.v1.json"
    ],
    "compatibility_policy_version": 1,
    "identity_policy_version": 1,
    "artifact_contracts": [
      {
        "contract": "result_artifact.v1",
        "schema_version": 1
      },
      {
        "contract": "campaign_repair.v2",
        "schema_version": 2
      },
      {
        "contract": "campaign_strategy.v3",
        "schema_version": 3
      },
      {
        "contract": "cadence_import_manifest.v1",
        "schema_version": 1
      }
    ],
    "failure": {
      "diagnostic": "expected output contract or schema policy version is unavailable",
      "remediation": "Run the schema export command into a temporary output and review compatibility before changing a pinned contract or version."
    }
  },
  "study_manifest_schema": {
    "task": "orbital_dynamics.manifest.schema.export",
    "argv": [
      "--output",
      "${OUTPUT_ROOT}/study_manifest.v1.schema.json"
    ],
    "contract": "study_manifest.v1",
    "schema_version": 1
  },
  "workflows": [
    {
      "id": "v1_study_run",
      "level_surface": "V1 study.run",
      "task": "orbital_dynamics.study.run",
      "argv": [
        "--manifest",
        "studies/leo_access_demo.json",
        "--output",
        "${OUTPUT_ROOT}/v1_study_result.json",
        "--run-id",
        "level5-workflow-v1",
        "--generated-at",
        "2026-05-14T00:00:00Z",
        "--format",
        "json"
      ],
      "output": "${OUTPUT_ROOT}/v1_study_result.json",
      "inputs": [
        {
          "role": "study_manifest",
          "path": "studies/leo_access_demo.json",
          "validation_contract": "study_manifest.v1",
          "schema_version": 1
        }
      ],
      "determinism": {
        "run_id": {
          "source": "argv",
          "value": "level5-workflow-v1"
        },
        "generated_at": {
          "source": "argv",
          "value": "2026-05-14T00:00:00Z"
        }
      },
      "expected_output": {
        "validation_contract": "result_artifact.v1",
        "schema_version": 1,
        "assertions": [
          {
            "path": ["study_id"],
            "value": "leo_access_demo"
          },
          {
            "path": ["run", "id"],
            "value": "level5-workflow-v1"
          },
          {
            "path": ["run", "metadata", "manifest", "path"],
            "value": "studies/leo_access_demo.json"
          },
          {
            "path": ["generated_at"],
            "value": "2026-05-14T00:00:00Z"
          },
          {
            "path": ["errors"],
            "value": []
          }
        ],
        "summary_assertions": [
          {
            "path": ["study"],
            "value": "leo_access_demo"
          },
          {
            "path": ["run_id"],
            "value": "level5-workflow-v1"
          },
          {
            "path": ["generated_at"],
            "value": "2026-05-14T00:00:00Z"
          },
          {
            "path": ["error_count"],
            "value": 0
          }
        ]
      },
      "failure": {
        "diagnostic": "invalid study manifest",
        "remediation": "Restore studies/leo_access_demo.json and run mix orbital_dynamics.manifest.lint --manifest studies/leo_access_demo.json before retrying."
      }
    },
    {
      "id": "v2_campaign_repair",
      "level_surface": "V2 campaign.run repair",
      "campaign_type": "repair",
      "task": "orbital_dynamics.campaign.run",
      "argv": [
        "--type",
        "repair",
        "--request",
        "studies/leo_constellation_campaign_repair_v2.json",
        "--output",
        "${OUTPUT_ROOT}/v2_campaign_repair.json",
        "--format",
        "json"
      ],
      "output": "${OUTPUT_ROOT}/v2_campaign_repair.json",
      "inputs": [
        {
          "role": "campaign_request",
          "path": "studies/leo_constellation_campaign_repair_v2.json",
          "request_type": "campaign_plan_repair",
          "schema_version": 1
        },
        {
          "role": "source_plan",
          "path": "study_results/leo_constellation_campaign.json",
          "artifact_key": "campaign_plan",
          "validation_contract": "campaign_plan.v1",
          "schema_version": 1
        }
      ],
      "determinism": {
        "run_id": {
          "supported": false,
          "reason": "campaign.run does not expose a run-id option"
        },
        "generated_at": {
          "source": "request",
          "value": "2026-05-14T20:23:00Z"
        }
      },
      "expected_output": {
        "validation_contract": "campaign_repair.v2",
        "schema_version": 2,
        "assertions": [
          {
            "path": ["planner"],
            "value": "OrbitalDynamics.CampaignPlanner.V2"
          },
          {
            "path": ["source_plan_id"],
            "value": "campaign_plan:leo_constellation_campaign:2026-05-14T00:00:00Z"
          },
          {
            "path": ["generated_at"],
            "value": "2026-05-14T20:23:00Z"
          }
        ],
        "summary_assertions": [
          {
            "path": ["type"],
            "value": "repair"
          },
          {
            "path": ["schema_contract"],
            "value": "campaign_repair.v2"
          },
          {
            "path": ["status"],
            "value": "pass"
          }
        ]
      },
      "failure": {
        "diagnostic": "source_plan_ref.path does not exist",
        "exception": "campaign request lint failed",
        "remediation": "Restore the pinned source_plan_ref.path study_results/leo_constellation_campaign.json, then run mix orbital_dynamics.campaign.lint --type repair --request studies/leo_constellation_campaign_repair_v2.json before retrying."
      }
    },
    {
      "id": "v3_campaign_strategy",
      "level_surface": "V3 campaign.run strategy",
      "campaign_type": "strategy",
      "task": "orbital_dynamics.campaign.run",
      "argv": [
        "--type",
        "strategy",
        "--request",
        "studies/leo_constellation_campaign_strategy_v3.json",
        "--output",
        "${OUTPUT_ROOT}/v3_campaign_strategy.json",
        "--format",
        "json"
      ],
      "output": "${OUTPUT_ROOT}/v3_campaign_strategy.json",
      "inputs": [
        {
          "role": "campaign_request",
          "path": "studies/leo_constellation_campaign_strategy_v3.json",
          "request_type": "campaign_strategy_v3",
          "schema_version": 1
        },
        {
          "role": "source_plan",
          "path": "study_results/leo_constellation_campaign.json",
          "artifact_key": "campaign_plan",
          "validation_contract": "campaign_plan.v1",
          "schema_version": 1
        }
      ],
      "determinism": {
        "run_id": {
          "supported": false,
          "reason": "campaign.run does not expose a run-id option"
        },
        "generated_at": {
          "source": "request",
          "value": "2026-05-14T20:23:00Z"
        }
      },
      "expected_output": {
        "validation_contract": "campaign_strategy.v3",
        "schema_version": 3,
        "assertions": [
          {
            "path": ["planner"],
            "value": "OrbitalDynamics.CampaignPlanner.V3"
          },
          {
            "path": ["strategy_metadata", "strategy_id"],
            "value": "f1551dff11d98e6f008b7f4a2c75db9194cd24289ebea02117eab052bc194bf9"
          },
          {
            "path": ["source_plan_id"],
            "value": "campaign_plan:leo_constellation_campaign:2026-05-14T00:00:00Z"
          },
          {
            "path": ["generated_at"],
            "value": "2026-05-14T20:23:00Z"
          },
          {
            "path": ["cadence_import_manifest", "schema_contract"],
            "value": "cadence_import_manifest.v1"
          }
        ],
        "summary_assertions": [
          {
            "path": ["type"],
            "value": "strategy"
          },
          {
            "path": ["schema_contract"],
            "value": "campaign_strategy.v3"
          },
          {
            "path": ["status"],
            "value": "pass"
          }
        ]
      },
      "failure": {
        "diagnostic": "source_plan_ref.path does not exist",
        "remediation": "Restore the pinned source_plan_ref.path study_results/leo_constellation_campaign.json, then run mix orbital_dynamics.campaign.lint --type strategy --request studies/leo_constellation_campaign_strategy_v3.json before retrying."
      }
    }
  ]
}
```
<!-- level5-workflow-index:end -->

The schema exports are compatibility views; executable Elixir validators remain
the semantic source of truth. A capability or schema-version mismatch is a
compatibility review, not an instruction to rewrite generated schemas in place.
Campaign outputs are artifact-only handoffs. Use
`OrbitalDynamics.CadenceImport.dry_run/3` with an explicit no-write adapter for
consumer conformance; this workflow does not approve or import anything.
