import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    waitTime: Number,
    playerId: Number,
    gameId: Number,
  }

  connect() {
    let turnIndicator = document.getElementById("turn-indicator");
    let newValue = '';
    if (!turnIndicator.dataset.turnIndicatorMovesAllowedValue) {
      newValue = 'yes';
    }
    turnIndicator.dataset.turnIndicatorMovesAllowedValue = newValue;

    new Promise((resolve) => setTimeout(resolve, this.waitTimeValue)).then(() => {
      fetch(`/games/${this.gameIdValue}/refresh/${this.playerIdValue}`);
    });
  }
}
