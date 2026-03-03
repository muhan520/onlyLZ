import Component from "@glimmer/component";
import { action } from "@ember/object";
import { inject as service } from "@ember/service";
import I18n from "I18n";

const FILTER_NAME = "only_lz";
const STORAGE_PREFIX = "only_lz.topic.v1.";
const TOPIC_PATH_REGEX = /^\/t\/[^/]+\/(\d+)(?:\/|$)/;

function topicIdFromPath(pathname) {
  const match = pathname.match(TOPIC_PATH_REGEX);
  if (!match) {
    return null;
  }

  const topicId = Number.parseInt(match[1], 10);
  return Number.isFinite(topicId) ? topicId : null;
}

export default class OnlyLzToggle extends Component {
  @service siteSettings;

  get showToggle() {
    return this.siteSettings.only_lz_enabled && this.topicId !== null;
  }

  get topicId() {
    const model = this.args.outletArgs?.model;
    const maybeId = model?.id ?? model?.topic?.id;
    const fromModel = Number.parseInt(maybeId, 10);
    if (Number.isFinite(fromModel)) {
      return fromModel;
    }

    if (typeof window === "undefined") {
      return null;
    }

    return topicIdFromPath(window.location.pathname);
  }

  get enabled() {
    if (typeof window === "undefined") {
      return false;
    }

    const currentUrl = new URL(window.location.href);
    return currentUrl.searchParams.get("filter") === FILTER_NAME;
  }

  get buttonClass() {
    return this.enabled
      ? "btn-primary only-lz-toggle-button is-active"
      : "only-lz-toggle-button";
  }

  get buttonIcon() {
    return this.enabled ? "filter" : "user";
  }

  get buttonLabel() {
    return this.enabled
      ? I18n.t("only_lz.show_all")
      : I18n.t("only_lz.only_op");
  }

  @action
  toggleFilter() {
    if (typeof window === "undefined" || this.topicId === null) {
      return;
    }

    const currentUrl = new URL(window.location.href);
    const nextEnabled = !this.enabled;

    if (nextEnabled) {
      currentUrl.searchParams.set("filter", FILTER_NAME);
    } else {
      currentUrl.searchParams.delete("filter");
    }

    this.persistTopicPreference(nextEnabled);
    window.location.assign(currentUrl.toString());
  }

  persistTopicPreference(enabled) {
    try {
      window.localStorage.setItem(
        `${STORAGE_PREFIX}${this.topicId}`,
        enabled ? "1" : "0"
      );
    } catch {
      // localStorage can fail in privacy modes; non-fatal.
    }
  }
}
