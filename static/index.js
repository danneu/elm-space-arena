
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
var sprites = require('./js/sprites');
var loader = require('./js/loader');


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
    pos: { x: 100, y: 100 },
    vel: { x: 0, y: 0 },
    acc: { x: 0, y: 0 }, // so we know when to play the engine sound
    angle: 0
  },
  bombs: {}
};

// Sprite store
var spriteStore = {};


// ELM


var Elm = require('../src/Main');
var app = Elm.Main.embed(document.getElementById('main'), {
  // Seed application with randomness
  startTime: Date.now()
});


// PIXI


var stage = new PIXI.Container();
var renderer = PIXI.autoDetectRenderer(viewport.x, viewport.y);
document.body.appendChild(renderer.view);

// Sprite factories

const makeTrail = sprites.makeTrailMaker(renderer, 16);

// Starfield
var starfield = PIXI.extras.TilingSprite.fromImage('./img/starfield.jpg', viewport.x, viewport.y);
starfield.alpha = 0.5;
stage.addChild(starfield);

// Greens
var greenLayer = new PIXI.Container();
stage.addChild(greenLayer);

// Player
var player = new PIXI.Sprite.fromImage('./img/warbird.gif');
player.position.set(viewport.x / 2, viewport.y / 2);
player.anchor.set(0.5);
stage.addChild(player);

// Grid
// Gets loaded with tiles in the `grid` subscription once app sends us the tilegrid
// Though needs to be mounted to the stage early so that it isn't drawn
// on top of anything.
var grid = new PIXI.Container();
stage.addChild(grid);

// Bombs
var bombs = new PIXI.Container();
stage.addChild(bombs);

// Trails
// TODO: Recycle/pool
var trails = new PIXI.Container();
stage.addChild(trails);

// Exhaust
var exhaustLayer = new PIXI.Container();
stage.addChild(exhaustLayer);

// EMP Bursts
var empburstLayer = new PIXI.Container();
stage.addChild(empburstLayer);


// DEBUG


/* setInterval(function () {
 *   console.log({
 *     bombs: bombs.children.length,
 *     trails: trails.children.length,
 *     exhaustLayer: exhaustLayer.children.length,
 *     empburstLayer: empburstLayer.children.length
 *   });
 * }, 1000);
 * */


// ASSET LOADER


loader
  // Begin render loop once assets are loaded
  .once('complete', function () {
    requestAnimationFrame(update);
  })
  .load();


// RENDER


var elapsed = Date.now();

function update () {
  requestAnimationFrame(update);
  var now = Date.now();
  var deltaTime = (now - elapsed) * 0.001;
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
  // Move greens
  greenLayer.position.set(offsetX, offsetY);
  // Move and decay exhaust
  exhaustLayer.position.set(offsetX, offsetY);
  for (var i = 0; i < exhaustLayer.children.length; i++) {
    var clip = exhaustLayer.children[i];
    // if clip is at final frame, destroy it
    if (clip.currentFrame === clip.totalFrames - 1) {
      exhaustLayer.removeChild(clip);
      clip.destroy();
    } else {
      // else, move it
      clip.position.x += clip.vel.x * deltaTime;
      clip.position.y += clip.vel.y * deltaTime;
    }
  }
  // Move and decay empbursts
  empburstLayer.position.set(offsetX, offsetY);
  for (var i = 0; i < empburstLayer.children.length; i++) {
    var clip = empburstLayer.children[i];
    // if clip is at final frame, destroy it
    if (clip.currentFrame === clip.totalFrames - 1) {
      empburstLayer.removeChild(clip);
      clip.destroy();
    }
  }
  // Move and decay trails
  trails.position.set(offsetX, offsetY);
  for (var i = 0; i < trails.children.length; i++) {
    var trail = trails.children[i];
    if (trail.alpha < 0.1) {
      trails.removeChild(trail);
      trail.destroy();
    } else {
      trail.alpha *= 0.90
    }
  }
  // Move grid
  if (grid) {
    grid.position.set(offsetX, offsetY);
  }
  renderer.render(stage);
  elapsed = now;
}


// PORT EVENTS

// FIXME: This is getting scatterbrained and lazy
var lastExhaust = 0;
var exhaustForce = 70;
var lastTrail = 0;

