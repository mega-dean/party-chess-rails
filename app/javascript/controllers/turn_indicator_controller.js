import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    currentColor: String,
    turnDuration: Number,
    movesAllowed: String,
  }

  get low() { return 50; }

  connect() {
    let trafficLight = document.getElementById("traffic-lights");
    trafficLight.style = `background: ${this.currentColorValue}`;

    this.changeColors({
      green: [0, 255, 0],
      yellow: [this.low, this.low, 0],
      red: [this.low, 0, 0],
    });

    const greenLightTimeout = (this.turnDurationValue - 5) * 1000;

    new Promise((resolve) => setTimeout(resolve, greenLightTimeout)).then(() => {
      this.changeColors({
        green: [0, this.low, 0],
        yellow: [255, 255, 0],
      });
    });
  }

  movesAllowedValueChanged() {
    let trafficLight = document.getElementById("traffic-lights");

    this.changeColors({
      green: [0, this.low, 0],
      yellow: [this.low, this.low, 0],
      red: [255, 0, 0],
    });
  }

  changeColors(colors) {
    const maybeChangeLight = (colors, color) => {
      const rgb = colors[color];
      if (rgb) {
        let light = document.getElementById(`${color}-light`);
        light.style = `background: rgba(${rgb[0]}, ${rgb[1]}, ${rgb[2]}, 50)`;
      }
    };

    maybeChangeLight(colors, 'green');
    maybeChangeLight(colors, 'yellow');
    maybeChangeLight(colors, 'red');
  }
}
