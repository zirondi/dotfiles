// The official Discord recipe (ferdium-recipes, MIT) plus Vencord.
const path = require('path');
const vencord = require('./vencord');

module.exports = (Ferdium, settings) => {
  // Registers the preload that injects Vencord, and refreshes its cache.
  vencord.setup();

  const getMessages = () => {
    let directCount = 0;
    const directCountPerServer = document.querySelectorAll(
      '[class*="lowerBadge_"] [class*="numberBadge_"]',
    );

    for (const directCountBadge of directCountPerServer) {
      directCount += Ferdium.safeParseInt(directCountBadge.textContent);
    }

    const indirectCountPerServer =
      document.title.search('• Discord') === -1 ? 0 : 1;

    Ferdium.setBadge(directCount, indirectCountPerServer);
  };

  Ferdium.loop(getMessages);

  Ferdium.injectCSS(path.join(__dirname, 'service.css'));
  Ferdium.injectJSUnsafe(path.join(__dirname, 'notification-compatibility.js'));

  document.addEventListener(
    'click',
    event => {
      const link = event.target.closest('a[href^="http"]');
      const button = event.target.closest('button[title^="http"]');

      if (link || button) {
        const url = link
          ? link.getAttribute('href')
          : button.getAttribute('title');
        const skipDomains = [
          /^https:\/\/discordapp\.com\/channels\//i,
          /^https:\/\/discord\.com\/channels\//i,
        ];

        let stayInsideDiscord;
        skipDomains.every(skipDomain => {
          stayInsideDiscord = skipDomain.test(url);
          return !stayInsideDiscord;
        });

        if (!Ferdium.isImage(link) && !stayInsideDiscord) {
          event.preventDefault();
          event.stopPropagation();

          if (
            // Always open file downloads in Ferdium, rather than the external browser
            url.includes('discordapp.com/attachments/') ||
            settings.trapLinkClicks === true
          ) {
            window.location.href = url;
          } else {
            Ferdium.openNewWindow(url);
          }
        }
      }
    },
    true,
  );
};
