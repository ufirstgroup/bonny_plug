defmodule BonnyPlug.WebhookHandlerTest do
  use ExUnit.Case

  alias BonnyPlug.{
    AdmissionReview,
    TestWebhookHandlerCRD,
    TestWebhookHandlerCRDV1Beta1,
    TestWebhookHandlerResource
  }

  import CompileTimeAssertions

  describe "__usage__/1" do
    test "Raises an ArgumentError if nothing passed as option" do
      assert_compile_time_raise(ArgumentError, "You have to pass either", fn ->
        use BonnyPlug.WebhookHandler
      end)
    end

    test "Raises an ArgumentError if CRD is not found" do
      assert_compile_time_raise(ArgumentError, "was not found", fn ->
        use BonnyPlug.WebhookHandler, crd: "test_support/crds/inexistent.yaml"
      end)
    end

    test "Raises an ArgumentError if invalid YAML passed as option" do
      assert_compile_time_raise(ArgumentError, "could not be parsed", fn ->
        use BonnyPlug.WebhookHandler, crd: "test_support/crds/invalid.yaml"
      end)
    end

    test "Raises an ArgumentError if CRD version is not supported" do
      assert_compile_time_raise(ArgumentError, "CRD version not supported.", fn ->
        use BonnyPlug.WebhookHandler, crd: "test_support/crds/unsupported_crd.yaml"
      end)
    end
  end

  describe "process/2" do
    test "processes a request if CRD matches" do
      Application.put_env(:bonny_plug, :admission_review_webhooks, [TestWebhookHandlerCRD])

      admission_review = %AdmissionReview{
        request: %{
          "uid" => "some_uid",
          "resource" => %{
            "group" => "bonny-plug.ufirst.io",
            "version" => "v1",
            "resource" => "testcrds"
          }
        },
        response: %{}
      }

      admission_review = TestWebhookHandlerCRD.process(admission_review, :validating_webhook)
      assert false == admission_review.response["allowed"]
    end

    test "processes a request if CRD v1beta1 matches" do
      Application.put_env(:bonny_plug, :admission_review_webhooks, [TestWebhookHandlerCRDV1Beta1])

      admission_review = %AdmissionReview{
        request: %{
          "uid" => "some_uid",
          "resource" => %{
            "group" => "bonny-plug.ufirst.io",
            "version" => "v1",
            "resource" => "testcrds"
          }
        },
        response: %{}
      }

      admission_review =
        TestWebhookHandlerCRDV1Beta1.process(admission_review, :validating_webhook)

      assert false == admission_review.response["allowed"]
    end

    test "processes a request if resource matches" do
      Application.put_env(:bonny_plug, :admission_review_webhooks, [TestWebhookHandlerResource])

      admission_webhook = %AdmissionReview{
        request: %{
          "uid" => "some_uid",
          "resource" => %{
            "group" => "apps",
            "version" => "v1",
            "resource" => "deployments"
          }
        },
        response: %{}
      }

      admission_review =
        TestWebhookHandlerResource.process(admission_webhook, :validating_webhook)

      assert false == admission_review.response["allowed"]
    end

    test "does not process request if no resource given" do
      Application.put_env(:bonny_plug, :admission_review_webhooks, [TestWebhookHandlerCRD])
      admission_review = %AdmissionReview{request: %{"uid" => "some_uid"}, response: %{}}

      assert admission_review ==
               TestWebhookHandlerCRD.process(admission_review, :validating_webhook)
    end

    test "does not process request for versions that are not served" do
      Application.put_env(:bonny_plug, :admission_review_webhooks, [TestWebhookHandlerCRD])

      admission_review = %AdmissionReview{
        request: %{
          "uid" => "some_uid",
          "resource" => %{
            "group" => "bonny-plug.ufirst.io",
            "version" => "v2",
            "resource" => "testcrds"
          }
        },
        response: %{}
      }

      assert admission_review ==
               TestWebhookHandlerCRD.process(
                 admission_review,
                 :validating_webhook
               )
    end

    test "does not process request if group does not match" do
      Application.put_env(:bonny_plug, :admission_review_webhooks, [TestWebhookHandlerCRD])

      admission_review = %AdmissionReview{
        request: %{
          "uid" => "some_uid",
          "resource" => %{
            "group" => "some-group",
            "version" => "v1",
            "resource" => "testcrds"
          }
        },
        response: %{}
      }

      assert admission_review ==
               TestWebhookHandlerCRD.process(
                 admission_review,
                 :validating_webhook
               )
    end
  end
end
