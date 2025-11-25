# frozen_string_literal: true

module Airwallex
  # Dispute resource for handling chargebacks and payment disputes
  #
  # Disputes represent chargebacks or payment disputes initiated by cardholders.
  # Merchants can view disputes, submit evidence to challenge them, or accept them.
  #
  # @example List open disputes
  #   disputes = Airwallex::Dispute.list(status: 'OPEN')
  #
  # @example Retrieve a dispute
  #   dispute = Airwallex::Dispute.retrieve('dis_123')
  #
  # @example Submit evidence
  #   dispute = Airwallex::Dispute.retrieve('dis_123')
  #   dispute.submit_evidence(
  #     customer_communication: "Email showing delivery confirmation",
  #     shipping_tracking_number: "1Z999AA10123456784"
  #   )
  #
  # @example Accept a dispute
  #   dispute = Airwallex::Dispute.retrieve('dis_123')
  #   dispute.accept
  #
  class Dispute < APIResource
    extend APIOperations::Retrieve
    extend APIOperations::List

    def self.resource_path
      "/api/v1/disputes"
    end

    # Accept a dispute without challenging it
    #
    # @return [Airwallex::Dispute] The updated dispute object
    def accept
      response = Airwallex.client.post("#{resource_path}/#{id}/accept", {})
      refresh_from(response)
      self
    end

    # Submit evidence to challenge a dispute
    #
    # @param evidence [Hash] Evidence details
    # @option evidence [String] :customer_communication Email or chat logs
    # @option evidence [String] :shipping_tracking_number Tracking number
    # @option evidence [String] :shipping_documentation Proof of shipping
    # @option evidence [String] :customer_signature Signed receipt
    # @option evidence [String] :receipt Proof of purchase
    # @option evidence [String] :refund_policy Refund policy document
    # @option evidence [String] :cancellation_policy Cancellation policy
    # @option evidence [String] :additional_information Other relevant info
    #
    # @return [Airwallex::Dispute] The updated dispute object
    def submit_evidence(evidence)
      response = Airwallex.client.post("#{resource_path}/#{id}/evidence", evidence)
      refresh_from(response)
      self
    end

    private

    def resource_path
      self.class.resource_path
    end
  end
end
