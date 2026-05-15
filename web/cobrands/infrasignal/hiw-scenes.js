// Loop the How It Works storyboard scenes while they are visible.
(function () {
  "use strict";

  var CYCLE = 5000;
  var STAGGER = 650;
  var scenes = document.querySelectorAll(".step-scene .scene");
  var reduced = window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  var timers = typeof WeakMap === "function" ? new WeakMap() : null;

  function restart(scene) {
    scene.classList.remove("is-playing");
    void scene.offsetWidth;
    scene.classList.add("is-playing");
  }

  function clearSceneTimer(scene) {
    if (!timers) {
      return;
    }

    var sceneTimers = timers.get(scene);
    if (sceneTimers) {
      clearTimeout(sceneTimers.timeout);
      clearInterval(sceneTimers.interval);
      timers.delete(scene);
    }
  }

  function startScene(scene, index) {
    var delay = (index || 0) * STAGGER;

    if (!timers) {
      setTimeout(function () {
        restart(scene);
      }, delay);
      return;
    }

    var sceneTimers = {};
    sceneTimers.timeout = setTimeout(function () {
      restart(scene);

      sceneTimers.interval = setInterval(function () {
        restart(scene);
      }, CYCLE);
    }, delay);

    timers.set(scene, sceneTimers);
  }

  if (!scenes.length) {
    return;
  }

  if (reduced) {
    for (var i = 0; i < scenes.length; i++) {
      scenes[i].classList.add("is-static");
    }
    return;
  }

  for (var resetIndex = 0; resetIndex < scenes.length; resetIndex++) {
    scenes[resetIndex].classList.remove("is-playing");
  }

  if (!("IntersectionObserver" in window)) {
    for (var j = 0; j < scenes.length; j++) {
      startScene(scenes[j], j);
    }
    return;
  }

  var observer = new IntersectionObserver(function (entries) {
    for (var i = 0; i < entries.length; i++) {
      var entry = entries[i];
      clearSceneTimer(entry.target);

      if (entry.isIntersecting) {
        startScene(entry.target, Array.prototype.indexOf.call(scenes, entry.target));
      }
    }
  }, { threshold: 0.25 });

  for (var k = 0; k < scenes.length; k++) {
    observer.observe(scenes[k]);
  }
}());