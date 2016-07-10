'use strict';

// 3rd party
var Howl = require('howler').Howl;
var Howler = require('howler').Howler;
// 1st party
var belt = require('./belt');


module.exports = {
  // I want to be able to spam play()/pause(), but Howler launches a
  // new sound instance for each play(). I built this mechanism to
  // ensure there's only one engine sound every playing.
  engine: (function () {
    var playing = false;
    var sound = new Howl({
      urls: ['./sounds/rev.mp3'],
      loop: true,
      onplay: function () { playing = true },
      onpause: function () { playing = false },
      volume: 0.5
    })
    return {
      play: function () {
        if (playing) return;
        sound.play();
      },
      pause: function () {
        sound.pause();
      }
    };
  })(),
  bounce: new Howl({
    urls: ['./sounds/bounce.mp3'],
  }),
  bomb: (function () {
    var _sounds = [
      new Howl({urls: ['./sounds/bomb1.mp3'], volume: 0.1}),
      new Howl({urls: ['./sounds/bomb2.mp3'], volume: 0.1}),
      new Howl({urls: ['./sounds/bomb3.mp3'], volume: 0.1}),
      new Howl({urls: ['./sounds/bomb2.mp3'], volume: 0.1})
    ];
    return {
      play: function () {
        return belt.randNth(_sounds).play();
      }
    };
  })()
};
