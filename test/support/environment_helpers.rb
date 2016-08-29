# Helper methods for environment management that are shared
# between test files.
#
module EnvironmentHelpers

  def clear_config_env_vars
    ENV.delete('LIBRATO_USER')
    ENV.delete('LIBRATO_TOKEN')
    ENV.delete('LIBRATO_PROXY')
    ENV.delete('LIBRATO_TAGS')
    ENV.delete('LIBRATO_PREFIX')
    ENV.delete('LIBRATO_SUITES')
    ENV.delete('LIBRATO_LOG_LEVEL')
    ENV.delete('LIBRATO_EVENT_MODE')
    # system
    ENV.delete('http_proxy')
  end

end
