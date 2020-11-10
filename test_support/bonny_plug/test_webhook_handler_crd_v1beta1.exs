defmodule BonnyPlug.TestWebhookHandlerCRDV1Beta1 do
  use BonnyPlug.WebhookHandler, crd: "test_support/crds/test_crd_v1beta1.yaml"

  @spec validating_webhook(BonnyPlug.AdmissionReview.t()) :: BonnyPlug.AdmissionReview.t()
  @impl true
  def validating_webhook(admission_review)  do
    Map.update!(admission_review, :response, &Map.put(&1, "allowed", false))
  end
end
