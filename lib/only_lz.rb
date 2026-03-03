# frozen_string_literal: true

module ::OnlyLz
  PLUGIN_NAME = "discourse-only-lz"
  FILTER_NAME = "only_lz"
  FILTER_ALIASES = [FILTER_NAME, "only-lz", "onlylz"].freeze

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
end
