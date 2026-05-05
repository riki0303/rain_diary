require "rails_helper"

RSpec.describe WeatherService do
  let(:api_key) { "test_api_key" }
  let(:service) { described_class.new(latitude: 35.68, longitude: 139.65, api_key: api_key) }

  let(:success_body_with_rain) do
    {
      "name" => "Tokyo",
      "weather" => [
        { "main" => "Rain", "description" => "小雨" }
      ],
      "main" => { "temp" => 22.5, "humidity" => 60 },
      "rain" => { "1h" => 1.2 }
    }
  end

  let(:success_body_without_rain) do
    {
      "name" => "Tokyo",
      "weather" => [
        { "main" => "Clouds", "description" => "曇り" }
      ],
      "main" => { "temp" => 18.0, "humidity" => 50 }
    }
  end

  def stub_connection(status:, body:)
    stubs = Faraday::Adapter::Test::Stubs.new
    stubs.get(WeatherService::ENDPOINT) { [ status, { "Content-Type" => "application/json" }, body ] }
    conn = Faraday.new(url: WeatherService::BASE_URL) do |f|
      f.response :json
      f.adapter :test, stubs
    end
    allow(service).to receive(:build_connection).and_return(conn)
  end

  describe "#fetch" do
    context "雨データがある場合" do
      before { stub_connection(status: 200, body: success_body_with_rain) }

      it "city_name が Tokyo を返す" do
        result = service.fetch
        expect(result[:city_name]).to eq("Tokyo")
      end

      it "current.temp を返す" do
        result = service.fetch
        expect(result[:temp]).to eq(22.5)
      end

      it "rainfall_mm が正の値を返す" do
        result = service.fetch
        expect(result[:rainfall_mm]).to eq(1.2)
      end

      it "weather_main と description を返す" do
        result = service.fetch
        expect(result[:weather_main]).to eq("Rain")
        expect(result[:description]).to eq("小雨")
      end

      it "humidity を返す" do
        result = service.fetch
        expect(result[:humidity]).to eq(60)
      end
    end

    context "雨データがない場合" do
      before { stub_connection(status: 200, body: success_body_without_rain) }

      it "rainfall_mm が 0.0 を返す" do
        result = service.fetch
        expect(result[:rainfall_mm]).to eq(0.0)
      end
    end

    context "APIキーが nil の場合" do
      let(:service) { described_class.new(latitude: 35.68, longitude: 139.65, api_key: nil) }

      it "nil を返し HTTP リクエストを発生させない" do
        expect(service).not_to receive(:build_connection)
        expect(service.fetch).to be_nil
      end
    end

    context "APIキーが空文字の場合" do
      let(:service) { described_class.new(latitude: 35.68, longitude: 139.65, api_key: "") }

      it "nil を返し HTTP リクエストを発生させない" do
        expect(service).not_to receive(:build_connection)
        expect(service.fetch).to be_nil
      end
    end

    context "レスポンスが 404 の場合" do
      before { stub_connection(status: 404, body: { "message" => "not found" }) }

      it "nil を返す" do
        expect(service.fetch).to be_nil
      end
    end

    context "レスポンスが 500 の場合" do
      before { stub_connection(status: 500, body: { "message" => "internal server error" }) }

      it "nil を返す" do
        expect(service.fetch).to be_nil
      end
    end

    context "Faraday::ConnectionFailed が発生した場合" do
      before do
        allow(service).to receive(:build_connection).and_raise(
          Faraday::ConnectionFailed.new("connection refused")
        )
      end

      it "nil を返す" do
        expect(service.fetch).to be_nil
      end

      it "エラーをログに記録する" do
        expect(Rails.logger).to receive(:error).with(/\[WeatherService\]/)
        service.fetch
      end
    end

    context "Faraday::TimeoutError が発生した場合" do
      it "nil を返しエラーをログに記録する" do
        allow_any_instance_of(WeatherService).to receive(:build_connection).and_raise(Faraday::TimeoutError)
        expect(Rails.logger).to receive(:error).with(/WeatherService/)
        expect(service.fetch).to be_nil
      end
    end
  end

  describe "#fetch キャッシュ動作" do
    include ActiveSupport::Testing::TimeHelpers

    before do
      allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
    end

    def counting_connection(count_ref, status:, body:)
      stubs = Faraday::Adapter::Test::Stubs.new
      stubs.get(WeatherService::ENDPOINT) do
        count_ref[:n] += 1
        [ status, { "Content-Type" => "application/json" }, body ]
      end
      Faraday.new(url: WeatherService::BASE_URL) { |f| f.response :json; f.adapter :test, stubs }
    end

    it "成功時: 2回呼んでも API は1回のみ呼ばれる" do
      count = { n: 0 }
      conn = counting_connection(count, status: 200, body: success_body_with_rain)
      allow(service).to receive(:build_connection).and_return(conn)

      result1 = service.fetch
      result2 = service.fetch

      expect(count[:n]).to eq(1)
      expect(result1).to eq(result2)
    end

    it "失敗(nil)はキャッシュされず次回呼び出しで再試行する" do
      stubs_500 = Faraday::Adapter::Test::Stubs.new
      stubs_500.get(WeatherService::ENDPOINT) { [ 500, { "Content-Type" => "application/json" }, {} ] }
      conn500 = Faraday.new(url: WeatherService::BASE_URL) { |f| f.response :json; f.adapter :test, stubs_500 }

      stubs_200 = Faraday::Adapter::Test::Stubs.new
      stubs_200.get(WeatherService::ENDPOINT) { [ 200, { "Content-Type" => "application/json" }, success_body_with_rain ] }
      conn200 = Faraday.new(url: WeatherService::BASE_URL) { |f| f.response :json; f.adapter :test, stubs_200 }

      allow(service).to receive(:build_connection).and_return(conn500, conn200)

      expect(service.fetch).to be_nil
      expect(service.fetch).to be_a(Hash)
    end

    it "TTL 経過後は API を再呼び出しする" do
      count = { n: 0 }
      conn = counting_connection(count, status: 200, body: success_body_with_rain)
      allow(service).to receive(:build_connection).and_return(conn)

      service.fetch
      travel_to(WeatherService::CACHE_TTL.from_now + 1.second) do
        service.fetch
      end

      expect(count[:n]).to eq(2)
    end

    it "異なる緯度経度では別々にキャッシュされる" do
      count = { n: 0 }
      conn = counting_connection(count, status: 200, body: success_body_with_rain)

      service_a = described_class.new(latitude: 35.68, longitude: 139.65, api_key: api_key)
      service_b = described_class.new(latitude: 34.69, longitude: 135.50, api_key: api_key)

      allow(service_a).to receive(:build_connection).and_return(conn)
      allow(service_b).to receive(:build_connection).and_return(conn)

      service_a.fetch
      service_b.fetch

      expect(count[:n]).to eq(2)
    end
  end
end
