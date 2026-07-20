defmodule OrbitalDynamics.OperationalReadiness.AdapterBoundaryGate do
  @moduledoc false

  def build(evidence) do
    cond do
      evidence["adapter_trust_boundary_untrusted_count"] > 0 ->
        gate(
          "blocked",
          "blocked",
          "adapter import context declares untrusted trust-boundary evidence",
          context(evidence)
        )

      evidence["adapter_trust_boundary_missing_count"] > 0 ->
        gate(
          "review_required",
          "review_only",
          "adapter import context is missing a declared trust boundary",
          context(evidence)
        )

      evidence["adapter_context_count"] > 0 ->
        gate(
          "passed",
          "importable",
          "adapter import context declares trust boundary evidence",
          context(evidence)
        )

      true ->
        gate(
          "passed",
          "importable",
          "no adapter-specific import boundary context was declared",
          %{}
        )
    end
  end

  def context(evidence) do
    %{
      "adapter_context_count" => evidence["adapter_context_count"],
      "adapter_trust_boundary_declared_count" =>
        evidence["adapter_trust_boundary_declared_count"],
      "adapter_trust_boundary_missing_count" => evidence["adapter_trust_boundary_missing_count"],
      "adapter_trust_boundary_untrusted_count" =>
        evidence["adapter_trust_boundary_untrusted_count"],
      "adapter_boundary_status_counts" => evidence["adapter_boundary_status_counts"]
    }
  end

  defp gate(status, classification, reason, context) do
    %{
      "id" => "adapter_boundary",
      "status" => status,
      "classification" => classification,
      "reason" => reason
    }
    |> Map.merge(context)
  end
end
