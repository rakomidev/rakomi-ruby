# frozen_string_literal: true

require "net/http"
require "openssl"
require "uri"

module Rakomi
  # Minimal HTTPS GET client on Net::HTTP: certificate verification on, no redirects followed,
  # timeouts on every phase and a cap on the response size.
  class HTTPClient
    DEFAULT_TIMEOUT = 5
    MAX_BODY_BYTES = 1_048_576

    def initialize(open_timeout: DEFAULT_TIMEOUT, read_timeout: DEFAULT_TIMEOUT, max_body_bytes: MAX_BODY_BYTES)
      @open_timeout = open_timeout
      @read_timeout = read_timeout
      @max_body_bytes = max_body_bytes
    end

    # Returns [status, body] for an https URI.
    def get(uri)
      raise DiscoveryError, "refusing a non-https URL: #{uri}" unless uri.is_a?(URI::HTTPS)

      Net::HTTP.start(uri.host, uri.port, **connection_options) do |http|
        request = Net::HTTP::Get.new(uri)
        request["Accept"] = "application/json"
        http.request(request) do |response|
          return [response.code.to_i, read_body(response, uri)]
        end
      end
    rescue Net::OpenTimeout, Net::ReadTimeout, Net::WriteTimeout
      raise DiscoveryError, "timed out fetching #{uri}"
    rescue OpenSSL::SSL::SSLError, SystemCallError, SocketError, IOError, EOFError => e
      raise DiscoveryError, "could not fetch #{uri}: #{e.class}"
    end

    private

    def connection_options
      {
        use_ssl: true,
        verify_mode: OpenSSL::SSL::VERIFY_PEER,
        open_timeout: @open_timeout,
        read_timeout: @read_timeout,
        write_timeout: @read_timeout,
        ssl_timeout: @open_timeout
      }
    end

    def read_body(response, uri)
      body = +""
      response.read_body do |chunk|
        body << chunk
        raise DiscoveryError, "response from #{uri} exceeds #{@max_body_bytes} bytes" if body.bytesize > @max_body_bytes
      end
      body
    end
  end
end
