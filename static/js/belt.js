'use strict';

// Get random item in an array
exports.randNth = function (items) {
  return items[Math.floor(Math.random() * items.length)];
};
