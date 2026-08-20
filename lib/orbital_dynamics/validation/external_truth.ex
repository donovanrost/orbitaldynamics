defmodule OrbitalDynamics.Validation.ExternalTruth do
  @moduledoc """
  Standalone registry for content-bound external numerical truth cases.

  This registry is intentionally separate from the curated internal fixture
  rollup. A registration promotes only its exact declared model combination.
  """

  alias OrbitalDynamics.Validation.ExternalTruth.{OrekitJ2DragEnvelope, OrekitLeoCase}

  @doc "Returns all exact external-truth registrations in stable ID order."
  def all do
    [OrekitJ2DragEnvelope.registration(), OrekitLeoCase.registration()]
    |> Enum.sort_by(& &1["id"])
  end

  @doc "Fetches one exact external-truth registration."
  def fetch(id) when is_binary(id) do
    Enum.find_value(all(), :error, fn registration ->
      if registration["id"] == id, do: {:ok, registration}
    end)
  end

  def fetch(_id), do: :error

  @doc "Executes the registered case's content and numerical verifier."
  def verify(id, opts \\ [])

  def verify(id, opts) when is_binary(id) and is_list(opts) do
    case fetch(id) do
      {:ok, %{"implementation" => implementation}} -> verify_implementation(implementation, opts)
      :error -> {:error, {:unknown_external_truth_case, id}}
    end
  end

  def verify(id, _opts), do: {:error, {:invalid_external_truth_verifier_options, id}}

  defp verify_implementation(
         "OrbitalDynamics.Validation.ExternalTruth.OrekitLeoCase",
         opts
       ),
       do: OrekitLeoCase.verify(opts)

  defp verify_implementation(
         "OrbitalDynamics.Validation.ExternalTruth.OrekitJ2DragEnvelope",
         opts
       ),
       do: OrekitJ2DragEnvelope.verify(opts)
end
