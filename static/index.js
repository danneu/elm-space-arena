
// CSS

require('./css/main.scss');

// JS

// 3rd party
// TODO: Even without `var PIXI = ...`, PIXI is available just by
//       writing `require('pixi.js')`. Is there a way to change this behavior
//       so that I must assign the return value to use PIXI?
var PIXI = require('pixi.js');
// 1st party
var sounds = require('./js/sounds');
var belt = require('./js/belt');


// UTIL


// TODO: Figure out why this is larger than actual viewport
function getViewport () {
  return {
    x: document.documentElement.clientWidth - 5,
    y: document.documentElement.clientHeight - 5
  };
}


// STORES


// Viewport store
var viewport = getViewport();

// App state
var state = {
  player: {
    pos: { x: 0, y: 0 },
    acc: { x: 0, y: 0 }, // so we know when to play the engine sound
    angle: 0
  },
  bombs: {}
};

// Sprite store
var sprites = {};


// ELM


var Elm = require('../src/Main');
var app = Elm.Main.embed(document.getElementById('main'), null);


// PIXI


var stage = new PIXI.Stage(0x000000);
var renderer = PIXI.autoDetectRenderer(viewport.x, viewport.y);
document.body.appendChild(renderer.view);

// Starfield
var starfield = PIXI.extras.TilingSprite.fromImage('./img/starfield.jpg', viewport.x, viewport.y);
starfield.alpha = 0.5;
stage.addChild(starfield);

// Player
var player = new PIXI.Sprite.fromImage('./img/warbird.gif');
player.position.set(viewport.x / 2, viewport.y / 2);
player.anchor.set(0.5);
stage.addChild(player);

// Bombs
var bombs = new PIXI.Container();
stage.addChild(bombs);

// Grid
var grid;


// RENDER


requestAnimationFrame(animate);

function animate () {
  requestAnimationFrame(animate);
  // Camera offset, since we keep our player ship in the center
  var offsetX = viewport.x / 2 - state.player.pos.x;
  var offsetY = viewport.y / 2 - state.player.pos.y;
  // Animate starfield
  starfield.tilePosition.x = -state.player.pos.x / 2;
  starfield.tilePosition.y = -state.player.pos.y / 2;
  // Rotate player
  player.rotation = state.player.angle;
  // Move bombs
  bombs.position.set(offsetX, offsetY);
  // Move grid
  if (grid) {
    grid.position.set(offsetX, offsetY);
  }
  renderer.render(stage);
}


// PORT EVENTS


app.ports.broadcast.subscribe(function (json) {
  var newState = JSON.parse(json);
  // Play engine sound if user is accelerating
  if (newState.player.acc.x === 0 && newState.player.acc.y === 0) {
    sounds.engine.pause();
  } else {
    sounds.engine.play();
  }
  // If any oldState bombs aren't in the newState, then remove them
  for (var id in state.bombs) {
    if (!newState.bombs[id]) {
      // remove bomb
      var sprite = sprites[id];
      bombs.removeChild(sprite);
      sprite.destroy();
      delete sprites[id];
    }
  }
  // Upsert newState bombs
  for (var id in newState.bombs) {
    var data = newState.bombs[id];
    var sprite = sprites[id];
    if (sprite) {
      // If there is a sprite, update it
      sprite.position.set(data.pos.x, data.pos.y);
    } else {
      // Else create it
      sprite = bombSprite();
      sprites[data.id] = sprite;
      bombs.addChild(sprite);
    }
  }
  state = newState;
});

app.ports.grid.subscribe(function (json) {
  // short-circuit on hot-reload
  if (grid) return;
  var blocks = JSON.parse(json);
  grid = new PIXI.Container();
  blocks.forEach(function (block) {
    var sprite = new PIXI.Sprite.fromImage('./img/wall.png');
    sprite.anchor.set(0.5);
    sprite.width = 16;
    sprite.height = 16;
    sprite.position.set(block.pos.x, block.pos.y);
    grid.addChild(sprite);
  });
  stage.addChild(grid);
});

app.ports.playerHitWall.subscribe(function () {
  sounds.bounce.play();
});

app.ports.playerBomb.subscribe(function () {
  sounds.bomb.play();
});


// DOM EVENTS


window.onresize = function () {
  viewport = getViewport();
  renderer.resize(viewport.x, viewport.y);
  player.position.set(viewport.x / 2, viewport.y / 2);
  starfield.width = viewport.x;
  starfield.height = viewport.y;
};


// SPRITE BUILDERS


// kind is A | B | C
// level is 1 | 2 | 3 | 4
function bombSprite (kind, level) {
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
  clip.scale.set(1.5);
  clip.play();
  return clip;
}
