// Loop the How It Works storyboard scenes while they are visible.
(function () {
  "use strict";

  var CYCLE = 5000;
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

    var timer = timers.get(scene);
    if (timer) {
      clearInterval(timer);
      timers.delete(scene);
    }
  }

  function startScene(scene) {
    restart(scene);

    if (!timers) {
      return;
    }

    timers.set(scene, setInterval(function () {
      restart(scene);
    }, CYCLE));
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

  if (!("IntersectionObserver" in window)) {
    for (var j = 0; j < scenes.length; j++) {
      startScene(scenes[j]);
    }
    return;
  }

  var observer = new IntersectionObserver(function (entries) {
    for (var i = 0; i < entries.length; i++) {
      var entry = entries[i];
      clearSceneTimer(entry.target);

      if (entry.isIntersecting) {
        startScene(entry.target);
      }
    }
  }, { threshold: 0.25 });

  for (var k = 0; k < scenes.length; k++) {
    observer.observe(scenes[k]);
  }
}());