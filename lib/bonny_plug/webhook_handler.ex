defmodule BonnyPlug.WebhookHandler do
  @moduledoc """
  This module dispatches the admission webhook requests to the handlers. You can `use` this module in your webhook
  handler to connect it to the Plug.

  ## Options

  When `use`-ing this module, you have to tell it about the resource you want to act upon:

  ### Custom Resource Definition

  * `crd` - If you have a CRD YAML file, just pass the path to the file as option `crd`. The `WebhookHandler` will extract the required values from the file.

  ### Explicit Resource Specification

  The `WebhookHandler` needs to know the following values from the resource you want to act upon:

  * `group` - The group of the resource, e.g. `"apps"`
  * `plural` - The plural name of the resource, e.g. `"deployments"`
  * `api_versions` - A list of versions of the resource, e.g. `["v1beta1", "v1"]`

  ## Functions to be implemented in your Webhook Handler

  Your webhook handler should implement at least one of the two functions `validating_webhook/1` and
  `mutating_webhook/1`. These are going to be called by this module depending on whether the incoming request is of
  type `:validating_webhook` or `:mutating_webhook` according to the `BonnyPlug.WebhookPlug` configuration.

  ## Examples

    defmodule FooAdmissionWebhookHandler do
      use BonnyPlug.WebhookHandler, crd: "manifest/src/crds/foo.crd.yaml"

      @impl true
      def validating_webhook(admission_review)  do
        check_immutable(admission_review, ["spec", "someField"])
      end

      @impl true
      def mutating_webhook(admission_review)  do
        allow(admission_review)
      end
    end

    defmodule BarAdmissionWebhookHandler do
      use BonnyPlug.WebhookHandler,
        group: "my.operator.com",
        resource: "barresources",
        api_versions: ["v1"]

      @impl true
      def validating_webhook(admission_review)  do
        check_immutable(admission_review, ["spec", "someField"])
      end

      @impl true
      def mutating_webhook(admission_review)  do
        deny(admission_review)
      end
    end
  """

  require Logger

  alias BonnyPlug.{AdmissionReview, WebhookPlug}

  @callback process(AdmissionReview.t(), WebhookPlug.webhook_type()) :: AdmissionReview.t()
  @callback mutating_webhook(AdmissionReview.t()) :: AdmissionReview.t()
  @callback validating_webhook(AdmissionReview.t()) :: AdmissionReview.t()
  @optional_callbacks mutating_webhook: 1, validating_webhook: 1

  @type webhook_type :: :mutating_webhook | :validating_webhook

  defmacro __using__(opts) do
    [group: group, plural: plural, api_versions: api_versions] = case opts do
      [crd: crd] -> read_crd(crd)
      [group: _, plural: _, api_versions: _] = bindings -> bindings
      _ -> raise(ArgumentError, "Wrong usage of BonnyPlug.WebhookHandler. You have to pass either `crd: \"path-to-crd.yaml\"` or all three of `group`, `plural` and `api_verions` when using BonnyPlug.WebhookHandler")
    end

    quote bind_quoted: [group: group, plural: plural, api_versions: api_versions] do
      import BonnyPlug.AdmissionReview.Request

      @behaviour BonnyPlug.WebhookHandler

      @group group
      @plural plural
      @api_versions api_versions

      @impl true
      @spec process(AdmissionReview.t(), WebhookPlug.webhook_type()) :: AdmissionReview.t()
      def process(
            %AdmissionReview{request: %{"resource" => %{"group" => @group, "version" => version, "resource" => @plural}}} = admission_review,
            webhook_type
          ) when webhook_type in [:validating_webhook, :mutating_webhook] and version in @api_versions do

        if function_exported?(__MODULE__, webhook_type, 1) do
          Kernel.apply(__MODULE__, webhook_type, [admission_review])
        else
          admission_review
        end
      end

      def process(admission_review, _), do: admission_review
    end
  end

  defp read_crd(path_to_crd) do
    crd = case YamlElixir.read_from_file(path_to_crd) do
      {:ok, crd} -> crd
      {:error, %YamlElixir.FileNotFoundError{message: error}} ->
        raise(ArgumentError, "Wrong usage of BonnyPlug.WebhookHandler. The CRD you passed was not found: " <> error)
      {:error, %YamlElixir.ParsingError{message: error}} ->
        raise(ArgumentError, "Wrong usage of BonnyPlug.WebhookHandler. The CRD YAML file you passed could not be parsed: " <> error)
    end
    api_versions = derive_api_versions(crd)

    [
      group: get_in(crd, ~w(spec group)),
      plural: get_in(crd, ~w(spec names plural)),
      api_versions: api_versions,
    ]
  end

  defp derive_api_versions(%{"spec" => %{"versions" => versions}}) do
      versions
      |> Enum.filter(&(&1["served"] == true))
      |> Enum.map(&Map.fetch!(&1, "name"))
  end
  defp derive_api_versions(%{"spec" => %{"version" => version}}), do: [version]
  defp derive_api_versions(_), do: raise(ArgumentError, "CRD version not supported. Currently only CRD versions v1 and v1beta1 are supported.")
end
