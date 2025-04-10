import "https://cdn.jsdelivr.net/npm/interactjs/dist/interact.min.js"

const canvas = document.getElementById("glcanvas");
canvas.width = window.innerWidth;
canvas.height = window.innerHeight;
const gl = canvas.getContext("webgl");

let rotationX = 0;
let rotationY = 0;

interact('#glcanvas')
    .draggable({
      inertia: true,   // Enable inertia
      modifiers: [
        interact.modifiers.restrict({
          restriction: 'parent',
        }),
      ],
      onmove(event) {
        rotationX += event.dy * 0.01;  // Adjust the sensitivity
        rotationY += event.dx * -0.01;  // Adjust the sensitivity
      }
    });

async function loadShaderSource(url) {
  const response = await fetch(url);
  return response.text();
}

function compileShader(type, source) {
  const shader = gl.createShader(type);
  gl.shaderSource(shader, source);
  gl.compileShader(shader);
  if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
    console.error('Shader error:', gl.getShaderInfoLog(shader));
    return null;
  }
  return shader;
}

async function main() {
  const [vertexSrc, fragmentSrc] = await Promise.all([
    loadShaderSource('vertex.glsl'),
    loadShaderSource('fragment.glsl')
  ]);

  const vertexShader = compileShader(gl.VERTEX_SHADER, vertexSrc);
  const fragmentShader = compileShader(gl.FRAGMENT_SHADER, fragmentSrc);

  const program = gl.createProgram();
  gl.attachShader(program, vertexShader);
  gl.attachShader(program, fragmentShader);
  gl.linkProgram(program);
  gl.useProgram(program);

  const vertices = new Float32Array([-1, -1, 3, -1, -1, 3]);
  const buffer = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
  gl.bufferData(gl.ARRAY_BUFFER, vertices, gl.STATIC_DRAW);
  const aPosition = gl.getAttribLocation(program, "aPosition");
  gl.enableVertexAttribArray(aPosition);
  gl.vertexAttribPointer(aPosition, 2, gl.FLOAT, false, 0, 0);

  const uTime = gl.getUniformLocation(program, "uTime");
  const uResolution = gl.getUniformLocation(program, "uResolution");

  const uRotationX = gl.getUniformLocation(program, "uRotationX");
  const uRotationY = gl.getUniformLocation(program, "uRotationY");


  function render(time) {
    time *= 0.001;
    gl.viewport(0, 0, canvas.width, canvas.height);
    gl.clear(gl.COLOR_BUFFER_BIT);
    gl.uniform1f(uTime, time);
    gl.uniform1f(uRotationX, rotationX)
    gl.uniform1f(uRotationY, rotationY)

    gl.uniform2f(uResolution, canvas.width, canvas.height);
    gl.drawArrays(gl.TRIANGLES, 0, 3);
    requestAnimationFrame(render);
  }

  render();
}

main();