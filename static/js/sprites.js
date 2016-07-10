
// 3rd
var PIXI = require('pixi.js');


//http://stackoverflow.com/questions/32078129/how-to-draw-multiple-instances-of-the-same-primitive-in-pixi-js

// Returns function that creates sprites
exports.makeTrailMaker = function (renderer, diameter) {
  var texture = new PIXI.RenderTexture(renderer, diameter, diameter);
  var g = new PIXI.Graphics();
  g.beginFill(0xF9C134);
  g.drawCircle(diameter/2,diameter/2,diameter/2);
  g.endFill();
  texture.render(g);
  return function makeTrail (x, y) {
    var sprite = new PIXI.Sprite(texture);
    sprite.position.set(x, y);
    sprite.alpha = 0.50;
    sprite.anchor.set(0.5);
    return sprite;
  };
}


exports.exhaustClip = function () {
  var base = new PIXI.Texture.fromImage('./img/exhaust.gif');
  var textures = [];
  for (var i = 0; i < 19; i++) {
    textures.push(new PIXI.Texture(base, new PIXI.Rectangle(i*16, 0, 16, 16)));
  }
  var clip = new PIXI.extras.MovieClip(textures);
  clip.animationSpeed = 0.70;
  clip.anchor.set(0.5);
  clip.loop = false;
  //clip.scale.set(1.30);
  clip.play();
  return clip;
};


exports.empburstClip = function () {
  var tilesize = 16 * 5;
  var base = new PIXI.Texture.fromImage('./img/empburst.gif');
  var textures = [];
  for (var i = 0; i < 2; i++) {
    for (var j = 0; j < 5; j++) {
      var x = j * tilesize;
      var y = i * tilesize;
      var rect = new PIXI.Rectangle(x, y, tilesize, tilesize);
      textures.push(new PIXI.Texture(base, rect));
    }
  }
  var clip = new PIXI.extras.MovieClip(textures);
  clip.animationSpeed = 0.25;
  clip.anchor.set(0.5);
  clip.loop = false;
  clip.scale.set(1.50);
  clip.play();
  return clip;
};
