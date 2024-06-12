import { Controller } from "@hotwired/stimulus"

console.log('game_controller.js');

export default class extends Controller {
  static targets = [ 'slide' ]
  static values = { index: Number }

  indexValueChanged() {
    this.showCurrentSlide();
  }

  previous() {
    this.indexValue--;
  }

  next() {
    this.indexValue++;
  }

  showCurrentSlide() {
    this.slideTargets.forEach((element, idx) => {
      element.hidden = idx !== this.indexValue % this.slideTargets.length;
    });
  }
};
