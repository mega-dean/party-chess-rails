import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    currentColor: String,
    greenLightTimeout: String,
  }

  connect() {
    let trafficLight = document.$("#traffic-lights");

    trafficLight.style.background = this.currentColorValue;

    if (this.greenLightTimeoutValue > 0) {
      this.lightColor('green');
      new Promise((resolve) => setTimeout(resolve, this.greenLightTimeoutValue)).then(() => {
        this.lightColor('yellow');
      });
    } else {
      this.lightColor('yellow');
    }
  }

  setRedLight() {
    this.lightColor('red');
  }

  lightColor(color) {
    let green = 50;
    let yellow = 50;
    let red = 50;

    if (color === 'green') {
      green = 255;
    } else if (color === 'yellow') {
      yellow = 255;
    } else if (color === 'red') {
      red = 255
    }

    this.changeColors({
      green: [0, green, 0],
      yellow: [yellow, yellow, 0],
      red: [red, 0, 0],
    });
  }

  changeColors(colors) {
    const changeLight = (colors, color) => {
      const rgb = colors[color];
      let light = document.$(`#${color}-light`);
      light.style = `background: rgba(${rgb[0]}, ${rgb[1]}, ${rgb[2]}, 50)`;
    };

    changeLight(colors, 'green');
    changeLight(colors, 'yellow');
    changeLight(colors, 'red');
  }
}
