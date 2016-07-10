
// 3rd
var PIXI = require('pixi.js');
// 1st
var belt = require('./belt');


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


// kind is A | B | C
// level is 1 | 2 | 3 | 4
exports.bombClip = function (kind, level) {
  // Randomize if kind/level aren't set
  kind = kind || belt.randNth(['A', 'B', 'C']);
  level = level || Math.floor(Math.random() * 4 + 1);
  var base = new PIXI.Texture.fromImage('./img/bombs.gif');
  var textures = [];
  var rowIdx = { 'A': 0, 'B': 1, 'C': 2 };
  var offsetY = rowIdx[kind] *
    (16 * 4) +       //  (rowHeight * levelsPerKind)
    ((level - 1) * 16);
  for (var i = 0; i < 10; i++) {
    textures.push(new PIXI.Texture(base, new PIXI.Rectangle(i*16, offsetY, 16, 16)));
  }
  var clip = new PIXI.extras.MovieClip(textures);
  clip.animationSpeed = 0.10;
  clip.anchor.set(0.5);
  clip.scale.set(1.30);
  clip.play();
  return clip;
};
