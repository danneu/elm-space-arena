
// pull in desired CSS/SASS files
require('./css/main.scss');


// UTIL


// TODO: Figure out why this is larger than actual viewport
function getViewport () {
  return {
    x: document.documentElement.clientWidth - 5,
    y: document.documentElement.clientHeight - 5
  };
}


// STORES


// App state
var state = {
  player: {
    pos: { x: 0, y: 0 },
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


require('./vendor/pixi-3.0.11.min.js');

var stage = new PIXI.Stage(0x000000);
var renderer = PIXI.autoDetectRenderer(getViewport().x, getViewport().y);
document.body.appendChild(renderer.view);

// Starfield
var starfield = PIXI.extras.TilingSprite.fromImage('./img/starfield.jpg', getViewport().x, getViewport().y);
stage.addChild(starfield);

// Player
var player = new PIXI.Sprite.fromImage('./img/warbird.gif');
player.position.set(getViewport().x / 2, getViewport().y / 2);
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
  var offsetX = getViewport().x / 2 - state.player.pos.x;
  var offsetY = getViewport().y / 2 - state.player.pos.y;
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
  for (var id in state.bombs) {
    if (!newState.bombs[id]) {
      // remove bomb
      var sprite = sprites[id];
      bombs.removeChild(sprite);
      sprite.destroy();
      delete sprites[id];
    }
  }
  for (var id in newState.bombs) {
    var data = newState.bombs[id];
    var sprite = sprites[id];
    if (sprite) {
      // If there is a sprite, update it
      sprite.position.set(data.pos.x, data.pos.y);
    } else {
      // Else create it
      sprite = bombSprite('A', 1);
      sprites[data.id] = sprite;
      bombs.addChild(sprite);
    }
  }
  state = newState;
});

app.ports.grid.subscribe(function (json) {
  var blocks = JSON.parse(json);
  console.log('got grid', blocks);
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


// DOM EVENTS


window.onresize = function () {
  var viewport = getViewport();
  renderer.resize(viewport.x, viewport.y);
};


// SPRITE BUILDERS


// kind is A | B | C
// level is 1 | 2 | 3 | 4
function bombSprite (kind, level) {
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
  clip.scale.set(1.5, 1.5);
  clip.play();
  return clip;
}
