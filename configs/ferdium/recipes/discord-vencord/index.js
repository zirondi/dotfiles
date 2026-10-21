// Same user agent as the official Discord recipe (ferdium-recipes, MIT).
module.exports = Ferdium =>
  class DiscordVencord extends Ferdium {
    overrideUserAgent() {
      return window.navigator.userAgent
        .replace('(KHTML, like Gecko)', '(KHTML, like Gecko) discord/0.0.250')
        .replace('Electron', 'Discord')
        .replace('Ferdium', 'Discord')
        .replace('Apple Mac OS X', 'Intel Mac OS X')
        .replace('Apple macOS', 'Intel Mac OS X');
    }
  };
