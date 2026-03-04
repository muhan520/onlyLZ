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

  filter_proc = proc do |posts, topic_view = nil, *extra_args|
    effective_topic_view = topic_view
    effective_topic_view ||= self if defined?(::TopicView) && self.is_a?(::TopicView)

    ::OnlyLz::TopicFilter.apply(posts: posts, topic_view: effective_topic_view)
  rescue StandardError => e
    ::OnlyLz.log(
      :warn,
      "topic view filter callback failed",
      topic_id: effective_topic_view&.topic&.id,
      error_class: e.class.name,
      error_message: e.message,
      extra_args_count: extra_args.length
    )
    posts
  end

  if respond_to?(:register_topic_view_posts_filter)
    ::OnlyLz::FILTER_ALIASES.each do |filter_name|
      register_topic_view_posts_filter(filter_name, &filter_proc)
    end
  elsif defined?(::TopicView) && ::TopicView.respond_to?(:add_custom_filter)
    ::OnlyLz::FILTER_ALIASES.each do |filter_name|
      ::TopicView.add_custom_filter(filter_name, &filter_proc)
    end
  else
    ::OnlyLz.log(
      :warn,
      "no topic filter registration API found; only_lz filter is disabled"
    )
  end
end
