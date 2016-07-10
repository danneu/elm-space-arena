'use strict';

// Get random item in an array
exports.randNth = function (items) {
  return items[Math.floor(Math.random() * items.length)];
};

// FIXME: It's starting to get gross duplicating logic on the JS side.

exports.nose = function (x, y, rads) {
  var r = 15; // ship radius
  var noseX = x + r * Math.cos(rads - Math.PI/2)
  var noseY = y + r * Math.sin(rads - Math.PI/2)
  return { x: noseX, y: noseY };
}

exports.tail = function (x, y, rads) {
  return exports.nose(x, y, rads + Math.PI);
}
