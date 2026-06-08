<h1>x86 Assembly Pong Game</h1>

<p>
A classic Pong game implemented in x86 Assembly Language for DOS, using BIOS interrupts, VGA text mode memory, and custom hardware interrupt handling.
</p>

<h2>Features</h2>
<ul>
  <li>Two-player Pong gameplay</li>
  <li>Real-time keyboard input (IRQ1)</li>
  <li>Timer-driven ball movement (IRQ0)</li>
  <li>Paddle and wall collision detection</li>
  <li>Score tracking (first to 3 wins)</li>
  <li>Win screen with ASCII art</li>
  <li>Sound effects via system speaker</li>
  <li>Direct VGA text-mode rendering (0xB800)</li>
</ul>

<h2>Technical Highlights</h2>
<ul>
  <li>Custom Interrupt Service Routines for keyboard and timer</li>
  <li>Direct hardware control without OS libraries</li>
  <li>Memory-mapped VGA graphics</li>
  <li>BIOS interrupts for input and display</li>
  <li>Low-level real-mode game loop in x86 assembly</li>
</ul>

<h2>Controls</h2>
<ul>
  <li>Player A: W / S</li>
  <li>Player B: Up / Down Arrow</li>
</ul>

<h2>Run Instructions</h2>
<pre><code>nasm pong.asm -f bin -o pong.com</code></pre>

<p>Run in DOSBox:</p>
<pre><code>pong.com</code></pre>

<h2>Purpose</h2>
<p>
This project was developed as a semester assignment to demonstrate low-level systems programming, interrupt handling, and hardware-level game development in x86 assembly.
</p>
