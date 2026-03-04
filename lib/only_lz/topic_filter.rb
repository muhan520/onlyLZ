# frozen_string_literal: true

module ::OnlyLz
  class TopicFilter
    def self.apply(posts:, topic_view:)
      return posts unless ::OnlyLz.enabled?
      return posts if posts.blank? || topic_view.blank?

      topic = topic_view.topic
      return posts if topic.blank? || topic.user_id.blank?

      first_post = topic_view.first_post || topic.first_post
      return posts if first_post.blank?

      first_post_anon_identity_id = anon_identity_id_for(first_post)

      if first_post_anon_identity_id.present?
        return anonymous_only(posts: posts, anon_identity_id: first_post_anon_identity_id)
      end

      if first_post_anonymous_marked?(first_post)
        ::OnlyLz.log(
          :warn,
          "anonymous first post missing #{::OnlyLz::Fields::ANON_IDENTITY_ID}; skip only_lz filter",
          topic_id: topic.id,
          post_id: first_post.id
        )
        return posts
      end

      real_owner_only(posts: posts, topic_owner_id: topic.user_id)
    rescue StandardError => e
      ::OnlyLz.log(
        :warn,
        "topic filter failed",
        topic_id: topic_view&.topic&.id,
        error_class: e.class.name,
        error_message: e.message
      )
      posts
    end

    def self.anonymous_only(posts:, anon_identity_id:)
      posts
        .joins(
          sanitize_sql_array(
            "INNER JOIN post_custom_fields only_lz_anon_cf " \
              "ON only_lz_anon_cf.post_id = posts.id " \
              "AND only_lz_anon_cf.name = ? " \
              "AND only_lz_anon_cf.value = ?",
            ::OnlyLz::Fields::ANON_IDENTITY_ID,
            anon_identity_id
          )
        )
        .distinct
    end

    def self.real_owner_only(posts:, topic_owner_id:)
      posts
        .where(user_id: topic_owner_id)
        .joins(
          sanitize_sql_array(
            "LEFT JOIN post_custom_fields only_lz_anon_cf " \
              "ON only_lz_anon_cf.post_id = posts.id " \
              "AND only_lz_anon_cf.name = ?",
            ::OnlyLz::Fields::ANON_IDENTITY_ID
          )
        )
        .where("only_lz_anon_cf.post_id IS NULL")
        .distinct
    end

    def self.anon_identity_id_for(post)
      custom_fields = post.custom_fields || {}
      identity_id = custom_fields[::OnlyLz::Fields::ANON_IDENTITY_ID]
      identity_id = identity_id.to_s.strip
      return identity_id if identity_id.present?

      PostCustomField
        .where(post_id: post.id, name: ::OnlyLz::Fields::ANON_IDENTITY_ID)
        .pick(:value)
        .to_s
        .strip
    end

    def self.first_post_anonymous_marked?(post)
      marker_keys = ::OnlyLz::Fields::ANON_MARKERS
      identity_key = ::OnlyLz::Fields::ANON_IDENTITY_ID
      custom_fields = post.custom_fields || {}

      custom_fields.key?(identity_key) ||
        marker_keys.any? { |field| custom_fields[field].present? } ||
        PostCustomField.where(post_id: post.id, name: marker_keys + [identity_key]).exists?
    end

    def self.sanitize_sql_array(template, *params)
      ActiveRecord::Base.send(:sanitize_sql_array, [template, *params])
    end
    private_class_method :sanitize_sql_array

    private_class_method :anon_identity_id_for, :first_post_anonymous_marked?,
                         :anonymous_only, :real_owner_only
  end
end
