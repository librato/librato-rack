if ENV['LIBRATO_NETWORK_MODE'] and ENV['LIBRATO_NETWORK_MODE'] == 'synchrony'
  Faraday.default_connection = Faraday::Connection.new do |builder|
    builder.use Faraday::Adapter::EMSynchrony
  end
end