defmodule OrbitalDynamics.Schema.ValidationDiagnosticContracts do
  @moduledoc false

  def validate_issue(issues, path, issue, callbacks) when is_list(callbacks) do
    issues
    |> require_fields(callbacks, path, issue, ["severity", "path", "message"])
    |> expect_one_of(callbacks, path, issue, "severity", ["error", "warning"])
    |> expect_type(callbacks, path, issue, "path", :binary)
    |> expect_type(callbacks, path, issue, "message", :binary)
    |> expect_optional_type(callbacks, path, issue, "remediation", :binary)
    |> expect_optional_type(callbacks, path, issue, "schema_contract", :binary)
    |> expect_optional_type(callbacks, path, issue, "artifact_path", :binary)
  end

  def validate_remediation(issues, path, remediation, callbacks) when is_list(callbacks) do
    issues
    |> require_fields(callbacks, path, remediation, [
      "path",
      "category",
      "action",
      "source_message"
    ])
    |> expect_type(callbacks, path, remediation, "path", :binary)
    |> expect_type(callbacks, path, remediation, "category", :binary)
    |> expect_type(callbacks, path, remediation, "action", :binary)
    |> expect_type(callbacks, path, remediation, "source_message", :binary)
  end

  defp require_fields(issues, callbacks, path, map, fields),
    do: apply(Keyword.fetch!(callbacks, :require_fields), [issues, path, map, fields])

  defp expect_one_of(issues, callbacks, path, map, field, allowed),
    do: apply(Keyword.fetch!(callbacks, :expect_one_of), [issues, path, map, field, allowed])

  defp expect_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_type), [issues, path, map, field, type])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_optional_type), [issues, path, map, field, type])
end
