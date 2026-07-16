defmodule OrbitalDynamics.Schema.ValidationDiagnosticContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [expect_one_of: 5, expect_optional_type: 5, expect_type: 5, require_fields: 4]

  def validate_issue(issues, path, issue) do
    issues
    |> require_fields(path, issue, ["severity", "path", "message"])
    |> expect_one_of(path, issue, "severity", ["error", "warning"])
    |> expect_type(path, issue, "path", :binary)
    |> expect_type(path, issue, "message", :binary)
    |> expect_optional_type(path, issue, "remediation", :binary)
    |> expect_optional_type(path, issue, "schema_contract", :binary)
    |> expect_optional_type(path, issue, "artifact_path", :binary)
  end

  def validate_remediation(issues, path, remediation) do
    issues
    |> require_fields(path, remediation, [
      "path",
      "category",
      "action",
      "source_message"
    ])
    |> expect_type(path, remediation, "path", :binary)
    |> expect_type(path, remediation, "category", :binary)
    |> expect_type(path, remediation, "action", :binary)
    |> expect_type(path, remediation, "source_message", :binary)
  end
end
