defmodule OrbitalDynamics.CadenceImport.Adapter do
  @moduledoc """
  Minimal read-only contract for Cadence consumer conformance adapters.

  Implementations expose only a capability declaration and a dry-run
  evaluation callback. The capability declaration must be exactly:

      %{
        "contract" => "cadence_consumer_dry_run_adapter.v1",
        "operations" => ["dry_run"],
        "writes" => false
      }

  `dry_run/2` receives a validated request and a bounded string-key options map
  containing at most 2,048 entries. It must return an acknowledgement that
  copies the request's source identity, immutable authority evidence, manifest
  digest, and idempotency identity. There is deliberately no create, update,
  write, or mutation callback. The callback runs synchronously in the caller
  process; this conformance boundary does not provide adapter timeout or
  process isolation, so callers must supply a trusted adapter implementation.
  """

  @type request :: %{required(String.t()) => term()}
  @type adapter_options :: %{optional(String.t()) => term()}
  @type acknowledgement :: %{required(String.t()) => term()}
  @type adapter_error :: term()

  @callback capabilities() :: map()

  @callback dry_run(request(), adapter_options()) ::
              {:ok, acknowledgement()} | {:error, adapter_error()}
end
