# frozen_string_literal: true

require "spec_helper"

RSpec.describe Airwallex::RFI do
  let(:account_id) { "acct_hydvdj7gNtaILQb6AHWptQ" }
  let(:on_behalf_of) { { "x-on-behalf-of" => account_id } }
  let(:rfi_id) { "f89a9093-8e32-495d-b870-70357db90e20" }
  let(:rfi_data) do
    {
      id: rfi_id,
      account_id: account_id,
      status: "ACTION_REQUIRED",
      type: "KYC_ONGOING",
      created_at: "2026-09-25T05:10:07+0000",
      answered_requests: [],
      active_request: {
        questions: [
          {
            id: "0c1ef5de-ed97-4649-95a6-3e581b0427ec",
            trigger: "OTHERS",
            answer: { type: "ATTACHMENT" },
            title: { en: "Nominated SMO Declaration" },
            attachments: []
          }
        ]
      }
    }
  end

  def json_response(body, status: 200)
    { status: status, body: body.to_json, headers: { "Content-Type" => "application/json" } }
  end

  describe ".resource_path" do
    it "returns the real RFI path" do
      expect(described_class.resource_path).to eq("/api/v1/rfis")
    end
  end

  describe ".retrieve" do
    it "fetches an RFI on behalf of a connected account, deep-symbolized" do
      stub = stub_request(:get, "#{BASE_URL}/api/v1/rfis/#{rfi_id}")
             .with(headers: on_behalf_of)
             .to_return(json_response(rfi_data))

      rfi = described_class.retrieve(rfi_id, headers: on_behalf_of)

      expect(stub).to have_been_requested
      expect(rfi).to be_a(described_class)
      expect(rfi.id).to eq(rfi_id)
      expect(rfi.status).to eq("ACTION_REQUIRED")
      question = rfi.active_request[:questions].first
      expect(question[:title][:en]).to eq("Nominated SMO Declaration")
      expect(question[:answer]).to eq(type: "ATTACHMENT")
    end

    it "raises AuthenticationError when the key lacks RFI read permission" do
      stub_request(:get, "#{BASE_URL}/api/v1/rfis/#{rfi_id}")
        .to_return(json_response({ code: "unauthorized", message: "Insufficient permissions" }, status: 401))

      expect { described_class.retrieve(rfi_id, headers: on_behalf_of) }
        .to raise_error(Airwallex::AuthenticationError, /Insufficient permissions/)
    end
  end

  describe ".list" do
    it "sends filters and headers, and exposes page_after as the cursor" do
      stub = stub_request(:get, "#{BASE_URL}/api/v1/rfis")
             .with(query: { statuses: "ACTION_REQUIRED", types: "KYC,KYC_ONGOING" }, headers: on_behalf_of)
             .to_return(json_response({ items: [rfi_data], page_after: "YWZ0ZXI9", page_before: "YmVmb3Jl" }))

      list = described_class.list({ statuses: "ACTION_REQUIRED", types: "KYC,KYC_ONGOING" }, headers: on_behalf_of)

      expect(stub).to have_been_requested
      expect(list).to be_a(Airwallex::ListObject)
      expect(list.first).to be_a(described_class)
      expect(list.first.status).to eq("ACTION_REQUIRED")
      expect(list.has_more).to be true
      expect(list.next_cursor).to eq("YWZ0ZXI9")
    end

    it "has no more pages when page_after is absent" do
      stub_request(:get, "#{BASE_URL}/api/v1/rfis")
        .to_return(json_response({ items: [rfi_data], page_before: "YmVmb3Jl" }))

      list = described_class.list

      expect(list.has_more).to be false
      expect(list.next_page).to be_nil
    end

    it "has no more pages when the page is empty, even with page_after" do
      stub_request(:get, "#{BASE_URL}/api/v1/rfis")
        .to_return(json_response({ items: [], page_after: "YWZ0ZXI9" }))

      expect(described_class.list.has_more).to be false
    end

    it "follows page_after across two pages, keeping filters and x-on-behalf-of" do
      page1 = stub_request(:get, "#{BASE_URL}/api/v1/rfis")
              .with(query: { statuses: "ACTION_REQUIRED" }, headers: on_behalf_of)
              .to_return(json_response({ items: [rfi_data.merge(id: "rfi_1")], page_after: "cGFnZTI=" }))
      page2 = stub_request(:get, "#{BASE_URL}/api/v1/rfis")
              .with(query: { statuses: "ACTION_REQUIRED", page: "cGFnZTI=" }, headers: on_behalf_of)
              .to_return(json_response({ items: [rfi_data.merge(id: "rfi_2")], page_before: "cGFnZTE=" }))

      ids = described_class.list({ statuses: "ACTION_REQUIRED" }, headers: on_behalf_of)
                           .auto_paging_each.map(&:id)

      expect(ids).to eq(%w[rfi_1 rfi_2])
      expect(page1).to have_been_requested.once
      expect(page2).to have_been_requested.once
    end
  end

  describe ".respond" do
    let(:answers) do
      {
        questions: [
          { id: "q1", answer: { type: "TEXT", text: "We operate in AU only" } },
          { id: "q2", answer: { type: "ATTACHMENT", attachments: [{ file_id: "file_123" }] } }
        ]
      }
    end

    it "posts the answers as-is with x-on-behalf-of and returns the RFI" do
      stub = stub_request(:post, "#{BASE_URL}/api/v1/rfis/#{rfi_id}/respond")
             .with(body: answers.to_json, headers: on_behalf_of.merge("Content-Type" => "application/json"))
             .to_return(json_response(rfi_data.merge(status: "ANSWERED")))

      rfi = described_class.respond(rfi_id, answers, headers: on_behalf_of)

      expect(stub).to have_been_requested
      expect(rfi).to be_a(described_class)
      expect(rfi.status).to eq("ANSWERED")
    end

    it "does not add a request_id to the body" do
      stub = stub_request(:post, "#{BASE_URL}/api/v1/rfis/#{rfi_id}/respond")
             .with { |req| !JSON.parse(req.body).key?("request_id") }
             .to_return(json_response(rfi_data))

      described_class.respond(rfi_id, answers)

      expect(stub).to have_been_requested
    end

    it "raises BadRequestError when the RFI is not ACTION_REQUIRED" do
      stub_request(:post, "#{BASE_URL}/api/v1/rfis/#{rfi_id}/respond")
        .to_return(json_response({ code: "invalid_state_for_operation", message: "invalid status" }, status: 400))

      expect { described_class.respond(rfi_id, answers, headers: on_behalf_of) }
        .to raise_error(Airwallex::BadRequestError, /invalid status/) { |e| expect(e.code).to eq("invalid_state_for_operation") }
    end
  end

  describe "#respond" do
    it "responds to this RFI and refreshes its state" do
      rfi = described_class.new(rfi_data)
      stub = stub_request(:post, "#{BASE_URL}/api/v1/rfis/#{rfi_id}/respond")
             .with(body: { questions: [{ id: "q1", answer: { type: "TEXT", text: "x" } }] }.to_json,
                   headers: on_behalf_of)
             .to_return(json_response(rfi_data.merge(status: "ANSWERED")))

      result = rfi.respond({ questions: [{ id: "q1", answer: { type: "TEXT", text: "x" } }] }, headers: on_behalf_of)

      expect(stub).to have_been_requested
      expect(result).to equal(rfi)
      expect(rfi.status).to eq("ANSWERED")
      expect(rfi.active_request[:questions].first[:title][:en]).to eq("Nominated SMO Declaration")
    end
  end

  describe ".simulate_create" do
    it "raises an RFI" do
      stub_request(:post, "#{BASE_URL}/api/v1/simulation/rfis/create")
        .with(body: hash_including(type: "KYC"))
        .to_return(
          status: 200,
          body: { id: "rfi_123", type: "KYC", status: "OPEN" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      rfi = described_class.simulate_create(type: "KYC", questions: [{ answer: { type: "TEXT" } }])

      expect(rfi).to be_a(described_class)
      expect(rfi.status).to eq("OPEN")
    end
  end

  describe ".simulate_close" do
    it "closes an RFI by id" do
      stub_request(:post, "#{BASE_URL}/api/v1/simulation/rfis/rfi_123/close")
        .to_return(
          status: 200,
          body: { id: "rfi_123", status: "CLOSED" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      rfi = described_class.simulate_close("rfi_123")

      expect(rfi.status).to eq("CLOSED")
    end
  end

  describe ".simulate_follow_up" do
    it "follows up on an RFI by id" do
      stub_request(:post, "#{BASE_URL}/api/v1/simulation/rfis/rfi_123/follow_up")
        .to_return(
          status: 200,
          body: { id: "rfi_123", status: "OPEN" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      rfi = described_class.simulate_follow_up("rfi_123", questions: [{ id: "q_1" }])

      expect(rfi.status).to eq("OPEN")
    end
  end

  describe "#simulate_close" do
    let(:rfi) { described_class.new(id: "rfi_123", status: "OPEN") }

    it "closes this RFI and refreshes its state" do
      stub_request(:post, "#{BASE_URL}/api/v1/simulation/rfis/rfi_123/close")
        .to_return(
          status: 200,
          body: { id: "rfi_123", status: "CLOSED" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = rfi.simulate_close

      expect(result).to eq(rfi)
      expect(rfi.status).to eq("CLOSED")
    end
  end

  describe "#simulate_follow_up" do
    let(:rfi) { described_class.new(id: "rfi_123", status: "CLOSED") }

    it "follows up on this RFI and refreshes its state" do
      stub_request(:post, "#{BASE_URL}/api/v1/simulation/rfis/rfi_123/follow_up")
        .to_return(
          status: 200,
          body: { id: "rfi_123", status: "OPEN" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      rfi.simulate_follow_up(questions: [{ answer: { type: "TEXT" } }])

      expect(rfi.status).to eq("OPEN")
    end
  end

  describe "simulation with x-on-behalf-of" do
    it "passes headers through .simulate_create" do
      stub = stub_request(:post, "#{BASE_URL}/api/v1/simulation/rfis/create")
             .with(body: hash_including(type: "KYC"), headers: on_behalf_of)
             .to_return(json_response({ id: "rfi_123", status: "ACTION_REQUIRED" }))

      described_class.simulate_create({ type: "KYC", questions: [{ answer: { type: "TEXT" } }] },
                                      headers: on_behalf_of)

      expect(stub).to have_been_requested
    end

    it "passes headers through .simulate_close and .simulate_follow_up" do
      close = stub_request(:post, "#{BASE_URL}/api/v1/simulation/rfis/rfi_123/close")
              .with(headers: on_behalf_of).to_return(json_response({ id: "rfi_123", status: "CLOSED" }))
      follow = stub_request(:post, "#{BASE_URL}/api/v1/simulation/rfis/rfi_123/follow_up")
               .with(headers: on_behalf_of).to_return(json_response({ id: "rfi_123", status: "ACTION_REQUIRED" }))

      described_class.simulate_close("rfi_123", headers: on_behalf_of)
      described_class.simulate_follow_up("rfi_123", { questions: [{ id: "q_1" }] }, headers: on_behalf_of)

      expect(close).to have_been_requested
      expect(follow).to have_been_requested
    end

    it "passes headers through the instance methods" do
      rfi = described_class.new(id: "rfi_123")
      close = stub_request(:post, "#{BASE_URL}/api/v1/simulation/rfis/rfi_123/close")
              .with(headers: on_behalf_of).to_return(json_response({ id: "rfi_123", status: "CLOSED" }))
      follow = stub_request(:post, "#{BASE_URL}/api/v1/simulation/rfis/rfi_123/follow_up")
               .with(headers: on_behalf_of).to_return(json_response({ id: "rfi_123", status: "ACTION_REQUIRED" }))

      rfi.simulate_close(headers: on_behalf_of)
      rfi.simulate_follow_up({ questions: [{ id: "q_1" }] }, headers: on_behalf_of)

      expect(close).to have_been_requested
      expect(follow).to have_been_requested
    end

    it "surfaces an ongoing RFI as BadRequestError" do
      stub_request(:post, "#{BASE_URL}/api/v1/simulation/rfis/create")
        .to_return(json_response({ code: "invalid_state_for_operation", message: "ongoing RFI case exists" },
                                 status: 400))

      expect { described_class.simulate_create(type: "KYC", questions: []) }
        .to raise_error(Airwallex::BadRequestError, /ongoing RFI case exists/)
    end
  end
end
