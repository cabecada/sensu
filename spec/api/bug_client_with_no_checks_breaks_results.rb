require File.join(File.dirname(__FILE__), "..", "helpers.rb")

require "sensu/api/process"
require "sensu/server/process"

describe "Sensu::API::Process" do
  include Helpers

  before do
    @l = [
      {"key" => "clients","type" => "set","value" => ["my-first-sensu-client","fake-source","fake-client"]},
      {"key" => "history:my-first-sensu-client:keepalive","type" => "list","value" => ["0"]},
      {"key" => "result:my-first-sensu-client","type" => "set","value" => ["keepalive"]},
      {"key" => "history:fake-source:fake-check","type" => "list","value" => ["0"]},
      {"key" => "result:fake-source","type" => "set","value" => ["fake-check"]},
      {"key" => "lock:leader","type" => "string","value" => "1467912262985"},
      {"key" => "client:my-first-sensu-client","type" => "string","value" => "{\"name\":\"my-first-sensu-client\",\"address\":\"127.0.0.1\",\"environment\":\"development\",\"subscriptions\":[\"dev\"],\"socket\":{\"bind\":\"127.0.0.1\",\"port\":3030},\"version\":\"0.25.3\",\"timestamp\":1467912244}"},
      {"key" => "client:my-first-sensu-client:signature","type" => "string","value" => ""},
      {"key" => "client:fake-client","type" => "string","value" => "{\"subscriptions\":[],\"address\":\"unknown\",\"name\":\"fake-client\",\"keepalives\":false,\"version\":\"0.25.3\",\"timestamp\":1467912243}"},
      {"key" => "client:fake-source","type" => "string","value" => "{\"subscriptions\":[],\"address\":\"unknown\",\"name\":\"fake-source\",\"keepalives\":false,\"version\":\"0.25.3\",\"timestamp\":1467912190}"},
      {"key" => "client:fake-source:signature","type" => "string","value" => ""},
      {"key" => "result:my-first-sensu-client:keepalive","type" => "string","value" => "{\"thresholds\":{\"warning\":120,\"critical\":180},\"name\":\"keepalive\",\"issued\":1467912244,\"executed\":1467912244,\"output\":\"Keepalive sent from client 0 seconds ago\",\"status\":0,\"type\":\"standard\"}"},
      {"key" => "leader","type" => "string","value" => "fd055756-f566-4bc3-a5cb-54478acb2563"},
      {"key" => "result:fake-source:fake-check","type" => "string","value" => "{\"source\":\"fake-source\",\"name\":\"fake-check\",\"output\":\"hello results API world\",\"status\":0,\"issued\":1467912022,\"executed\":1467912022,\"type\":\"standard\",\"origin\":\"sensu-api\"}"}
    ]
  end

  before do
    async_wrapper do
      redis.callback do
        redis.flushdb do
          async_done
        end
        @l.each do |x|
          if x["type"] == "string"
            redis.set(x["key"], x["value"]) do
              async_done
            end
          end
          if x["type"] == "list"
            x["value"].each do |y|
              redis.lpush(x["key"], y) do
                async_done
              end
            end
          end
          if x["type"] == "set"
            x["value"].each do |y|
              #if x["key"] == "clients" and y == "fake-client"
                #next
              #end
              redis.sadd(x["key"], y) do
                async_done
              end
            end
          end
        end
      end
    end
  end

  it "client with no check does not break /results" do
    api_test do
      api_request("/clients") do |http, body|
        expect(http.response_header.status).to eq(200)
        expect(body).to be_kind_of(Array)
        expect(body.size).to eq(3)
        async_done
      end
    end
    api_test do
      api_request("/results") do |http, body|
        expect(http.response_header.status).to eq(200)
        expect(body).to be_kind_of(Array)
        expect(body.size).to eq(3)
        async_done
      end
    end
  end
end
