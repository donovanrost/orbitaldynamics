defmodule OrbitalDynamics.Schema.ArtifactValidation do
  @moduledoc false

  alias OrbitalDynamics.Schema.Inference

  def validate(%{} = artifact, opts, contracts, callbacks)
      when is_list(opts) and is_map(contracts) and is_list(callbacks) do
    requested_contract = Inference.contract_name_from_opts(opts)
    contract_fun = Keyword.fetch!(callbacks, :contract)
    error_fun = Keyword.fetch!(callbacks, :error)
    validate_contract_fun = Keyword.fetch!(callbacks, :validate_contract)

    with {:ok, contract_name, artifact} <-
           Inference.artifact_for_validation(artifact, opts, contracts),
         {:ok, contract} <- contract_fun.(contract_name) do
      issues = validate_contract_fun.(contract_name, contract, artifact)
      errors = Enum.filter(issues, &(&1["severity"] == "error"))
      warnings = Enum.filter(issues, &(&1["severity"] == "warning"))

      report = %{
        "schema_contract" => contract_name,
        "artifact_family" => contract["artifact_family"],
        "schema_version" => contract["schema_version"],
        "status" => if(errors == [], do: "pass", else: "fail"),
        "errors" => errors,
        "warnings" => warnings
      }

      if errors == [], do: {:ok, report}, else: {:error, report}
    else
      {:error, reason} ->
        {:error, failure_report(requested_contract, error_fun.("$", reason))}

      :error ->
        {:error,
         failure_report(
           requested_contract,
           error_fun.("$", "unknown schema contract: #{requested_contract || "not declared"}")
         )}
    end
  end

  defp failure_report(requested_contract, error) do
    %{
      "schema_contract" => requested_contract,
      "artifact_family" => nil,
      "schema_version" => nil,
      "status" => "fail",
      "errors" => [error],
      "warnings" => []
    }
  end
end
