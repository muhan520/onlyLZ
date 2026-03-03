# frozen_string_literal: true

# name: discourse-only-lz
# about: Topic-level "only OP" filter with anonymous-identity-aware privacy behavior.
# version: 0.1.0
# authors: Codex
# url: https://github.com/discourse/discourse-only-lz

enabled_site_setting :only_lz_enabled

register_asset "stylesheets/common/only-lz.scss"

require_relative "lib/only_lz"

after_initialize do
  require_relative "lib/only_lz/topic_filter"

  register_topic_view_posts_filter(::OnlyLz::FILTER_NAME) do |posts, topic_view|
    ::OnlyLz::TopicFilter.apply(posts: posts, topic_view: topic_view)
  end
end
