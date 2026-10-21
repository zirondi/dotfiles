// Session preload registered by webview.js (see vencord.js). It runs at
// document start in every frame of the service, so it only acts on
// Discord's top frame.
if (window.top === window && window.location.hostname === 'discord.com') {
  require('./vencord').inject();
}
