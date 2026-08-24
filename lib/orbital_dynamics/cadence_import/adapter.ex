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
  write, or mutation callback.

  `CadenceImport.dry_run/3` preserves the original trusted-adapter behavior and
  runs callbacks synchronously in the caller process.
  `CadenceImport.bounded_dry_run/4` instead runs `capabilities/0` and `dry_run/2`
  in monitored workers under one caller-supplied monotonic deadline. Each
  callback has a separate controller monitoring the original caller and direct
  worker plus an independent guardian that reaps the worker after caller
  cancellation or controller shutdown. Cleanup uses an untrappable kill and
  drains the direct worker and monitor messages before lifecycle termination.

  The bounded path contains only the direct callback process lifecycle. An
  adapter is ordinary BEAM code: this behavior is not a malicious-code sandbox,
  cannot guarantee containment of descendant processes (including descendants
  that trap exits) or ambient side effects, grants no write authority, supplies
  no live Cadence client, and does not prove acceptance by a downstream
  consumer.
  """

  @type request :: %{required(String.t()) => term()}
  @type adapter_options :: %{optional(String.t()) => term()}
  @type acknowledgement :: %{required(String.t()) => term()}
  @type adapter_error :: term()

  @callback capabilities() :: map()

  @callback dry_run(request(), adapter_options()) ::
              {:ok, acknowledgement()} | {:error, adapter_error()}
end
