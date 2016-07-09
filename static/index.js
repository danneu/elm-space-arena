
// pull in desired CSS/SASS files
require('./css/main.scss');

// inject bundled Elm app into div#main

var Elm = require('../src/Main');

var app = Elm.Main.embed(document.getElementById('main'), {
  viewport: getViewport()
});

window.onresize = function () {
  app.ports.resizes.send(getViewport());
};

function getViewport () {
  return {
    x: window.innerWidth,
    y: window.innerHeight
    //x: document.documentElement.clientWidth,
    //y: document.documentElement.clientHeight
  };
}
