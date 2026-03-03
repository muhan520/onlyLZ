import { withPluginApi } from "discourse/lib/plugin-api";

const FILTER_NAME = "only_lz";
const STORAGE_PREFIX = "only_lz.topic.v1.";
const TOPIC_PATH_REGEX = /^\/t\/[^/]+\/(\d+)(?:\/|$)/;

function extractTopicId(pathname) {
  const match = pathname.match(TOPIC_PATH_REGEX);
  if (!match) {
    return null;
  }

  const topicId = Number.parseInt(match[1], 10);
  return Number.isFinite(topicId) ? topicId : null;
}

function storageKeyFor(topicId) {
  return `${STORAGE_PREFIX}${topicId}`;
}

export default {
  name: "only-lz-topic-filter",

  initialize() {
    withPluginApi("1.15.0", (api) => {
      api.onPageChange((url) => {
        if (typeof window === "undefined") {
          return;
        }

        const siteSettings = api.container.lookup("service:site-settings");
        if (siteSettings && !siteSettings.only_lz_enabled) {
          return;
        }

        const transitionUrl = new URL(url, window.location.origin);
        const currentUrl = new URL(window.location.href);
        const topicId =
          extractTopicId(transitionUrl.pathname) ||
          extractTopicId(currentUrl.pathname);

        if (!topicId) {
          return;
        }

        const activeFilter =
          transitionUrl.searchParams.get("filter") ||
          currentUrl.searchParams.get("filter");

        if (activeFilter) {
          return;
        }

        let rememberedValue = null;
        try {
          rememberedValue = window.localStorage.getItem(storageKeyFor(topicId));
        } catch {
          return;
        }

        if (rememberedValue !== "1") {
          return;
        }

        transitionUrl.searchParams.set("filter", FILTER_NAME);
        window.location.replace(transitionUrl.toString());
      });
    });
  },
};
