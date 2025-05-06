<script lang="ts">
  import { onMount, onDestroy } from "svelte";
  import type { HTMLCanvasAttributes } from "svelte/elements";
  // Import BrachistochroneSolver from the main JS file
  import { BrachistochroneSolver } from "wasm/brachistochrone_solver.js";
  // Import memory from the background WASM JS file
  import { memory } from "wasm/brachistochrone_solver_bg.wasm"; // Adjust if your bundler handles .wasm differently

  // --- Props ---
  export let style: string = "border:1px solid #000;";
  export let id: string =
    "canvas-" + Math.random().toString(36).substring(2, 15); // Generate a somewhat unique ID

  // --- Constants ---
  const NUM_POINTS = 256; // Number of points to draw the cycloid
  const pointRadius = 10;

  // --- WASM ---
  // Use the imported class directly
  const solver = BrachistochroneSolver.new();

  // --- Component State ---
  let canvasElement: HTMLCanvasElement | null = null;
  let ctx: CanvasRenderingContext2D | null = null;
  let clientWidth: number = 0; // Bound to canvas display width
  let clientHeight: number = 0; // Bound to canvas display height
  let pointA = { x: 100, y: 200 };
  let pointB = { x: 400, y: 250 };
  let draggingPoint: "A" | "B" | null = null;
  let offsetX = 0;
  let offsetY = 0;
  let showHint = true; // State to control hint visibility

  // --- Initial Solve ---
  // Needs to be done after pointA/pointB are initialized
  solver.solve(pointA.x, pointA.y, pointB.x, pointB.y);

  // --- Forward Declaration for redrawCanvas ---
  // Necessary because redrawCanvas is used in the reactive block below,
  // and the reactive block needs to be defined before lifecycle hooks that might trigger it.
  let redrawCanvas: () => void;

  // --- Reactive Statement ---
  // Update canvas resolution and redraw on resize
  $: if (canvasElement && ctx && clientWidth > 0 && clientHeight > 0) {
    // Check if size actually changed to avoid unnecessary redraws/clearing
    if (
      canvasElement.width !== clientWidth ||
      canvasElement.height !== clientHeight
    ) {
      canvasElement.width = clientWidth;
      canvasElement.height = clientHeight;
      if (redrawCanvas) redrawCanvas(); // Redraw with new dimensions (check if defined)
    }
  }

  // --- Drawing Functions ---

  /** Draws a cycloid path on the canvas. */
  function drawCycloid(
    localCtx: CanvasRenderingContext2D,
    options: { color?: string; lineWidth?: number } = {}
  ): void {
    const { color = "black", lineWidth = 3 } = options;

    localCtx.beginPath();
    localCtx.strokeStyle = color;
    localCtx.lineWidth = lineWidth;
    // Re-solve whenever drawing, as points might have moved
    solver.solve(pointA.x, pointA.y, pointB.x, pointB.y);

    const points_ptr = solver.points();
    const points = new Float64Array(memory.buffer, points_ptr, 2 * NUM_POINTS);

    if (points.length < 2) return; // Ensure we have at least one point

    localCtx.moveTo(points[0], points[1]); // Start at point A
    for (let i = 2; i < points.length; i += 2) {
      const x = points[i];
      const y = points[i + 1];
      localCtx.lineTo(x, y);
    }

    localCtx.stroke(); // Draw the path
  }

  /** Draws a point with a label */
  function drawPoint(
    context: CanvasRenderingContext2D,
    x: number,
    y: number,
    label: string,
    color: string
  ) {
    context.beginPath();
    context.arc(x, y, pointRadius, 0, Math.PI * 2);
    context.fillStyle = color;
    context.fill();
    context.fillStyle = "white";
    context.font = "bold 12px sans-serif";
    context.textAlign = "center";
    context.textBaseline = "middle";
    context.fillText(label, x, y);
  }

  /** Draws an arrow between two points */
  function drawArrow(
    context: CanvasRenderingContext2D,
    fromX: number,
    fromY: number,
    toX: number,
    toY: number,
    color: string = "black",
    lineWidth: number = 2
  ) {
    const headlen = 10; // length of head in pixels
    const dx = toX - fromX;
    const dy = toY - fromY;
    const angle = Math.atan2(dy, dx);

    context.save(); // Save context state
    context.strokeStyle = color;
    context.lineWidth = lineWidth;
    context.beginPath();
    context.moveTo(fromX, fromY);
    context.lineTo(toX, toY);
    context.lineTo(
      toX - headlen * Math.cos(angle - Math.PI / 6),
      toY - headlen * Math.sin(angle - Math.PI / 6)
    );
    context.moveTo(toX, toY);
    context.lineTo(
      toX - headlen * Math.cos(angle + Math.PI / 6),
      toY - headlen * Math.sin(angle + Math.PI / 6)
    );
    context.stroke();
    context.restore(); // Restore context state
  }

  /** Clears and redraws the entire canvas */
  redrawCanvas = () => {
    // Assign implementation to the forward-declared variable
    if (!ctx || !canvasElement) return;

    // Clear canvas using the current dynamic width/height
    ctx.clearRect(0, 0, canvasElement.width, canvasElement.height);

    // Draw cycloid
    drawCycloid(ctx, { color: "#004d99", lineWidth: 3 });

    // Draw points
    drawPoint(ctx, pointA.x, pointA.y, "A", "red");
    drawPoint(ctx, pointB.x, pointB.y, "B", "purple");

    // Draw info text in the upper right corner
    ctx.fillStyle = "black";
    ctx.font = "14px monospace";
    ctx.textAlign = "right";
    ctx.textBaseline = "top";
    const textX = canvasElement.width - 10;
    const textY = 10;
    const lineHeight = 18; // Adjust as needed for spacing

    ctx.fillText(
      `Point A: (${pointA.x.toFixed(2)}, ${pointA.y.toFixed(2)})`,
      textX,
      textY
    );
    ctx.fillText(
      `Point B: (${pointB.x.toFixed(2)}, ${pointB.y.toFixed(2)})`,
      textX,
      textY + lineHeight
    );

    ctx.fillText(`Eq: x(θ) = r(θ - sin(θ))`, textX, textY + 2 * lineHeight);
    ctx.fillText(`    y(θ) = r(1 - cos(θ))`, textX, textY + 3 * lineHeight);

    // Format equation string based on theta_max sign
    const thetaMaxFormatted = solver.theta_max.toFixed(2);
    const rhoFormatted = solver.rho.toFixed(2);
    const thetaRange =
      solver.theta_max >= 0
        ? `[0, +${thetaMaxFormatted}]`
        : `[${thetaMaxFormatted}, 0]`;
    const equationText = `r=${rhoFormatted}, θ ∈ ${thetaRange}`;

    ctx.fillText(equationText, textX, textY + 4 * lineHeight);

    // Draw hint if needed
    if (showHint) {
      const hintText = "Move the points!";
      // Position hint text roughly between the points
      const hintX = (pointA.x + pointB.x) / 2 + 60;
      const hintY = (pointA.y + pointB.y) / 2 - 60; // Adjust vertical offset as needed

      // Calculate text width for background rectangle
      ctx.font = "bold 16px sans-serif"; // Set font before measuring
      const textMetrics = ctx.measureText(hintText);
      const textWidth = textMetrics.width;
      const textHeight = 16; // Approximate height based on font size
      const padding = 10;

      // Draw semi-transparent background
      ctx.fillStyle = "rgba(0, 0, 0, 0.7)";
      ctx.fillRect(
        hintX - textWidth / 2 - padding,
        hintY - textHeight / 2 - padding,
        textWidth + 2 * padding,
        textHeight + 2 * padding
      );

      // Draw hint text
      ctx.fillStyle = "white";
      ctx.textAlign = "center";
      ctx.textBaseline = "middle";
      ctx.fillText(hintText, hintX, hintY);

      // Draw arrows from hint text to points (use a visible color like black)
      const arrowStartY = hintY + textHeight / 2 + padding; // Start arrow below the background box
      drawArrow(
        ctx,
        hintX,
        arrowStartY,
        pointA.x + 15,
        pointA.y - 5,
        "black",
        2
      ); // Arrow to A
      drawArrow(
        ctx,
        hintX,
        arrowStartY,
        pointB.x - 15,
        pointB.y - 15,
        "black",
        2
      ); // Arrow to B
    }
  };

  // --- Helper Functions ---

  /** Checks if a click/touch is near a given point */
  function isNearPoint(
    x1: number,
    y1: number,
    x2: number,
    y2: number
  ): boolean {
    const distance = Math.sqrt((x1 - x2) ** 2 + (y1 - y2) ** 2);
    return distance < pointRadius * 1.5; // Use a slightly larger radius for easier interaction
  }

  /** Hides the hint text and redraws the canvas */
  function hideHintAndRedraw() {
    if (showHint) {
      showHint = false;
      redrawCanvas(); // Redraw immediately to remove the hint
    }
  }

  // --- Interaction Logic ---

  /** Gets mouse or touch position relative to the canvas, scaled to the internal resolution */
  function getPointerPos(
    canvas: HTMLCanvasElement,
    evt: MouseEvent | TouchEvent
  ) {
    const rect = canvas.getBoundingClientRect();
    // Use canvas.width/height which are now updated reactively
    const scaleX = canvas.width / rect.width;
    const scaleY = canvas.height / rect.height;

    let clientX: number;
    let clientY: number;

    if (evt instanceof MouseEvent) {
      clientX = evt.clientX;
      clientY = evt.clientY;
    } else if (evt.touches && evt.touches.length > 0) {
      // Use the first touch point for dragging
      clientX = evt.touches[0].clientX;
      clientY = evt.touches[0].clientY;
    } else {
      // Handle edge cases or other event types if necessary
      return { x: 0, y: 0 }; // Or throw an error
    }

    return {
      x: (clientX - rect.left) * scaleX,
      y: (clientY - rect.top) * scaleY,
    };
  }

  // Event Handlers
  function handlePointerDown(event: MouseEvent | TouchEvent) {
    hideHintAndRedraw(); // Hide hint on first interaction
    if (!canvasElement) return;
    // Prevent default touch behavior like scrolling when dragging on canvas
    if (event instanceof TouchEvent) {
      event.preventDefault();
    }
    const pos = getPointerPos(canvasElement, event);

    if (isNearPoint(pos.x, pos.y, pointA.x, pointA.y)) {
      draggingPoint = "A";
      offsetX = pos.x - pointA.x;
      offsetY = pos.y - pointA.y;
    } else if (isNearPoint(pos.x, pos.y, pointB.x, pointB.y)) {
      draggingPoint = "B";
      offsetX = pos.x - pointB.x;
      offsetY = pos.y - pointB.y;
    } else {
      draggingPoint = null;
    }
  }

  function handlePointerMove(event: MouseEvent | TouchEvent) {
    if (!draggingPoint || !canvasElement) return;
    // Prevent default touch behavior like scrolling when dragging on canvas
    if (event instanceof TouchEvent) {
      event.preventDefault();
    }
    const pos = getPointerPos(canvasElement, event);

    if (draggingPoint === "A") {
      pointA = { x: pos.x - offsetX, y: pos.y - offsetY };
    } else if (draggingPoint === "B") {
      pointB = { x: pos.x - offsetX, y: pos.y - offsetY };
    }
    // No need to call solve here, redrawCanvas calls drawCycloid which calls solve
    redrawCanvas(); // Redraw while dragging
  }

  function handlePointerUp() {
    draggingPoint = null;
  }

  function handlePointerLeave() {
    // For mouse, stop dragging if it leaves. Touch events don't have a direct 'leave' equivalent in the same way.
    // touchend handles the end of touch interaction.
    draggingPoint = null;
  }

  // --- Lifecycle ---
  onMount(() => {
    if (canvasElement) {
      ctx = canvasElement.getContext("2d");
      // Initial draw is handled by the reactive block `$: ...` which runs after mount
      // when clientWidth/clientHeight get their initial values.

      // Add event listeners directly to the canvas element
      // Mouse events
      canvasElement.addEventListener(
        "mousedown",
        handlePointerDown as EventListener
      );
      canvasElement.addEventListener(
        "mousemove",
        handlePointerMove as EventListener
      );
      window.addEventListener("mouseup", handlePointerUp); // Use window for mouseup
      canvasElement.addEventListener("mouseleave", handlePointerLeave);

      // Touch events
      canvasElement.addEventListener(
        "touchstart",
        handlePointerDown as EventListener,
        { passive: false }
      ); // Use passive: false to allow preventDefault
      canvasElement.addEventListener(
        "touchmove",
        handlePointerMove as EventListener,
        { passive: false }
      ); // Use passive: false to allow preventDefault
      window.addEventListener("touchend", handlePointerUp); // Use window for touchend

      // Perform an initial draw explicitly after context is obtained
      redrawCanvas();
    } else {
      console.error("Canvas element not found on mount");
    }
  });

  onDestroy(() => {
    // Clean up event listeners
    if (canvasElement) {
      // Mouse events
      canvasElement.removeEventListener(
        "mousedown",
        handlePointerDown as EventListener
      );
      canvasElement.removeEventListener(
        "mousemove",
        handlePointerMove as EventListener
      );
      window.removeEventListener("mouseup", handlePointerUp); // Remove from window
      canvasElement.removeEventListener("mouseleave", handlePointerLeave);

      // Touch events
      canvasElement.removeEventListener(
        "touchstart",
        handlePointerDown as EventListener
      );
      canvasElement.removeEventListener(
        "touchmove",
        handlePointerMove as EventListener
      );
      window.removeEventListener("touchend", handlePointerUp); // Remove from window
    }
  });

  // --- Exposed Methods ---
  export function getCanvas(): HTMLCanvasElement | null {
    return canvasElement;
  }

  export function drawCycloidExample() {
    // This might be redundant if redrawCanvas is sufficient
    redrawCanvas(); // Trigger redraw
  }

  // --- $$Props Interface ---
  // Allow passing through other canvas attributes
  // Remove id as it is explicitly defined above
  interface $$Props extends Omit<HTMLCanvasAttributes, "id"> {
    style?: string;
  }
</script>

<canvas
  bind:this={canvasElement}
  bind:clientWidth
  bind:clientHeight
  {id}
  {style}
  {...$$restProps}
></canvas>
