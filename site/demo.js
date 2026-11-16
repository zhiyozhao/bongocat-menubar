// Demo for the BongoCat Menubar site. Same rules as the app:
// Follow Mode: a paw is down while any key on its side is held.
// Normal Mode: every key press alternates the paws; idle after 0.5 s.
// Runs only in this page. Nothing is stored or sent anywhere.
(() => {
  const LEFT = new Set(("Escape F1 F2 F3 F4 F5 Backquote Digit1 Digit2 Digit3 Digit4 Digit5 Tab KeyQ KeyW KeyE KeyR KeyT " +
    "KeyA KeyS KeyD KeyF KeyG ShiftLeft KeyZ KeyX KeyC KeyV KeyB ControlLeft AltLeft MetaLeft").split(" "));
  const RIGHT = new Set(("F6 F7 F8 F9 F10 F11 F12 Digit6 Digit7 Digit8 Digit9 Digit0 Minus Equal Backspace " +
    "KeyY KeyU KeyI KeyO KeyP BracketLeft BracketRight Backslash KeyH KeyJ KeyK KeyL Semicolon Quote Enter " +
    "KeyN KeyM Comma Period Slash ShiftRight Space MetaRight AltRight ControlRight ArrowLeft ArrowRight ArrowUp ArrowDown").split(" "));
  const hand = (code) => (LEFT.has(code) ? "left" : RIGHT.has(code) ? "right" : null);

  const cats = document.querySelectorAll(".cat[data-frame]");
  const keyEls = new Map([...document.querySelectorAll(".key[data-code]")].map((el) => [el.dataset.code, el]));
  const demo = document.querySelector(".demo");
  const reduceMotion = matchMedia("(prefers-reduced-motion: reduce)").matches;

  let follow = true;
  const held = { left: new Set(), right: new Set() };
  const pressed = new Set();
  let toggle = false, idleTimer = 0, frame = "idle";

  const show = (f) => {
    if (f === frame) return;
    frame = f;
    cats.forEach((c) => (c.dataset.frame = f));
  };
  const followFrame = () => {
    const l = held.left.size > 0, r = held.right.size > 0;
    show(l && r ? "both" : l ? "a" : r ? "b" : "idle");
  };
  const mark = (code, down) => keyEls.get(code)?.classList.toggle("down", down);

  function keyDown(code) {
    const h = hand(code);
    if (!h || pressed.has(code)) return;
    pressed.add(code);
    mark(code, true);
    if (follow) {
      held[h].add(code);
      followFrame();
    } else {
      toggle = !toggle;
      show(toggle ? "a" : "b");
      clearTimeout(idleTimer);
      idleTimer = setTimeout(() => show("idle"), 500);
    }
  }
  function keyUp(code) {
    const h = hand(code);
    if (!h) return;
    pressed.delete(code);
    mark(code, false);
    if (follow) {
      held[h].delete(code);
      followFrame();
    }
  }
  function releaseAll() {
    [...pressed].forEach(keyUp);
    held.left.clear();
    held.right.clear();
    if (follow) followFrame();
  }

  // Mode switch, like the app's menu. Switching puts the cat back to rest.
  document.querySelectorAll('input[name="mode"]').forEach((input) =>
    input.addEventListener("change", () => {
      releaseAll();
      follow = input.value === "follow";
      clearTimeout(idleTimer);
      toggle = false;
      show("idle");
    }));

  // Autoplay: types "bongo cat" until the visitor tries it themselves.
  const STROKES = [["KeyB", 0.9, 1.0], ["KeyO", 1.08, 1.17], ["KeyN", 1.24, 1.33], ["KeyG", 1.4, 1.52], ["KeyO", 1.46, 1.58],
    ["Space", 1.72, 1.81], ["KeyC", 1.92, 2.02], ["KeyA", 2.08, 2.17], ["KeyT", 2.24, 2.36]];
  let timers = [], loop = 0, resume = 0, playing = false;
  function play() {
    playing = true;
    const run = () => {
      timers = [];
      // "g" and "o" overlap briefly, so both paws come down for a moment.
      STROKES.forEach(([code, down, up]) => {
        timers.push(setTimeout(() => keyDown(code), down * 1000));
        timers.push(setTimeout(() => keyUp(code), up * 1000));
      });
    };
    run();
    loop = setInterval(run, 4000);
  }
  function stop() {
    if (playing) {
      timers.forEach(clearTimeout);
      timers = [];
      clearInterval(loop);
      playing = false;
      releaseAll();
    }
    clearTimeout(resume);
    if (!reduceMotion) resume = setTimeout(play, 6000);
  }
  if (!reduceMotion) play();

  // Real keyboard. Space and arrows would scroll the page, so while the demo is
  // on screen and nothing is focused, keep them for the cat.
  let demoVisible = true;
  new IntersectionObserver(([e]) => (demoVisible = e.isIntersecting)).observe(demo);
  const pageKeys = new Set(["Space", "ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight"]);
  addEventListener("keydown", (e) => {
    if (!hand(e.code)) return;
    const idle = document.activeElement === document.body || document.activeElement === null;
    if (pageKeys.has(e.code) && demoVisible && idle && !e.metaKey && !e.ctrlKey && !e.altKey) e.preventDefault();
    if (e.repeat) return;
    stop();
    keyDown(e.code);
  });
  addEventListener("keyup", (e) => {
    keyUp(e.code);
    // macOS browsers drop key-up events for keys released while Command is held.
    if (e.key === "Meta") releaseAll();
  });
  addEventListener("blur", releaseAll);

  // On-screen keys for touch and mouse.
  keyEls.forEach((el, code) => {
    el.addEventListener("pointerdown", (e) => {
      e.preventDefault();
      el.setPointerCapture?.(e.pointerId);
      stop();
      keyDown(code);
    });
    const up = () => keyUp(code);
    el.addEventListener("pointerup", up);
    el.addEventListener("pointercancel", up);
    el.addEventListener("lostpointercapture", up);
  });

  // Menu bar clock.
  const clocks = document.querySelectorAll(".clock");
  const tick = () => {
    const t = new Date().toLocaleTimeString([], { hour: "2-digit", minute: "2-digit", hour12: false });
    clocks.forEach((c) => (c.textContent = t));
  };
  tick();
  setInterval(tick, 15000);

  // Copy the install command.
  document.querySelectorAll(".copy").forEach((btn) =>
    btn.addEventListener("click", async () => {
      try {
        await navigator.clipboard.writeText(btn.dataset.copy);
        btn.textContent = btn.dataset.done;
      } catch {
        getSelection().selectAllChildren(btn.previousElementSibling);
      }
    }));
})();
