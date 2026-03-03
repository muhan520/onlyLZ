import Component from "@glimmer/component";
import { action } from "@ember/object";
import { inject as service } from "@ember/service";
import I18n from "I18n";

const FILTER_NAME = "only_lz";
const STORAGE_PREFIX = "only_lz.topic.v1.";
const TOPIC_PATH_REGEXES = [/^\/t\/[^/]+\/(\d+)(?:\/|$)/, /^\/t\/(\d+)(?:\/|$)/];

function topicIdFromPath(pathname) {
  for (const regex of TOPIC_PATH_REGEXES) {
    const match = pathname.match(regex);
    if (match) {
      const topicId = Number.parseInt(match[1], 10);
      if (Number.isFinite(topicId)) {
        return topicId;
      }
    }
  }
  return null;
}

export default class OnlyLzToggle extends Component {
  @service siteSettings;

  get showToggle() {
    return this.siteSettings.only_lz_enabled && this.topicId !== null;
  }

  get topicId() {
    const outletArgs = this.args.outletArgs || {};
    const model = outletArgs.model || outletArgs.topic;
    const maybeId =
      model && (model.id || (model.topic && model.topic.id));
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
    const classes = ["btn", "only-lz-toggle-button"];
    if (this.enabled) {
      classes.push("btn-primary", "is-active");
    } else {
      classes.push("btn-default");
    }
    return classes.join(" ");
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
    } catch (error) {
      // localStorage can fail in privacy modes; non-fatal.
    }
  }
}
