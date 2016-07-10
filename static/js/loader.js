
var PIXI = require('pixi.js');


module.exports = new PIXI.loaders.Loader()
  .add('tile:wall', './img/wall.png')
  .add('starfield', './img/starfield.jpg')
  .add('ship:warbird', './img/warbird.gif')
  .add('exhaust', './img/exhaust.gif')
  .add('empburst', './img/empburst.gif')
  .add('bombs', './img/bombs.gif')
  .add('prizes', './img/prizes.gif');
