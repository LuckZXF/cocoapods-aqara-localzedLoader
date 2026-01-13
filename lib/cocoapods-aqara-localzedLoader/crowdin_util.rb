# frozen_string_literal: true
require "net/http"
require "uri"
require "json"
class CrowdinUtil

  def crowdin_headers
    {
      "Authorization" => "Bearer db0506fb755d528c7b9b750e15174d3cfa483859488da978748ad6b9e34d13dc94d8716810a2f978",
      "Content-Type"  => "application/json"
    }
  end

  def release_distribution(distribution_hash = "e-53615346e6d639beb7263b3iht")
    url = URI(
      "https://aqara.crowdin.com/api/v2/projects/71/distributions/#{distribution_hash}/release"
    )

    puts "🚀 OTA Release: distribution=#{distribution_hash}"

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(url.request_uri)
    crowdin_headers.each do |k, v|
      request[k] = v
    end

    request.body = {}.to_json

    response = http.request(request)

    unless response.is_a?(Net::HTTPSuccess)
      raise "Crowdin OTA Release failed: #{response.code} #{response.body}"
    end

    puts "✅ OTA Release 成功"
  end
end
