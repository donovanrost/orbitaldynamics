defmodule OrbitalDynamics.Schema.ValidationJsonSchema do
  @moduledoc false

  def execution_failure(stable_id_pattern) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => ["scenario_id", "stage", "error"],
      "properties" => %{
        "scenario_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "stage" => %{"type" => "string"},
        "error" => %{}
      }
    }
  end

  def issue do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => ["severity", "path", "message"],
      "properties" => %{
        "severity" => %{"type" => "string", "enum" => ["error", "warning"]},
        "path" => %{"type" => "string"},
        "message" => %{"type" => "string"}
      }
    }
  end

  def manifest_lint_issue do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => ["code", "path", "message", "details"],
      "properties" => %{
        "code" => %{"type" => "string"},
        "path" => %{"type" => "string"},
        "message" => %{"type" => "string"},
        "details" => %{"type" => "object"}
      }
    }
  end

  def remediation do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => ["path", "category", "action", "source_message"],
      "properties" => %{
        "path" => %{"type" => "string"},
        "category" => %{"type" => "string"},
        "action" => %{"type" => "string"},
        "source_message" => %{"type" => "string"}
      }
    }
  end

  def model_limits(model_limits) do
    %{
      "type" => "array",
      "const" => model_limits,
      "items" => %{
        "type" => "string",
        "enum" => model_limits
      }
    }
  end

  def batch_entry(report_schema) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => ["path", "report"],
      "properties" => %{
        "path" => %{"type" => "string"},
        "report" => report_schema
      }
    }
  end

  def migration_row do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "schema_contract",
        "artifact_family",
        "schema_version",
        "status",
        "migration_action",
        "required_field_count",
        "optional_field_count",
        "nested_contract_count"
      ],
      "properties" => %{
        "schema_contract" => %{"type" => "string"},
        "artifact_family" => %{"type" => "string"},
        "schema_version" => %{"type" => "integer", "minimum" => 0},
        "status" => %{
          "type" => "string",
          "enum" => OrbitalDynamics.Validation.capabilities().schema_migration_row_statuses
        },
        "migration_action" => %{
          "type" => "string",
          "enum" => OrbitalDynamics.Validation.capabilities().schema_migration_actions
        },
        "replacement_contract" => %{"type" => "string"},
        "required_field_count" => %{"type" => "integer", "minimum" => 0},
        "optional_field_count" => %{"type" => "integer", "minimum" => 0},
        "nested_contract_count" => %{"type" => "integer", "minimum" => 0},
        "deprecation_warning" => %{"type" => "string"}
      }
    }
  end

  def skipped_artifact do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => ["path", "reason"],
      "properties" => %{
        "path" => %{"type" => "string"},
        "reason" => %{"type" => "string"}
      }
    }
  end

  def record(stable_id_pattern, validation_level_schema) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" => %{
        "id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "model" => %{"type" => "string"},
        "implementation" => %{"type" => "string"},
        "validation_level" => validation_level_schema,
        "covered_regime" => %{"type" => "string"},
        "evidence" => string_array_schema(),
        "known_limits" => string_array_schema(),
        "tolerances" => %{"type" => "object", "additionalProperties" => true}
      },
      "allOf" => registry_conditions(stable_id_pattern)
    }
  end

  def registry_conditions(stable_id_pattern) do
    OrbitalDynamics.Validation.registry()
    |> Map.values()
    |> Enum.sort_by(& &1["id"])
    |> Enum.map(fn %{"id" => id, "model" => model, "known_limits" => limits} ->
      %{
        "if" => %{"properties" => %{"id" => stable_id_const(id, stable_id_pattern)}},
        "then" => %{
          "properties" => %{
            "model" => %{"const" => model},
            "known_limits" => %{"const" => limits}
          }
        }
      }
    end)
  end

  def model_acceptance_row(stable_id_pattern, validation_record_schema) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => ["id", "rank", "model_id", "validation_level", "status", "reason"],
      "properties" => %{
        "id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "rank" => %{"type" => "integer", "minimum" => 0},
        "model_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "implementation" => %{"type" => "string"},
        "validation_level" => %{"type" => "string"},
        "status" => %{
          "type" => "string",
          "enum" => OrbitalDynamics.Validation.capabilities().row_statuses
        },
        "reason" => %{"type" => "string"},
        "validation_record" => validation_record_schema
      }
    }
  end

  def safety_case_evidence_row(stable_id_pattern) do
    count_properties =
      [
        "rank",
        "model_accepted_count",
        "model_review_required_count",
        "model_blocked_count",
        "unknown_model_count",
        "readiness_review_required_count",
        "readiness_blocked_count",
        "ready_for_import_count",
        "quality_gate_review_count",
        "quality_gate_blocked_count",
        "schema_error_count",
        "schema_warning_count",
        "schema_validation_report_count",
        "schema_validation_failed_report_count",
        "fixture_passed_count",
        "fixture_failed_count"
      ]
      |> Map.new(&{&1, %{"type" => "integer", "minimum" => 0}})

    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => ["schema_contract", "status", "rank", "evidence_ref"],
      "properties" =>
        Map.merge(count_properties, %{
          "schema_contract" => %{"type" => "string"},
          "status" => %{
            "type" => "string",
            "enum" => OrbitalDynamics.Validation.capabilities().safety_case_statuses
          },
          "evidence_ref" => %{"type" => "string", "pattern" => stable_id_pattern},
          "report_id" => %{"type" => "string", "pattern" => stable_id_pattern},
          "source_readiness_report_id" => %{
            "type" => "string",
            "pattern" => stable_id_pattern
          },
          "artifact_path" => %{"type" => "string"},
          "validated_contract" => %{"type" => "string"},
          "input_dir" => %{"type" => "string"},
          "validation_mode" => %{"type" => "string"},
          "intended_use" => %{"type" => "string"},
          "readiness_level" => %{"type" => "string"},
          "import_classification" => %{"type" => "string"}
        })
    }
  end

  def reference_report(stable_id_pattern, validation_level_schema, validation_check_schema) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "schema_contract",
        "fixture_id",
        "model_id",
        "validation_level",
        "status",
        "checks"
      ],
      "properties" => %{
        "schema_contract" => %{
          "type" => "string",
          "const" => "validation_reference_report.v1"
        },
        "fixture_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "model_id" => %{"type" => "string"},
        "validation_level" => validation_level_schema,
        "status" => %{"type" => "string", "enum" => ["pass", "fail"]},
        "status_counts" => enum_count_map_schema(["pass", "fail"]),
        "checks" => %{
          "type" => "array",
          "items" => validation_check_schema
        }
      }
    }
  end

  def reference_fixture_report_property("reports", opts) do
    %{
      "type" => "array",
      "items" => Keyword.fetch!(opts, :reference_report_schema)
    }
  end

  def reference_fixture_report_property("schema_contract", opts) do
    schema_contract = Keyword.fetch!(opts, :schema_contract)

    %{
      "type" => "string",
      "const" => schema_contract,
      "description" => "Stable executable contract identifier"
    }
  end

  def reference_fixture_report_property("status", _opts) do
    %{"type" => "string"}
  end

  def reference_fixture_report_property("fixture_count", _opts) do
    %{"type" => "integer", "minimum" => 0}
  end

  def reference_fixture_report_property("status_counts", _opts) do
    enum_count_map_schema(["pass", "fail"])
  end

  def reference_report_property("checks", opts) do
    %{
      "type" => "array",
      "items" => Keyword.fetch!(opts, :validation_check_schema)
    }
  end

  def reference_report_property("schema_contract", opts) do
    schema_contract = Keyword.fetch!(opts, :schema_contract)

    %{
      "type" => "string",
      "const" => schema_contract,
      "description" => "Stable executable contract identifier"
    }
  end

  def reference_report_property(field, opts) when field in ["fixture_id", "model_id"] do
    %{"type" => "string", "pattern" => Keyword.fetch!(opts, :stable_id_pattern)}
  end

  def reference_report_property("status_counts", _opts) do
    enum_count_map_schema(["pass", "fail"])
  end

  def reference_report_property("status", _opts) do
    %{"type" => "string", "enum" => ["pass", "fail"]}
  end

  def reference_report_property("validation_level", opts) do
    Keyword.fetch!(opts, :validation_level_schema)
  end

  def record_property("validation_level", opts) do
    Keyword.fetch!(opts, :validation_level_schema)
  end

  def record_property("schema_contract", opts) do
    schema_contract = Keyword.fetch!(opts, :schema_contract)

    %{
      "type" => "string",
      "const" => schema_contract,
      "description" => "Stable executable contract identifier"
    }
  end

  def record_property("id", opts) do
    %{"type" => "string", "pattern" => Keyword.fetch!(opts, :stable_id_pattern)}
  end

  def record_property("model", _opts) do
    %{"type" => "string"}
  end

  def record_property(field, _opts) when field in ["implementation", "covered_regime"] do
    %{"type" => "object"}
  end

  def record_property(field, _opts) when field in ["evidence", "known_limits"] do
    string_array_schema()
  end

  def record_property("tolerances", _opts) do
    %{"type" => "object", "additionalProperties" => true}
  end

  def check_property("schema_contract", opts) do
    schema_contract = Keyword.fetch!(opts, :schema_contract)

    %{
      "type" => "string",
      "const" => schema_contract,
      "description" => "Stable executable contract identifier"
    }
  end

  def check_property(field, _opts) when field in ["expected", "observed"] do
    %{}
  end

  def check_property("field", _opts) do
    %{"type" => "string"}
  end

  def check_property("tolerance", _opts) do
    %{"type" => ["number", "string"]}
  end

  def check_property(field, _opts) when field in ["error", "max_abs_error"] do
    %{"type" => "number"}
  end

  def check_property("status", _opts) do
    %{"type" => "string", "enum" => ["pass", "fail"]}
  end

  def check do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => ["field", "status", "expected", "observed", "tolerance"],
      "properties" => %{
        "field" => %{"type" => "string"},
        "status" => %{"type" => "string", "enum" => ["pass", "fail"]},
        "expected" => %{},
        "observed" => %{},
        "tolerance" => %{"type" => ["number", "string"]},
        "error" => %{"type" => "number"},
        "max_abs_error" => %{"type" => "number"}
      }
    }
  end

  defp stable_id_const(id, stable_id_pattern) do
    %{"type" => "string", "pattern" => stable_id_pattern, "const" => id}
  end

  defp enum_count_map_schema(values) do
    %{
      "type" => "object",
      "propertyNames" => %{"enum" => values},
      "additionalProperties" => %{"type" => "integer", "minimum" => 0}
    }
  end

  defp string_array_schema do
    %{"type" => "array", "items" => %{"type" => "string"}}
  end
end
