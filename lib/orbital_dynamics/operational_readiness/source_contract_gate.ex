defmodule OrbitalDynamics.OperationalReadiness.SourceContractGate do
  @moduledoc false

  def build(nil) do
    gate(
      "blocked",
      "blocked",
      "source artifact type could not be inferred"
    )
  end

  def build(_source_artifact_type) do
    gate(
      "passed",
      "importable",
      "source artifact type is declared"
    )
  end

  defp gate(status, classification, reason) do
    %{
      "id" => "source_contract",
      "status" => status,
      "classification" => classification,
      "reason" => reason
    }
  end
end
