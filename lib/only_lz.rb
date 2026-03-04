# frozen_string_literal: true

module ::OnlyLz
  PLUGIN_NAME = "discourse-only-lz"
  FILTER_NAME = "only_lz"
  FILTER_ALIASES = [FILTER_NAME, "only-lz", "onlylz"].freeze
  LOG_LEVELS = %i[debug info warn error fatal unknown].freeze

  module Fields
    ANON_IDENTITY_ID = "anon_identity_id"

    # These fields come from discourse-anonymous-topic-identity and are used
    # for anomaly detection only.
    ANON_MARKERS = %w[
      anon_alias_snapshot
      anon_code_snapshot
      anon_display_name_snapshot
    ].freeze
  end

  def self.enabled?
    SiteSetting.only_lz_enabled
  end

  def self.log_enabled?
    SiteSetting.only_lz_log_enabled
  rescue StandardError
    false
  end

  def self.log(level, message, context = {})
    return unless log_enabled?

    logger = Rails.logger
    return unless logger

    safe_context = context.respond_to?(:to_h) ? context.to_h : {}
    context_fragments = safe_context.each_with_object([]) do |(key, value), fragments|
      next if value.nil?

      fragments << "#{key}=#{value.inspect}"
    end

    entry = "[#{PLUGIN_NAME}] #{message}"
    entry = "#{entry} #{context_fragments.join(' ')}" if context_fragments.any?

    log_level = level.to_s.downcase.to_sym
    log_level = :info unless LOG_LEVELS.include?(log_level)

    logger.public_send(log_level, entry)
  rescue StandardError
    nil
  end
end
