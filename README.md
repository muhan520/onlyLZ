# discourse-only-lz

Discourse「只看楼主」独立插件，兼容话题级匿名身份插件（`discourse-anonymous-topic-identity`）。

## 功能概览

- 话题页支持 `filter=only_lz` 过滤参数。
- 在 `topic-above-post-stream` 提供「只看楼主 / 查看全部」按钮。
- 支持按话题记忆开关状态（`localStorage["only_lz.topic.v1.<topic_id>"]`）。
- 匿名兼容策略默认「隐私优先」：
  - 首帖匿名：仅展示同 `anon_identity_id` 的帖子。
  - 首帖实名：仅展示楼主实名帖子（排除带 `anon_identity_id` 的帖子）。
- 匿名插件未安装或未启用时自动降级为普通「只看楼主」行为。

## 隐私与取舍

本插件固定采用隐私优先策略，不提供「完整优先」切换：

- 不会把楼主匿名帖与楼主实名帖在同一过滤结果里强关联。
- staff 与普通用户在 `only_lz` 过滤下行为一致。
- 若出现异常数据（首帖存在匿名标记但缺少 `anon_identity_id`），会记录 warn 并跳过过滤，避免误筛空。

## 站点设置

- `only_lz_enabled`（默认 `true`，客户端可读）

## 目录结构

```text
.
├── plugin.rb
├── lib/
│   ├── only_lz.rb
│   └── only_lz/topic_filter.rb
├── assets/
│   ├── javascripts/discourse/initializers/only-lz-topic-filter.js
│   ├── javascripts/discourse/connectors/topic-above-post-stream/only-lz-toggle.js
│   ├── javascripts/discourse/connectors/topic-above-post-stream/only-lz-toggle.hbs
│   └── stylesheets/common/only-lz.scss
├── config/
│   ├── settings.yml
│   └── locales/
│       ├── server.en.yml
│       ├── server.zh_CN.yml
│       ├── client.en.yml
│       └── client.zh_CN.yml
└── spec/
    └── integration/only_lz_topic_filter_spec.rb
```

## 安装

1. 将插件目录放入 Discourse 的 `plugins/` 下（目录名可为 `discourse-only-lz`）。
2. 重建 Discourse 容器。
3. 在后台确认 `only_lz_enabled` 为开启状态。

## 使用

- 在话题 URL 增加参数：`?filter=only_lz`。
- 通过话题页按钮切换过滤；按钮状态会按话题记忆。

## 测试

插件包含后端冒烟测试：

- `spec/integration/only_lz_topic_filter_spec.rb`

在 Discourse 测试环境内运行：

```bash
bundle exec rspec plugins/discourse-only-lz/spec/integration/only_lz_topic_filter_spec.rb
```

## 与匿名插件对接约定

- 读取 `post_custom_fields` 中的 `anon_identity_id` 作为匿名身份主键。
- 不依赖 `anonymous_display_name` 等展示字段字符串。

