require "digest"

# General API rate limit by IP
Rack::Attack.throttle("api/anon", limit: 100, period: 60.seconds) do |req|
  next unless req.path.start_with?("/api")

  auth = req.get_header("HTTP_AUTHORIZATION").to_s
  req.ip unless auth.start_with?("Bearer ")
end

Rack::Attack.throttle("api/auth", limit: 300, period: 60.seconds) do |req|
  next unless req.path.start_with?("/api")

  auth = req.get_header("HTTP_AUTHORIZATION").to_s
  if auth.start_with?("Bearer ")
    token = auth.delete_prefix("Bearer ")
    Digest::SHA256.hexdigest(token)
  end
end

Rack::Attack.throttled_response_retry_after_header = true