app.ports.broadcast.subscribe(function (newState) {
  // Play engine sound if user is accelerating
  if (newState.player.acc.x === 0 && newState.player.acc.y === 0) {
    sounds.engine.pause();
  } else {
    sounds.engine.play();
    // FIXME: All this logic on the JS side is nasty
    // Show a puff of exhaust no more than every 50ms
    if (Date.now() - lastExhaust > 50) {
      var exhaust = sprites.exhaustClip();
      var pos = belt.tail(state.player.pos.x, state.player.pos.y, state.player.angle);
      exhaust.position.set(pos.x, pos.y);
      var reversing = false; // TODO
      exhaust.vel = {
        x: exhaustForce * Math.sin(state.player.angle + (reversing ? 0 : Math.PI)),
        y: exhaustForce * -Math.cos(state.player.angle + (reversing ? 0 : Math.PI))
      };
      exhaustLayer.addChild(exhaust);
      lastExhaust = Date.now();
    }
  }
  // If any oldState bombs aren't in the newState, then remove them
  for (var id in state.bombs) {
    if (!newState.bombs[id]) {
      // remove bomb
      var sprite = spriteStore[id];
      bombs.removeChild(sprite);
      sprite.destroy();
      delete spriteStore[id];
    }
  }
  // Upsert newState bombs
  for (var id in newState.bombs) {
    var data = newState.bombs[id];
    var sprite = spriteStore[id];
    if (sprite) {
      // If there is a sprite, update it
      // And only make a trail every 50ms
      if (Date.now() - lastTrail > 50) {
        var trail =
          makeTrail(sprite.position.x, sprite.position.y, sprite.width / 3);
        trails.addChild(trail);
        lastTrail = Date.now();
      }
      sprite.position.set(data.pos.x, data.pos.y);
    } else {
      // Else create it
      sprite = sprites.bombClip('B', 2);
      spriteStore[data.id] = sprite;
      bombs.addChild(sprite);
    }
  }
  state = newState;
});

app.ports.grid.subscribe(function (data) {
  // short-circuit on hot-reload
  if (grid.children.length > 0) return;
  data.tiles.forEach(function (tile) {
    var sprite;
    if (tile.kind === 'BOX') {
      sprite = new PIXI.extras.TilingSprite.fromImage('./img/wall.png', 16, 16);
    } else if (tile.kind === 'EMPTY') {
      sprite = new PIXI.extras.TilingSprite(PIXI.Texture.EMPTY, 16, 16);
    }
    sprite.anchor.set(0.5);
    sprite.position.set(tile.pos.x, tile.pos.y);
    grid.addChild(sprite);
    // .state is my personal place to put stuff
    sprite.state = {
      idx: tile.idx
    };
    // Hook up handlers to each sprite
    connectTileSprite(sprite);
  });
});

app.ports.bombHitWall.subscribe(function (bomb) {
  var clip = sprites.empburstClip();
  clip.position.x = bomb.pos.x;
  clip.position.y = bomb.pos.y;
  empburstLayer.addChild(clip);
  sounds.bombExplode.play();
});

app.ports.greenSpawned.subscribe(function (tile) {
  var clip = sprites.greenClip(tile.pos.x, tile.pos.y);
  greenLayer.addChild(clip);
});

app.ports.greensCollected.subscribe(function (tiles) {
  // destroy greens
  greenLayer.children.filter(function (clip) {
    return tiles.some(function (tile) {
      return clip.position.x === tile.pos.x && clip.position.y === tile.pos.y;
    });
  }).forEach(function (clip) {
    greenLayer.removeChild(clip);
    clip.destroy();
  });
  // play sound
  sounds.green.play();
});

app.ports.playerHitWall.subscribe(function () {
  sounds.bounce.play();
});

app.ports.playerBomb.subscribe(function () {
  sounds.bombShoot.play();
});


// MAP BUILDING


// While a fun experiment, this project will become insufferable
// unless I start abstracting this.
app.ports.tileUpdated.subscribe(function (tile) {
  console.log('update', tile);
  var sprite = grid.children.find(function (sprite) {
    return sprite.state.idx.x === tile.idx.x
      && sprite.state.idx.y === tile.idx.y;
  });
  if (tile.kind === 'EMPTY') {
    sprite.texture = PIXI.Texture.EMPTY;
  } else if (tile.kind === 'BOX') {
    sprite.texture = PIXI.Texture.fromImage('./img/wall.png');
  }
  if (!tile.green) {
    var green = greenLayer.children.find(function (sprite) {
      return sprite.position.x === tile.pos.x
        && sprite.position.y === tile.pos.y;
    });
    if (green) {
      greenLayer.removeChild(green);
      green.destroy();
    }
  }
});


// DOM EVENTS


window.onresize = function () {
  viewport = getViewport();
  renderer.resize(viewport.x, viewport.y);
  player.position.set(viewport.x / 2, viewport.y / 2);
  starfield.width = viewport.x;
  starfield.height = viewport.y;
};


// TILE SPRITE INTERACTIVITY


function connectTileSprite (sprite) {
  sprite.interactive = true;
  sprite.on('mousedown', onTileClick);
}

function onTileClick () {
  console.log('tile click', this.state.idx);
  app.ports.tileClicked.send([this.state.idx.x, this.state.idx.y]);
}
