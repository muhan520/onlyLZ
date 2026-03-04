# frozen_string_literal: true

require "rails_helper"

RSpec.describe "OnlyLz topic filter" do
  fab!(:topic_owner) { Fabricate(:user) }
  fab!(:viewer) { Fabricate(:user) }
  fab!(:other_user) { Fabricate(:user) }

  before do
    SiteSetting.only_lz_enabled = true
    SiteSetting.only_lz_log_enabled = false
  end

  def filtered_post_ids(topic, scope_user = viewer)
    TopicView.new(topic.id, scope_user, filter: "only_lz").posts.map(&:id)
  end

  def set_post_field(post, name, value)
    post.custom_fields[name] = value
    post.save_custom_fields
    post.reload
  end

  def apply_filter(topic)
    posts = Post.where(topic_id: topic.id)
    topic_view = double("topic_view", topic: topic, first_post: topic.first_post)
    ::OnlyLz::TopicFilter.apply(posts: posts, topic_view: topic_view)
  end

  it "keeps only topic-owner real-name posts when first post is real-name" do
    topic = Fabricate(:topic, user: topic_owner)
    first_post = topic.first_post

    owner_real_reply = Fabricate(:post, topic: topic, user: topic_owner, raw: "owner real reply")
    owner_anonymous_reply = Fabricate(:post, topic: topic, user: topic_owner, raw: "owner anonymous reply")
    other_reply = Fabricate(:post, topic: topic, user: other_user, raw: "other reply")

    set_post_field(owner_anonymous_reply, "anon_identity_id", "identity-101")

    expect(filtered_post_ids(topic)).to contain_exactly(first_post.id, owner_real_reply.id)
    expect(filtered_post_ids(topic)).not_to include(owner_anonymous_reply.id, other_reply.id)
  end

  it "keeps only same anonymous identity posts when first post is anonymous" do
    topic = Fabricate(:topic, user: topic_owner)
    first_post = topic.first_post

    owner_anonymous_reply = Fabricate(:post, topic: topic, user: topic_owner, raw: "owner anonymous reply")
    owner_real_reply = Fabricate(:post, topic: topic, user: topic_owner, raw: "owner real reply")
    other_anonymous_reply = Fabricate(:post, topic: topic, user: other_user, raw: "other anonymous reply")

    set_post_field(first_post, "anon_identity_id", "identity-202")
    set_post_field(owner_anonymous_reply, "anon_identity_id", "identity-202")
    set_post_field(other_anonymous_reply, "anon_identity_id", "identity-999")

    expect(filtered_post_ids(topic)).to contain_exactly(first_post.id, owner_anonymous_reply.id)
    expect(filtered_post_ids(topic)).not_to include(owner_real_reply.id, other_anonymous_reply.id)
  end

  it "falls back to unfiltered posts when first post has anonymous marker but missing identity id" do
    topic = Fabricate(:topic, user: topic_owner)
    first_post = topic.first_post

    owner_reply = Fabricate(:post, topic: topic, user: topic_owner, raw: "owner reply")
    other_reply = Fabricate(:post, topic: topic, user: other_user, raw: "other reply")

    set_post_field(first_post, "anon_display_name_snapshot", "alias#abcd123")

    expect(filtered_post_ids(topic)).to contain_exactly(first_post.id, owner_reply.id, other_reply.id)
  end

  it "does nothing when only_lz site setting is disabled" do
    SiteSetting.only_lz_enabled = false

    topic = Fabricate(:topic, user: topic_owner)
    first_post = topic.first_post
    other_reply = Fabricate(:post, topic: topic, user: other_user, raw: "other reply")

    expect(filtered_post_ids(topic)).to contain_exactly(first_post.id, other_reply.id)
  end

  it "falls back to topic.first_post when topic_view does not expose first_post" do
    topic = Fabricate(:topic, user: topic_owner)
    owner_reply = Fabricate(:post, topic: topic, user: topic_owner, raw: "owner reply")
    other_reply = Fabricate(:post, topic: topic, user: other_user, raw: "other reply")

    posts = Post.where(topic_id: topic.id)
    topic_view = double("topic_view_without_first_post", topic: topic)

    filtered_ids = ::OnlyLz::TopicFilter.apply(posts: posts, topic_view: topic_view).pluck(:id)

    expect(filtered_ids).to contain_exactly(topic.first_post.id, owner_reply.id)
    expect(filtered_ids).not_to include(other_reply.id)
  end

  it "does not write plugin logs when only_lz_log_enabled is disabled" do
    SiteSetting.only_lz_log_enabled = false

    topic = Fabricate(:topic, user: topic_owner)
    set_post_field(topic.first_post, "anon_display_name_snapshot", "alias#abcd123")

    logger = spy("logger")
    allow(Rails).to receive(:logger).and_return(logger)

    apply_filter(topic)

    expect(logger).not_to have_received(:warn).with(include("[#{::OnlyLz::PLUGIN_NAME}]"))
  end

  it "writes plugin logs when only_lz_log_enabled is enabled" do
    SiteSetting.only_lz_log_enabled = true

    topic = Fabricate(:topic, user: topic_owner)
    set_post_field(topic.first_post, "anon_display_name_snapshot", "alias#abcd123")

    logger = spy("logger")
    allow(Rails).to receive(:logger).and_return(logger)

    apply_filter(topic)

    expect(logger).to have_received(:warn).with(include("[#{::OnlyLz::PLUGIN_NAME}]")).at_least(:once)
  end
end
