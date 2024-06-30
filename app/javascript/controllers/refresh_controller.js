import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    waitTime: Number,
    playerId: Number,
    gameId: Number,
  }

  connect() {
    this.dispatch("setRedLight");

    new Promise((resolve) => setTimeout(resolve, this.waitTimeValue)).then(() => {
      fetch(`/games/${this.gameIdValue}/refresh/${this.playerIdValue}`);
    });
  }
}
